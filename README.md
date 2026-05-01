# The Stevens Nexus

> **One app. Three pillars. Zero wasted semesters.**
> A campus operating system for Stevens Institute of Technology — built in 24 hours.

[![Built at Stevens Hackathon](https://img.shields.io/badge/Built%20at-Stevens%20Hackathon-A32638)](https://www.stevens.edu/)
[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-black?logo=apple)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-blue?logo=swift)](https://developer.apple.com/swiftui/)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-orange?logo=firebase)](https://firebase.google.com/)
[![Anthropic](https://img.shields.io/badge/AI-Claude%20Opus%204.7-D77655?logo=anthropic)](https://www.anthropic.com/)

---

## The Problem

Last semester, three Stevens students signed leases sight-unseen and got scammed.
One didn't know which professor matched her PhD interests until four weeks before the deadline.
Hundreds missed free pizza, study jams, and career fairs because the events page is buried five clicks deep on Workday.

**Stevens has the people. Stevens has the resources. What we don't have is a way to *find them in time*.**

That's why we built The Stevens Nexus.

---

## The Three Pillars

### 🗺️ Social Presence
A 3D campus map with real Stevens building coordinates. See friends in class right now (pulled from their schedules), discover events happening across campus today, and browse verified housing listings — all from a single map with three toggleable modes.

### 🔬 Academic Discovery
Type your research interest in plain English. Nexus matches you against Stevens faculty using their interests and recent papers, then generates a personalized cold-outreach email — referencing the professor's exact work, your major, and your GitHub — in three tones (formal, neutral, warm). One tap opens it in Mail.

### 🏠 Housing Trust
Three sub-features for off-campus rental safety:
- **Lease Verifier** — Upload a lease PDF, get an AI-generated brief with a Consent Clarity Score, money map, NJ statute–grounded red flags, and ready-to-send negotiation messages.
- **Bounty System** — Can't visit a place in person? Post a verification request with a $10–$30 bounty. A Stevens student near the listing claims it, walks the unit, submits photos + a video, and only gets paid when you approve.
- **Roommate Matching** — Find Stevens students looking to share housing, filtered by budget, neighborhood, move-in date, and lifestyle.

---

## Live Demo

The app is deployed locally for the demo session. **Architecture overview:**

```
┌─────────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐
│   iOS (SwiftUI)         │    │   Firebase           │    │   AI Pipeline        │
│   • 5 tabs              │    │   • Auth (email)     │    │   • Anthropic Opus   │
│   • Real-time UI        │◄──►│   • Firestore        │◄──►│     4.7 (Trust)      │
│   • MapKit 3D           │    │   • Cloud Functions  │    │   • OpenAI GPT-4     │
│   • Local notifications │    │   • Storage          │    │     (Discover)       │
└─────────────────────────┘    └──────────────────────┘    └──────────────────────┘
```

---

## Feature Walkthrough

### Tab 1 — The Map
Open the app and you land on a 3D MapKit view of Stevens campus, real elevation, real coordinates. Three toggle pills at the top:

| Mode | What it shows |
|------|---|
| **People** | Friends currently in class — pulled from their schedule × current time |
| **Events** | Color-coded calendar pins at every venue with an event today (12+ real Stevens events) |
| **Housing** | Verified rental listings spread across Hoboken, Jersey City, Union City, Weehawken, Edgewater |

Tap any pin → info card slides up with details + a "Register Now" button (events) or full listing details (housing). Search bar highlights matches. Ghost Mode (on Profile) hides your dot from everyone.

### Tab 2 — Research
- **AI Assistant card**: type your research interest, get matched to Stevens faculty
- **Trending Categories** (Quantum Computing, Sustainability, FinTech, Cybersecurity, BioTech) — tapping a chip changes the **Spotlight card** to a real Stevens seminar/lab
- **Tap any professor** → full profile sheet with bio, research interests, Stevens directory link, and the **Draft Outreach Email** button

### Tab 3 — Housing
Four sub-tabs:
- **Browse** — open verification requests with countdown timers, "Interested" hearts, and the **Lease Verifier** banner at the top
- **Roommates** — 5+ profiles with budget pills, lifestyle tags, neighborhoods. Tap + to post your own.
- **My Listings** — what you've posted, with status (open / claimed / submitted / verified)
- **My Jobs** — bounties you've completed as a verifier, with payout amounts

### Tab 4 — Events
Filter chips (All, Social, Workshop, Fitness, Cultural, Networking, Competition) + search bar. 12 real Stevens events. Tap any → detail sheet with:
- Big date badge, club, location, spots
- Star rating breakdown bars
- **Register & Get Notified** button — schedules iOS local notifications 1 day + 1 hour before
- **Reviews** — peer comments with stars, posted live to Firestore (anonymous toggle supported)

### Tab 5 — Profile
- Hero with initials avatar, real-time Firebase profile data (name, major, GitHub, about)
- **Nexus Wallet** — supports Credit/Debit Card (international Visa, Mastercard, Amex, RuPay), Apple Pay, Bank Transfer
- Ghost Mode + Sync Schedule toggles
- Sign out

### Global — Nexus AI
A floating sparkly red bubble on every tab opens an in-app chat assistant. 10 hardcoded essential Q&As (covering every feature) accessible via tappable chips, plus a free-form **search bar** at the bottom that uses keyword matching to route to the closest answer.

---

## Tech Stack

**iOS Frontend (Swift / SwiftUI)**
- MapKit 3D with realistic elevation and `MapCameraPosition`
- Firebase iOS SDK (Auth, Firestore, Storage)
- CoreLocation for live blue dot
- UserNotifications for event reminders
- Real-time Firestore `addSnapshotListener` for reviews, housing, roommates

**Backend (`feat/lease-pipeline-and-bootstrap` branch)**
- Python + Pydantic v2
- 3-stage Anthropic pipeline:
  - **Stage 1 (Extractor)** — Opus 4.7 extracts every clause from the PDF
  - **Stage 2 (Analyzer)** — per-clause analysis grounded in 14 NJ statutes
  - **Stage 3 (Briefer)** — synthesizes a tenant-facing LeaseBrief with ConsenTerra attribution
- Deterministic JSON serialization for prompt-cache stability
- FastAPI route boundary documented in `api/CONTRACT.md`

**Data**
- 50 real Stevens campus events with date index
- 14 NJ landlord-tenant statutes (incl. Hoboken §155 and flood disclosure)
- Pre-seeded faculty corpus from CS / ECE
- 858 course sections parsed from the Stevens registrar

---

## Project Structure

```
Nexus/
├── Nexus/                          ← iOS app source
│   ├── NexusApp.swift              ← @main + AuthStateManager
│   ├── ContentView.swift           ← TabView root + global AI overlay
│   ├── MapView.swift               ← 3D map, 3 modes, search, info cards
│   ├── ResearchView.swift          ← Faculty matching, trending, spotlight
│   ├── HousingView.swift           ← 4 sub-tabs, listings, roommates, interest
│   ├── EventsView.swift            ← Filter chips, reviews, registration
│   ├── ProfileView.swift           ← Wallet, ghost mode, settings
│   ├── AssistantView.swift         ← Global AI chat (Nexus AI)
│   ├── LeaseAnalyzerView.swift     ← PDF upload + brief display
│   ├── LeaseAPI.swift              ← Backend client + demo fallback
│   ├── ProfessorProfileView.swift  ← Profile sheet + email drafter
│   ├── AddFundsSheet.swift         ← Card / Apple Pay / Bank checkout
│   ├── EventsData.swift            ← 12 seed events
│   ├── CampusData.swift            ← 17 buildings, 10 students, schedules
│   ├── FirebaseManager.swift       ← Faculty fetch + matching
│   ├── LocationManager.swift       ← CLLocationManager wrapper
│   ├── NotificationManager.swift   ← Local event reminders
│   ├── Theme.swift                 ← Stevens colors + Color(hex:)
│   └── Assets.xcassets             ← Icons, accent colors
│
├── api/                            ← Python backend (separate branch)
│   ├── CONTRACT.md                 ← iOS ↔ backend source of truth
│   ├── lease_pipeline/             ← Stages 1, 2, 3 + schemas
│   ├── negotiator/                 ← Round-by-round negotiation engine
│   └── shared/                     ← Usage logger, citation validators
│
└── data/
    ├── events/sample_events.json   ← 50 Stevens events
    ├── statutes/nj_statutes.json   ← 14 NJ statutes
    └── demo_cache/                 ← Pre-baked demo replays
```

See [`ARCHITECTURE.md`](./ARCHITECTURE.md) for a deeper architectural overview and [`FEATURES.md`](./FEATURES.md) for a feature-by-feature spec.

---

## Setup

### iOS App

```bash
git clone https://github.com/KPandya1903/Nexus.git
cd Nexus/Nexus/Nexus
open Nexus.xcodeproj
```

In Xcode:
1. **Signing & Capabilities** → set your Apple Development team
2. Change Bundle ID to something unique (e.g. `com.YOUR_NAME.stevennexus`)
3. Add your `GoogleService-Info.plist` from the Firebase console (project: `nexus-stevens`)
4. Set iOS Minimum Deployment to **17.0** (required for `MapCameraPosition`)
5. **Cmd+R**

### Backend (lease pipeline)

```bash
git checkout feat/lease-pipeline-and-bootstrap
cd Desktop/Projects/Nexus/api/lease_pipeline
pip install -r requirements.txt
cp .env.example .env  # add your ANTHROPIC_API_KEY
python run_pipeline.py path/to/lease.pdf
```

### Required Firestore collections
- `users` — user profiles
- `housingRequests` — verification requests
- `housingInterest` — "interested" tracker
- `roommateProfiles` — roommate matching
- `eventComments` — event reviews
- `faculty` — pre-seeded Stevens faculty

---

## Team

| | Name | Role |
|---|---|---|
| 💻 | **Jhanvi Damwani** | iOS frontend, Firebase auth, UX design — entire SwiftUI surface |
| 🎨 | **Ashika** | Product, social presence layer, event review system |
| 🧠 | **Aditya Bhatia** | AI pipeline architect — 3-stage Anthropic Opus reasoning + NJ statute grounding |
| ⚙️ | **Kunj Pandya** | Faculty scraper, course parser, professor matching backend |

Built in 24 hours at the Stevens Institute of Technology hackathon.

---

## Demo Highlights

- 🎯 **Hoboken lease scored 62/100** — pipeline caught a 60-day auto-renewal trap costing students two months of rent
- 💰 **$38,630 actual annual cost** vs `$2,400/mo` listing — money map exposes hidden broker fees + last month + utilities
- 🏠 **7 Hoboken listings** spread across Garden, Bloomfield, Hudson, Park, Adams streets — all scattered with unique coordinates
- 📅 **12 real Stevens events** for the week — Career Fair, Mehfil, Therapy Dogs, AI Paper Reading, CTF Practice
- 🤖 **Nexus AI** — global floating assistant answering 10 essential questions for new students, plus free-form search

---

## License

MIT — built for and by Stevens students.

---

## Acknowledgments

- Stevens Institute of Technology
- Anthropic (Claude Opus 4.7) for the lease analysis backbone
- The ConsenTerra framework for consent-clarity scoring methodology
- Stevens faculty whose public profiles power the matching engine

> *"The Stevens Nexus isn't three apps glued together. It's one fabric: discover, connect, sign safely. Built by students, for students."*
