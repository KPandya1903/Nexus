"""Usage logging — minimal shared utility for all pipeline stages."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path


@dataclass
class UsageRecord:
    stage: str  # "extractor", "analyzer", "briefer", "drafter", "classifier", "strategist"
    model: str
    input_tokens: int
    output_tokens: int
    cache_read_input_tokens: int
    cache_creation_input_tokens: int
    latency_ms: int
    stop_reason: str
    timestamp: str = ""

    def __post_init__(self) -> None:
        if not self.timestamp:
            self.timestamp = datetime.now(timezone.utc).isoformat()


_run_records: list[UsageRecord] = []


def log_usage(record: UsageRecord) -> None:
    """Append a usage record to the current run's log."""
    _run_records.append(record)


def reset_run() -> None:
    """Clear the in-memory run log. Call at the start of each pipeline run."""
    _run_records.clear()


def write_run_summary(output_path: Path) -> dict:
    """Write all accumulated usage records to disk as usage.json. Returns the summary."""
    summary = {
        "records": [asdict(r) for r in _run_records],
        "totals": {
            "input_tokens": sum(r.input_tokens for r in _run_records),
            "output_tokens": sum(r.output_tokens for r in _run_records),
            "cache_read_input_tokens": sum(r.cache_read_input_tokens for r in _run_records),
            "cache_creation_input_tokens": sum(
                r.cache_creation_input_tokens for r in _run_records
            ),
            "total_latency_ms": sum(r.latency_ms for r in _run_records),
            "stages": [r.stage for r in _run_records],
        },
    }
    output_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return summary
