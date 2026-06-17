"""Run Stage 1 from the command line.

    python -m lease_pipeline.cli path/to/lease.pdf -o stage1.json
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from .extractor import DEFAULT_MODEL, extract_lease


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Stage 1 lease extractor.")
    parser.add_argument("pdf", type=Path, help="Path to the lease PDF.")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Write JSON to this file. Defaults to stdout.",
    )
    parser.add_argument("--model", default=DEFAULT_MODEL)
    args = parser.parse_args(argv)

    if not args.pdf.is_file():
        parser.error(f"PDF not found: {args.pdf}")

    extracted = extract_lease(args.pdf, model=args.model)
    payload = extracted.model_dump_json(indent=2)

    if args.output:
        args.output.write_text(payload, encoding="utf-8")
    else:
        sys.stdout.write(payload + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
