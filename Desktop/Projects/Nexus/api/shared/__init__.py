"""Shared utilities for the api package — usage logging + citation grounding.

Used by api.lease_pipeline (Stages 1/2/3) and api.negotiator (drafter,
classifier, strategist). New consumers should import from this package
rather than from individual modules where possible.
"""

from .citations import (
    ApprovedCase,
    Statute,
    load_statutes,
    validate_case_citation,
    validate_statute_citation,
)
from .usage import (
    UsageRecord,
    log_usage,
    reset_run,
    write_run_summary,
)

__all__ = [
    "UsageRecord",
    "log_usage",
    "reset_run",
    "write_run_summary",
    "ApprovedCase",
    "Statute",
    "load_statutes",
    "validate_case_citation",
    "validate_statute_citation",
]
