"""Reply Classifier agent — Haiku 4.5 structured extraction.

Takes a raw landlord reply (pasted by the tenant) plus the case state and
returns a LandlordReply with classification, per-target ExtractedOffers, and
calibrated confidence + reasoning.

Does NOT cite statutes. Does NOT recommend a next move (Strategist's job).
Verbatim_quote drift (against the original raw_text) is not validated in
v0.1; can be added in v0.2 if the classifier shows signs of paraphrasing.
"""

from __future__ import annotations

import json
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from anthropic import AsyncAnthropic

from api.shared.usage import UsageRecord, log_usage

from .drafter import _TONE_INSTRUCTIONS  # shared tone vocabulary
from .schemas import LandlordReply, NegotiationCase

DEFAULT_MODEL = "claude-haiku-4-5-20251001"
MAX_TOKENS = 4000

PROMPT_PATH = (
    Path(__file__).parent.parent.parent / "prompts" / "negotiator_reply_classifier.md"
)


def _render_prompt(case: NegotiationCase) -> str:
    if not PROMPT_PATH.exists():
        raise FileNotFoundError(
            f"Classifier prompt not found at {PROMPT_PATH}. "
            "Ensure prompts/negotiator_reply_classifier.md exists at repo root."
        )
    template = PROMPT_PATH.read_text(encoding="utf-8")
    if "{TONE_INSTRUCTIONS}" not in template:
        raise RuntimeError(
            f"Classifier prompt at {PROMPT_PATH} is missing the {{TONE_INSTRUCTIONS}} placeholder."
        )
    return template.replace("{TONE_INSTRUCTIONS}", _TONE_INSTRUCTIONS[case.tenant_tone_preference])


def _serialize_input(case: NegotiationCase, reply_text: str, received_at: datetime) -> str:
    """Pack raw_text + targets + most-recent round into a deterministic blob."""
    most_recent = case.rounds[-1] if case.rounds else None
    payload: dict[str, Any] = {
        "raw_text": reply_text,
        "received_at": received_at.isoformat(),
        "targets": [t.model_dump(mode="json") for t in case.targets],
        "most_recent_round": (
            {
                "round_number": most_recent.round_number,
                "round_type": most_recent.round_type,
                "draft_subject": most_recent.draft_subject,
                "draft_body": most_recent.draft_body,
                "targets_addressed": most_recent.targets_addressed,
            }
            if most_recent is not None
            else None
        ),
    }
    return json.dumps(payload, sort_keys=True, ensure_ascii=False, indent=2)


async def classify_reply(
    case: NegotiationCase,
    reply_text: str,
    *,
    client: AsyncAnthropic,
    received_at: datetime | None = None,
    model: str = DEFAULT_MODEL,
    max_tokens: int = MAX_TOKENS,
) -> LandlordReply:
    """Classify a pasted landlord reply.

    Returns a LandlordReply (not yet attached to the case — caller persists).
    Raises RuntimeError on truncation or parse failure (fail loud per Constraint 7).
    """
    if received_at is None:
        received_at = datetime.now(timezone.utc)

    system_prompt = _render_prompt(case)
    user_content_text = _serialize_input(case, reply_text, received_at)

    system_blocks = [
        {
            "type": "text",
            "text": system_prompt,
            "cache_control": {"type": "ephemeral"},
        }
    ]
    user_content = [{"type": "text", "text": user_content_text}]

    start = time.perf_counter()
    response = await client.messages.parse(
        model=model,
        max_tokens=max_tokens,
        thinking={"type": "adaptive"},
        output_config={"effort": "medium"},
        system=system_blocks,
        messages=[{"role": "user", "content": user_content}],
        output_format=LandlordReply,
    )
    latency_ms = int((time.perf_counter() - start) * 1000)

    if response.stop_reason == "max_tokens":
        raise RuntimeError(
            "Classifier truncated at max_tokens. "
            "Reply is too long to classify in one pass — split or summarize before re-running."
        )

    parsed = response.parsed_output
    if parsed is None:
        raise RuntimeError(
            f"Classifier returned no parseable output (stop_reason={response.stop_reason})."
        )

    log_usage(
        UsageRecord(
            stage="classifier",
            model=model,
            input_tokens=response.usage.input_tokens,
            output_tokens=response.usage.output_tokens,
            cache_read_input_tokens=response.usage.cache_read_input_tokens or 0,
            cache_creation_input_tokens=response.usage.cache_creation_input_tokens or 0,
            latency_ms=latency_ms,
            stop_reason=response.stop_reason or "unknown",
        )
    )

    return parsed
