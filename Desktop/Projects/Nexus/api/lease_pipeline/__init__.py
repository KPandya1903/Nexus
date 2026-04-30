"""Housing Verifier lease analysis pipeline.

Stage 1: extract clauses (extractor.py)
Stage 2: analyze each clause against NJ statutes (analyzer.py)
Stage 3: synthesize tenant brief — not yet implemented
"""

from .analyzer import analyze_clause, analyze_clauses
from .extractor import extract_lease
from .schemas import (
    CaseCitation,
    ClauseAnalysis,
    ExtractedClause,
    ExtractedLease,
    NumericValue,
    Statute,
    StatuteCitation,
    TenantContext,
)

__all__ = [
    "extract_lease",
    "analyze_clause",
    "analyze_clauses",
    "ExtractedClause",
    "ExtractedLease",
    "NumericValue",
    "Statute",
    "TenantContext",
    "ClauseAnalysis",
    "StatuteCitation",
    "CaseCitation",
]
