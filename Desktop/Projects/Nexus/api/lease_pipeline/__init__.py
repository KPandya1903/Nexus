"""Housing Verifier lease analysis pipeline.

Stage 1: extract clauses (extractor.py)
Stage 2: analyze each clause against NJ statutes (analyzer.py)
Stage 3: synthesize tenant brief (briefer.py)

End-to-end: run_pipeline.parse_lease(pdf_path, tenant_context) -> LeaseBrief
"""

from .analyzer import analyze_clause, analyze_clauses
from .briefer import generate_brief
from .extractor import extract_lease
from .run_pipeline import parse_lease
from .schemas import (
    CaseCitation,
    ClauseAnalysis,
    ClosingNotes,
    ExtractedClause,
    ExtractedLease,
    LeaseBrief,
    MoneyMap,
    NegotiationOpening,
    NumericValue,
    OtherRecurringCharge,
    RedFlag,
    RedFlagLabel,
    Referral,
    Statute,
    StatuteCitation,
    TenantContext,
)
from .usage import UsageRecord, log_usage, reset_run, write_run_summary

__all__ = [
    # Stage 1
    "extract_lease",
    "ExtractedClause",
    "ExtractedLease",
    "NumericValue",
    # Stage 2
    "analyze_clause",
    "analyze_clauses",
    "Statute",
    "TenantContext",
    "ClauseAnalysis",
    "StatuteCitation",
    "CaseCitation",
    # Stage 3
    "generate_brief",
    "LeaseBrief",
    "MoneyMap",
    "OtherRecurringCharge",
    "RedFlag",
    "RedFlagLabel",
    "NegotiationOpening",
    "Referral",
    "ClosingNotes",
    # Orchestrator
    "parse_lease",
    # Usage
    "UsageRecord",
    "log_usage",
    "reset_run",
    "write_run_summary",
]
