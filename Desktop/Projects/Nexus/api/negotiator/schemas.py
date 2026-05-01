"""Negotiator data model — Pydantic v2 schemas.

Defines the full negotiation case lifecycle: NegotiationCase wraps the frozen
LeaseBrief snapshot, the tenant's chosen targets, and an ordered list of
NegotiationRound artifacts. Each round may carry a LandlordReply (once the
tenant pastes one in) and an AgentAssessment (Strategist output, attached to
every round after OPENING).

All closed vocabularies are Literal types per Constraint 2 — schema-level
enforcement over prompt-level. The model physically cannot emit a value
outside the allowed set, regardless of prompt instruction.

Cross-module imports:
- LeaseBrief, TenantContext, StatuteCitation, CaseCitation from
  api.lease_pipeline.schemas (the brief snapshot and citation types).
- UsageRecord from api.shared.usage (per-round LLM call accounting).
"""

from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from api.lease_pipeline.schemas import (
    CaseCitation,
    LeaseBrief,
    StatuteCitation,
    TenantContext,
)
from api.shared.usage import UsageRecord


# ---------------------------------------------------------------------------
# Closed vocabularies (Literal types)
# ---------------------------------------------------------------------------


TonePreference = Literal["firm", "neutral", "conciliatory"]
"""Tenant-chosen drafting register. Defaults to 'neutral' when unspecified.

- "firm": cite statutes by NJSA number, state legal consequences plainly.
- "neutral": reference statutes by topic, lean professional/business.
- "conciliatory": frame as collaborative problem-solving; citations only on
  must-haves.
"""


RoundType = Literal[
    "OPENING",
    "FOLLOW_UP",
    "COUNTER",
    "ESCALATION",
    "WALK_AWAY",
    "ACCEPTANCE",
]
"""The kind of correspondence this round produces. Each round_type maps to a
distinct prompts/negotiator_drafter_<type>.md system prompt — legal posture
materially differs across types and a single branchy prompt produces lower-
quality output at the corners.
"""


CaseStatus = Literal[
    "DRAFTING",
    "AWAITING_TENANT_APPROVAL",
    "AWAITING_SEND",
    "SENT",
    "AWAITING_REPLY",
    "FOLLOW_UP_DUE",
    "REPLY_RECEIVED",
    "ESCALATED",
    "RESOLVED_ACCEPTED",
    "RESOLVED_WALKED_AWAY",
    "RESOLVED_UNRESOLVED",
]
"""Where the case is right now. Distinct from RoundType: a case can have
multiple ESCALATION rounds and still not be in a RESOLVED_ status. Status
transitions are gated by code-level state-machine checks, not by Literal
alone.
"""


TargetPriority = Literal["must_have", "preferred", "nice_to_have"]


TargetSource = Literal["red_flag", "negotiation_opening", "tenant_added"]
"""Where the target came from. 'tenant_added' covers items NOT in the brief
that the tenant nonetheless wants raised — these bypass the
target_not_in_brief 400 error in the API surface.
"""


TargetStatus = Literal[
    "pending",
    "accepted_by_landlord",
    "rejected_by_landlord",
    "withdrawn_by_tenant",
    "compromise_reached",
]


Channel = Literal["email", "letter_pdf", "in_app_message", "demo_only"]
"""How the tenant intends to deliver this round. v0.1 Drafter ignores the
field — informational metadata only. v0.2 may use it to route between SMTP,
PDF generation, and in-app messaging.
"""


ReplyClassification = Literal[
    "FULL_ACCEPT",
    "PARTIAL_ACCEPT",
    "COUNTER_OFFER",
    "REJECT",
    "REQUEST_FOR_INFO",
    "DEFLECTION",
    "AMBIGUOUS",
]
"""How the Reply Classifier interprets the landlord's reply.

- FULL_ACCEPT: landlord agrees to all targets currently pending.
- PARTIAL_ACCEPT: landlord agrees to some, defers/rejects others.
- COUNTER_OFFER: landlord proposes alternative terms.
- REJECT: landlord refuses outright.
- REQUEST_FOR_INFO: landlord asks tenant a question; not yet a position.
- DEFLECTION: non-substantive reply (e.g., 'I'll get back to you').
- AMBIGUOUS: classifier unsure; agent_assessment must surface this for
  tenant judgment.
"""


ClassifierConfidence = Literal["low", "medium", "high"]


ResolutionType = Literal["full_accept", "partial_accept", "walked_away", "unresolved"]


# ---------------------------------------------------------------------------
# Negotiation targets — what the tenant is asking for
# ---------------------------------------------------------------------------


class NegotiationTarget(BaseModel):
    clause_id: str = Field(
        description="Echoes red_flags[].clause_id or negotiation_openings[].clause_id from the brief, "
        "or a tenant-supplied identifier when source == 'tenant_added'."
    )
    priority: TargetPriority
    acceptable_outcome: str = Field(
        description="Tenant's stated minimum acceptable resolution. Free-text in v0.1; "
        "Strategist reads as full context. Reconsider for v0.2."
    )
    source: TargetSource
    current_status: TargetStatus = "pending"
    compromise_text: str | None = Field(
        default=None,
        description="Populated when current_status == 'compromise_reached'. "
        "Captures the specific compromise language agreed to.",
    )


# ---------------------------------------------------------------------------
# Landlord replies + classification
# ---------------------------------------------------------------------------


class ExtractedOffer(BaseModel):
    target_clause_id: str = Field(
        description="The clause this offer pertains to. Should match a NegotiationTarget.clause_id "
        "on the case; if the landlord raises something off-target, classifier emits a tenant_added "
        "stand-in and surfaces it in agent_assessment.open_questions_for_tenant."
    )
    landlord_position: str = Field(
        description="Plain-English summary of what the landlord is offering or refusing for this clause."
    )
    verbatim_quote: str = Field(
        description="Verbatim slice of the landlord reply text that supports this extraction. "
        "Same grounding discipline as Stage 2 verbatim_text — never paraphrase."
    )
    is_acceptable_under_acceptable_outcome: bool | None = Field(
        default=None,
        description="True if the landlord's position satisfies the corresponding target's "
        "acceptable_outcome. None means the classifier could not decide — tenant must judge.",
    )


class LandlordReply(BaseModel):
    received_at: datetime = Field(description="When the tenant pasted the reply in.")
    raw_text: str = Field(description="Verbatim landlord reply as the tenant pasted it.")
    classified_as: ReplyClassification
    extracted_offers: list[ExtractedOffer] = Field(default_factory=list)
    classifier_confidence: ClassifierConfidence
    classifier_reasoning: str = Field(
        description="Why the classifier reached this classification. Surfaces to the tenant "
        "alongside the classification so they can sanity-check before approving the next draft."
    )


# ---------------------------------------------------------------------------
# Strategist output — attached to every round AFTER OPENING
# ---------------------------------------------------------------------------


class AgentAssessment(BaseModel):
    summary: str = Field(
        description="2-3 sentence tenant-facing summary of where the case stands now."
    )
    recommended_targets_to_drop: list[str] = Field(
        default_factory=list,
        description="Clause IDs the strategist recommends withdrawing from negotiation.",
    )
    recommended_targets_to_hold: list[str] = Field(
        default_factory=list,
        description="Clause IDs the strategist recommends pushing on in the next round.",
    )
    recommended_targets_to_concede: list[str] = Field(
        default_factory=list,
        description="Clause IDs where the strategist recommends accepting the landlord's compromise.",
    )
    recommended_next_round_type: RoundType
    rationale: str = Field(
        description="Strategist reasoning grounded in the case state. References specific rounds, "
        "specific landlord positions, specific statute citations where relevant."
    )
    open_questions_for_tenant: list[str] = Field(
        default_factory=list,
        description="Items the agent cannot decide without tenant input. Empty list means the "
        "Strategist's recommendation is fully actionable as-is.",
    )


# ---------------------------------------------------------------------------
# Rounds — the artifacts of correspondence
# ---------------------------------------------------------------------------


class NegotiationRound(BaseModel):
    round_number: int = Field(ge=1, description="1-indexed.")
    round_type: RoundType
    drafted_at: datetime
    drafter_model: str = Field(
        description="The Anthropic model identifier used for drafting (e.g. 'claude-opus-4-7')."
    )
    channel: Channel
    draft_subject: str
    draft_body: str = Field(description="Full letter or message body, no truncation.")
    cited_statutes: list[StatuteCitation] = Field(
        default_factory=list,
        description="Full StatuteCitation objects per Constraint — never bare citation strings. "
        "Each citation must validate against api.shared.citations.validate_statute_citation.",
    )
    cited_cases: list[CaseCitation] = Field(
        default_factory=list,
        description="Only the three approved NJ cases (Marini v. Ireland, Reste Realty Corp. v. "
        "Cooper, Berzito v. Gambino). Enforced via the ApprovedCase Literal at the type level.",
    )
    targets_addressed: list[str] = Field(
        default_factory=list,
        description="NegotiationTarget.clause_id values referenced in this draft.",
    )
    tenant_approved: bool = False
    tenant_approved_at: datetime | None = None
    sent_at: datetime | None = Field(
        default=None,
        description="Always None on draft. v0.1 has no real send — tenant manually sets this via "
        "the mark_sent endpoint when they actually paste the draft into their email/mail client. "
        "v0.2 with real send replaces this with the SMTP/Gmail success timestamp.",
    )
    follow_up_due_at: datetime | None = Field(
        default=None,
        description="round.drafted_at + N days. Surfaces FOLLOW_UP_DUE state to iOS for polling. "
        "v0.1 has no background scheduler — iOS or the tenant triggers the next draft manually.",
    )
    landlord_reply: LandlordReply | None = None
    agent_assessment: AgentAssessment | None = Field(
        default=None,
        description="Null on the OPENING round (no prior state to assess). Populated on every "
        "subsequent round by the Strategist before the Drafter runs.",
    )
    usage: UsageRecord = Field(
        description="Token / latency / cache usage for the LLM call(s) that produced this round. "
        "When both Strategist and Drafter ran for a round, totals are aggregated."
    )


# ---------------------------------------------------------------------------
# Final outcome — terminal state
# ---------------------------------------------------------------------------


class FinalOutcome(BaseModel):
    resolved_at: datetime
    resolution_type: ResolutionType
    accepted_target_ids: list[str] = Field(default_factory=list)
    rejected_target_ids: list[str] = Field(default_factory=list)
    summary: str = Field(
        description="Tenant-facing summary of how the negotiation concluded. Saved to the case "
        "for the tenant's records — useful if the dispute is later reopened."
    )


# ---------------------------------------------------------------------------
# Top-level case
# ---------------------------------------------------------------------------


class NegotiationCase(BaseModel):
    case_id: str = Field(description="UUID4 generated at case creation.")
    created_at: datetime
    updated_at: datetime
    lease_brief: LeaseBrief = Field(
        description="Frozen at case creation. Do not mutate after the case is created. If the "
        "tenant re-runs the lease pipeline (e.g. after re-uploading a corrected PDF), that's a "
        "NEW case — otherwise reasoning chains across rounds become inconsistent."
    )
    tenant_context: TenantContext
    tenant_tone_preference: TonePreference = "neutral"
    targets: list[NegotiationTarget] = Field(
        description="Subset of red_flags + negotiation_openings + tenant_added items the tenant "
        "chose to negotiate. Order is significant: priority should be sorted must_have first."
    )
    rounds: list[NegotiationRound] = Field(default_factory=list)
    status: CaseStatus = "DRAFTING"
    final_outcome: FinalOutcome | None = Field(
        default=None,
        description="Populated only when status starts with RESOLVED_.",
    )
