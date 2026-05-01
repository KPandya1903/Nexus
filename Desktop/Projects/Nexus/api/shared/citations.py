"""Shared citation utilities — statute corpus loader + grounding validators.

Used by both api.lease_pipeline (Stage 2 grounding, Stage 3 brief synthesis)
and api.negotiator (drafter validation, strategist reasoning) to ensure all
cited statutes come from the curated data/statutes/nj_statutes.json corpus
and all cited cases come from the three approved NJ cases.

ApprovedCase is re-exported here for ergonomics; the canonical Literal
definition lives in api.lease_pipeline.schemas.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import get_args

from api.lease_pipeline.schemas import ApprovedCase, Statute

__all__ = [
    "ApprovedCase",
    "Statute",
    "load_statutes",
    "validate_statute_citation",
    "validate_case_citation",
]


# Repo-root-relative path. From api/shared/citations.py:
#   __file__.parent           = api/shared
#   .parent                   = api
#   .parent                   = <repo root>
DEFAULT_STATUTES_PATH = (
    Path(__file__).parent.parent.parent / "data" / "statutes" / "nj_statutes.json"
)


def load_statutes(path: Path | None = None) -> list[Statute]:
    """Load and validate the NJ statutes corpus from disk.

    Maps corpus JSON entries (citation, title, full_text, plain_summary,
    applicable_categories, common_violations, confidence) onto the Statute
    Pydantic model (citation, title, full_text, plain_summary, topics).
    `applicable_categories` -> `topics`.

    Raises FileNotFoundError if the corpus is missing — fail loud per
    Constraint 7. The negotiator and lease pipeline both depend on this
    grounding source; a missing corpus is a hard error.
    """
    target = path or DEFAULT_STATUTES_PATH
    if not target.exists():
        raise FileNotFoundError(
            f"NJ statutes corpus not found at {target}. "
            "Pipeline grounding cannot run without it."
        )
    raw = json.loads(target.read_text(encoding="utf-8"))
    statutes: list[Statute] = []
    for entry in raw["statutes"]:
        statutes.append(
            Statute(
                citation=entry["citation"],
                title=entry["title"],
                full_text=entry["full_text"],
                plain_summary=entry["plain_summary"],
                topics=entry.get("applicable_categories", []),
            )
        )
    return statutes


def validate_statute_citation(citation: str, statutes: list[Statute]) -> bool:
    """Return True if the citation appears verbatim in the corpus."""
    return any(s.citation == citation for s in statutes)


def validate_case_citation(case: str) -> bool:
    """Return True if the case is one of the three approved NJ cases."""
    return case in get_args(ApprovedCase)
