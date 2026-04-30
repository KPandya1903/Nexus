"""End-to-end lease intelligence pipeline.

Stage 1 (Extractor) -> Stage 2 (Analyzer) -> Stage 3 (Briefer)

Public API:
    parse_lease(pdf_path, tenant_context) -> LeaseBrief

This is the function Kunj's FastAPI route at /trust/lease/parse should call.

Note: existing extractor.py and analyzer.py are synchronous (use
`anthropic.Anthropic`). The briefer is async (uses `AsyncAnthropic`). The
orchestrator runs the sync stages in a thread pool via asyncio.to_thread so
the public API can be a single async coroutine without forcing a refactor of
the existing tested Stage 1/2 code. Two clients are constructed: a sync one
for stages 1+2 and an async one for stage 3.
"""

from __future__ import annotations

import asyncio
import json
from pathlib import Path

import anthropic
from anthropic import AsyncAnthropic

from .analyzer import analyze_clauses
from .briefer import generate_brief
from .extractor import extract_lease
from .schemas import LeaseBrief, Statute, TenantContext
from .usage import reset_run, write_run_summary

STATUTES_PATH = (
    Path(__file__).parent.parent.parent / "data" / "statutes" / "nj_statutes.json"
)


def _load_statutes() -> list[Statute]:
    """Load and validate the NJ statutes corpus from disk."""
    if not STATUTES_PATH.exists():
        raise FileNotFoundError(
            f"NJ statutes corpus not found at {STATUTES_PATH}. "
            "Stage 2 cannot run without it."
        )
    raw = json.loads(STATUTES_PATH.read_text(encoding="utf-8"))
    # Map the corpus JSON shape onto the Statute Pydantic model.
    # Corpus entries have: citation, title, full_text, plain_summary,
    # applicable_categories, common_violations, confidence.
    # The Statute model only consumes: citation, title, full_text,
    # plain_summary, topics. We map applicable_categories -> topics.
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


async def parse_lease(
    pdf_path: Path,
    tenant_context: TenantContext,
    *,
    async_client: AsyncAnthropic | None = None,
    sync_client: anthropic.Anthropic | None = None,
    usage_output_path: Path | None = None,
) -> LeaseBrief:
    """Run the full Stage 1 -> 2 -> 3 pipeline on a PDF.

    Args:
        pdf_path: path to the lease PDF on disk
        tenant_context: who's signing this lease
        async_client: optional pre-configured AsyncAnthropic for Stage 3; created if None
        sync_client: optional pre-configured Anthropic for Stages 1+2; created if None
        usage_output_path: if provided, writes per-run usage.json here

    Returns:
        LeaseBrief — the final tenant-facing brief

    Raises on any stage failure (truncation, validation, missing data).
    Fails loud rather than returning a partial brief.
    """
    if async_client is None:
        async_client = AsyncAnthropic()
    if sync_client is None:
        sync_client = anthropic.Anthropic()

    reset_run()

    # Stage 1: extract clauses (sync; run in thread pool)
    extracted = await asyncio.to_thread(extract_lease, pdf_path, client=sync_client)

    # Load + validate statutes corpus
    statutes = _load_statutes()

    # Stage 2: analyze each clause against statutes (sync; run in thread pool)
    analyses = await asyncio.to_thread(
        analyze_clauses,
        extracted.clauses,
        statutes,
        tenant_context,
        client=sync_client,
    )

    # Stage 3: synthesize into the LeaseBrief (native async)
    brief, _usage = await generate_brief(
        extracted=extracted,
        analyses=analyses,
        tenant_context=tenant_context,
        client=async_client,
    )

    if usage_output_path is not None:
        write_run_summary(usage_output_path)

    return brief


# CLI entrypoint for local testing
async def _cli_main(pdf_path: str, output_path: str) -> None:
    tenant_ctx = TenantContext(
        is_student=True,
        is_international=False,
        is_first_us_lease=False,
        notes="CLI test run.",
    )

    brief = await parse_lease(
        Path(pdf_path),
        tenant_ctx,
        usage_output_path=Path(output_path).parent / "usage.json",
    )

    Path(output_path).write_text(brief.model_dump_json(indent=2), encoding="utf-8")
    print(f"✓ Brief written to {output_path}")
    print(f"  Consent clarity score: {brief.consent_clarity_score}/100")
    print(f"  Red flags: {len(brief.red_flags)}")
    print(f"  Negotiation openings: {len(brief.negotiation_openings)}")


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 3:
        print("Usage: python -m api.lease_pipeline.run_pipeline <lease.pdf> <output.json>")
        sys.exit(1)
    asyncio.run(_cli_main(sys.argv[1], sys.argv[2]))
