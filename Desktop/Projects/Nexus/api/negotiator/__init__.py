"""Negotiator module — multi-round lease negotiation correspondence.

v0.1 ships drafter, reply classifier, and strategist agents. NO autonomous
send. NO inbox monitoring. NO persistent storage beyond demo cache. All
drafts await tenant approval before any external communication.

Public API (per the design doc §4):

    case = create_case(lease_brief=..., tenant_context=..., targets=...)
    round_1 = await draft_next_round(case, client=async_client)
    case = approve_round(case, round_1.round_number)  # tenant says yes
    case = mark_sent(case, round_1.round_number)
    reply, assessment = await record_landlord_reply(case, reply_text, client=async_client)
    # ... caller attaches reply to case.rounds[-1] and persists ...
    round_2 = await draft_next_round(case, client=async_client)
    # ... etc ...
    case = resolve_case(case, resolution_type="partial_accept", summary="...")

Every drafted letter:
  - Cites only statutes from data/statutes/nj_statutes.json
  - Cites only the three approved NJ cases (Marini, Reste Realty, Berzito)
  - Carries the not_legal_advice disclaimer + the two referrals
  - Awaits tenant approval before being marked sent
"""

from .cases import (
    InvalidStateTransition,
    approve_round,
    create_case,
    draft_next_round,
    get_strategy,
    mark_sent,
    record_landlord_reply,
    resolve_case,
)
from .cases import get_strategy as get_strategy_recommendation  # design doc naming
from .schemas import (
    AgentAssessment,
    CaseStatus,
    Channel,
    ClassifierConfidence,
    ExtractedOffer,
    FinalOutcome,
    LandlordReply,
    NegotiationCase,
    NegotiationRound,
    NegotiationTarget,
    ReplyClassification,
    ResolutionType,
    RoundType,
    TargetPriority,
    TargetSource,
    TargetStatus,
    TonePreference,
)

__all__ = [
    # Schemas
    "NegotiationCase",
    "NegotiationRound",
    "NegotiationTarget",
    "LandlordReply",
    "ExtractedOffer",
    "AgentAssessment",
    "FinalOutcome",
    "TonePreference",
    "RoundType",
    "CaseStatus",
    "TargetPriority",
    "TargetSource",
    "TargetStatus",
    "Channel",
    "ReplyClassification",
    "ClassifierConfidence",
    "ResolutionType",
    # Public API
    "create_case",
    "draft_next_round",
    "record_landlord_reply",
    "get_strategy_recommendation",
    "get_strategy",
    "approve_round",
    "mark_sent",
    "resolve_case",
    "InvalidStateTransition",
]
