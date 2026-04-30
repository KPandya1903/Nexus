# Project: The Stevens Nexus
**Campus OS for Stevens Institute of Technology**

## 1. Project Overview
A unified native iOS application designed to bridge gaps in campus life through three primary pillars:
- **Academic Discovery:** AI-powered professor research matching and course transparency.
- **Social Presence:** 3D Map-based friend scheduling (non-live) and community event discovery.
- **Housing Security:** A peer-to-peer verification marketplace for Hoboken apartment rentals.

## 2. Technical Stack
- **Frontend:** SwiftUI (Xcode)
- **Maps:** MapKit (Native 3D Realistic Elevation)
- **Backend/Database:** Firebase (Auth, Firestore, Storage)
- **AI Engine:** OpenAI API (GPT-4o) for semantic matching and email synthesis.
- **Local Tools:** Python (BeautifulSoup) for pre-hackathon data ingestion.

## 3. Data Architecture (Firestore Collections)

### `users`
- `uid`: String (Primary Key)
- `email`: String (@stevens.edu only)
- `schedule`: Map<String, String> (Key: "Mon_10am", Value: "Babbio_210")
- `friends`: Array<String> (UIDs)
- `ghostMode`: Boolean (Privacy toggle)
- `walletBalance`: Number (Simulated)

### `faculty` (Pre-seeded via Scraper)
- `name`: String
- `department`: String ("CS" or "Engineering")
- `research_interests`: Array<String>
- `bio`: String
- `email`: String

### `courses`
- `courseCode`: String (e.g., "CS-544")
- `title`: String
- `reviews`: Array<Map> (text, rating, isAnonymous)

### `events`
- `title`: String
- `location`: String (Building Name)
- `category`: String ("Free Food", "Tech", "Social")
- `timestamp`: Date
- `likes`: Number

### `housingRequests`
- `listerID`: String
- `address`: String
- `status`: String ("pending", "in_progress", "completed")
- `mediaURLs`: Array<String> (Firebase Storage links)
- `escrowAmount`: Number (Default: 10.00)

## 4. Feature Execution Logic

### Academic Module
1. **Matching:** Send `UserInterestString` + `FacultyCollection` to GPT-4o.
2. **Output:** Return Top 3 matches with specific reasoning.
3. **Outreach:** Generate professional email draft using `MFMailComposeViewController`.

### Social Module (The "Friend Map")
1. **Logic:** Check `Date()` -> Match against `User.schedule`.
2. **Display:** Place `Annotation` on MapKit 3D view at building coordinates (Lat/Long).
3. **Privacy:** If `ghostMode == true`, exclude from friend queries.

### Housing Module (The "Verifier" Flow)
1. **Escrow:** Mark $10 as "held" in Lister's simulated wallet.
2. **Proof:** Verifier must upload photos + video link. 
3. **Release:** Once Lister confirms, move $10 to Verifier's wallet.

## 5. Design System & UI Specs
- **Primary Color:** Stevens Red (#A32638)
- **Secondary Color:** Castle Point Grey (#D6D6D6)
- **Map View:** 3D Realistic style with a focus on Hoboken campus boundaries.
- **Navigation:** Tab-based (Map, Academics, Housing, Profile).

## 6. Coding Standards
- Use **SwiftUI** for all views.
- Use **MVVM** architecture (separate logic in ViewModels).
- Keep Firebase calls within a centralized `FirebaseManager.swift`.
- Priority for demo: "The Golden Path" (Academic Match -> Schedule Map -> Housing Verifier).