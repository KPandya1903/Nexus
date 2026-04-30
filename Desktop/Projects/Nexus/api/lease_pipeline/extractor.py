"""Stage 1: structured extraction of lease clauses.

The PDF is sent inline as a base64 document block with a `cache_control`
breakpoint so Stage 2 / Stage 3 can re-read the same lease without paying for
the document tokens again. The system prompt has its own breakpoint for the
same reason — it is frozen across runs.
"""

from __future__ import annotations

import base64
import time
from pathlib import Path

import anthropic

from .prompts import EXTRACTOR_SYSTEM_PROMPT
from .schemas import ExtractedLease
from .usage import UsageRecord, log_usage

DEFAULT_MODEL = "claude-opus-4-7"
MAX_TOKENS = 16000


def extract_lease(
    pdf_path: str | Path,
    *,
    model: str = DEFAULT_MODEL,
    client: anthropic.Anthropic | None = None,
) -> ExtractedLease:
    """Run Stage 1 extraction on a residential lease PDF.

    Returns a validated ExtractedLease. Raises anthropic.APIError on API
    failure and pydantic.ValidationError if the model produces a payload
    that does not conform to the schema.
    """
    client = client or anthropic.Anthropic()
    pdf_b64 = base64.standard_b64encode(Path(pdf_path).read_bytes()).decode("utf-8")

    start = time.perf_counter()
    response = client.messages.parse(
        model=model,
        max_tokens=MAX_TOKENS,
        thinking={"type": "adaptive"},
        output_config={"effort": "high"},
        system=[
            {
                "type": "text",
                "text": EXTRACTOR_SYSTEM_PROMPT,
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "document",
                        "source": {
                            "type": "base64",
                            "media_type": "application/pdf",
                            "data": pdf_b64,
                        },
                        "cache_control": {"type": "ephemeral"},
                    },
                    {
                        "type": "text",
                        "text": "Extract every clause from this lease per your instructions. Return the structured JSON only.",
                    },
                ],
            }
        ],
        output_format=ExtractedLease,
    )
    latency_ms = int((time.perf_counter() - start) * 1000)

    log_usage(
        UsageRecord(
            stage="extractor",
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
            f"Extractor returned no parseable output (stop_reason={response.stop_reason})"
        )
    return parsed
