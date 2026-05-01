"""Strategist agent — produces an AgentAssessment from full case state.

Reasons across rounds, not just the most recent. Recommends the next
round_type and the per-target drop/hold/concede split, plus open questions
for the tenant where the agent cannot decide unilaterally.

Soft citation validation: any NJSA citations referenced in `rationale` are
checked against the case's prior cited_statutes[] across all rounds. A
mismatch logs a warning but does NOT fail the call — the rationale is
advisory, not authoritative output. The Drafter inherits citations from the
brief and from prior rounds, not from the Strategist's narrative.
"""

from __future__ import annotations

import json
import logging
import re
import time
from pathlib import Path
from typing import Any

from anthropic import AsyncAnthropic

from api.shared.usage import UsageRecord, log_usage

from .drafter import _TONE_INSTRUCTIONS
from .schemas import AgentAssessment, NegotiationCase

DEFAULT_MODEL = "claude-opus-4-7"
MAX_TOKENS = 4000

PROMPT_PATH = Path(__file__).parent.parent.parent / "prompts" / "negotiator_strategist.md"

_logger = logging.getLogger(__name__)

# Loose NJSA-style citation pattern. Matches "NJSA 46:8-19", "N.J.S.A. 2A:18-61.1", etc.
_NJSA_PATTERN = re.compile(r"N\.?J\.?S\.?A\.?\s*\d+[A-Za-z]?:\d+-\d+(?:\.\d+)?", re.IGNORECASE)


def _render_prompt(case: NegotiationCase) -> str:
    if not PROMPT_PATH.exists():
        raise FileNotFoundError(
            f"Strategist prompt not found at {PROMPT_PATH}. "
            "Ensure prompts/negotiator_strategist.md exists at repo root."
        )
    template = PROMPT_PATH.read_text(encoding="utf-8")
    if "{TONE_INSTRUCTIONS}" not in template:
        raise RuntimeError(
            f"Strategist prompt at {PROMPT_PATH} is missing the {{TONE_INSTRUCTIONS}} placeholder."
        )
    return template.replace("{TONE_INSTRUCTIONS}", _TONE_INSTRUCTIONS[case.tenant_tone_preference])


def _serialize_case(case: NegotiationCase) -> str:
    payload: dict[str, Any] = {
        "case_id": case.case_id,
        "status": case.status,
        "tenant_tone_preference": case.tenant_tone_preference,
        "tenant_context": case.tenant_context.model_dump(mode="json"),
        "lease_brief": case.lease_brief.model_dump(mode="json"),
        "targets": [t.model_dump(mode="json") for t in case.targets],
        "rounds": [r.model_dump(mode="json") for r in case.rounds],
    }
    return json.dumps(payload, sort_keys=True, ensure_ascii=False, indent=2)


def _collect_prior_citations(case: NegotiationCase) -> set[str]:
    """All statute citation strings referenced by any prior round on the case."""
    seen: set[str] = set()
    for r in case.rounds:
        for c in r.cited_statutes:
            seen.add(c.citation)
    # Brief-level references are also "history" for citation purposes.
    for rf in case.lease_brief.red_flags:
        for c in rf.statute_citations:
            seen.add(c.citation)
    return seen


def _soft_validate_rationale(assessment: AgentAssessment, case: NegotiationCase) -> None:
    """Warn (don't raise) if rationale references a citation not in case history."""
    cited_in_rationale = set(_NJSA_PATTERN.findall(assessment.rationale))
    if not cited_in_rationale:
        return
    history = _collect_prior_citations(case)

    def _normalize(s: str) -> str:
        return re.sub(r"[\s\.]", "", s).upper()

    history_norm = {_normalize(c) for c in history}
    for c in cited_in_rationale:
        if _normalize(c) not in history_norm:
            _logger.warning(
                "Strategist rationale references citation '%s' which does not appear in "
                "any prior round's cited_statutes or in the brief's red_flags. "
                "Strategist output is advisory, so this is a soft warning — but the "
                "Drafter will reject this citation if it propagates downstream.",
                c,
            )


async def get_strategy_recommendation(
    case: NegotiationCase,
    *,
    client: AsyncAnthropic,
    model: str = DEFAULT_MODEL,
    max_tokens: int = MAX_TOKENS,
) -> AgentAssessment:
    """Run the Strategist on the current case state.

    Returns an AgentAssessment. Raises on truncation or parse failure.
    Soft-validates citations in the rationale (warning only).
    """
    system_prompt = _render_prompt(case)
    user_content_text = _serialize_case(case)

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
        output_config={"effort": "high"},
        system=system_blocks,
        messages=[{"role": "user", "content": user_content}],
        output_format=AgentAssessment,
    )
    latency_ms = int((time.perf_counter() - start) * 1000)

    if response.stop_reason == "max_tokens":
        raise RuntimeError(
            "Strategist truncated at max_tokens. AgentAssessment is incomplete and unsafe to return."
        )

    parsed = response.parsed_output
    if parsed is None:
        raise RuntimeError(
            f"Strategist returned no parseable output (stop_reason={response.stop_reason})."
        )

    log_usage(
        UsageRecord(
            stage="strategist",
            model=model,
            input_tokens=response.usage.input_tokens,
            output_tokens=response.usage.output_tokens,
            cache_read_input_tokens=response.usage.cache_read_input_tokens or 0,
            cache_creation_input_tokens=response.usage.cache_creation_input_tokens or 0,
            latency_ms=latency_ms,
            stop_reason=response.stop_reason or "unknown",
        )
    )

    _soft_validate_rationale(parsed, case)
    return parsed
