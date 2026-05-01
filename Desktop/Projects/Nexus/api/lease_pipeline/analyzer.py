"""Stage 2: per-clause legal analysis grounded in a curated NJ statute database.

Cache layout (3 of 4 breakpoints used):
  1. System prompt (frozen across runs)
  2. Statute database (frozen for a given batch of clauses)
  3. Tenant context (frozen for a given lease)
  4. Per-clause user message — never cached, varies every call

Stages 1, 2, and 3 are intended to share the same lease document upstream.
Stage 2 itself does not see the PDF unless `lease_pdf_path` is supplied for an
ambiguous clause re-check (per the system prompt's input #4).
"""

from __future__ import annotations

import base64
import json
import time
from pathlib import Path

import anthropic

from .prompts import ANALYZER_SYSTEM_PROMPT
from .schemas import ClauseAnalysis, ExtractedClause, Statute, TenantContext
from api.shared.usage import UsageRecord, log_usage

DEFAULT_MODEL = "claude-opus-4-7"
MAX_TOKENS = 8000


def _serialize_statutes(statutes: list[Statute]) -> str:
    """Render the statute database deterministically so the cache prefix is stable.

    `cache_control` matches on bytes — non-deterministic ordering or whitespace
    changes here would silently invalidate the cache for every analyzer call.
    """
    payload = [
        {
            "citation": s.citation,
            "title": s.title,
            "full_text": s.full_text,
            "plain_summary": s.plain_summary,
            "topics": sorted(s.topics),
        }
        for s in sorted(statutes, key=lambda s: s.citation)
    ]
    return json.dumps(payload, indent=2, sort_keys=True, ensure_ascii=False)


def _build_clause_block(clause: ExtractedClause) -> str:
    return json.dumps(
        {
            "clause_id": clause.clause_id,
            "category": clause.category,
            "verbatim_text": clause.verbatim_text,
            "page_number": clause.page_number,
            "line_reference": clause.line_reference,
            "numeric_values": [v.model_dump() for v in clause.numeric_values],
            "extraction_quality": clause.extraction_quality,
            "notes": clause.notes,
        },
        indent=2,
        ensure_ascii=False,
    )


def analyze_clause(
    clause: ExtractedClause,
    statutes: list[Statute],
    tenant: TenantContext,
    *,
    lease_pdf_path: str | Path | None = None,
    model: str = DEFAULT_MODEL,
    client: anthropic.Anthropic | None = None,
) -> ClauseAnalysis:
    """Analyze a single clause against the NJ statute database."""
    client = client or anthropic.Anthropic()

    user_content: list[dict] = [
        {
            "type": "text",
            "text": "REFERENCE DATABASE (NJ statutes — exhaustive for this analysis):\n\n"
            + _serialize_statutes(statutes),
            "cache_control": {"type": "ephemeral"},
        },
        {
            "type": "text",
            "text": "TENANT CONTEXT:\n\n" + tenant.model_dump_json(indent=2),
            "cache_control": {"type": "ephemeral"},
        },
    ]

    if lease_pdf_path is not None and clause.extraction_quality == "partial":
        pdf_b64 = base64.standard_b64encode(Path(lease_pdf_path).read_bytes()).decode(
            "utf-8"
        )
        user_content.append(
            {
                "type": "document",
                "source": {
                    "type": "base64",
                    "media_type": "application/pdf",
                    "data": pdf_b64,
                },
            }
        )

    user_content.append(
        {
            "type": "text",
            "text": "CLAUSE TO ANALYZE:\n\n" + _build_clause_block(clause),
        }
    )

    start = time.perf_counter()
    response = client.messages.parse(
        model=model,
        max_tokens=MAX_TOKENS,
        thinking={"type": "adaptive"},
        output_config={"effort": "high"},
        system=[
            {
                "type": "text",
                "text": ANALYZER_SYSTEM_PROMPT,
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[{"role": "user", "content": user_content}],
        output_format=ClauseAnalysis,
    )
    latency_ms = int((time.perf_counter() - start) * 1000)

    log_usage(
        UsageRecord(
            stage="analyzer",
            model=model,
            input_tokens=response.usage.input_tokens,
            output_tokens=response.usage.output_tokens,
            cache_read_input_tokens=response.usage.cache_read_input_tokens or 0,
            cache_creation_input_tokens=response.usage.cache_creation_input_tokens or 0,
            latency_ms=latency_ms,
            stop_reason=response.stop_reason or "unknown",
        )
    )

    parsed = response.parsed_output
    if parsed is None:
        raise RuntimeError(
            f"Analyzer returned no parseable output for clause {clause.clause_id} "
            f"(stop_reason={response.stop_reason})"
        )
    return parsed


def analyze_clauses(
    clauses: list[ExtractedClause],
    statutes: list[Statute],
    tenant: TenantContext,
    *,
    lease_pdf_path: str | Path | None = None,
    model: str = DEFAULT_MODEL,
    client: anthropic.Anthropic | None = None,
) -> list[ClauseAnalysis]:
    """Analyze every clause sequentially. The statute database and tenant context
    are cached after the first call, so subsequent calls only pay for the
    per-clause text."""
    client = client or anthropic.Anthropic()
    return [
        analyze_clause(
            clause,
            statutes,
            tenant,
            lease_pdf_path=lease_pdf_path,
            model=model,
            client=client,
        )
        for clause in clauses
    ]
