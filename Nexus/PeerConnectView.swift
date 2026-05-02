import SwiftUI

// MARK: - Peer model

struct PeerProfile: Identifiable {
    let id: String
    let name: String
    let email: String
    let avatarColorHex: String
    let major: String
    let year: String
    let gradSemester: String
    let registeredEvents: [String]   // event IDs (from sampleEvents)
    let interestedEvents: [String]   // event IDs
    let githubThemes: [String]
    let githubUsername: String?
    let about: String

    var initials: String {
        name.split(separator: " ").compactMap { $0.first }.map { String($0) }.prefix(2).joined()
    }
}

// MARK: - Hardcoded peer pool

let samplePeers: [PeerProfile] = [
    PeerProfile(
        id: "peer-1",
        name: "Priya Patel",
        email: "ppatel3@stevens.edu",
        avatarColorHex: "#A32638",
        major: "Computer Science",
        year: "Junior",
        gradSemester: "Spring 2027",
        registeredEvents: ["evt6", "evt11", "evt14"],
        interestedEvents: ["evt3", "evt2"],
        githubThemes: ["Graph Neural Networks", "iOS / SwiftUI", "Drug Discovery"],
        githubUsername: "priyapatel-cs",
        about: "GNN-based molecular property prediction. Looking for study buddies for CS-583."
    ),
    PeerProfile(
        id: "peer-2",
        name: "Marcus Chen",
        email: "mchen14@stevens.edu",
        avatarColorHex: "#1a6b9a",
        major: "Computer Science",
        year: "Junior",
        gradSemester: "Spring 2027",
        registeredEvents: ["evt1", "evt6"],
        interestedEvents: ["evt11", "evt19"],
        githubThemes: ["iOS / SwiftUI", "Firebase Real-Time Systems", "Computer Vision"],
        githubUsername: "marcusc-dev",
        about: "Building CV-based campus apps. Side project: real-time dining hall queue tracker."
    ),
    PeerProfile(
        id: "peer-3",
        name: "Aisha Johnson",
        email: "ajohns22@stevens.edu",
        avatarColorHex: "#6b3fa0",
        major: "Biomedical Engineering",
        year: "Graduate",
        gradSemester: "Spring 2026",
        registeredEvents: ["evt4", "evt6"],
        interestedEvents: ["evt19"],
        githubThemes: ["Drug Discovery", "Computer Vision", "PyTorch"],
        githubUsername: "aishaj-bme",
        about: "PhD work on protein structure prediction. Always down for ML paper readings."
    ),
    PeerProfile(
        id: "peer-4",
        name: "Jake Williams",
        email: "jwilli17@stevens.edu",
        avatarColorHex: "#2D6A4F",
        major: "Mechanical Engineering",
        year: "Sophomore",
        gradSemester: "Spring 2028",
        registeredEvents: ["evt8", "evt5"],
        interestedEvents: ["evt12"],
        githubThemes: ["Robotics", "Embedded Systems"],
        githubUsername: "jakew-robotics",
        about: "Climbing club + Stevens Robotics Club. Open to interdisciplinary projects."
    ),
    PeerProfile(
        id: "peer-5",
        name: "Sofia Martinez",
        email: "smartin8@stevens.edu",
        avatarColorHex: "#c47c1a",
        major: "Computer Science",
        year: "Junior",
        gradSemester: "Spring 2027",
        registeredEvents: ["evt4", "evt14", "evt6"],
        interestedEvents: ["evt11"],
        githubThemes: ["iOS / SwiftUI", "Firebase Real-Time Systems", "Graph Neural Networks"],
        githubUsername: "sofiam-dev",
        about: "Internship at JPMorgan this summer. Building a mobile-first study planner."
    ),
    PeerProfile(
        id: "peer-6",
        name: "Raj Gupta",
        email: "rgupta11@stevens.edu",
        avatarColorHex: "#7a3b2e",
        major: "Computer Science",
        year: "Graduate",
        gradSemester: "Fall 2026",
        registeredEvents: ["evt6", "evt11"],
        interestedEvents: ["evt19", "evt3"],
        githubThemes: ["Graph Neural Networks", "PyTorch", "MLOps"],
        githubUsername: "rajg-ml",
        about: "MS in CS. Previously SDE at Walmart Labs. Looking for project teammates for CS-559."
    ),
    PeerProfile(
        id: "peer-7",
        name: "Nadia Rahman",
        email: "nrahman5@stevens.edu",
        avatarColorHex: "#4a4a7a",
        major: "Software Engineering",
        year: "Junior",
        gradSemester: "Spring 2027",
        registeredEvents: ["evt7", "evt2"],
        interestedEvents: ["evt6", "evt9"],
        githubThemes: ["iOS / SwiftUI", "React Native", "Backend APIs"],
        githubUsername: "nadiar-swe",
        about: "Co-founder of campus dating app prototype. Big into clean UI and accessibility."
    ),
    PeerProfile(
        id: "peer-8",
        name: "Tyler Brooks",
        email: "tbrooks2@stevens.edu",
        avatarColorHex: "#2e77bb",
        major: "Computer Science",
        year: "Senior",
        gradSemester: "Fall 2026",
        registeredEvents: ["evt11"],
        interestedEvents: ["evt6"],
        githubThemes: ["Cybersecurity", "CTF", "Reverse Engineering"],
        githubUsername: "tyler-ctf",
        about: "Stevens Cyber Defense Team captain. Hosts weekly CTF practice in EAS 322."
    ),
]

// MARK: - Scoring

struct PeerMatch: Identifiable {
    let peer: PeerProfile
    let score: Int
    let reasons: [String]
    var id: String { peer.id }
}

func scorePeer(
    peer: PeerProfile,
    userMajor: String,
    userYear: String,
    userGradSemester: String,
    userRegisteredEvents: Set<String>,
    userInterestedEvents: Set<String>,
    userGithubThemes: Set<String>
) -> PeerMatch {
    var score = 0
    var reasons: [String] = []

    if !userMajor.isEmpty && peer.major.caseInsensitiveCompare(userMajor) == .orderedSame {
        score += 5
        reasons.append("Same major")
    }
    if !userYear.isEmpty && peer.year.caseInsensitiveCompare(userYear) == .orderedSame {
        score += 3
        reasons.append("Same year")
    }
    if !userGradSemester.isEmpty && peer.gradSemester == userGradSemester {
        score += 2
        reasons.append("Graduating together")
    }

    let sharedRegistered = Set(peer.registeredEvents).intersection(userRegisteredEvents)
    if !sharedRegistered.isEmpty {
        score += sharedRegistered.count * 2
        reasons.append("\(sharedRegistered.count) shared event\(sharedRegistered.count == 1 ? "" : "s")")
    }

    let sharedInterested = Set(peer.interestedEvents).intersection(userInterestedEvents)
    if !sharedInterested.isEmpty {
        score += sharedInterested.count
        if sharedRegistered.isEmpty {
            reasons.append("\(sharedInterested.count) shared interest\(sharedInterested.count == 1 ? "" : "s")")
        }
    }

    let sharedThemes = Set(peer.githubThemes).intersection(userGithubThemes)
    if !sharedThemes.isEmpty {
        score += sharedThemes.count * 2
        reasons.append(sharedThemes.sorted().prefix(2).joined(separator: ", "))
    }

    if reasons.isEmpty { reasons.append("Stevens peer") }
    return PeerMatch(peer: peer, score: score, reasons: reasons)
}

// MARK: - Main view

struct PeerConnectView: View {
    @EnvironmentObject var authState: AuthStateManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPeer: PeerProfile? = nil

    @State private var isScanning = true
    @State private var scanStep = 0
    @State private var progress = 0.0
    @State private var scanTimer: Timer? = nil

    private let scanSubsteps = [
        "Reading your profile...",
        "Scanning 12 events you've engaged with...",
        "Pulling themes from your GitHub repos...",
        "Cross-referencing 240 Stevens students...",
        "Ranking by overlap..."
    ]

    // Pull from authState; fall back to demo defaults so the page never feels empty
    private var userMajor: String { authState.userProfile["major"] as? String ?? "Computer Science" }
    private var userYear: String { authState.userProfile["year"] as? String ?? "Junior" }
    private var userGradSemester: String { authState.userProfile["gradSemester"] as? String ?? "Spring 2027" }

    // Demo: assume Jhanvi is registered for the same starter set + has GitHub themes from her last match
    private var userRegisteredEvents: Set<String> { ["evt6", "evt4", "evt11"] }
    private var userInterestedEvents: Set<String> { ["evt2", "evt19"] }
    private var userGithubThemes: Set<String> { ["Graph Neural Networks", "iOS / SwiftUI", "Firebase Real-Time Systems"] }

    private var rankedMatches: [PeerMatch] {
        samplePeers.map {
            scorePeer(
                peer: $0,
                userMajor: userMajor,
                userYear: userYear,
                userGradSemester: userGradSemester,
                userRegisteredEvents: userRegisteredEvents,
                userInterestedEvents: userInterestedEvents,
                userGithubThemes: userGithubThemes
            )
        }
        .sorted { $0.score > $1.score }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isScanning {
                    scanningView
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {

                            // Hero
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Find Your Tribe")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.stevensRed)
                                Text("Stevens students who share your major, your events, and your code.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.nexusSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            // Your-profile signal strip
                            VStack(alignment: .leading, spacing: 8) {
                                Text("WE'RE MATCHING ON")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.nexusSecondary)
                                    .tracking(1)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        signalChip(icon: "graduationcap.fill", text: userMajor)
                                        signalChip(icon: "calendar", text: userYear)
                                        signalChip(icon: "ticket.fill", text: "\(userRegisteredEvents.count) registered events")
                                        signalChip(icon: "heart.fill", text: "\(userInterestedEvents.count) interested")
                                        ForEach(Array(userGithubThemes), id: \.self) { theme in
                                            signalChip(icon: "chevron.left.forwardslash.chevron.right", text: theme)
                                        }
                                    }
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.stevensRed.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.stevensRed.opacity(0.2))
                            )
                            .cornerRadius(14)
                            .padding(.horizontal, 16)

                            // Match cards
                            VStack(spacing: 12) {
                                ForEach(rankedMatches) { match in
                                    PeerCard(match: match) {
                                        selectedPeer = match.peer
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .background(Color.nexusSurface)
            .navigationTitle("Connect with Peers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $selectedPeer) { peer in
                PeerConnectSheet(peer: peer)
                    .environmentObject(authState)
            }
            .onAppear { startScan() }
            .onDisappear { scanTimer?.invalidate() }
        }
    }

    private var scanningView: some View {
        VStack(spacing: 20) {
            Group {
                if #available(iOS 17.0, *) {
                    Image(systemName: "person.2.wave.2.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.stevensRed)
                        .symbolEffect(.pulse, options: .repeating)
                } else {
                    Image(systemName: "person.2.wave.2.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.stevensRed)
                }
            }

            Text("Finding your tribe...")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.stevensRed)

            Text("We're matching you with Stevens students who share your major, events, and code.")
                .font(.system(size: 14))
                .foregroundColor(.nexusSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.stevensRed)
                .padding(.horizontal, 40)

            Text(scanSubsteps[scanStep % scanSubsteps.count])
                .font(.system(size: 13).italic())
                .foregroundColor(.nexusSecondary)
                .id(scanStep)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func startScan() {
        isScanning = true
        scanStep = 0
        progress = 0.0

        withAnimation(.linear(duration: 10.0)) {
            progress = 1.0
        }

        scanTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut) {
                scanStep += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            scanTimer?.invalidate()
            scanTimer = nil
            withAnimation(.easeInOut(duration: 0.5)) {
                isScanning = false
            }
        }
    }

    @ViewBuilder
    private func signalChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10))
            Text(text).font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.stevensRed)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white)
        .cornerRadius(999)
    }
}

// MARK: - Peer card

struct PeerCard: View {
    let match: PeerMatch
    let onConnect: () -> Void

    var matchTier: (String, Color) {
        switch match.score {
        case 10...: return ("STRONG MATCH", Color(hex: "#2D6A4F"))
        case 5...9: return ("GOOD MATCH",   Color(hex: "#c47c1a"))
        default:    return ("WORTH A LOOK", Color.nexusSecondary)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color(hex: match.peer.avatarColorHex))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(match.peer.initials)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(match.peer.name)
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Text(matchTier.0)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(matchTier.1)
                            .cornerRadius(999)
                    }
                    Text("\(match.peer.major) · \(match.peer.year)")
                        .font(.system(size: 13))
                        .foregroundColor(.nexusSecondary)
                    if let gh = match.peer.githubUsername {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 10))
                            Text("github.com/\(gh)")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.stevensRed)
                    }
                }
            }

            // Match reasons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(match.reasons, id: \.self) { reason in
                        Text(reason)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.stevensRed)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.stevensRed.opacity(0.08))
                            .cornerRadius(999)
                    }
                }
            }

            // About
            if !match.peer.about.isEmpty {
                Text(match.peer.about)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            // Connect button
            Button(action: onConnect) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Connect")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Color.stevensRed)
                .cornerRadius(10)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
    }
}

// MARK: - Connect sheet (email composer)

struct PeerConnectSheet: View {
    @EnvironmentObject var authState: AuthStateManager
    @Environment(\.dismiss) private var dismiss

    let peer: PeerProfile

    @State private var subject: String = ""
    @State private var body_: String = ""
    @State private var copied = false

    private var senderName: String {
        authState.userProfile["fullName"] as? String ?? "A fellow Stevens student"
    }
    private var senderMajor: String {
        authState.userProfile["major"] as? String ?? "Computer Science"
    }
    private var senderGitHub: String {
        authState.userProfile["github"] as? String ?? ""
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    // Recipient card
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: peer.avatarColorHex))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(peer.initials)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(peer.name).font(.system(size: 15, weight: .semibold))
                            Text(peer.email).font(.system(size: 12)).foregroundColor(.nexusSecondary)
                            Text("\(peer.major) · \(peer.year)").font(.system(size: 12)).foregroundColor(.nexusSecondary)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)

                    // Subject
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SUBJECT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                            .tracking(1)
                        TextField("", text: $subject, axis: .vertical)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)

                    // Body
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MESSAGE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                            .tracking(1)
                        TextEditor(text: $body_)
                            .frame(minHeight: 240)
                            .font(.system(size: 14))
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)

                    // Open in Mail
                    Button(action: openInMail) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Open in Mail")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 14).padding(.horizontal, 16)
                        .background(Color.stevensRed)
                        .cornerRadius(14)
                    }

                    // Copy
                    Button(action: copyToClipboard) {
                        HStack {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy Email")
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                        }
                        .foregroundColor(.stevensRed)
                        .padding(.vertical, 12).padding(.horizontal, 16)
                        .background(Color.stevensRed.opacity(0.08))
                        .cornerRadius(12)
                    }

                    Text("Sent emails are between you and \(peer.name) — Nexus does not log them.")
                        .font(.system(size: 11))
                        .foregroundColor(.nexusSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Color.nexusSurface)
            .navigationTitle("Send Intro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { generateDraft() }
        }
    }

    private func generateDraft() {
        let theme = peer.githubThemes.first ?? peer.major
        subject = "Stevens \(senderMajor) student — fan of your work on \(theme.lowercased())"

        let firstName = peer.name.split(separator: " ").first.map(String.init) ?? peer.name
        let myFirst = senderName.split(separator: " ").first.map(String.init) ?? "Hey"

        var b = "Hey \(firstName),\n\n"
        b += "I'm \(senderName) — a fellow \(senderMajor) student at Stevens. Nexus surfaced you as someone with overlapping interests, and your work on \(theme.lowercased()) caught my eye.\n\n"
        if !peer.about.isEmpty {
            b += "Loved this from your bio: \"\(peer.about)\"\n\n"
        }
        b += "Would you be up for a quick coffee at Pierce or a 15-min Zoom this week? Always trying to meet other Stevens students working on cool stuff.\n\n"
        if !senderGitHub.isEmpty {
            b += "A bit about me: github.com/\(senderGitHub)\n\n"
        }
        b += "Thanks,\n\(myFirst)"

        body_ = b
    }

    private func openInMail() {
        let subjectEnc = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEnc = body_.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(peer.email)?subject=\(subjectEnc)&body=\(bodyEnc)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = "To: \(peer.email)\nSubject: \(subject)\n\n\(body_)"
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
    }
}

#Preview {
    PeerConnectView()
        .environmentObject(AuthStateManager())
}
