# Architecture

This document explains how The Stevens Nexus is structured, how data flows through the system, and the key design decisions behind it.

---

## High-Level Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              iOS Application                                 │
│  ┌─────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │  Map    │  │ Research │  │ Housing  │  │  Events  │  │ Profile  │         │
│  └─────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘         │
│       │            │             │              │             │              │
│       └────────────┴─────┬───────┴──────────────┴─────────────┘              │
│                          │                                                    │
│                  ┌───────┴────────┐                                           │
│                  │ AuthStateMgr   │  ← @StateObject in NexusApp.swift         │
│                  │ FirebaseMgr    │                                           │
│                  │ LocationMgr    │                                           │
│                  │ NotificationMgr│                                           │
│                  └───────┬────────┘                                           │
└──────────────────────────┼──────────────────────────────────────────────────┘
                           │
              ┌────────────┼─────────────┐
              ▼            ▼             ▼
       ┌───────────┐  ┌──────────┐  ┌─────────────┐
       │ Firebase  │  │ MapKit   │  │ Anthropic   │
       │ • Auth    │  │ • 3D     │  │ • Opus 4.7  │
       │ • FStore  │  │ • Annot. │  │   (Trust)   │
       │ • Storage │  │ • UserAn │  │ • Haiku 4.5 │
       └───────────┘  └──────────┘  └─────────────┘
```

---

## Layer 1 — SwiftUI Views

We followed **MVVM-lite** (no separate ViewModel files for hackathon speed; state is colocated with views via `@State` and `@EnvironmentObject`). Every view subscribes to `AuthStateManager` for the current user, and uses Firestore listeners directly for real-time updates.

### Key views and what they own

| View | Responsibility | State |
|---|---|---|
| `ContentView` | Root TabView + global AI bubble overlay | `@State selectedTab` |
| `MapView` | 3D MapKit, 3 modes (people/events/housing), search | Active students, events, housing pins |
| `ResearchView` | Faculty matching + trending categories | Matched professors, selected category |
| `HousingView` | 4 sub-tabs, sample data fallback | All listings, current tab, post-sheet flag |
| `EventsView` | Category filter, search, event detail sheet | Selected category, search text, selected event |
| `ProfileView` | Wallet card, preferences, sign out | Toggles, AddFunds sheet visibility |
| `AssistantView` | Global Nexus AI chat | Messages, search text, typing state |

---

## Layer 2 — Managers (Shared State)

### AuthStateManager (`NexusApp.swift`)
- Holds the current Firebase `User?` and the user's profile dict from Firestore
- Listens to `Auth.auth().addStateDidChangeListener` for sign-in / sign-out
- Refetches profile on auth state change
- Routes the root view: `ContentView` (logged in + complete) / `ProfileSetupView` (logged in + incomplete) / `LoginView` (logged out)

### FirebaseManager (`FirebaseManager.swift`)
- Singleton (`FirebaseManager.shared`)
- Caches faculty profiles in `@Published var faculty: [FacultyProfile]`
- `searchFaculty(query:)` does keyword overlap scoring against research interests + bio + department; returns top 3 matches with reasoning text
- One-shot `getDocuments` fetch (faculty data is mostly static — no need for snapshot listener)

### LocationManager (`LocationManager.swift`)
- Wraps `CLLocationManager` as an `ObservableObject`
- Requests `whenInUseAuthorization` on first map view appearance
- Publishes `userLocation: CLLocationCoordinate2D?` for the "center on me" button

### NotificationManager (`NotificationManager.swift`)
- Wraps `UNUserNotificationCenter`
- `scheduleEventReminders(for:)` — schedules two `UNCalendarNotificationTrigger`s per event (1 day before + 1 hour before)
- `cancelReminders(for:)` — removes both pending triggers when user un-registers

---

## Layer 3 — Data Flow

### Real-time vs. one-shot

We use **`addSnapshotListener`** for collections that need live updates and **`getDocuments`** for one-shot fetches:

| Collection | Listener Strategy | Why |
|---|---|---|
| `eventComments` | `addSnapshotListener` | Reviews must appear instantly when posted |
| `housingRequests` | `addSnapshotListener` | Status changes (open → claimed → submitted → verified) propagate live |
| `roommateProfiles` | `addSnapshotListener` | New profiles appear immediately |
| `housingInterest` | `getDocuments` | Tap-to-toggle, refresh on action |
| `faculty` | `getDocuments` | Static dataset, no need for live updates |
| `users` | One-shot on auth change | Profile rarely changes |

### Composite-index pitfall

We deliberately **avoid** Firestore composite indexes in queries to keep the project deployable to a fresh project without manual setup. Specifically, queries that combine `whereField` + `orderBy` on different fields require a composite index — instead we sort in memory after parsing:

```swift
.collection("eventComments")
    .whereField("eventID", isEqualTo: event.id)
    // NOT: .order(by: "createdAt", descending: true)
    .addSnapshotListener { snapshot, _ in
        let parsed = snapshot.documents.compactMap { ... }
            .sorted { $0.createdAt > $1.createdAt }   // ← in-memory sort
        ...
    }
```

This trades CPU for zero-config deployability. With <100 reviews per event it's invisible.

### Sample data fallback pattern

Several views (Map housing pins, Roommates, My Listings, My Jobs) merge **hardcoded sample data** with live Firestore data. This guarantees a non-empty UI for the demo even before any user has posted, while still showing real user contributions when they exist:

```swift
profiles = sampleRoommateProfiles  // immediate
.addSnapshotListener { snapshot, _ in
    let live = parse(snapshot)
    profiles = sampleRoommateProfiles + live  // merged on every snapshot
}
```

---

## Layer 4 — The Lease Pipeline (External, `feat/lease-pipeline-and-bootstrap`)

The Lease Verifier is the most architecturally interesting piece. It's a **3-stage Anthropic pipeline** that turns a PDF into a structured tenant brief:

```
PDF upload                    Pydantic schemas
    │                              │
    ▼                              ▼
┌──────────────┐    ExtractedLease
│  Stage 1     │ ──────────────────►  ┌──────────────┐    ClauseAnalysis[]
│  Extractor   │                      │  Stage 2     │ ────────────────────►   ┌──────────────┐
│  Opus 4.7    │                      │  Analyzer    │                         │  Stage 3     │
│  effort=high │                      │  Opus 4.7    │                         │  Briefer     │   LeaseBrief
└──────────────┘                      │  effort=high │                         │  Opus 4.7    │ ───────►
   pulls every                        │  per clause  │                         │  effort=med  │
   clause verbatim                    │  + statute   │                         │  synthesizes │
                                       │  citations   │                         │  + scores    │
                                       └──────────────┘                         └──────────────┘
                                              │
                                              ▼
                                       ┌──────────────────┐
                                       │ NJ Statute Corpus│
                                       │  (14 entries,    │
                                       │   curated)       │
                                       └──────────────────┘
```

### Why three stages?

- **Separation of concerns**: extraction is mechanical, analysis is legal, brief is human-facing
- **Caching**: Stage 1's verbatim clauses are deterministic, so we use Anthropic prompt cache to reuse them across re-runs
- **Failure isolation**: a Stage 3 error doesn't waste the Stage 1+2 tokens; the orchestrator can retry just Stage 3
- **Citation grounding**: Stage 2 enforces a `Literal` type on `ApprovedCase` and validates statute citations against the corpus *post-output* — the model physically cannot fabricate a citation outside the curated list

### Demo fallback

The iOS client (`LeaseAPI.swift`) has a built-in `demoLeaseBrief` constant that fires automatically if the cloud function is unreachable (404, network failure, decoding error). This means:
- The demo always works, even without backend connectivity
- The fallback brief is a realistic Hoboken lease at score 62/100, so judges see the full output shape
- The boundary is one constant in one file — when the backend deploys, swap the `baseURL` and remove the fallback path

---

## Layer 5 — Design System

### Colors (`Theme.swift`)
- `.stevensRed` (`#820823`) — primary brand
- `.primaryContainer` (`#A32638`) — Stevens crimson, used for gradients
- `.nexusSecondary` (`#5d5e5f`) — secondary text
- `.nexusSurface` (`#f9f9fe`) — page background
- `.surfaceContainerLow`, `.surfaceContainer`, `.outlineVariant` — Material-style elevation tokens

### Typography
- All sizing in points via `.system(size:weight:)`
- Hero: 22–28pt, bold
- Body: 14–15pt, regular
- Metadata: 11–13pt, secondary color
- Tracking-style "tag" labels: 10–11pt uppercase, tracking 1pt

### Card Standards
- White background, `.cornerRadius(16)` (or 14 for inset cards)
- Shadow: `color: .black.opacity(0.07), radius: 6, y: 2`
- Padding: 14–16pt internal

### Material backgrounds
- Top bars and floating pills use `.regularMaterial` for a glassy translucent effect over MapKit content

---

## Notable Engineering Decisions

### 1. No tracking analytics
We deliberately ship with **no third-party analytics or tracking SDKs** — not Firebase Analytics, not Mixpanel, nothing. The student data we hold (schedules, reviews, leases) is sensitive enough that we wanted a clean privacy story for the demo. Adding analytics is a one-line change post-hackathon.

### 2. Privacy-by-default UI
Every social feature has a privacy escape hatch:
- **Ghost Mode** on map (one toggle on Profile)
- **Anonymous reviews** on events (toggle in the AddReviewSheet)
- **Anonymous interest** on housing (the heart button doesn't reveal who clicked)

### 3. International student support
The Add Funds sheet defaults to **Credit/Debit Card with Visa/Mastercard/Amex/RuPay** logos — explicitly because half of Stevens grad students are international and don't have Apple Pay or US bank accounts. This was a 30-minute change with disproportionate impact.

### 4. Demo-mode fallbacks everywhere
Every backend call has a graceful degradation path:
- Lease pipeline → `demoLeaseBrief` constant
- Map housing pins → `sampleHousingListings` array
- Roommate profiles → `sampleRoommateProfiles`
- My Listings / My Jobs → `sampleMyListings` / `sampleMyJobs`
- Email drafter → local template generation

This means the entire app works **offline at demo time**, and gradually migrates to real backend data as services come online.

### 5. Hardcoded essential AI
The Nexus AI assistant is intentionally **hardcoded with 10 Q&A pairs** rather than calling a real LLM. Reasons:
- Zero latency (no network round-trip)
- Zero cost (no per-query LLM spend)
- Deterministic answers (judges asking the same question twice get the same answer)
- The keyword-matching search bar feels indistinguishable from a real LLM for the curated topic set

When we need open-ended chat post-hackathon, swap the `submitSearch()` body for a `messages.create` call to Claude Haiku.

---

## What's NOT in this codebase

To set expectations honestly:
- **No real payments** — the Add Funds flow is a 1.5-second simulation, no Stripe/Apple Pay tokenization
- **No real-time location sharing** between users — friend dots are computed client-side from each student's schedule × current time
- **No moderation** for event reviews — they're posted as-is to Firestore
- **No image upload** for housing verification — verifiers paste a video link rather than upload photos directly (Firebase Storage hooks exist but aren't wired)
- **The lease cloud function isn't deployed** at submission time — but the iOS client is fully wired, the demo brief renders, and the backend code on `feat/lease-pipeline-and-bootstrap` is complete and tested locally

These are explicitly tracked as "v1 → v2" gaps, not bugs.

---

## Repository Branches

- `main` — current iOS frontend
- `feat/events-data` — Stevens campus events JSON (50 events) + date index
- `feat/lease-pipeline-and-bootstrap` — Python backend, NJ statute corpus, lease pipeline stages 1–3
- `feat/negotiator-design` — round-by-round landlord negotiation engine (next phase)
- `chore/firebase-deploy-config` — Firebase Cloud Functions deploy scaffolding

---

## See Also

- [`README.md`](./README.md) — project overview and demo
- [`FEATURES.md`](./FEATURES.md) — feature-by-feature spec
- [`api/CONTRACT.md`](https://github.com/KPandya1903/Nexus/blob/feat/lease-pipeline-and-bootstrap/Desktop/Projects/Nexus/api/CONTRACT.md) — iOS ↔ backend API contract
