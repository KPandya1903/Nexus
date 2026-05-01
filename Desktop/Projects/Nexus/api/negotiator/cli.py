"""Negotiator CLI — local testing + demo cache prebuilding.

Subcommands:
    create    Build a new case from a lease brief JSON + targets JSON.
    draft     Draft the next round on an existing case.
    reply     Record a landlord reply on the most recent round.
    show      Pretty-print a saved case.

Persistence: data/demo_cache/negotiation/<case_id>.json. The CLI is for
local testing and demo cache prebuilding — not the API surface.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from anthropic import AsyncAnthropic

from api.lease_pipeline.schemas import LeaseBrief, TenantContext

from .cases import (
    approve_round,
    create_case,
    draft_next_round,
    mark_sent,
    record_landlord_reply,
)
from .schemas import NegotiationCase, NegotiationTarget, TonePreference

CACHE_DIR = Path(__file__).parent.parent.parent / "data" / "demo_cache" / "negotiation"


def _case_path(case_id: str) -> Path:
    return CACHE_DIR / f"{case_id}.json"


def _save(case: NegotiationCase) -> Path:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    path = _case_path(case.case_id)
    path.write_text(case.model_dump_json(indent=2), encoding="utf-8")
    return path


def _load(case_id: str) -> NegotiationCase:
    path = _case_path(case_id)
    if not path.exists():
        raise FileNotFoundError(f"No saved case at {path}.")
    return NegotiationCase.model_validate_json(path.read_text(encoding="utf-8"))


# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------


def cmd_create(args: argparse.Namespace) -> int:
    brief = LeaseBrief.model_validate_json(Path(args.brief).read_text(encoding="utf-8"))
    targets_raw = json.loads(Path(args.targets).read_text(encoding="utf-8"))
    targets = [NegotiationTarget.model_validate(t) for t in targets_raw]

    tenant_ctx = TenantContext(
        is_student=args.is_student,
        is_international=args.is_international,
        is_first_us_lease=args.is_first_us_lease,
        notes=args.notes,
    )

    case = create_case(
        lease_brief=brief,
        tenant_context=tenant_ctx,
        targets=targets,
        tone_preference=args.tone,
    )
    path = _save(case)
    print(f"✓ Case created: {case.case_id}")
    print(f"  Targets: {len(case.targets)}")
    print(f"  Tone: {case.tenant_tone_preference}")
    print(f"  Saved: {path}")
    return 0


async def _draft_async(args: argparse.Namespace) -> int:
    case = _load(args.case)
    client = AsyncAnthropic()
    new_round = await draft_next_round(
        case,
        client=client,
        force_round_type=args.force_round_type,
    )
    case.rounds.append(new_round)
    case.status = "AWAITING_TENANT_APPROVAL"
    case.updated_at = datetime.now(timezone.utc)
    if args.auto_approve:
        case = approve_round(case, new_round.round_number)
    if args.auto_send:
        case = mark_sent(case, new_round.round_number)
    path = _save(case)

    print(f"✓ Round {new_round.round_number} ({new_round.round_type}) drafted")
    print(f"  Subject: {new_round.draft_subject}")
    print(f"  Body length: {len(new_round.draft_body)} chars")
    print(f"  Cited statutes: {len(new_round.cited_statutes)}")
    print(f"  Cited cases: {len(new_round.cited_cases)}")
    print(f"  Targets addressed: {new_round.targets_addressed}")
    if new_round.agent_assessment:
        print(f"  Strategist next-round recommendation: {new_round.agent_assessment.recommended_next_round_type}")
    print(f"  Saved: {path}")
    return 0


def cmd_draft(args: argparse.Namespace) -> int:
    return asyncio.run(_draft_async(args))


async def _reply_async(args: argparse.Namespace) -> int:
    case = _load(args.case)
    if not case.rounds:
        print("Cannot record a reply: case has no rounds.", file=sys.stderr)
        return 1
    reply_text = Path(args.reply_file).read_text(encoding="utf-8")

    client = AsyncAnthropic()
    reply, assessment = await record_landlord_reply(case, reply_text, client=client)

    case.rounds[-1].landlord_reply = reply
    case.rounds[-1].agent_assessment = assessment
    case.status = "REPLY_RECEIVED"
    case.updated_at = datetime.now(timezone.utc)
    path = _save(case)

    print(f"✓ Reply recorded on round {case.rounds[-1].round_number}")
    print(f"  Classification: {reply.classified_as} (confidence={reply.classifier_confidence})")
    print(f"  Extracted offers: {len(reply.extracted_offers)}")
    print(f"  Strategist next-round: {assessment.recommended_next_round_type}")
    print(f"  Targets to drop: {assessment.recommended_targets_to_drop}")
    print(f"  Targets to hold: {assessment.recommended_targets_to_hold}")
    print(f"  Targets to concede: {assessment.recommended_targets_to_concede}")
    if assessment.open_questions_for_tenant:
        print(f"  Open questions ({len(assessment.open_questions_for_tenant)}):")
        for q in assessment.open_questions_for_tenant:
            print(f"    - {q}")
    print(f"  Saved: {path}")
    return 0


def cmd_reply(args: argparse.Namespace) -> int:
    return asyncio.run(_reply_async(args))


def cmd_show(args: argparse.Namespace) -> int:
    case = _load(args.case)
    print(f"Case {case.case_id}")
    print(f"  Status: {case.status}")
    print(f"  Tone: {case.tenant_tone_preference}")
    print(f"  Targets: {len(case.targets)}")
    for t in case.targets:
        print(f"    - {t.clause_id} [{t.priority}] status={t.current_status}")
    print(f"  Rounds: {len(case.rounds)}")
    for r in case.rounds:
        approved = "approved" if r.tenant_approved else "draft"
        sent = f" sent={r.sent_at.isoformat()}" if r.sent_at else ""
        reply = f" reply={r.landlord_reply.classified_as}" if r.landlord_reply else ""
        print(f"    #{r.round_number} {r.round_type} ({approved}){sent}{reply}")
    if case.final_outcome:
        print(f"  Final outcome: {case.final_outcome.resolution_type}")
    return 0


# ---------------------------------------------------------------------------
# Argparse
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="api.negotiator.cli")
    sub = p.add_subparsers(dest="cmd", required=True)

    # create
    pc = sub.add_parser("create", help="Build a new case from a lease brief JSON + targets JSON.")
    pc.add_argument("--brief", required=True, help="Path to LeaseBrief JSON.")
    pc.add_argument("--targets", required=True, help="Path to NegotiationTargets JSON list.")
    pc.add_argument(
        "--tone",
        choices=["firm", "neutral", "conciliatory"],
        default="neutral",
        help="Tenant tone preference. Default: neutral.",
    )
    pc.add_argument("--is-student", action="store_true")
    pc.add_argument("--is-international", action="store_true")
    pc.add_argument("--is-first-us-lease", action="store_true")
    pc.add_argument("--notes", default=None)
    pc.set_defaults(func=cmd_create)

    # draft
    pd = sub.add_parser("draft", help="Draft the next round.")
    pd.add_argument("--case", required=True, help="case_id (UUID).")
    pd.add_argument(
        "--force-round-type",
        choices=["OPENING", "FOLLOW_UP", "COUNTER", "ESCALATION", "WALK_AWAY", "ACCEPTANCE"],
        default=None,
    )
    pd.add_argument("--auto-approve", action="store_true", help="Mark the drafted round tenant-approved immediately (testing only).")
    pd.add_argument("--auto-send", action="store_true", help="Mark the round sent immediately (testing only).")
    pd.set_defaults(func=cmd_draft)

    # reply
    pr = sub.add_parser("reply", help="Record a landlord reply on the most recent round.")
    pr.add_argument("--case", required=True)
    pr.add_argument("--reply-file", required=True, help="Path to a text file with the landlord reply.")
    pr.set_defaults(func=cmd_reply)

    # show
    ps = sub.add_parser("show", help="Pretty-print a saved case.")
    ps.add_argument("--case", required=True)
    ps.set_defaults(func=cmd_show)

    return p


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
