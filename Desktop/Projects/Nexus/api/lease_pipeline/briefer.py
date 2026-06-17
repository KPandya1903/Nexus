"""Stage 3: Lease Briefer.

Synthesizes Stage 1 extraction + Stage 2 per-clause analyses into a
tenant-facing LeaseBrief, branded with the ConsenTerra framework.

Inherits the document file_id from Stage 1 if present (for cache continuity).
"""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Optional

from anthropic import AsyncAnthropic

from .schemas import ClauseAnalysis, ExtractedLease, LeaseBrief, TenantContext
from .usage import UsageRecord, log_usage

PROMPT_PATH = Path(__file__).parent.parent.parent / "prompts" / "lease_briefer.md"


def _load_prompt() -> str:
    """Load the briefer system prompt from the .md file."""
    if not PROMPT_PATH.exists():
        raise FileNotFoundError(
            f"Briefer prompt not found at {PROMPT_PATH}. "
            "Ensure prompts/lease_briefer.md exists at repo root."
        )
    return PROMPT_PATH.read_text(encoding="utf-8")


async def generate_brief(
    *,
    extracted: ExtractedLease,
    analyses: list[ClauseAnalysis],
    tenant_context: TenantContext,
    client: AsyncAnthropic,
    model: str = "claude-opus-4-7",
    max_tokens: int = 8000,
    lease_file_id: Optional[str] = None,
) -> tuple[LeaseBrief, UsageRecord]:
    """Generate the tenant-facing LeaseBrief from Stages 1 + 2 outputs.

    Returns (brief, usage_record). Raises on truncation, validation failure,
    or any model error — fail loud per Constraint 7.
    """
    system_prompt = _load_prompt()

    extracted_json = extracted.model_dump_json()
    analyses_json = json.dumps(
        [a.model_dump(mode="json") for a in analyses],
        sort_keys=True,
        ensure_ascii=False,
    )
    tenant_json = tenant_context.model_dump_json()

    user_content = [
        {
            "type": "text",
            "text": (
                "Below are the Stage 1 extraction, Stage 2 per-clause analyses, "
                "and tenant context. Synthesize them into a complete LeaseBrief.\n\n"
                f"=== EXTRACTED LEASE ===\n{extracted_json}\n\n"
                f"=== CLAUSE ANALYSES ===\n{analyses_json}\n\n"
                f"=== TENANT CONTEXT ===\n{tenant_json}"
            ),
        }
    ]

    system_blocks = [
        {
            "type": "text",
            "text": system_prompt,
            "cache_control": {"type": "ephemeral"},
        }
    ]

    start = time.perf_counter()

    response = await client.messages.parse(
        model=model,
        max_tokens=max_tokens,
        system=system_blocks,
        messages=[{"role": "user", "content": user_content}],
        output_format=LeaseBrief,
        thinking={"type": "adaptive"},
        output_config={"effort": "medium"},
    )

    latency_ms = int((time.perf_counter() - start) * 1000)

    if response.stop_reason == "max_tokens":
        raise RuntimeError(
            "Stage 3 briefer truncated at max_tokens. "
            "Brief is incomplete and unsafe to return. "
            "Increase max_tokens or reduce lease complexity."
        )

    parsed = response.parsed_output
    if parsed is None:
        raise RuntimeError(
            "Stage 3 briefer returned no parsed output. "
            f"stop_reason={response.stop_reason}"
        )

    usage = UsageRecord(
        stage="briefer",
        model=model,
        input_tokens=response.usage.input_tokens,
        output_tokens=response.usage.output_tokens,
        cache_read_input_tokens=getattr(response.usage, "cache_read_input_tokens", 0) or 0,
        cache_creation_input_tokens=getattr(
            response.usage, "cache_creation_input_tokens", 0
        )
        or 0,
        latency_ms=latency_ms,
        stop_reason=response.stop_reason or "unknown",
    )
    log_usage(usage)

    return parsed, usage
