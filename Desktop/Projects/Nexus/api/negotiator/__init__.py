"""Negotiator module — multi-round lease negotiation correspondence.

Build-out order:
  1. Schemas (this commit)
  2. Prompts (prompts/negotiator_*.md — six drafter prompts + classifier + strategist)
  3. Agents (drafter.py, classifier.py, strategist.py)
  4. Orchestrator + CLI (cases.py, cli.py)

v0.1 ships drafter, reply classifier, and strategist agents. NO autonomous
send. NO inbox monitoring. NO persistent storage beyond demo cache. All
drafts await tenant approval before any external communication.

Every drafted letter:
  - Cites only statutes from data/statutes/nj_statutes.json
  - Cites only the three approved NJ cases (Marini, Reste Realty, Berzito)
  - Carries the not_legal_advice disclaimer + the two referrals
  - Awaits tenant approval before being marked sent
"""

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
]
