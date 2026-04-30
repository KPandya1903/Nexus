# Stevens Nexus — API Contract

**Source of truth for the iOS ↔ Python service boundary. Pydantic v2 models in `api/shared/schemas.py` mirror these shapes; Swift `Codable` structs on the iOS side mirror them in the opposite direction. If this doc and the code disagree, this doc is wrong — fix it, then the code.**

Status: **DRAFT v0.2** — pending approval before endpoints are implemented.

---

## Conventions

- **Base URL (prod):** `https://stevens-nexus-api.up.railway.app` (placeholder — replace once Railway provisions)
- **Base URL (dev):** `http://localhost:8000`
- **Content type:** `application/json` everywhere except `POST /trust/lease/parse` which is `multipart/form-data` (PDF upload).
- **Auth:** `Authorization: Bearer <firebase_id_token>` on every request. The server validates the Firebase ID token's signature and `aud`/`iss` claims against a configured `FIREBASE_PROJECT_ID` environment variable (set in Railway). The hackathon build does **not** enforce email-domain restrictions server-side (iOS gates `@stevens.edu`); we may tighten this post-hackathon.
- **Idempotency:** `Idempotency-Key: <uuid>` optional on every POST. Same key within 24h returns the cached response. Requests carrying `X-Demo-Replay` **bypass idempotency** — demo replay always returns the canonical pre-baked response from `data/demo_cache/`.
- **Errors:** All non-2xx responses use the envelope below. The HTTP status carries the category; `code` is a stable string the client can switch on.

```json
{
  "error": {
    "code": "validation_error",
    "message": "field 'tenant_context.is_student' is required",
    "details": {"field": "tenant_context.is_student"}
  }
}
```

Stable error codes:
- `validation_error` (400)
- `unauthorized` (401)
- `not_found` (404)
- `rate_limited` (429)
- `upstream_anthropic_error` (502)
- `output_truncated` (502) — Anthropic returned `stop_reason: "max_tokens"`
- `internal_error` (500)

- **Usage telemetry:** Every response includes a top-level `usage` object summarizing the Anthropic spend for that request. iOS may surface this in a debug overlay; judges will ask. See `Usage` schema below.

---

## Shared Schemas

### `Usage`
```json
{
  "input_tokens": 1234,
  "output_tokens": 567,
  "cache_read_input_tokens": 4500,
  "cache_creation_input_tokens": 0,
  "latency_ms": 8421,
  "model": "claude-opus-4-7",
  "calls": 12
}
```

### `StudentProfile`
```json
{
  "uid": "firebase_user_uid",
  "name": "Avery Patel",
  "program": "MS Computer Science",
  "year": 1,
  "interests": "graph neural networks, molecular property prediction, drug discovery",
  "background": "BS in CS from BITS Pilani; built a GNN-based property predictor as undergrad capstone; interned at a biotech analytics startup.",
  "cv_text": "Optional plain-text CV body, used by the Outreach agent."
}
```

### `Faculty` (subset shipped on response, full record in `data/faculty/`)
```json
{
  "faculty_id": "stevens_faculty_jdoe",
  "name": "Jane Doe",
  "title": "Associate Professor",
  "department": "Computer Science",
  "email": "jdoe@stevens.edu",
  "research_interests": ["machine learning", "graph algorithms"],
  "recent_papers": [
    {
      "title": "...",
      "venue": "NeurIPS 2024",
      "year": 2024,
      "abstract_excerpt": "...",
      "url": "https://..."
    }
  ]
}
```

### `TenantContext`
```json
{
  "is_student": true,
  "is_international": false,
  "is_first_us_lease": false,
  "notes": "Optional free-text additional context."
}
```

---

## 1. `POST /trust/lease/parse`

Run a NJ residential lease through Stages 1 → 2 → 3 and return the full tenant brief.

**Request** (`multipart/form-data`):
- `lease` (file, required): the lease PDF
- `tenant_context` (string, required): JSON-encoded `TenantContext`

**Response 200:**
```json
{
  "lease_id": "uuid-v4",
  "anthropic_file_id": "file_01abc...",
  "extracted": { /* ExtractedLease — see api/lease_pipeline/schemas.py */ },
  "analyses": [ /* ClauseAnalysis[] */ ],
  "brief": { /* LeaseBrief — see schema below */ },
  "usage": { /* Usage */ }
}
```

### `LeaseBrief` (Stage 3 output — Pydantic model in `api/lease_pipeline/schemas.py`)

```json
{
  "consent_clarity_score": 62,
  "score_meaning": "This lease is moderately tenant-hostile. Two high-risk clauses materially shift risk to you; several money items are not clearly disclosed.",
  "plain_english_summary": [
    "Rent is $2,400/month with a 5-day grace period before a $75 late fee.",
    "Security deposit is 1.5x monthly rent — the NJ statutory cap.",
    "Landlord may enter with 24-hour notice except in emergencies.",
    "You are responsible for water, gas, and electric; landlord pays trash.",
    "Lease auto-renews month-to-month unless either party gives 60-day notice."
  ],
  "money_map": {
    "base_rent_annual": 28800.00,
    "security_deposit": 3600.00,
    "application_fees": 50.00,
    "broker_fees": 2400.00,
    "last_month_required": true,
    "last_month_amount": 2400.00,
    "late_fee_structure": "$75 flat after a 5-day grace period; no compounding.",
    "utility_responsibilities": "Tenant: water, gas, electric, internet. Landlord: trash, common-area lighting.",
    "parking": "One assigned spot included; second spot $100/month.",
    "amenity_fees": "None disclosed.",
    "other_recurring": [
      { "label": "Renter's insurance (required)", "amount_annual": 180.00 }
    ],
    "estimated_total_annual": 34830.00,
    "notes": "Estimated total assumes second parking spot is not taken and renter's insurance is purchased at the cheapest disclosed quote."
  },
  "red_flags": [
    {
      "clause_id": "entry_rights",
      "headline": "Landlord retains broad entry rights without 'reasonable hours' qualifier.",
      "verbatim_text": "Landlord may enter the Premises at any time with 24 hours' notice for inspection or repairs.",
      "statute_citations": [
        {
          "citation": "N.J.S.A. 2A:39-1",
          "relevant_quote": "No person shall enter upon or into any real property...",
          "relevance": "NJ courts read landlord entry rights to require reasonable hours and bona fide purpose; this clause omits both."
        }
      ],
      "explanation": "The clause as written allows entry at 3am for any 'inspection,' which NJ case law treats as constructive eviction if abused. You can negotiate a 'between 9am and 6pm except for emergencies' qualifier.",
      "label": "aggressive_but_legal",
      "risk": "high"
    }
  ],
  "negotiation_openings": [
    {
      "clause_id": "entry_rights",
      "headline": "Tighten landlord entry to reasonable hours.",
      "draft_message": "I'd like to add 'between 9am and 6pm, except in emergencies' to the entry clause. NJ courts already read this in; making it explicit avoids ambiguity for both of us.",
      "counter_position": "If landlord refuses, ask for 48-hour notice instead of 24 as a fallback."
    }
  ],
  "closing_notes": {
    "not_legal_advice_disclaimer": "This brief provides legal information, not legal advice. It is not a substitute for consulting a licensed New Jersey attorney about your specific situation.",
    "when_to_consult_attorney": "Before signing if any red flag is labeled 'recommend_attorney_review' or 'conflicts_with_nj_law', or before any eviction or security-deposit dispute.",
    "referrals": [
      { "name": "NJ Volunteer Lawyers for Justice", "url": "https://www.njvlj.org/" },
      { "name": "Legal Services of NJ", "url": "https://www.lsnjlaw.org/" }
    ]
  },
  "consenterra_attribution": "Powered by the ConsenTerra framework for consent clarity.",
  "mocked_in_demo": false
}
```

**Field notes:**
- `consent_clarity_score`: int, 1–100. Higher = clearer / more tenant-fair.
- `plain_english_summary`: array of **exactly 5** strings. Stage 3 fails loud if not 5.
- `money_map.other_recurring[]`: each entry is `{ label: string, amount_annual: number }`.
- `red_flags[].statute_citations[]`: full `StatuteCitation` objects (`citation`, `relevant_quote`, `relevance`) — the same shape as in `ClauseAnalysis.statute_citations`. Never bare citation strings.
- `red_flags[].label`: enum, locked to four values — `conflicts_with_nj_law | aggressive_but_legal | common_but_worth_knowing | recommend_attorney_review`. See **Label derivation** below.
- `red_flags[].risk`: `"moderate" | "high"` only. `low` and `none` items don't surface as red flags.
- `mocked_in_demo`: `true` when the response was served from `data/demo_cache/` via `X-Demo-Replay`.

#### Label derivation

`red_flags[].label` is **not** a free-form judgment. Stage 3 derives it deterministically from Stage 2's `ClauseAnalysis` fields. iOS and Stage 3 must share this mapping verbatim:

| Label | Rule (evaluated top-down; first match wins) |
|---|---|
| `recommend_attorney_review` | `attorney_consultation_recommended == true` (overrides every other rule) |
| `conflicts_with_nj_law` | `legal_assessment ∈ {"conflicts", "unenforceable"}` |
| `aggressive_but_legal` | `legal_assessment == "consistent"` AND `risk_score == "high"` |
| `common_but_worth_knowing` | `risk_score == "moderate"` AND `legal_assessment ∈ {"consistent", "silent_on_protection"}` |

Rationale: these labels ground in objective Stage 2 signals, not subjective tenant reactions — defending the brief against "deal-breaker for whom?" questions. Any clause whose `ClauseAnalysis` doesn't satisfy one of the rules above is **not** a red flag and should not appear in `red_flags[]`.

**Demo replay mode:** if the request includes header `X-Demo-Replay: <demo_lease_id>`, the server returns a pre-baked response from `data/demo_cache/` and sets `brief.mocked_in_demo = true`. Demo replay bypasses idempotency caching (see Conventions).

---

## 2. `POST /discover/match`

Return top-K Stevens faculty matched to a student's interests.

**Request:**
```json
{
  "student": { /* StudentProfile */ },
  "top_k": 3,
  "department_filter": ["Computer Science", "Electrical and Computer Engineering"]
}
```

`department_filter` is **optional** (`string[]`). When omitted or `null`, all departments are eligible.

**Response 200:**
```json
{
  "matches": [
    {
      "rank": 1,
      "faculty": { /* Faculty */ },
      "match_score": 0.87,
      "reasoning": "Specifically grounded in the faculty's NeurIPS 2024 paper on...",
      "bridge_paper": {
        "title": "...",
        "year": 2024,
        "why_it_bridges": "Connects student's GNN background to professor's molecular work."
      }
    }
  ],
  "usage": { /* Usage */ }
}
```

---

## 3. `POST /discover/email`

Generate a Critic-reviewed cold email from student to faculty.

**Request:**
```json
{
  "student": { /* StudentProfile */ },
  "faculty_id": "stevens_faculty_jdoe",
  "bridge_paper": { /* same shape as in /match response */ },
  "ask": "I'm hoping to do an independent study with you this Fall."
}
```

**Response 200:**
```json
{
  "draft": {
    "subject": "Independent study on GNNs for molecular property prediction",
    "body": "Dear Professor Doe,\n\n...",
    "word_count": 178
  },
  "critic": {
    "passed": true,
    "iterations": 2,
    "checks": {
      "cites_specific_paper": true,
      "under_200_words": true,
      "clear_ask": true,
      "sounds_human": true
    },
    "notes": "Initial draft was too generic; revised to ground in the NeurIPS paper."
  },
  "usage": { /* Usage */ }
}
```

If `critic.passed == false` after the iteration cap, `draft` still returns the best attempt and `critic.notes` explains the residual failures.

---

## 4. `POST /presence/catalyst`

Rank the day's high-leverage social moments (overlapping schedules + shared interests + upcoming events).

**Request:**
```json
{
  "user_id": "firebase_user_uid",
  "now": "2026-04-30T14:30:00-04:00",
  "user": {
    "interests": ["climbing", "ML reading group", "Indian food"],
    "schedule_today": [
      {"start": "10:00", "end": "11:50", "location": "Babbio_210", "course": "CS-544"}
    ]
  },
  "friends": [
    {
      "uid": "...",
      "name": "Sam",
      "interests": ["climbing", "rust"],
      "schedule_today": [
        {"start": "10:00", "end": "11:50", "location": "Babbio_210", "course": "CS-544"}
      ],
      "ghost_mode": false
    }
  ],
  "upcoming_events": [
    {"title": "Free pizza @ ACM", "location": "Burchard_118", "starts_at": "2026-04-30T17:00:00-04:00", "category": "Free Food"}
  ]
}
```

**Response 200:**
```json
{
  "moments": [
    {
      "rank": 1,
      "title": "Coffee with Sam after CS-544",
      "why": "You and Sam share the 10am CS-544 block and both list climbing — a 12pm Pierce coffee fits the gap before your next class.",
      "when": "2026-04-30T12:00:00-04:00",
      "where": "Pierce Dining Hall",
      "friend_uids": ["..."],
      "linked_event_id": null
    }
  ],
  "usage": { /* Usage */ }
}
```

Friends with `ghost_mode == true` are filtered out client-side **before** the request is sent. The server treats `friends[]` as the eligible set.

**Time semantics:** the server treats the client-supplied `now` field as **authoritative** — it does not consult the server clock. Every `schedule_today[].start` and `end` is interpreted as a same-date wall-clock time in `now`'s timezone offset (the offset is parsed from `now`). The client is responsible for sending a timezone-aware `now`.

---

## 5. `POST /crown_moment`

The single demo card composing one signal from each module — the platform proof.

**Request:**
```json
{
  "user_id": "firebase_user_uid"
}
```

**Response 200:**
```json
{
  "card": {
    "headline": "A strong week ahead.",
    "discover": {
      "label": "Top faculty match",
      "faculty_name": "Jane Doe",
      "one_line": "GNNs for molecular property prediction — your capstone area."
    },
    "presence": {
      "label": "Tomorrow's moment",
      "one_line": "Coffee with Sam after CS-544 — first overlap this week."
    },
    "trust": {
      "label": "Lease brief ready",
      "one_line": "2 high-risk flags found in the Hoboken Newark Street lease.",
      "high_risk_count": 2
    },
    "generated_at": "2026-04-30T14:35:00-04:00"
  },
  "usage": { /* Usage */ }
}
```

This endpoint reads cached outputs of the per-module endpoints by default; pass `X-Force-Refresh: 1` to recompute.

---

## 6. `GET /trust/lease/{lease_id}` *(planned for v0.2 — not implemented in v0)*

Retrieve a previously-parsed lease by `lease_id` without re-uploading the PDF. Returns the same response envelope as `POST /trust/lease/parse` (extracted + analyses + brief + usage), served from server-side cache keyed by `lease_id`.

**Why deferred:** v0 has no persistent storage layer beyond `data/demo_cache/`. Once Railway provisions Postgres (or we wire Firestore directly), this endpoint lights up. iOS clients should treat the `lease_id` returned by `POST /trust/lease/parse` as opaque and forward-compatible — store it now, fetch it later.

**Status code while unimplemented:** `501 Not Implemented` with `code: "not_found"`.

---

## Versioning

This contract is `v0` and unstable until the demo. Breaking changes will be tagged in commit messages with `contract:` prefix and announced in the team channel.

Once stable post-hackathon: bump to `v1`, expose under `/v1/...` prefix, lock the schema.
