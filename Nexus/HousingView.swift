import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Data Model

struct HousingRequest: Identifiable, Codable {
    var id: String
    var listerID: String
    var listerName: String
    var address: String
    var neighborhood: String
    var listingURL: String
    var bountyAmount: Double
    var status: String // "open", "claimed", "submitted", "verified", "expired"
    var verifierID: String?
    var verifierName: String?
    var videoLink: String?
    var photoNote: String?
    var createdAt: Date
    var deadlineAt: Date
    var satisfactionConfirmed: Bool
    var beds: String
    var baths: String
    var monthlyRent: String
}

// MARK: - Roommate Model

struct RoommateProfile: Identifiable, Codable {
    var id: String
    var userID: String
    var userName: String
    var major: String
    var year: String
    var budget: String           // "$800–$1,200", "$1,200–$1,600", "$1,600–$2,000", "$2,000+"
    var neighborhoods: [String]  // from: Hoboken, Jersey City, Union City, Weehawken, Edgewater
    var moveIn: String           // "May 2026", "June 2026", "August 2026", "Flexible"
    var lifestyle: [String]      // multi-select from list below
    var about: String
    var createdAt: Date
}

let roommateLifestyleOptions: [String] = [
    "Early Bird", "Night Owl", "Clean", "Relaxed", "Quiet", "Social",
    "Pet-Friendly", "No Pets", "Non-Smoker", "Study-Focused", "Remote Worker", "Gym-Goer"
]

// MARK: - Sample Data (My Listings / My Jobs / Roommates)

// Listings Jhanvi posted from India before arriving on campus
let sampleMyListings: [HousingRequest] = [
    HousingRequest(
        id: "my-listing-1", listerID: "me", listerName: "Jhanvi D.",
        address: "Garden St & 8th, Hoboken", neighborhood: "Hoboken",
        listingURL: "https://zillow.com/example1",
        bountyAmount: 25, status: "submitted",
        verifierID: "v1", verifierName: "Tyler B.",
        videoLink: "https://drive.google.com/walkthrough1",
        photoNote: "Building entrance is well-lit, lobby clean. Apartment has natural light, kitchen appliances are recent. Heating works. Bathroom tile has minor cracks but no mold.",
        createdAt: Date().addingTimeInterval(-72*3600),
        deadlineAt: Date().addingTimeInterval(12*3600),
        satisfactionConfirmed: false,
        beds: "2 Bed", baths: "1 Bath", monthlyRent: "$2,400/mo"
    ),
    HousingRequest(
        id: "my-listing-2", listerID: "me", listerName: "Jhanvi D.",
        address: "Bloomfield St & 5th, Hoboken", neighborhood: "Hoboken",
        listingURL: "https://apartments.com/example2",
        bountyAmount: 20, status: "verified",
        verifierID: "v2", verifierName: "Nadia R.",
        videoLink: "https://drive.google.com/walkthrough2",
        photoNote: "Quiet street. Floor was newly refinished. Closet space is small.",
        createdAt: Date().addingTimeInterval(-30*24*3600),
        deadlineAt: Date().addingTimeInterval(-28*24*3600),
        satisfactionConfirmed: true,
        beds: "Studio", baths: "1 Bath", monthlyRent: "$1,800/mo"
    ),
    HousingRequest(
        id: "my-listing-3", listerID: "me", listerName: "Jhanvi D.",
        address: "Grove St & Newark Ave, Jersey City", neighborhood: "Jersey City",
        listingURL: "https://zillow.com/example3",
        bountyAmount: 15, status: "open",
        verifierID: nil, verifierName: nil,
        videoLink: nil, photoNote: nil,
        createdAt: Date().addingTimeInterval(-6*3600),
        deadlineAt: Date().addingTimeInterval(42*3600),
        satisfactionConfirmed: false,
        beds: "1 Bed", baths: "1 Bath", monthlyRent: "$1,950/mo"
    ),
]

// Bounties Jhanvi has completed as a verifier
let sampleMyJobs: [HousingRequest] = [
    HousingRequest(
        id: "my-job-1", listerID: "alex", listerName: "Alex P.",
        address: "Hudson St & 4th, Hoboken", neighborhood: "Hoboken",
        listingURL: "https://zillow.com/job1",
        bountyAmount: 20, status: "verified",
        verifierID: "me", verifierName: "Jhanvi D.",
        videoLink: "https://drive.google.com/jhanvi-walk1",
        photoNote: "Visited at 2pm. Building has working elevator. Apartment matches photos. Water pressure good. Reported small water stain on bedroom ceiling.",
        createdAt: Date().addingTimeInterval(-14*24*3600),
        deadlineAt: Date().addingTimeInterval(-12*24*3600),
        satisfactionConfirmed: true,
        beds: "1 Bed", baths: "1 Bath", monthlyRent: "$2,100/mo"
    ),
    HousingRequest(
        id: "my-job-2", listerID: "rina", listerName: "Rina M.",
        address: "Washington St & 6th, Hoboken", neighborhood: "Hoboken",
        listingURL: "https://apartments.com/job2",
        bountyAmount: 25, status: "verified",
        verifierID: "me", verifierName: "Jhanvi D.",
        videoLink: "https://drive.google.com/jhanvi-walk2",
        photoNote: "Visited Saturday morning. Front-door buzzer works. Confirmed in-unit washer/dryer. Heat tested. Neighbors quiet during visit.",
        createdAt: Date().addingTimeInterval(-21*24*3600),
        deadlineAt: Date().addingTimeInterval(-19*24*3600),
        satisfactionConfirmed: true,
        beds: "2 Bed", baths: "1 Bath", monthlyRent: "$2,650/mo"
    ),
    HousingRequest(
        id: "my-job-3", listerID: "kavin", listerName: "Kavin S.",
        address: "Boulevard East, Weehawken", neighborhood: "Weehawken",
        listingURL: "https://zillow.com/job3",
        bountyAmount: 30, status: "submitted",
        verifierID: "me", verifierName: "Jhanvi D.",
        videoLink: "https://drive.google.com/jhanvi-walk3",
        photoNote: "Took NJ Transit bus to visit. View of NYC skyline confirmed. Living room has hardwood floors. Kitchen cabinets are dated but functional.",
        createdAt: Date().addingTimeInterval(-2*24*3600),
        deadlineAt: Date().addingTimeInterval(46*3600),
        satisfactionConfirmed: false,
        beds: "1 Bed", baths: "1 Bath", monthlyRent: "$2,300/mo"
    ),
]

// Sample roommate profiles
let sampleRoommateProfiles: [RoommateProfile] = [
    RoommateProfile(
        id: "rmp-1", userID: "user1", userName: "Priya Patel",
        major: "Computer Science", year: "Junior",
        budget: "$1,200–$1,600",
        neighborhoods: ["Hoboken", "Jersey City"],
        moveIn: "August 2026",
        lifestyle: ["Clean", "Study-Focused", "Non-Smoker", "Early Bird"],
        about: "Looking for a quiet apartment near campus. Vegetarian, OK with dietary restrictions. Love board games and weekend hikes.",
        createdAt: Date().addingTimeInterval(-3*24*3600)
    ),
    RoommateProfile(
        id: "rmp-2", userID: "user2", userName: "Marcus Chen",
        major: "Software Engineering", year: "Senior",
        budget: "$1,600–$2,000",
        neighborhoods: ["Hoboken"],
        moveIn: "June 2026",
        lifestyle: ["Night Owl", "Social", "Gym-Goer", "Pet-Friendly"],
        about: "Have a friendly cat (Pixel). Work late on side projects. Looking for someone chill who doesn't mind weekend hangouts.",
        createdAt: Date().addingTimeInterval(-5*24*3600)
    ),
    RoommateProfile(
        id: "rmp-3", userID: "user3", userName: "Aisha Johnson",
        major: "Biomedical Engineering", year: "Graduate",
        budget: "$1,200–$1,600",
        neighborhoods: ["Hoboken", "Weehawken"],
        moveIn: "May 2026",
        lifestyle: ["Quiet", "Clean", "Remote Worker", "Non-Smoker"],
        about: "PhD student, mostly working from home. Need quiet during weekdays. Cook a lot — happy to share groceries.",
        createdAt: Date().addingTimeInterval(-1*24*3600)
    ),
    RoommateProfile(
        id: "rmp-4", userID: "user4", userName: "Jake Williams",
        major: "Mechanical Engineering", year: "Sophomore",
        budget: "$800–$1,200",
        neighborhoods: ["Jersey City", "Union City"],
        moveIn: "Flexible",
        lifestyle: ["Social", "Gym-Goer", "Early Bird"],
        about: "Looking for 2-3 roommates to split a bigger place. Active, into climbing and running. Easy to live with.",
        createdAt: Date().addingTimeInterval(-7*24*3600)
    ),
    RoommateProfile(
        id: "rmp-5", userID: "user5", userName: "Sofia Martinez",
        major: "Business", year: "Junior",
        budget: "$1,600–$2,000",
        neighborhoods: ["Hoboken"],
        moveIn: "August 2026",
        lifestyle: ["Clean", "Social", "Non-Smoker", "No Pets"],
        about: "Marketing major, internship at a startup in NYC. Looking for someone organized and clean. Love coffee shops and trying new restaurants.",
        createdAt: Date().addingTimeInterval(-2*24*3600)
    ),
]

// MARK: - Neighborhood Color Map

func neighborhoodColor(_ neighborhood: String) -> Color {
    switch neighborhood {
    case "Hoboken":    return Color(hex: "#A32638")
    case "Jersey City": return Color(hex: "#1a6b9a")
    case "Union City": return Color(hex: "#6b3fa0")
    case "Weehawken":  return Color(hex: "#2D6A4F")
    case "Edgewater":  return Color(hex: "#c47c1a")
    case "Bergen":     return Color(hex: "#4a4a7a")
    case "Bayonne":    return Color(hex: "#7a3b2e")
    default:           return Color(hex: "#A32638")
    }
}

// MARK: - Countdown Helpers

private func timeRemainingString(from deadline: Date) -> String {
    let remaining = deadline.timeIntervalSinceNow
    guard remaining > 0 else { return "Expired" }
    let hours = Int(remaining) / 3600
    let minutes = (Int(remaining) % 3600) / 60
    return "\(hours)h \(minutes)m left"
}

private func countdownColor(deadline: Date) -> Color {
    let remaining = deadline.timeIntervalSinceNow
    if remaining < 3600 { return .red }
    if remaining < 7200 { return .orange }
    return Color(hex: "#2D6A4F")
}

// MARK: - Main HousingView

struct HousingView: View {
    @EnvironmentObject var authState: AuthStateManager

    @State private var selectedTab: Int = 0
    @State private var allListings: [HousingRequest] = []
    @State private var showPostSheet = false
    @State private var selectedRequest: HousingRequest? = nil
    @State private var showDetailSheet = false
    @State private var now = Date()

    private let tabs = ["Browse", "Roommates", "My Listings", "My Jobs"]
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var currentUID: String { authState.currentUser?.uid ?? "" }

    var browseListings: [HousingRequest] {
        allListings.filter { $0.status == "open" }
    }
    var myListings: [HousingRequest] {
        sampleMyListings + allListings.filter { $0.listerID == currentUID }
    }
    var myJobs: [HousingRequest] {
        sampleMyJobs + allListings.filter { $0.verifierID == currentUID }
    }

    // Only used for tabs 0, 2, 3 (Browse, My Listings, My Jobs)
    var displayedListings: [HousingRequest] {
        switch selectedTab {
        case 0: return browseListings
        case 2: return myListings
        case 3: return myJobs
        default: return []
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.nexusSurface.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segment Control
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(0..<tabs.count, id: \.self) { i in
                            Text(tabs[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.nexusSurface)

                    Divider()

                    if selectedTab == 1 {
                        // Roommates tab
                        RoommateView()
                            .environmentObject(authState)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if selectedTab == 0 {
                                    LeaseAnalyzerBanner()
                                }
                                if displayedListings.isEmpty {
                                    EmptyHousingState(tabIndex: selectedTab)
                                        .frame(minHeight: 240)
                                } else {
                                    ForEach(displayedListings) { request in
                                        HousingListingCard(
                                            request: request,
                                            currentUID: currentUID,
                                            now: now
                                        ) {
                                            selectedRequest = request
                                            showDetailSheet = true
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .padding(.bottom, 80)
                        }
                    }
                }

                // Floating Action Button (hide for Roommates tab — RoommateView has its own FAB)
                if selectedTab != 1 {
                    Button(action: { showPostSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.stevensRed)
                            .clipShape(Circle())
                            .shadow(color: Color.stevensRed.opacity(0.45), radius: 10, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NexusTopBar()
                }
            }
            .sheet(isPresented: $showPostSheet) {
                PostListingSheet(isPresented: $showPostSheet) { newRequest in
                    saveNewListing(newRequest)
                }
                .environmentObject(authState)
            }
            .sheet(isPresented: $showDetailSheet) {
                if let req = selectedRequest {
                    ListingDetailSheet(
                        request: req,
                        isPresented: $showDetailSheet,
                        onUpdate: { updated in
                            updateListing(updated)
                            selectedRequest = updated
                        }
                    )
                    .environmentObject(authState)
                }
            }
        }
        .onAppear { loadListings() }
        .onReceive(timer) { _ in now = Date() }
    }

    // MARK: - Firestore Load

    private func loadListings() {
        Firestore.firestore()
            .collection("housingRequests")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let parsed: [HousingRequest] = docs.compactMap { doc in
                    let d = doc.data()
                    guard
                        let listerID = d["listerID"] as? String,
                        let listerName = d["listerName"] as? String,
                        let address = d["address"] as? String,
                        let neighborhood = d["neighborhood"] as? String,
                        let listingURL = d["listingURL"] as? String,
                        let bountyAmount = d["bountyAmount"] as? Double,
                        let status = d["status"] as? String,
                        let createdAtTS = d["createdAt"] as? Timestamp,
                        let deadlineAtTS = d["deadlineAt"] as? Timestamp,
                        let beds = d["beds"] as? String,
                        let baths = d["baths"] as? String,
                        let monthlyRent = d["monthlyRent"] as? String
                    else { return nil }

                    return HousingRequest(
                        id: doc.documentID,
                        listerID: listerID,
                        listerName: listerName,
                        address: address,
                        neighborhood: neighborhood,
                        listingURL: listingURL,
                        bountyAmount: bountyAmount,
                        status: status,
                        verifierID: d["verifierID"] as? String,
                        verifierName: d["verifierName"] as? String,
                        videoLink: d["videoLink"] as? String,
                        photoNote: d["photoNote"] as? String,
                        createdAt: createdAtTS.dateValue(),
                        deadlineAt: deadlineAtTS.dateValue(),
                        satisfactionConfirmed: d["satisfactionConfirmed"] as? Bool ?? false,
                        beds: beds,
                        baths: baths,
                        monthlyRent: monthlyRent
                    )
                }
                DispatchQueue.main.async {
                    self.allListings = parsed
                }
            }
    }

    private func saveNewListing(_ request: HousingRequest) {
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "listerID": request.listerID,
            "listerName": request.listerName,
            "address": request.address,
            "neighborhood": request.neighborhood,
            "listingURL": request.listingURL,
            "bountyAmount": request.bountyAmount,
            "status": request.status,
            "createdAt": Timestamp(date: request.createdAt),
            "deadlineAt": Timestamp(date: request.deadlineAt),
            "satisfactionConfirmed": false,
            "beds": request.beds,
            "baths": request.baths,
            "monthlyRent": request.monthlyRent
        ]
        if let vid = request.verifierID { data["verifierID"] = vid }
        if let vname = request.verifierName { data["verifierName"] = vname }

        db.collection("housingRequests").document(request.id).setData(data) { _ in
            // Deduct wallet balance
            db.collection("users").document(request.listerID)
                .updateData(["walletBalance": FieldValue.increment(-request.bountyAmount)])
        }
    }

    private func updateListing(_ request: HousingRequest) {
        DispatchQueue.main.async {
            if let idx = self.allListings.firstIndex(where: { $0.id == request.id }) {
                self.allListings[idx] = request
            }
        }
    }
}

// MARK: - Empty State

struct EmptyHousingState: View {
    let tabIndex: Int

    var message: String {
        switch tabIndex {
        case 0: return "No open listings yet —\nbe the first to post!"
        case 2: return "You haven't posted any\nverification requests yet."
        default: return "You haven't claimed any\nbounties yet."
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "house.and.flag")
                .font(.system(size: 56))
                .foregroundColor(Color.stevensRed.opacity(0.3))
            Text(message)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.nexusSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Listing Card

struct HousingListingCard: View {
    let request: HousingRequest
    let currentUID: String
    let now: Date
    let onTap: () -> Void

    @State private var isInterested = false
    @State private var interestCount = 0

    private var isLister: Bool { request.listerID == currentUID }
    private var isVerifier: Bool { request.verifierID == currentUID }
    private var headerColor: Color { neighborhoodColor(request.neighborhood) }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Gradient header
                ZStack(alignment: .top) {
                    LinearGradient(
                        colors: [headerColor, headerColor.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.15))
                    )

                    HStack(alignment: .top) {
                        // Status badge top-left
                        HousingStatusBadge(status: request.status)

                        Spacer()

                        // Bounty badge top-right
                        HStack(spacing: 4) {
                            Text("🎯")
                                .font(.system(size: 12))
                            Text("$\(Int(request.bountyAmount)) Bounty")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#FFD700"))
                        .cornerRadius(8)
                    }
                    .padding(12)

                    // Countdown (if claimed)
                    if (request.status == "claimed" || request.status == "submitted"),
                       request.deadlineAt > now {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Label(timeRemainingString(from: request.deadlineAt), systemImage: "clock")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(countdownColor(deadline: request.deadlineAt).opacity(0.85))
                                    .cornerRadius(6)
                                    .padding(8)
                            }
                        }
                        .frame(height: 120)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 0))

                // Details section
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.address)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            Text(request.neighborhood)
                                .font(.system(size: 12))
                                .foregroundColor(.nexusSecondary)
                        }
                        Spacer()
                        Text(request.monthlyRent)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.stevensRed)
                    }

                    Divider()

                    HStack(spacing: 16) {
                        Label(request.beds, systemImage: "bed.double")
                        Label(request.baths, systemImage: "shower")
                        Spacer()
                        Text("by \(request.listerName)")
                            .font(.system(size: 11))
                            .foregroundColor(.nexusSecondary)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.nexusSecondary)

                    // Action button
                    actionButton

                    // Interested button
                    Button(action: toggleInterest) {
                        HStack {
                            Image(systemName: isInterested ? "heart.fill" : "heart")
                            Text(isInterested ? "Interested" : "Show Interest")
                            Spacer()
                            if interestCount > 0 {
                                Text("\(interestCount) interested")
                            }
                        }
                    }
                    .foregroundColor(isInterested ? .stevensRed : .nexusSecondary)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(14)
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .onAppear { fetchInterestData() }
    }

    @ViewBuilder
    private var actionButton: some View {
        if request.status == "open" && !isLister {
            Text("Claim Bounty — Earn $\(Int(request.bountyAmount))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.stevensRed)
                .cornerRadius(10)
        } else if request.status == "submitted" && isLister {
            Label("View Proof & Release Payment", systemImage: "checkmark.seal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#2D6A4F"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "#d8f3dc"))
                .cornerRadius(10)
        } else if (request.status == "claimed" || request.status == "submitted") && isVerifier {
            Label("Submit Evidence", systemImage: "arrow.up.doc")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "#1a6b9a"))
                .cornerRadius(10)
        } else if request.status == "verified" {
            Label("Verified", systemImage: "checkmark.seal.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#2D6A4F"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "#d8f3dc"))
                .cornerRadius(10)
        } else {
            Text("View Details")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.nexusSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.nexusSurface)
                .cornerRadius(10)
        }
    }

    private func fetchInterestData() {
        let db = Firestore.firestore()
        db.collection("housingInterest")
            .whereField("listingID", isEqualTo: request.id)
            .getDocuments { snapshot, _ in
                let docs = snapshot?.documents ?? []
                DispatchQueue.main.async {
                    interestCount = docs.count
                    isInterested = docs.contains(where: { ($0.data()["userID"] as? String) == currentUID })
                }
            }
    }

    private func toggleInterest() {
        let db = Firestore.firestore()
        if isInterested {
            // Remove interest document
            db.collection("housingInterest")
                .whereField("listingID", isEqualTo: request.id)
                .whereField("userID", isEqualTo: currentUID)
                .getDocuments { snapshot, _ in
                    snapshot?.documents.forEach { $0.reference.delete() }
                    DispatchQueue.main.async {
                        isInterested = false
                        interestCount = max(0, interestCount - 1)
                    }
                }
        } else {
            // Add interest document
            let docID = UUID().uuidString
            let data: [String: Any] = [
                "listingID": request.id,
                "userID": currentUID,
                "createdAt": Timestamp(date: Date())
            ]
            db.collection("housingInterest").document(docID).setData(data) { _ in
                DispatchQueue.main.async {
                    isInterested = true
                    interestCount += 1
                }
            }
        }
    }
}

// MARK: - Status Badge

struct HousingStatusBadge: View {
    let status: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(bgColor.opacity(0.92))
        .cornerRadius(8)
    }

    var icon: String {
        switch status {
        case "open":       return "circle.fill"
        case "claimed":    return "person.fill.checkmark"
        case "submitted":  return "doc.fill"
        case "verified":   return "checkmark.seal.fill"
        case "expired":    return "clock.badge.xmark"
        default:           return "questionmark"
        }
    }

    var label: String {
        switch status {
        case "open":       return "Open"
        case "claimed":    return "Claimed"
        case "submitted":  return "Under Review"
        case "verified":   return "Verified"
        case "expired":    return "Expired"
        default:           return status.capitalized
        }
    }

    var textColor: Color {
        switch status {
        case "open":       return Color(hex: "#2D6A4F")
        case "claimed":    return Color(hex: "#c47c1a")
        case "submitted":  return Color(hex: "#1a6b9a")
        case "verified":   return Color(hex: "#2D6A4F")
        case "expired":    return .gray
        default:           return .primary
        }
    }

    var bgColor: Color {
        switch status {
        case "open":       return Color(hex: "#d8f3dc")
        case "claimed":    return Color(hex: "#fff3cd")
        case "submitted":  return Color(hex: "#cce5f6")
        case "verified":   return Color(hex: "#d8f3dc")
        case "expired":    return Color.gray.opacity(0.2)
        default:           return Color.white
        }
    }
}

// MARK: - Post Listing Sheet

struct PostListingSheet: View {
    @EnvironmentObject var authState: AuthStateManager
    @Binding var isPresented: Bool
    var onPost: (HousingRequest) -> Void

    @State private var neighborhood = "Hoboken"
    @State private var address = ""
    @State private var monthlyRent = ""
    @State private var beds = "1 Bed"
    @State private var baths = "1 Bath"
    @State private var listingURL = ""
    @State private var bountyAmount: Double = 10
    @State private var isPosting = false
    @State private var showError = false
    @State private var errorMsg = ""

    private let neighborhoods = ["Hoboken", "Jersey City", "Union City", "Weehawken", "Edgewater", "Bergen", "Bayonne"]
    private let bedOptions = ["Studio", "1 Bed", "2 Bed", "3 Bed"]
    private let bathOptions = ["1 Bath", "2 Bath"]

    private var walletBalance: Double {
        authState.userProfile["walletBalance"] as? Double ?? 0
    }
    private var canAfford: Bool { walletBalance >= bountyAmount }
    private var formValid: Bool {
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        !monthlyRent.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Neighborhood
                    formSection(title: "Neighborhood") {
                        Picker("Neighborhood", selection: $neighborhood) {
                            ForEach(neighborhoods, id: \.self) { n in
                                Text(n).tag(n)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.stevensRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.nexusSurface)
                        .cornerRadius(10)
                    }

                    // Address
                    formSection(title: "Street Address") {
                        TextField("e.g. 123 Washington St", text: $address)
                            .textFieldStyle(NexusFieldStyle())
                    }

                    // Rent
                    formSection(title: "Monthly Rent") {
                        TextField("e.g. $1,800/mo", text: $monthlyRent)
                            .textFieldStyle(NexusFieldStyle())
                            .keyboardType(.default)
                    }

                    // Beds & Baths
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Beds")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.nexusSecondary)
                            Picker("Beds", selection: $beds) {
                                ForEach(bedOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(.stevensRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.nexusSurface)
                            .cornerRadius(10)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Baths")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.nexusSecondary)
                            Picker("Baths", selection: $baths) {
                                ForEach(bathOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(.stevensRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.nexusSurface)
                            .cornerRadius(10)
                        }
                    }

                    // Listing URL
                    formSection(title: "Listing URL") {
                        TextField("Zelle, Zillow, Apartments.com link...", text: $listingURL)
                            .textFieldStyle(NexusFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }

                    // Bounty Amount
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bounty Amount")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.nexusSecondary)

                        // Big visual display
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(
                                    colors: [Color.stevensRed, Color.primaryContainer],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                            VStack(spacing: 4) {
                                Text("$\(Int(bountyAmount))")
                                    .font(.system(size: 48, weight: .black))
                                    .foregroundColor(.white)
                                Text("Bounty")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .frame(height: 110)

                        HStack(spacing: 0) {
                            ForEach([10, 15, 20, 25, 30], id: \.self) { amount in
                                Button(action: { bountyAmount = Double(amount) }) {
                                    Text("$\(amount)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(bountyAmount == Double(amount) ? .white : .stevensRed)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            bountyAmount == Double(amount)
                                                ? Color.stevensRed
                                                : Color.nexusSurface
                                        )
                                }
                            }
                        }
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.stevensRed.opacity(0.3)))

                        HStack {
                            Image(systemName: "wallet.bifold")
                                .font(.system(size: 12))
                                .foregroundColor(.nexusSecondary)
                            Text("Wallet: $\(String(format: "%.2f", walletBalance))")
                                .font(.system(size: 12))
                                .foregroundColor(.nexusSecondary)
                            Spacer()
                            if !canAfford {
                                Text("Insufficient balance")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    // Rules
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How it works")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                        VStack(alignment: .leading, spacing: 4) {
                            ruleRow("Verifier must complete within 48 hours")
                            ruleRow("Payment released only after your approval")
                            ruleRow("Verifier is banned if deadline is missed")
                        }
                        .padding(12)
                        .background(Color(hex: "#fff3cd").opacity(0.6))
                        .cornerRadius(10)
                    }

                    // Submit
                    Button(action: submitListing) {
                        ZStack {
                            if isPosting {
                                ProgressView().tint(.white)
                            } else {
                                Label("Post & Hold Bounty", systemImage: "lock.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(formValid && canAfford ? Color.stevensRed : Color.gray.opacity(0.4))
                        .cornerRadius(14)
                    }
                    .disabled(!formValid || !canAfford || isPosting)
                }
                .padding(20)
            }
            .background(Color.nexusSurface.ignoresSafeArea())
            .navigationTitle("Post Verification Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.stevensRed)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMsg)
            }
        }
    }

    @ViewBuilder
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.nexusSecondary)
            content()
        }
    }

    @ViewBuilder
    private func ruleRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#c47c1a"))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
    }

    private func submitListing() {
        guard let uid = authState.currentUser?.uid else { return }
        let fullName = authState.userProfile["fullName"] as? String ?? "Anonymous"
        isPosting = true

        let now = Date()
        let deadline = now.addingTimeInterval(48 * 3600)
        let docID = UUID().uuidString

        let request = HousingRequest(
            id: docID,
            listerID: uid,
            listerName: fullName,
            address: address.trimmingCharacters(in: .whitespaces),
            neighborhood: neighborhood,
            listingURL: listingURL.trimmingCharacters(in: .whitespaces),
            bountyAmount: bountyAmount,
            status: "open",
            verifierID: nil,
            verifierName: nil,
            videoLink: nil,
            photoNote: nil,
            createdAt: now,
            deadlineAt: deadline,
            satisfactionConfirmed: false,
            beds: beds,
            baths: baths,
            monthlyRent: monthlyRent.trimmingCharacters(in: .whitespaces)
        )

        onPost(request)
        isPosting = false
        isPresented = false
    }
}

// MARK: - Listing Detail Sheet

struct ListingDetailSheet: View {
    @EnvironmentObject var authState: AuthStateManager
    var request: HousingRequest
    @Binding var isPresented: Bool
    var onUpdate: (HousingRequest) -> Void

    @State private var showSubmitProof = false
    @State private var isUpdating = false
    @State private var localRequest: HousingRequest
    @State private var now = Date()

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    init(request: HousingRequest, isPresented: Binding<Bool>, onUpdate: @escaping (HousingRequest) -> Void) {
        self.request = request
        self._isPresented = isPresented
        self.onUpdate = onUpdate
        self._localRequest = State(initialValue: request)
    }

    private var currentUID: String { authState.currentUser?.uid ?? "" }
    private var isLister: Bool { localRequest.listerID == currentUID }
    private var isVerifier: Bool { localRequest.verifierID == currentUID }
    private var isOpenForClaiming: Bool { localRequest.status == "open" && !isLister }
    private var headerColor: Color { neighborhoodColor(localRequest.neighborhood) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero header
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [headerColor, headerColor.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.12))
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            HousingStatusBadge(status: localRequest.status)
                            Text(localRequest.address)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text(localRequest.neighborhood)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(16)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        // Key stats
                        HStack(spacing: 0) {
                            statCell(icon: "bed.double.fill", value: localRequest.beds, label: "Beds")
                            Divider().frame(height: 40)
                            statCell(icon: "shower.fill", value: localRequest.baths, label: "Baths")
                            Divider().frame(height: 40)
                            statCell(icon: "dollarsign.circle.fill", value: localRequest.monthlyRent, label: "Rent")
                            Divider().frame(height: 40)
                            statCell(icon: "target", value: "$\(Int(localRequest.bountyAmount))", label: "Bounty")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.regularMaterial)
                        .cornerRadius(14)

                        // Lister info
                        infoRow(icon: "person.fill", label: "Posted by", value: localRequest.listerName)

                        // Listing URL
                        if !localRequest.listingURL.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Listing Link")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.nexusSecondary)
                                if let url = URL(string: localRequest.listingURL.hasPrefix("http") ? localRequest.listingURL : "https://\(localRequest.listingURL)") {
                                    Link(destination: url) {
                                        HStack {
                                            Image(systemName: "link")
                                                .font(.system(size: 13))
                                            Text(localRequest.listingURL)
                                                .font(.system(size: 13))
                                                .lineLimit(1)
                                            Spacer()
                                            Image(systemName: "arrow.up.right.square")
                                                .font(.system(size: 13))
                                        }
                                        .foregroundColor(.stevensRed)
                                        .padding(12)
                                        .background(Color.nexusSurface)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }

                        // Countdown (if active)
                        if (localRequest.status == "claimed" || localRequest.status == "submitted"),
                           localRequest.deadlineAt > now {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(countdownColor(deadline: localRequest.deadlineAt))
                                Text(timeRemainingString(from: localRequest.deadlineAt))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(countdownColor(deadline: localRequest.deadlineAt))
                                Spacer()
                                Text("Deadline")
                                    .font(.system(size: 12))
                                    .foregroundColor(.nexusSecondary)
                            }
                            .padding(12)
                            .background(countdownColor(deadline: localRequest.deadlineAt).opacity(0.08))
                            .cornerRadius(10)
                        }

                        Divider()

                        // Mode-specific content
                        if isOpenForClaiming {
                            verifierClaimSection
                        } else if isVerifier && (localRequest.status == "claimed" || localRequest.status == "submitted") {
                            verifierJobSection
                        } else if isLister && localRequest.status == "submitted" {
                            listerReviewSection
                        } else if localRequest.status == "verified" {
                            verifiedSection
                        } else {
                            // Generic view
                            infoRow(icon: "info.circle", label: "Status", value: localRequest.status.capitalized)
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color.nexusSurface.ignoresSafeArea())
            .navigationTitle("Listing Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                        .foregroundColor(.stevensRed)
                }
            }
            .sheet(isPresented: $showSubmitProof) {
                SubmitProofSheet(request: localRequest, isPresented: $showSubmitProof) { updated in
                    localRequest = updated
                    onUpdate(updated)
                }
                .environmentObject(authState)
            }
        }
        .onReceive(timer) { _ in now = Date() }
    }

    // MARK: - Sub-sections

    @ViewBuilder
    private var verifierClaimSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What you need to verify")
                .font(.system(size: 15, weight: .bold))

            VStack(spacing: 0) {
                checklistRow(icon: "camera.fill", text: "Take exterior photos of the building")
                Divider().padding(.leading, 40)
                checklistRow(icon: "photo.stack.fill", text: "Take interior photos of each room")
                Divider().padding(.leading, 40)
                checklistRow(icon: "video.fill", text: "Record a walkthrough video")
                Divider().padding(.leading, 40)
                checklistRow(icon: "wrench.and.screwdriver.fill", text: "Check appliances & utilities")
            }
            .background(.regularMaterial)
            .cornerRadius(12)

            Button(action: claimBounty) {
                ZStack {
                    if isUpdating {
                        ProgressView().tint(.white)
                    } else {
                        Text("Claim This Bounty — Earn $\(Int(localRequest.bountyAmount))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.stevensRed)
                .cornerRadius(14)
            }
            .disabled(isUpdating)
        }
    }

    @ViewBuilder
    private var verifierJobSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let verName = localRequest.verifierName {
                infoRow(icon: "person.badge.shield.checkmark.fill", label: "Assigned to", value: verName)
            }

            if localRequest.status == "submitted" {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#2D6A4F"))
                    Text("Evidence submitted — awaiting lister confirmation")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#2D6A4F"))
                }
                .padding(12)
                .background(Color(hex: "#d8f3dc"))
                .cornerRadius(10)
            } else {
                Button(action: { showSubmitProof = true }) {
                    Label("Submit Evidence", systemImage: "arrow.up.doc.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color(hex: "#1a6b9a"))
                        .cornerRadius(14)
                }
            }
        }
    }

    @ViewBuilder
    private var listerReviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Verification Evidence")
                .font(.system(size: 15, weight: .bold))

            if let verName = localRequest.verifierName {
                infoRow(icon: "person.badge.shield.checkmark.fill", label: "Verifier", value: verName)
            }

            if let note = localRequest.photoNote, !note.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Verifier Notes")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.nexusSecondary)
                    Text(note)
                        .font(.system(size: 14))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.nexusSurface)
                        .cornerRadius(10)
                }
            }

            if let videoLink = localRequest.videoLink, !videoLink.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Walkthrough Video")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.nexusSecondary)
                    if let url = URL(string: videoLink.hasPrefix("http") ? videoLink : "https://\(videoLink)") {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "video.fill")
                                Text(videoLink)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .font(.system(size: 13))
                            .foregroundColor(.stevensRed)
                            .padding(12)
                            .background(Color.nexusSurface)
                            .cornerRadius(10)
                        }
                    }
                }
            }

            VStack(spacing: 10) {
                Button(action: confirmAndRelease) {
                    ZStack {
                        if isUpdating {
                            ProgressView().tint(.white)
                        } else {
                            Label("Confirm & Release $\(Int(localRequest.bountyAmount))", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#2D6A4F"))
                    .cornerRadius(14)
                }
                .disabled(isUpdating)

                Button(action: requestMoreEvidence) {
                    Label("Request More Evidence", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.stevensRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.nexusSurface)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stevensRed.opacity(0.4)))
                        .cornerRadius(14)
                }
                .disabled(isUpdating)
            }
        }
    }

    @ViewBuilder
    private var verifiedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#2D6A4F"))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Verification Complete")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#2D6A4F"))
                    Text("This property has been verified by a Nexus member.")
                        .font(.system(size: 13))
                        .foregroundColor(.nexusSecondary)
                }
            }
            .padding(14)
            .background(Color(hex: "#d8f3dc"))
            .cornerRadius(12)

            if let verName = localRequest.verifierName {
                infoRow(icon: "person.badge.shield.checkmark.fill", label: "Verified by", value: verName)
            }

            if let note = localRequest.photoNote, !note.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Verifier Notes")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.nexusSecondary)
                    Text(note)
                        .font(.system(size: 14))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.nexusSurface)
                        .cornerRadius(10)
                }
            }

            if let videoLink = localRequest.videoLink, !videoLink.isEmpty {
                if let url = URL(string: videoLink.hasPrefix("http") ? videoLink : "https://\(videoLink)") {
                    Link(destination: url) {
                        Label("Watch Walkthrough", systemImage: "video.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#1a6b9a"))
                            .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func checklistRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.stevensRed)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 14))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func statCell(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.stevensRed)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.nexusSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.stevensRed)
                .frame(width: 22)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.nexusSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Actions

    private func claimBounty() {
        guard let uid = authState.currentUser?.uid else { return }
        let fullName = authState.userProfile["fullName"] as? String ?? "Anonymous"
        isUpdating = true

        let deadline = Date().addingTimeInterval(48 * 3600)
        let updates: [String: Any] = [
            "status": "claimed",
            "verifierID": uid,
            "verifierName": fullName,
            "deadlineAt": Timestamp(date: deadline)
        ]

        Firestore.firestore()
            .collection("housingRequests")
            .document(localRequest.id)
            .updateData(updates) { error in
                DispatchQueue.main.async {
                    isUpdating = false
                    if error == nil {
                        var updated = localRequest
                        updated.status = "claimed"
                        updated.verifierID = uid
                        updated.verifierName = fullName
                        updated.deadlineAt = deadline
                        localRequest = updated
                        onUpdate(updated)
                    }
                }
            }
    }

    private func confirmAndRelease() {
        guard let verID = localRequest.verifierID else { return }
        isUpdating = true
        let db = Firestore.firestore()
        let bounty = localRequest.bountyAmount

        db.collection("housingRequests").document(localRequest.id).updateData([
            "status": "verified",
            "satisfactionConfirmed": true
        ]) { error in
            if error == nil {
                db.collection("users").document(verID)
                    .updateData(["walletBalance": FieldValue.increment(bounty)])
            }
            DispatchQueue.main.async {
                isUpdating = false
                if error == nil {
                    var updated = localRequest
                    updated.status = "verified"
                    updated.satisfactionConfirmed = true
                    localRequest = updated
                    onUpdate(updated)
                }
            }
        }
    }

    private func requestMoreEvidence() {
        isUpdating = true
        Firestore.firestore()
            .collection("housingRequests")
            .document(localRequest.id)
            .updateData(["status": "claimed"]) { error in
                DispatchQueue.main.async {
                    isUpdating = false
                    if error == nil {
                        var updated = localRequest
                        updated.status = "claimed"
                        localRequest = updated
                        onUpdate(updated)
                    }
                }
            }
    }
}

// MARK: - Submit Proof Sheet

struct SubmitProofSheet: View {
    @EnvironmentObject var authState: AuthStateManager
    let request: HousingRequest
    @Binding var isPresented: Bool
    var onSubmit: (HousingRequest) -> Void

    @State private var videoLink = ""
    @State private var photoNote = ""
    @State private var isSubmitting = false
    @State private var showError = false

    private var formValid: Bool {
        !videoLink.trimmingCharacters(in: .whitespaces).isEmpty &&
        !photoNote.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Address header
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(neighborhoodColor(request.neighborhood))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.address)
                                .font(.system(size: 15, weight: .bold))
                            Text(request.neighborhood)
                                .font(.system(size: 13))
                                .foregroundColor(.nexusSecondary)
                        }
                        Spacer()
                        Text("$\(Int(request.bountyAmount))")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(Color(hex: "#c47c1a"))
                    }
                    .padding(14)
                    .background(.regularMaterial)
                    .cornerRadius(14)

                    // Countdown
                    if request.deadlineAt > Date() {
                        HStack {
                            Image(systemName: "clock.badge.exclamationmark.fill")
                                .foregroundColor(countdownColor(deadline: request.deadlineAt))
                            Text(timeRemainingString(from: request.deadlineAt))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(countdownColor(deadline: request.deadlineAt))
                            Spacer()
                        }
                        .padding(12)
                        .background(countdownColor(deadline: request.deadlineAt).opacity(0.08))
                        .cornerRadius(10)
                    }

                    Divider()

                    // Video link
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Walkthrough Video Link")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                        Text("Upload to Google Drive, YouTube, or iCloud and paste the link")
                            .font(.system(size: 12))
                            .foregroundColor(.nexusSecondary)
                        TextField("https://drive.google.com/...", text: $videoLink)
                            .textFieldStyle(NexusFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Observation Notes")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                        Text("Describe what you observed: condition, appliances, neighborhood, anything notable")
                            .font(.system(size: 12))
                            .foregroundColor(.nexusSecondary)
                        ZStack(alignment: .topLeading) {
                            if photoNote.isEmpty {
                                Text("Describe what you observed...")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(EdgeInsets(top: 14, leading: 10, bottom: 0, trailing: 10))
                            }
                            TextEditor(text: $photoNote)
                                .font(.system(size: 15))
                                .frame(height: 140)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .background(Color.nexusSurface)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.outlineVariant))
                    }

                    // Warning
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(hex: "#c47c1a"))
                            .font(.system(size: 16))
                        Text("Submitting false evidence will result in a permanent account ban and forfeiture of your wallet balance.")
                            .font(.system(size: 12))
                            .foregroundColor(.nexusSecondary)
                    }
                    .padding(12)
                    .background(Color(hex: "#fff3cd").opacity(0.6))
                    .cornerRadius(10)

                    // Submit
                    Button(action: submitEvidence) {
                        ZStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Label("Submit for Review", systemImage: "checkmark.shield.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(formValid ? Color.stevensRed : Color.gray.opacity(0.4))
                        .cornerRadius(14)
                    }
                    .disabled(!formValid || isSubmitting)
                }
                .padding(20)
            }
            .background(Color.nexusSurface.ignoresSafeArea())
            .navigationTitle("Submit Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.stevensRed)
                }
            }
        }
    }

    private func submitEvidence() {
        isSubmitting = true
        let updates: [String: Any] = [
            "status": "submitted",
            "videoLink": videoLink.trimmingCharacters(in: .whitespaces),
            "photoNote": photoNote.trimmingCharacters(in: .whitespaces)
        ]

        Firestore.firestore()
            .collection("housingRequests")
            .document(request.id)
            .updateData(updates) { error in
                DispatchQueue.main.async {
                    isSubmitting = false
                    if error == nil {
                        var updated = request
                        updated.status = "submitted"
                        updated.videoLink = videoLink.trimmingCharacters(in: .whitespaces)
                        updated.photoNote = photoNote.trimmingCharacters(in: .whitespaces)
                        onSubmit(updated)
                        isPresented = false
                    }
                }
            }
    }
}

// MARK: - Custom TextField Style

struct NexusFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 15))
            .padding(12)
            .background(Color.nexusSurface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.outlineVariant))
    }
}

// MARK: - Roommate View

struct RoommateView: View {
    @EnvironmentObject var authState: AuthStateManager
    @State private var profiles: [RoommateProfile] = []
    @State private var showPostRoommate = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if profiles.isEmpty {
                VStack(spacing: 18) {
                    Spacer()
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Color.stevensRed.opacity(0.3))
                    Text("No roommate profiles yet —\nbe the first to post!")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.nexusSecondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.horizontal, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(profiles) { profile in
                            RoommateCard(profile: profile)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
            }

            // FAB
            Button(action: { showPostRoommate = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.stevensRed)
                    .clipShape(Circle())
                    .shadow(color: Color.stevensRed.opacity(0.45), radius: 10, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .onAppear { loadProfiles() }
        .sheet(isPresented: $showPostRoommate) {
            PostRoommateSheet(isPresented: $showPostRoommate) { newProfile in
                Firestore.firestore()
                    .collection("roommateProfiles")
                    .document(newProfile.id)
                    .setData([
                        "userID": newProfile.userID,
                        "userName": newProfile.userName,
                        "major": newProfile.major,
                        "year": newProfile.year,
                        "budget": newProfile.budget,
                        "neighborhoods": newProfile.neighborhoods,
                        "moveIn": newProfile.moveIn,
                        "lifestyle": newProfile.lifestyle,
                        "about": newProfile.about,
                        "createdAt": Timestamp(date: newProfile.createdAt)
                    ]) { _ in }
            }
            .environmentObject(authState)
        }
    }

    private func loadProfiles() {
        // Always start with sample profiles so the tab is never empty
        profiles = sampleRoommateProfiles

        Firestore.firestore()
            .collection("roommateProfiles")
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let parsed: [RoommateProfile] = docs.compactMap { doc in
                    let d = doc.data()
                    guard
                        let userID = d["userID"] as? String,
                        let userName = d["userName"] as? String,
                        let budget = d["budget"] as? String,
                        let moveIn = d["moveIn"] as? String,
                        let createdTS = d["createdAt"] as? Timestamp
                    else { return nil }
                    return RoommateProfile(
                        id: doc.documentID,
                        userID: userID,
                        userName: userName,
                        major: d["major"] as? String ?? "",
                        year: d["year"] as? String ?? "",
                        budget: budget,
                        neighborhoods: d["neighborhoods"] as? [String] ?? [],
                        moveIn: moveIn,
                        lifestyle: d["lifestyle"] as? [String] ?? [],
                        about: d["about"] as? String ?? "",
                        createdAt: createdTS.dateValue()
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
                DispatchQueue.main.async {
                    profiles = sampleRoommateProfiles + parsed
                }
            }
    }
}

// MARK: - Roommate Card

struct RoommateCard: View {
    let profile: RoommateProfile

    private var initials: String {
        profile.userName.split(separator: " ")
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.stevensRed, Color.stevensRed.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    Text(initials)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.userName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    if !profile.major.isEmpty || !profile.year.isEmpty {
                        Text([profile.major, profile.year].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.system(size: 13))
                            .foregroundColor(.nexusSecondary)
                    }
                }

                Spacer()

                // Budget pill
                Text(profile.budget)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D6A4F"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "#d8f3dc"))
                    .cornerRadius(999)
            }

            // Neighborhoods
            if !profile.neighborhoods.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(profile.neighborhoods, id: \.self) { n in
                            Text(n)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.nexusSecondary)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(999)
                        }
                    }
                }
            }

            // Lifestyle tags (up to 4 + overflow count)
            if !profile.lifestyle.isEmpty {
                let shown = Array(profile.lifestyle.prefix(4))
                let overflow = profile.lifestyle.count - shown.count
                HStack(spacing: 6) {
                    ForEach(shown, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.stevensRed)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.stevensRed.opacity(0.08))
                            .cornerRadius(999)
                    }
                    if overflow > 0 {
                        Text("+\(overflow) more")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.nexusSecondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(999)
                    }
                    Spacer()
                }
            }

            // Move-in date
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(.nexusSecondary)
                Text("Move-in: \(profile.moveIn)")
                    .font(.system(size: 12))
                    .foregroundColor(.nexusSecondary)
            }

            // About
            if !profile.about.isEmpty {
                Text(profile.about)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            // Connect button
            Button(action: connectAction) {
                Label("Connect", systemImage: "envelope.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.stevensRed)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
    }

    private func connectAction() {
        // Try to open mail to Stevens email, else copy name to clipboard
        let email = "\(profile.userID)@stevens.edu"
        if let url = URL(string: "mailto:\(email)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            UIPasteboard.general.string = profile.userName
        }
    }
}

// MARK: - Post Roommate Sheet

struct PostRoommateSheet: View {
    @EnvironmentObject var authState: AuthStateManager
    @Binding var isPresented: Bool
    var onPost: (RoommateProfile) -> Void

    @State private var budget = "$800–$1,200"
    @State private var selectedNeighborhoods: Set<String> = []
    @State private var moveIn = "May 2026"
    @State private var selectedLifestyle: Set<String> = []
    @State private var about = ""
    @State private var isPosting = false

    private let budgetOptions = ["$800–$1,200", "$1,200–$1,600", "$1,600–$2,000", "$2,000+"]
    private let neighborhoodOptions = ["Hoboken", "Jersey City", "Union City", "Weehawken", "Edgewater"]
    private let moveInOptions = ["May 2026", "June 2026", "August 2026", "Flexible"]

    private var formValid: Bool {
        !selectedNeighborhoods.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Budget
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Budget")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                        Picker("Budget", selection: $budget) {
                            ForEach(budgetOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Neighborhoods
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred Neighborhoods")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 8) {
                            ForEach(neighborhoodOptions, id: \.self) { n in
                                let selected = selectedNeighborhoods.contains(n)
                                Button(action: {
                                    if selected { selectedNeighborhoods.remove(n) }
                                    else { selectedNeighborhoods.insert(n) }
                                }) {
                                    Text(n)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(selected ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(selected ? Color.stevensRed : Color(.systemGray6))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }

                    // Move-in date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Move-in Date")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                        Picker("Move-in", selection: $moveIn) {
                            ForEach(moveInOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Lifestyle
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lifestyle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                            ForEach(roommateLifestyleOptions, id: \.self) { tag in
                                let selected = selectedLifestyle.contains(tag)
                                Button(action: {
                                    if selected { selectedLifestyle.remove(tag) }
                                    else { selectedLifestyle.insert(tag) }
                                }) {
                                    Text(tag)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(selected ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(selected ? Color.stevensRed : Color(.systemGray6))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }

                    // About
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About You")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                        ZStack(alignment: .topLeading) {
                            if about.isEmpty {
                                Text("Tell potential roommates about yourself...")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(EdgeInsets(top: 14, leading: 10, bottom: 0, trailing: 10))
                            }
                            TextEditor(text: $about)
                                .font(.system(size: 15))
                                .frame(height: 120)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .background(Color.nexusSurface)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.outlineVariant))
                    }

                    // Post button
                    Button(action: postProfile) {
                        ZStack {
                            if isPosting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Post Profile")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(formValid ? Color.stevensRed : Color.gray.opacity(0.4))
                        .cornerRadius(14)
                    }
                    .disabled(!formValid || isPosting)
                }
                .padding(20)
            }
            .background(Color.nexusSurface.ignoresSafeArea())
            .navigationTitle("Find a Roommate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.stevensRed)
                }
            }
        }
    }

    private func postProfile() {
        guard let uid = authState.currentUser?.uid else { return }
        let fullName = authState.userProfile["fullName"] as? String ?? "Anonymous"
        let major = authState.userProfile["major"] as? String ?? ""
        let year = authState.userProfile["year"] as? String ?? ""
        isPosting = true

        let profile = RoommateProfile(
            id: UUID().uuidString,
            userID: uid,
            userName: fullName,
            major: major,
            year: year,
            budget: budget,
            neighborhoods: Array(selectedNeighborhoods),
            moveIn: moveIn,
            lifestyle: Array(selectedLifestyle),
            about: about.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date()
        )

        onPost(profile)
        isPosting = false
        isPresented = false
    }
}

// MARK: - Preview

#Preview {
    HousingView()
        .environmentObject(AuthStateManager())
}
