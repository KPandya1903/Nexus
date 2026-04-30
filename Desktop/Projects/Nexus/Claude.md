# Claude.md — Stevens Nexus

**Audience: every future Claude Code session working in this repo.** This file is prescriptive, not descriptive. If a rule here conflicts with the README, this file wins for engineering decisions; the README wins for human framing. The API contract is governed by `api/CONTRACT.md`.

Companion docs:
- [`README.md`](./README.md) — human-facing project description, demo narrative, setup instructions.
- [`api/CONTRACT.md`](./api/CONTRACT.md) — iOS ↔ Python service boundary. Pydantic v2 + Swift `Codable` mirror this doc.

---

## Project (one paragraph)

Stevens Nexus is a hackathon-built campus OS for Stevens Institute of Technology, composed of three modules behind a single iOS surface: **Discover** (OpenAI-backed faculty matching with grounded outreach drafts), **Presence** (3D Hoboken campus map of declared schedules with a Catalyst daily-moments agent), and **Trust** (an Anthropic-backed three-stage NJ residential lease pipeline that produces a tenant brief grounded in NJ statutes). Built for the Stevens AI Hackathon sponsored by ConsenTerra; the Trust module's brief carries ConsenTerra attribution per the sponsor partnership. LLM provider is module-scoped — see Hard Constraint 1.

---

## Monorepo file tree (current reality)

```
.
├── .cspell.json                 # project word list (cspell)
├── .github/workflows/           # CI (python-ci.yml lints + tests api/)
├── .gitignore                   # Python + Xcode + Firebase secrets
├── .mcp.json                    # MCP servers (github, apify)
├── Claude.md                    # this file — AI-facing rules
├── README.md                    # human-facing description
├── api/
│   ├── CONTRACT.md              # API source of truth — iOS ↔ Python
│   ├── lease_pipeline/          # Trust module — Stage 1/2/3
│   │   ├── extractor.py         # Stage 1: PDF → ExtractedLease
│   │   ├── analyzer.py          # Stage 2: clauses → ClauseAnalysis[]
│   │   ├── prompts.py           # (will move to prompts/*.md — see constraint)
│   │   ├── schemas.py           # Pydantic v2 models
│   │   ├── cli.py               # local debug runner
│   │   └── requirements.txt
│   ├── discover/                # NOT YET — Matcher, Bridge, Outreach, Critic
│   ├── presence/                # NOT YET — Catalyst
│   ├── shared/                  # NOT YET — schemas, AsyncAnthropic wrapper, usage logger
│   └── main.py                  # NOT YET — FastAPI app
├── data/
│   ├── statutes/                # NOT YET — NJ statute corpus (curated)
│   ├── faculty/                 # NOT YET — Stevens faculty corpus (Apify-scraped)
│   ├── sample_leases/           # NOT YET — anonymized PDFs for dev
│   └── demo_cache/              # NOT YET — pre-baked demo responses
├── ios/                         # SwiftUI app (Kunj owns)
│   └── README.md
├── prompts/                     # NOT YET — system prompts as .md files
└── scrapers/                    # NOT YET — Apify-driven ingestion
```

Anything marked **NOT YET** is referenced in `README.md` / `CONTRACT.md` but not yet created. Do not invent stubs without an explicit task.

---

## Locked tech stack

| Layer | Choice | Notes |
|---|---|---|
| LLM (Trust module) | **Anthropic Claude Opus 4.7** (`claude-opus-4-7`) + **Haiku 4.5** (`claude-haiku-4-5-20251001`) | Adi's domain. Stage 2/3 reasoning on Opus, Stage 1 extraction formatting on Haiku. ConsenTerra integration. |
| LLM (Discover module) | **OpenAI GPT-4-class** | Kunj's domain. Working implementation against the existing faculty embeddings + matching pipeline. |
| LLM (Presence module) | **TBD when built** | Default to OpenAI for Discover consistency unless module need (e.g. statute-grounded reasoning) justifies switching. Decision required in Decisions Log before implementation. |
| Backend | **FastAPI** (Python 3.11+) | async-first, on Railway |
| Validation | **Pydantic v2** | every LLM output via `client.messages.parse()` |
| LLM client (Trust) | `anthropic` SDK with `AsyncAnthropic` | async-only; `asyncio.gather` for fan-out |
| LLM client (Discover) | `openai` SDK with `AsyncOpenAI` | async-only; same `asyncio.gather` fan-out pattern |
| iOS | **SwiftUI** + **MapKit** (3D realistic) + **MFMailComposeViewController** | MVVM; centralized `FirebaseManager.swift` |
| Auth/DB | **Firebase Auth** + **Firestore** + **Firebase Storage** | iOS gates `@stevens.edu`; server validates ID token against `FIREBASE_PROJECT_ID` |
| Scraping | **Apify** (MCP-driven during dev) | faculty bios, OpenAlex paper crawl |
| Hosting | **Railway** (API), **TestFlight** (iOS) | env vars hold all secrets |
| Tooling | `uv`, `ruff`, `mypy`, `pytest`, `httpx` | enforce in CI |

**Cross-module rule:** within a module, the provider is locked. Don't mix providers inside a single module — caching, error envelopes, and `usage` accounting assume one client per module.

---

## Hard engineering constraints

These are non-negotiable. A PR that violates one is a defect, not a tradeoff.

1. **LLM provider is module-scoped, not project-scoped.** Trust uses Anthropic exclusively. Discover uses OpenAI exclusively. A new module justifies its provider in the Decisions Log. Within a module, the provider does not change.
2. **Schema-level enforcement over prompt-level.** Use Pydantic `Literal` types for closed vocabularies (statute citations, case citations, label enums). The model must not be able to emit invalid values, regardless of prompt instruction.
3. **Prompts as `.md` files.** Every system prompt lives in `prompts/<stage>.md` and is loaded at runtime via `Path.read_text()`. **Never inline a prompt longer than 5 lines in Python.** `lease_pipeline/prompts.py` is a temporary holdover and must be migrated.
4. **Async throughout.** Use the module's async client (`AsyncAnthropic` for Trust, `AsyncOpenAI` for Discover). `asyncio.gather` for fan-out. Never `time.sleep`; use `asyncio.sleep`.
5. **Mandatory provider-native caching with deterministic serialization.** Anthropic-backed modules set `cache_control: {"type": "ephemeral"}` on stable prefixes (system prompt + statute corpus). OpenAI-backed modules use the equivalent (e.g. cached prompt prefixes via the Responses/Chat Completions cache hints). In both cases, serialization of the cache prefix must be byte-for-byte stable across runs (sorted keys, fixed float repr) — otherwise cache hits silently regress.
6. **Usage logging on every LLM call.** Capture `input_tokens`, `output_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens`, latency, model, and stop_reason. Aggregate per request into a `Usage` object that ships in every API response (see CONTRACT.md). Per-batch totals also write to `usage.json`.
7. **Fail loud.** Raise on `stop_reason == "max_tokens"`, on Pydantic validation failure, on retrieval miss when retrieval was required, and on any approved-citation `Literal` rejection. No silent degradation. No fallback strings.
8. **No legal advice claims.** The Trust module produces **legal information**, not legal advice. Every `LeaseBrief` carries the disclaimer + the two referrals (NJ Volunteer Lawyers for Justice, Legal Services of NJ). Never remove these.
9. **No overclaiming (Hackathon Rule 6).** Demo replay mode (`X-Demo-Replay`) sets `mocked_in_demo: true` and is disclosed in the on-stage brief. Do not claim live API generation when serving cached responses.
10. **Secrets at boundaries only.** API keys live in environment variables loaded via `dotenv` in dev and Railway env in prod. Never commit `.env`, `GoogleService-Info.plist`, or any `*-adminsdk-*.json`. The `.gitignore` already covers these — keep it that way.

---

## Demo Golden Path (5 steps)

The single demo flow that judges will see. Every engineering decision optimizes for these five steps working in order, on stage, without a network failure.

1. **Onboarding.** `@stevens.edu` Firebase login → student profile capture (program, year, interests, background CV paste).
2. **Discover.** Top-3 faculty matches with bridge-paper reasoning → user picks one → Critic-reviewed cold-email draft opens in `MFMailComposeViewController`.
3. **Presence.** 3D MapKit view of Hoboken campus with friend annotations placed at building coordinates per declared schedule. Catalyst surfaces today's highest-leverage moment.
4. **Trust.** Drop a Hoboken lease PDF → Stage 1/2/3 pipeline → `LeaseBrief` rendered as a card stack (consent_clarity_score, money_map, red_flags, negotiation_openings).
5. **Crown Moment.** Single composite card pulling one signal from each module — the platform proof that Discover + Presence + Trust are one product, not three.

The Trust step uses pre-baked Stage 1→2→3 outputs from `data/demo_cache/` during the live demo to remove network risk; this is disclosed in the brief itself per Constraint 9.

---

## Build status (auto-update as work proceeds)

Update this checklist in the same commit as the work it describes. Don't let it drift.

- [x] Monorepo scaffolding (`api/`, `ios/`, `data/`, `prompts/`, `scrapers/` placeholders)
- [x] `api/CONTRACT.md` v0.2 — locked
- [x] `lease_pipeline/` Stage 1 (extractor) + Stage 2 (analyzer)
- [x] `.cspell.json` project word list
- [ ] Migrate `lease_pipeline/prompts.py` → `prompts/lease_*.md`
- [ ] `lease_pipeline/` Stage 3 (`LeaseBrief` synthesizer) — schema in CONTRACT.md, Pydantic model pending
- [ ] `api/main.py` FastAPI app with `/trust/lease/parse`, `/discover/match`, `/discover/email`, `/presence/catalyst`, `/crown_moment`
- [ ] `api/shared/` — `AsyncAnthropic` wrapper, usage logger, prompt loader
- [ ] Firebase ID-token middleware (validates against `FIREBASE_PROJECT_ID`)
- [ ] `data/statutes/` curated NJ statute corpus
- [ ] `scrapers/` Apify-driven faculty + OpenAlex ingestion → `data/faculty/`
- [ ] `data/demo_cache/` pre-baked Trust replay artifacts
- [ ] iOS app shell (tab bar: Discover, Presence, Trust, Profile)
- [ ] Railway deploy + env config
- [ ] GitHub repo + branch protection (deferred per Decisions Log)

---

## Operational rules

Commit, branch, and PR conventions tied to the constraints above.

- **Commit message prefixes.** `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`, and the special **`contract:`** prefix for any change that touches `api/CONTRACT.md` or its mirrored Pydantic / `Codable` models. A `contract:` commit MUST update CONTRACT.md, the Pydantic schema, and the Swift `Codable` struct in the same commit — never just one of the three.
- **Branch naming.** `feat/<module>-<slug>`, `fix/<module>-<slug>`, `contract/<short-desc>`. Module values: `trust`, `discover`, `presence`, `crown`, `infra`, `ios`.
- **PR rule.** Every PR description states (1) which Hard Constraint(s) the change is bound by, and (2) whether `usage.json` deltas were inspected for cache-hit regressions if any LLM call was modified.
- **Status checklist.** If the PR completes a `[ ]` item in **Build status** above, check it off in the same PR. If it adds a new follow-up, append a new `[ ]` line.
- **Decisions Log.** Any decision that changes a constraint, locks a vocabulary, defers a feature, or chooses between viable alternatives appends a dated line to the Decisions Log in the same commit. Don't litigate a settled decision in a PR — re-open it by appending a new dated line that overrides the old one.

---

## How to extend (recipe for a new endpoint or module)

Follow this order. Skipping a step usually means re-doing the others.

1. **Update `api/CONTRACT.md` first.** Define request, response, error codes, and any new shared schema. Bump the draft version. Open a `contract:` PR and get sign-off before writing code.
2. **Mirror the contract in Pydantic.** Add models to `api/shared/schemas.py` (or the module's `schemas.py`). Use `Literal` for any closed vocabulary. Run `mypy` strict.
3. **Mirror the contract in Swift.** Add `Codable` structs on the iOS side. Field names match the JSON exactly (use `CodingKeys` if Swift-style names differ).
4. **Write the prompt** in `prompts/<module>_<stage>.md`. Reference it from Python via a single `Path.read_text()` call. Never inline.
5. **Wire the call.** Use the shared async-client wrapper in `api/shared/` for the module's locked provider (Anthropic for Trust, OpenAI for Discover) so caching, usage logging, and fail-loud behavior are inherited. Set provider-native cache hints on stable prefixes; verify cache hits in `usage.json` after the first two runs.
6. **Test with a fixture.** Add a fixture lease/profile/schedule under `data/sample_*/` and a `pytest` integration test that asserts the response validates against the Pydantic model.
7. **Update Build status + Decisions Log.** Tick the checklist item, append any decisions made along the way.

---

## Decisions Log

Append-only. Format: `YYYY-MM-DD — decision — rationale`. Future sessions read this to avoid relitigating settled questions.

- **2026-04-30** — Initial draft prescribed Anthropic-only across all modules. Superseded same day (see later entry "LLM provider relaxed…"). Rationale for the original Anthropic-only call: grounded-citation requirements + Pydantic `Literal` enforcement against Anthropic structured outputs is the Trust module's correctness story.
- **2026-04-30** — Monorepo, not separate repos. Rationale: contract-driven iOS/Python coupling; one PR can update CONTRACT.md + both sides atomically.
- **2026-04-30** — `api/CONTRACT.md` locked at DRAFT v0.2 as the iOS↔Python source of truth. Code mirrors the doc; if they disagree, the doc is wrong — fix the doc, then the code.
- **2026-04-30** — `red_flags[].label` enum locked to four values (`conflicts_with_nj_law | aggressive_but_legal | common_but_worth_knowing | recommend_attorney_review`) with deterministic derivation from Stage 2 `ClauseAnalysis` fields. Rationale: defends the brief on stage against "deal-breaker for whom?" — labels ground in objective signals, not tenant subjectivity.
- **2026-04-30** — `GET /trust/lease/{lease_id}` deferred to v0.2; v0 has no persistent storage beyond `data/demo_cache/`. iOS treats `lease_id` as opaque and forward-compatible.
- **2026-04-30** — Team monorepo lives at `KPandya1903/Nexus`. Adi contributes via PRs into Kunj's repo, not a separate Adi-owned repo. Rationale: single source of truth for the iOS + API + lease pipeline team; CONTRACT.md reachable from one URL.
- **2026-04-30** — Team scope: Kunj owns Python backend (Discover, Presence, Trust API endpoint, FastAPI, Railway deploy); Jhanvi owns iOS/SwiftUI; Adi owns lease pipeline (Stage 1/2/3) as importable package, NJ statutes database, demo cache, ConsenTerra integration.
- **2026-04-30** — The repo currently wraps the project inside `Desktop/Projects/Nexus/` (likely an accidental `git init` in `~/Desktop` on Kunj's machine). Lifting to repo root is deferred to a separate cleanup PR — not pre-empted by this contribution.
- **2026-04-30** — Restructure of `Desktop/Projects/Nexus/backend/` into `api/discover/`, `api/courses/`, `scrapers/` paths is deferred to a follow-up PR after team sync.
- **2026-04-30** — Branch protection not configured on `KPandya1903/Nexus`. Rationale: free private-tier silently no-ops protection rules; 3-person hackathon team prioritizes velocity over enforcement.
- **2026-04-30** — Demo replay (`X-Demo-Replay`) bypasses `Idempotency-Key` caching and sets `mocked_in_demo: true`. Rationale: Constraint 9 (no overclaiming).
- **2026-04-30** — LLM provider relaxed from project-scoped (Anthropic only) to module-scoped. Trust=Anthropic (sponsor + sunk pipeline), Discover=OpenAI (Kunj's working implementation, migration cost > benefit). Two-provider operational cost accepted as price of team velocity. Each module locked to its provider; no mid-module switching.
