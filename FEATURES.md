# Features

A feature-by-feature spec for The Stevens Nexus. Each section lists the user story, the implementation, and the file(s) where it lives.

---

## 🗺️ The Map

### People Mode
**As a Stevens student, I want to see which of my friends are on campus right now so I can grab coffee between classes.**

- Shows ~6 active students at real Stevens building coordinates
- Each student has a circular avatar marker (initials, color, pulse animation if selected)
- Tap a marker → student info card with name, building, course code, room
- Match logic: `(SeedStudent.schedule × current weekday × current hour)` → `currentBuildingKey`
- Demo fallback: if no students match the live time window, shows all 6 at preset buildings

**Files:** `MapView.swift`, `CampusData.swift`

### Events Mode
**As a student, I want to see what's happening on campus today and where it's happening.**

- 12 events plotted at their venue's real GPS coordinates
- Color-coded by category: Social (blue), Workshop (red), Fitness (green), Cultural (purple), Networking (orange), Competition (slate)
- Tap a pin → event info card with name, time, location, **registration status badge**:
  - 🟢 **Registration Open** + Register Now button (opens external link)
  - ✓ **No Registration Needed — Just Show Up**
  - 🔒 **Registration Closed**
  - ⏰ **Event has passed**

**Files:** `MapView.swift`, `EventsData.swift`, `CampusData.swift` (`buildingKeyForEventLocation`)

### Housing Mode
**As a student looking for an apartment, I want to see verified listings near campus on a map.**

- 11 listings scattered across Hoboken (7), Jersey City, Union City, Weehawken, Edgewater
- Hoboken pins use per-listing coordinate offsets so they don't stack — Garden St, Bloomfield, Hudson, Park, Adams, etc.
- Each pin shows the rent label below the marker
- Tap → housing info card with neighborhood badge, bounty pill, beds/baths/rent, status

**Files:** `MapView.swift` (`sampleHousingListings`, `sampleListingCoordinates`, `neighborhoodCoordinates`)

### Search & Live Location
- Top search bar with auto-suggest pills below — matches against student names, building names, event names, course codes
- Search results pills auto-zoom the map when tapped
- Live blue dot via `CoreLocation` (`UserAnnotation()`) — works on real device (simulator shows fake location)
- "Center on me" location button uses real GPS coordinates

**Files:** `MapView.swift`, `LocationManager.swift`

---

## 🔬 Research

### Faculty Matching
**As a student looking for a research advisor, I want to describe my interests in plain English and find professors who match.**

- Free-form text input
- `searchFaculty(query:)` does keyword overlap scoring against research interests + bio + department
- Returns top 3 with:
  - Photo (AsyncImage, fallback to initials avatar)
  - Name + rank + department
  - 3 research interest tags
  - One-line **shortBio** like "Associate Professor in CS — works on graph algorithms"

**Files:** `ResearchView.swift`, `FirebaseManager.swift`

### Trending Categories with Live Spotlight
**As a student browsing without a specific query, I want to see what's hot in different research areas.**

- 5 chips: Quantum Computing, Sustainability, FinTech, Cybersecurity, BioTech
- Tapping a chip animates the **Spotlight card** to a real Stevens seminar/lab/workshop matching that category:
  - Quantum Computing → Prof. Yuping Huang's Quantum Algorithms seminar
  - Sustainability → Davidson Lab Coastal Resilience open house
  - FinTech → Bloomberg Terminal Algorithmic Trading workshop (Babbio Trading Lab)
  - Cybersecurity → Stevens Cyber Defense Team CTF practice
  - BioTech → Prof. Samantha Kleinberg's AI in Drug Discovery talk
- Each spotlight has its own gradient color matching the category

**Files:** `ResearchView.swift` (Spotlight struct, spotlights dict)

### Professor Profile Sheet
**As a student, I want to see a professor's full background before reaching out.**

- Tap any professor card → modal sheet with:
  - Photo, name, rank, department, email
  - "Why this match" callout (red-tinted) explaining the match reason
  - Research interest chip flow (`FlexibleTagFlow` custom Layout)
  - Bio
  - **Draft Outreach Email** primary button
  - View Stevens Profile link (opens directory page)

**Files:** `ProfessorProfileView.swift`

### AI Email Drafter
**As a student, I want a professional cold email drafted for me that I can edit before sending.**

- Tone selector: Formal / Neutral / Warm
- Editable "Your Ask" text area (sensible default pre-filled)
- Tap Generate → 1-second simulated AI delay → produces:
  - Subject line referencing the professor's first research interest
  - Body greeting + opener + background (pulled from user profile: name, major, year, about, GitHub) + ask + closer
  - All three tones have distinct openers and closers
- Generated email is fully editable
- **Open in Mail** uses `mailto:` URL with To/Subject/Body pre-filled
- **Copy Email** copies subject + body to clipboard with green checkmark

**Backend swap point:** `generate()` body — replace local template with `POST /discover/email` to get a Critic-reviewed email from Claude Opus.

**Files:** `ProfessorProfileView.swift` (`EmailDrafterSheet`)

---

## 🏠 Housing

### Lease Verifier
**As an international student signing my first U.S. lease, I want AI to flag predatory clauses before I sign.**

Flow:
1. Tap red "Lease Verifier" banner at top of Housing > Browse
2. Toggle: "Are you on F-1 visa?" / "First U.S. lease"
3. Pick PDF via `fileImporter`
4. Tap **Analyze My Lease** → shows progress for 30–90s

Output (`LeaseBriefView`):
- **Consent Clarity Score** (1–100) with red/orange/green tint based on tenant-fairness
- 5-bullet plain-English summary
- **Money Map**: rent, deposit, fees, utilities, parking, last-month, estimated annual total
- **Red Flags** with severity badge (high / moderate), headline, plain explanation, italicized verbatim quote
- **Negotiation Openings** with ready-to-send draft messages
- Closing notes + NJ legal aid links + Stevens Dean of Students

**Backend:** Anthropic Opus 4.7, 3-stage pipeline grounded in 14 NJ statutes (curated from NJSA 46:8-19, 46:8-21.1, 46:8-21.2, plus Hoboken §155 and flood disclosure entries)
**Demo fallback:** `demoLeaseBrief` const auto-fires on network failure with a realistic Hoboken lease at score 62/100

**Files:** `LeaseAnalyzerView.swift`, `LeaseAPI.swift`

### Bounty Verification System
**As a student abroad, I want to pay another Stevens student to physically verify a rental property.**

Lister flow:
1. Tap red **+** button on Housing tab
2. Fill: neighborhood, address, monthly rent, beds/baths, listing URL
3. Pick bounty: $10 / $15 / $20 / $25 / $30
4. Submit → wallet deducts, listing goes "open"

Verifier flow:
1. Browse open listings, tap **Claim Bounty**
2. 48-hour countdown starts
3. Visit the property, paste video link + notes
4. Submit for review

Lister approval:
1. Sees status change to "submitted" with verifier's evidence
2. Tap **Confirm & Release Payment** or **Request More Evidence**
3. On confirm: bounty transfers to verifier's wallet

Auto-expire: if 48h passes without submission, bounty refunds to lister and verifier gets banned (status → "expired").

**Files:** `HousingView.swift` (`HousingRequest`, `HousingListingCard`, `PostListingSheet`, `ListingDetailSheet`, `SubmitProofSheet`)

### Roommate Matching
**As a student looking for housemates, I want to filter by lifestyle and budget.**

- Roommate profile fields:
  - Budget pill ($800–$1,200 / $1,200–$1,600 / $1,600–$2,000 / $2,000+)
  - Neighborhood multi-select (Hoboken, Jersey City, Union City, Weehawken, Edgewater)
  - Move-in date (May 2026 / June 2026 / August 2026 / Flexible)
  - Lifestyle multi-select (12 options: Early Bird, Night Owl, Clean, Relaxed, Quiet, Social, Pet-Friendly, No Pets, Non-Smoker, Study-Focused, Remote Worker, Gym-Goer)
  - About paragraph
- 5 sample profiles seeded for the demo
- Live profiles from Firestore appear above samples
- Each card has a "Connect" button (currently shows your name copy; ready for in-app messaging)

**Files:** `HousingView.swift` (`RoommateProfile`, `RoommateView`, `RoommateCard`, `PostRoommateSheet`, `FlowLayout`)

### Show Interest
**As a student browsing housing, I want to express interest without committing.**

- Heart button on every listing card
- Tap → adds doc to `housingInterest` collection with `{listingID, userID, userName, createdAt}`
- Counter shows "X interested" next to the heart
- Tap again → removes the doc, decrements counter

**Files:** `HousingView.swift` (`HousingListingCard.toggleInterest`, `loadInterest`)

### My Listings & My Jobs Tabs
- **My Listings** — 3 sample listings as if Jhanvi posted from India before arriving (statuses: submitted / verified / open)
- **My Jobs** — 3 sample bounties as if Jhanvi has completed verifications, with photo notes about each visit
- Real listings/jobs from Firestore merge with sample data

---

## 📅 Events

### Filter & Browse
**As a student, I want to filter campus events by what I care about.**

- Top horizontal chip strip: All / Social / Workshop / Fitness / Cultural / Networking / Competition
- Selected chip is filled red, others have border outline
- Search bar matches event name, club, location
- Sorted ascending by date

**Files:** `EventsView.swift` (`searchResults`, `filteredEvents`)

### Event Detail Sheet
- Hero with category color gradient + event name + club
- Date, time, duration, location rows
- Spots remaining row (color-coded green/orange/red based on availability)
- Registration required indicator
- **Register & Get Notified** button:
  - Toggles between red "Register" and green "Registered — Reminders Set"
  - Schedules iOS local notifications 1 day + 1 hour before event start
- View Event Page link (external URL)

**Files:** `EventsView.swift`, `NotificationManager.swift`

### Reviews System
**As an attendee, I want to leave a review and see what others thought.**

- Star rating breakdown (5★ through 1★ with proportional fill bars)
- Reviews list with avatar (gray for anonymous, red-tinted for named), star row, text, relative timestamp ("2 days ago")
- **Write a Review** button → sheet with:
  - Tap-to-set 5-star picker with spring animation
  - TextEditor for comment
  - Anonymous toggle showing "Posting as: Jhanvi" or "Posting as: Anonymous"
  - Submit validates rating > 0 and non-empty text
- Real-time `addSnapshotListener` on `eventComments` — reviews appear immediately
- In-memory sort by `createdAt` (no composite index required)

**Files:** `EventsView.swift` (`EventComment`, `CommentCard`, `AddReviewSheet`, `loadComments`)

---

## 👤 Profile

### Hero & Profile Data
- Initials avatar with red gradient + green status dot
- Full name, major · year · gradSemester
- GitHub link (if set)
- About paragraph
- All pulled from Firestore `users/{uid}` document, written by ProfileSetupView on first launch

**Files:** `ProfileView.swift`, `ProfileSetupView.swift`, `NexusApp.swift` (`AuthStateManager.fetchProfile`)

### Nexus Wallet
- Big balance display in red gradient card
- **Add Funds** button → opens AddFundsSheet (international card support, see below)
- Transaction history button (placeholder)

### Add Funds Payment Flow
**As an international student, I want to add funds without Apple Pay or a US bank.**

- Amount chips: $10 / $25 / $50 / $100
- Payment methods (Card is default & first):
  - **Credit / Debit Card** — "Visa, Mastercard, Amex, RuPay — works internationally"
    - Card details form: cardholder name, card number, MM/YY, CVV
    - Visa/MC/AMEX colored mini-logos in section header
  - **Apple Pay** — black "Pay" button (US accounts only)
  - **Bank Transfer** — ACH (US accounts only)
- 1.5s "processing" spinner
- Success view: green checkmark, summary, new balance
- "Demo mode — no real charge" disclaimer

**Files:** `AddFundsSheet.swift`

### Preferences
- **Ghost Mode** toggle — hides your dot from everyone's map
- **Sync Schedule** toggle — auto-update from Workday (placeholder)
- **Edit Profile** chevron

### Sign Out
- Single tap, calls `Auth.auth().signOut()` and resets `AuthStateManager` state

**Files:** `ProfileView.swift`

---

## 🤖 Nexus AI (Global)

**As a new user, I want answers to common questions without leaving the screen I'm on.**

- Sparkly red gradient floating bubble (52pt) with pulse ring on every tab
- Position: bottom-right normally, **bottom-left on Housing** (so it doesn't conflict with the post-listing + button)
- Tap → modal chat sheet titled "Nexus AI"

Chat features:
- Welcome bubble: "Hi! I'm Nexus AI 👋"
- 10 hardcoded essential Q&A pairs accessible via horizontal chip scroll:
  1. What is The Stevens Nexus?
  2. How do I find a research professor?
  3. How does the Lease Verifier work?
  4. How does the housing bounty system work?
  5. How do I find a roommate?
  6. What is Ghost Mode?
  7. How do I see today's events?
  8. How do I leave a review on an event?
  9. What can the campus map show me?
  10. Is my data private?
- **Free-form search bar** at the bottom — type any question, hit send
- Keyword-overlap matching: scores each Q&A by how many user words appear in the question + answer text, returns highest-scoring response
- Falls back to "I'm not sure about that yet — try one of the suggested questions" if nothing scores > 0
- Animated typing indicator (3 pulsing dots) before each bot reply

**Files:** `AssistantView.swift`

---

## 🔐 Authentication & Onboarding

### Login
- Email/password Firebase Auth
- Validates `@stevens.edu` domain (also allows `@gmail.com` for testing)
- Toggle between Sign In and Sign Up modes
- Inline error messages (auth errors surfaced in red)

### Profile Setup (first-time signup only)
- Multi-step form: Full Name, Major (Picker), Year (Freshman/Sophomore/.../Graduate), Graduation Semester, GitHub username, About paragraph
- Saves to `users/{uid}` with `profileComplete: true`
- AuthStateManager flips `profileComplete = true` → routes to `ContentView`

**Files:** `LoginView.swift`, `ProfileSetupView.swift`

---

## ⚡ Engineering Niceties

- **Smooth animations** — all sheet transitions, mode toggles, and rating taps use `.spring()` or `.easeInOut`
- **Haptic-friendly tap targets** — all buttons are at least 44×44pt
- **Real-time everywhere** — `addSnapshotListener` ensures the UI updates instantly when any user posts a review, claims a bounty, or shows interest
- **Fail-loud when it matters** — review/lease submission errors surface in the UI rather than silently dropping
- **Demo-mode fallbacks** — every backend dependency has a graceful degradation path for offline demos
- **Color-coded countdowns** — bounty timers turn orange under 2h, red under 1h
- **Privacy escape hatches** — Ghost Mode, anonymous reviews, anonymous interest

---

## What's Coming Next

Tracked in branches and notes:
- 🤖 **Negotiator engine** (`feat/negotiator-design`) — round-by-round landlord email negotiation with classifier + strategist + 6 drafter prompts
- 📷 **Photo upload for housing verification** — Firebase Storage integration (hooks exist, UI not wired)
- 💬 **Real-time roommate messaging** — Firestore subcollection per pair
- 📊 **Course reviews** — leveraging the 858 Stevens course sections we've already parsed
- 💳 **Real Stripe payments** — wallet → Stripe → bank
- 📨 **Real `/discover/email` endpoint** — Critic-reviewed cold emails via Claude Opus
- 🎓 **Workday OAuth** — auto-sync class schedules

---

See [`README.md`](./README.md) for the project overview and [`ARCHITECTURE.md`](./ARCHITECTURE.md) for the architectural overview.
