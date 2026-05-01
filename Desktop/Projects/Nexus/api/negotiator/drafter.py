"""Drafter agent — produces NegotiationRound artifacts for any of six round_types.

One agent, six prompts (prompts/negotiator_drafter_<type>.md). The round_type
selects the prompt; the case state + tone preference are interpolated in.

Post-LLM validation: every cited_statutes entry is checked against the
curated NJ statute corpus (api.shared.citations.validate_statute_citation).
A hallucinated citation is a fail-loud error per Constraint 7 — the drafter
will not return a round whose authority cannot be grounded in the corpus.

Model: Opus 4.7 (effort=high). Cache_control on the system prompt block.
User content is serialized deterministically (sort_keys=True) so the cache
prefix is byte-stable across calls.
"""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any

from anthropic import AsyncAnthropic

from api.shared.citations import load_statutes, validate_statute_citation
from api.shared.usage import UsageRecord, log_usage

from .schemas import NegotiationCase, NegotiationRound, RoundType, TonePreference

DEFAULT_MODEL = "claude-opus-4-7"
MAX_TOKENS = 8000

_PROMPTS_DIR = Path(__file__).parent.parent.parent / "prompts"

_PROMPT_PATHS: dict[RoundType, Path] = {
    "OPENING": _PROMPTS_DIR / "negotiator_drafter_opening.md",
    "FOLLOW_UP": _PROMPTS_DIR / "negotiator_drafter_follow_up.md",
    "COUNTER": _PROMPTS_DIR / "negotiator_drafter_counter.md",
    "ESCALATION": _PROMPTS_DIR / "negotiator_drafter_escalation.md",
    "WALK_AWAY": _PROMPTS_DIR / "negotiator_drafter_walk_away.md",
    "ACCEPTANCE": _PROMPTS_DIR / "negotiator_drafter_acceptance.md",
}

_TONE_INSTRUCTIONS: dict[TonePreference, str] = {
    "firm": (
        "Tone: FIRM. Cite statutes by NJSA number where the prompt's CITATION DISCIPLINE allows. "
        "State legal consequences plainly. Direct, businesslike sentences. No hedge phrases. "
        "The tenant is asserting their position with respect — not apologizing for asking, "
        "not threatening. Authority comes from citation and documentary record."
    ),
    "neutral": (
        "Tone: NEUTRAL / professional. Reference statutes by topic on first mention "
        "(\"NJ's security deposit law\") and by NJSA number on subsequent reference where "
        "the prompt requires citations. Business-correspondence register. Polite but "
        "specific. This is the default tone for most tenants."
    ),
    "conciliatory": (
        "Tone: CONCILIATORY. Frame asks as collaborative problem-solving rather than demands. "
        "Cite only on must_have items where the prompt explicitly requires citations; "
        "otherwise rely on the cooperative framing already established. Warmer language. "
        "Acknowledge the landlord's perspective where appropriate without conceding the ask."
    ),
}


def _render_prompt(round_type: RoundType, tone: TonePreference) -> str:
    """Load the round-type prompt and substitute the tone block."""
    path = _PROMPT_PATHS[round_type]
    if not path.exists():
        raise FileNotFoundError(
            f"Drafter prompt not found at {path}. "
            f"Ensure prompts/negotiator_drafter_{round_type.lower()}.md exists at repo root."
        )
    template = path.read_text(encoding="utf-8")
    if "{TONE_INSTRUCTIONS}" not in template:
        raise RuntimeError(
            f"Drafter prompt at {path} is missing the {{TONE_INSTRUCTIONS}} placeholder."
        )
    return template.replace("{TONE_INSTRUCTIONS}", _TONE_INSTRUCTIONS[tone])


def _serialize_case_state(case: NegotiationCase, round_type: RoundType) -> str:
    """Render the case state deterministically for the user message.

    sort_keys=True so the cache prefix is stable across calls. The user
    content varies per round (this is per-clause-equivalent input), but the
    SYSTEM prompt is what carries the cache_control breakpoint, so this
    serialization just needs to be consistent within a single call to be
    parseable on the model side.
    """
    payload: dict[str, Any] = {
        "round_type_to_draft": round_type,
        "case_id": case.case_id,
        "tenant_tone_preference": case.tenant_tone_preference,
        "tenant_context": case.tenant_context.model_dump(mode="json"),
        "lease_brief": case.lease_brief.model_dump(mode="json"),
        "targets": [t.model_dump(mode="json") for t in case.targets],
        "prior_rounds": [
            {
                "round_number": r.round_number,
                "round_type": r.round_type,
                "draft_subject": r.draft_subject,
                "draft_body": r.draft_body,
                "targets_addressed": r.targets_addressed,
                "sent_at": r.sent_at.isoformat() if r.sent_at else None,
                "landlord_reply": r.landlord_reply.model_dump(mode="json")
                if r.landlord_reply
                else None,
                "agent_assessment": r.agent_assessment.model_dump(mode="json")
                if r.agent_assessment
                else None,
            }
            for r in case.rounds
        ],
    }
    return json.dumps(payload, sort_keys=True, ensure_ascii=False, indent=2)


def _validate_cited_statutes(round_obj: NegotiationRound) -> None:
    """Verify every cited statute appears verbatim in the curated corpus.

    Constraint 7: fail loud. A drafted round with a hallucinated citation is
    not safe to return — the tenant might rely on it. Caller is expected to
    propagate the exception; in v0.1 the orchestrator does not retry.
    """
    if not round_obj.cited_statutes:
        return
    statutes = load_statutes()
    for citation in round_obj.cited_statutes:
        if not validate_statute_citation(citation.citation, statutes):
            raise RuntimeError(
                f"Drafter emitted a citation not in the corpus: '{citation.citation}'. "
                f"Round '{round_obj.round_type}' (#{round_obj.round_number}) cannot be returned. "
                "This is a hard fail per Constraint 7 — hallucinated citations propagate to "
                "tenant correspondence and are unsafe."
            )


async def draft_round(
    case: NegotiationCase,
    *,
    client: AsyncAnthropic,
    force_round_type: RoundType | None = None,
    model: str = DEFAULT_MODEL,
    max_tokens: int = MAX_TOKENS,
) -> NegotiationRound:
    """Produce the next NegotiationRound for the given case.

    Round-type selection:
      - force_round_type set       -> use it
      - case.rounds empty          -> "OPENING"
      - case has rounds, no force  -> ValueError; the orchestrator
                                       (api.negotiator.cases.draft_next_round)
                                       must run the Strategist first and pass
                                       the recommended round_type as force_round_type.

    The drafter does NOT call the Strategist itself. That is intentional —
    keeps this function single-purpose and lets the orchestrator decide
    whether to short-circuit (e.g., OPENING needs no Strategist).

    Raises RuntimeError on:
      - max_tokens truncation
      - parsed_output is None
      - any cited statute that fails corpus validation
    """
    if force_round_type is not None:
        round_type: RoundType = force_round_type
    elif not case.rounds:
        round_type = "OPENING"
    else:
        raise ValueError(
            "draft_round on a case with prior rounds requires force_round_type. "
            "Use api.negotiator.cases.draft_next_round to run the Strategist first."
        )

    system_prompt = _render_prompt(round_type, case.tenant_tone_preference)
    user_content_text = _serialize_case_state(case, round_type)

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
        output_format=NegotiationRound,
    )
    latency_ms = int((time.perf_counter() - start) * 1000)

    if response.stop_reason == "max_tokens":
        raise RuntimeError(
            f"Drafter truncated at max_tokens drafting round_type={round_type}. "
            "Round is incomplete and unsafe to return. Increase max_tokens or split the case."
        )

    parsed = response.parsed_output
    if parsed is None:
        raise RuntimeError(
            f"Drafter returned no parseable output for round_type={round_type} "
            f"(stop_reason={response.stop_reason})."
        )

    log_usage(
        UsageRecord(
            stage="drafter",
            model=model,
            input_tokens=response.usage.input_tokens,
            output_tokens=response.usage.output_tokens,
            cache_read_input_tokens=response.usage.cache_read_input_tokens or 0,
            cache_creation_input_tokens=response.usage.cache_creation_input_tokens or 0,
            latency_ms=latency_ms,
            stop_reason=response.stop_reason or "unknown",
        )
    )

    _validate_cited_statutes(parsed)
    return parsed
