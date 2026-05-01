"""Case management — public API for the negotiator module.

Pure-logic functions over NegotiationCase. Caller owns persistence.

State transitions raise InvalidStateTransition (CONTRACT.md error code
'invalid_state_transition', HTTP 409) when the case is in a state that
doesn't allow the requested action. No autonomous send. No Gmail / SMTP.

Auto-run pattern (per design decision):
  record_landlord_reply runs the Classifier first, then the Strategist on
  the case state with the new reply attached, and returns BOTH outputs.
  Caller decides what to persist.

draft_next_round routing:
  - case.rounds empty            -> Drafter with round_type="OPENING";
                                    no Strategist call (no prior state).
  - force_round_type set         -> Strategist runs (assessment attaches),
                                    Drafter uses force_round_type.
  - force_round_type None        -> Strategist runs, Drafter uses
                                    strategist.recommended_next_round_type.
"""

from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from anthropic import AsyncAnthropic

from api.lease_pipeline.schemas import LeaseBrief, TenantContext

from .classifier import classify_reply
from .drafter import draft_round
from .schemas import (
    AgentAssessment,
    CaseStatus,
    FinalOutcome,
    LandlordReply,
    NegotiationCase,
    NegotiationRound,
    NegotiationTarget,
    ResolutionType,
    RoundType,
    TonePreference,
)
from .strategist import get_strategy_recommendation


class InvalidStateTransition(RuntimeError):
    """Raised when the case is in a state that does not allow the requested action.

    Maps to CONTRACT.md error code 'invalid_state_transition' (HTTP 409).
    """

    def __init__(self, message: str, *, case_id: str | None = None, current_status: CaseStatus | None = None) -> None:
        super().__init__(message)
        self.case_id = case_id
        self.current_status = current_status


def _now() -> datetime:
    return datetime.now(timezone.utc)


# ---------------------------------------------------------------------------
# Pure construction
# ---------------------------------------------------------------------------


def create_case(
    *,
    lease_brief: LeaseBrief,
    tenant_context: TenantContext,
    targets: list[NegotiationTarget],
    tone_preference: TonePreference = "neutral",
) -> NegotiationCase:
    """Construct a fresh NegotiationCase with a frozen brief snapshot.

    No LLM call. The lease_brief is captured by reference but treated as
    immutable for the lifetime of the case (a re-run of the lease pipeline
    on a new PDF should produce a new case, not mutate an existing one).
    """
    if not targets:
        raise ValueError(
            "create_case requires at least one NegotiationTarget. "
            "An empty targets list means the tenant has nothing to negotiate."
        )
    now = _now()
    return NegotiationCase(
        case_id=str(uuid4()),
        created_at=now,
        updated_at=now,
        lease_brief=lease_brief,
        tenant_context=tenant_context,
        tenant_tone_preference=tone_preference,
        targets=list(targets),
        rounds=[],
        status="DRAFTING",
        final_outcome=None,
    )


# ---------------------------------------------------------------------------
# Drafting
# ---------------------------------------------------------------------------


async def draft_next_round(
    case: NegotiationCase,
    *,
    client: AsyncAnthropic,
    force_round_type: RoundType | None = None,
) -> NegotiationRound:
    """Draft the next round on the case.

    OPENING short-circuit: when case.rounds is empty, the Strategist is
    skipped (no prior state to assess) and the Drafter runs directly with
    round_type="OPENING". The returned NegotiationRound carries
    agent_assessment=None.

    Otherwise the Strategist runs first. The Drafter then runs with
    force_round_type if provided, else with strategist.recommended_next_round_type.
    The Strategist's AgentAssessment attaches to the returned round.

    Caller appends the returned round to case.rounds and persists. This
    function does NOT mutate `case`.
    """
    # OPENING short-circuit: case has no prior rounds AND we're drafting
    # the natural first round. No Strategist call (no prior state to assess).
    if not case.rounds and (force_round_type is None or force_round_type == "OPENING"):
        return await draft_round(
            case,
            client=client,
            force_round_type="OPENING",
        )

    # Strategist runs in all other cases — even on an empty case where the
    # tenant forced a non-OPENING round (rare but legal per design §4 escape
    # hatch). The Strategist's assessment may surface "this round_type is
    # unusual for an empty case" in open_questions_for_tenant.
    assessment = await get_strategy_recommendation(case, client=client)
    chosen: RoundType = force_round_type or assessment.recommended_next_round_type

    round_obj = await draft_round(case, client=client, force_round_type=chosen)
    round_obj.agent_assessment = assessment
    return round_obj


# ---------------------------------------------------------------------------
# Reply ingest (Classifier + Strategist auto-run)
# ---------------------------------------------------------------------------


async def record_landlord_reply(
    case: NegotiationCase,
    reply_text: str,
    *,
    client: AsyncAnthropic,
    received_at: datetime | None = None,
) -> tuple[LandlordReply, AgentAssessment]:
    """Classify a pasted landlord reply, then run the Strategist on the
    updated case state.

    Returns (LandlordReply, AgentAssessment). Caller is responsible for:
      1. Attaching the LandlordReply to case.rounds[-1].landlord_reply.
      2. Persisting the case.
      3. Surfacing the AgentAssessment to the tenant.

    The Classifier and Strategist do not mutate `case`. The Strategist sees
    a deep-copied version of the case with the new reply attached so its
    reasoning reflects the post-reply state.
    """
    if not case.rounds:
        raise InvalidStateTransition(
            "Cannot record a landlord reply on a case with no prior rounds. "
            "Tenant must draft and send at least one round first.",
            case_id=case.case_id,
            current_status=case.status,
        )

    reply = await classify_reply(case, reply_text, client=client, received_at=received_at)

    # Build a temp view of the case with the reply attached so the Strategist
    # sees the post-reply state. Caller's `case` is NOT mutated.
    temp = case.model_copy(deep=True)
    temp.rounds[-1].landlord_reply = reply
    assessment = await get_strategy_recommendation(temp, client=client)

    return reply, assessment


# ---------------------------------------------------------------------------
# State transitions (pure, no LLM)
# ---------------------------------------------------------------------------


def _find_round(case: NegotiationCase, round_number: int) -> NegotiationRound:
    for r in case.rounds:
        if r.round_number == round_number:
            return r
    raise InvalidStateTransition(
        f"Round {round_number} does not exist on case {case.case_id}.",
        case_id=case.case_id,
        current_status=case.status,
    )


def approve_round(case: NegotiationCase, round_number: int) -> NegotiationCase:
    """Mark a round tenant-approved.

    Validates that the round exists and that case.status is one of
    DRAFTING / AWAITING_TENANT_APPROVAL. Idempotent if the round is already
    approved (returns the case unchanged with updated_at refreshed).

    Pure function: returns a new case object, does not mutate input.
    """
    new_case = case.model_copy(deep=True)
    target = _find_round(new_case, round_number)

    if case.status not in ("DRAFTING", "AWAITING_TENANT_APPROVAL"):
        raise InvalidStateTransition(
            f"Cannot approve a round when case.status is '{case.status}'. "
            "Approval is only valid in DRAFTING or AWAITING_TENANT_APPROVAL.",
            case_id=case.case_id,
            current_status=case.status,
        )

    if target.tenant_approved:
        new_case.updated_at = _now()
        return new_case

    target.tenant_approved = True
    target.tenant_approved_at = _now()
    new_case.status = "AWAITING_SEND"
    new_case.updated_at = _now()
    return new_case


def mark_sent(
    case: NegotiationCase,
    round_number: int,
    sent_at: datetime | None = None,
) -> NegotiationCase:
    """Tenant tells us they actually sent the round. State transition only.

    Validates that the round is tenant_approved. Sets sent_at to provided
    datetime or now. Transitions case.status:
      - WALK_AWAY round   -> RESOLVED_WALKED_AWAY (terminal; caller should
                              still call resolve_case to populate FinalOutcome)
      - ACCEPTANCE round  -> RESOLVED_ACCEPTED (same caveat)
      - any other         -> AWAITING_REPLY
    """
    new_case = case.model_copy(deep=True)
    target = _find_round(new_case, round_number)

    if not target.tenant_approved:
        raise InvalidStateTransition(
            f"Cannot mark round {round_number} as sent before tenant approval. "
            "Call approve_round first.",
            case_id=case.case_id,
            current_status=case.status,
        )
    if target.sent_at is not None:
        # Idempotent: already sent.
        new_case.updated_at = _now()
        return new_case

    target.sent_at = sent_at or _now()
    if target.round_type == "WALK_AWAY":
        new_case.status = "RESOLVED_WALKED_AWAY"
    elif target.round_type == "ACCEPTANCE":
        new_case.status = "RESOLVED_ACCEPTED"
    else:
        new_case.status = "AWAITING_REPLY"
    new_case.updated_at = _now()
    return new_case


def resolve_case(
    case: NegotiationCase,
    resolution_type: ResolutionType,
    summary: str,
) -> NegotiationCase:
    """Terminal transition. Builds FinalOutcome from current target statuses.

    accepted_target_ids: targets with current_status in
      {accepted_by_landlord, compromise_reached}.
    rejected_target_ids: targets with current_status in
      {rejected_by_landlord, withdrawn_by_tenant}.

    Maps resolution_type -> case.status:
      full_accept | partial_accept -> RESOLVED_ACCEPTED
      walked_away                  -> RESOLVED_WALKED_AWAY
      unresolved                   -> RESOLVED_UNRESOLVED
    """
    new_case = case.model_copy(deep=True)

    if case.status.startswith("RESOLVED_"):
        raise InvalidStateTransition(
            f"Case {case.case_id} is already in terminal state '{case.status}'. "
            "Cannot re-resolve.",
            case_id=case.case_id,
            current_status=case.status,
        )

    accepted = [
        t.clause_id
        for t in new_case.targets
        if t.current_status in ("accepted_by_landlord", "compromise_reached")
    ]
    rejected = [
        t.clause_id
        for t in new_case.targets
        if t.current_status in ("rejected_by_landlord", "withdrawn_by_tenant")
    ]

    new_case.final_outcome = FinalOutcome(
        resolved_at=_now(),
        resolution_type=resolution_type,
        accepted_target_ids=accepted,
        rejected_target_ids=rejected,
        summary=summary,
    )

    if resolution_type in ("full_accept", "partial_accept"):
        new_case.status = "RESOLVED_ACCEPTED"
    elif resolution_type == "walked_away":
        new_case.status = "RESOLVED_WALKED_AWAY"
    else:
        new_case.status = "RESOLVED_UNRESOLVED"
    new_case.updated_at = _now()
    return new_case
