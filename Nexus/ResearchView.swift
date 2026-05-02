import SwiftUI

struct ResearchView: View {
    @EnvironmentObject var authState: AuthStateManager
    @StateObject private var firebase = FirebaseManager.shared
    @State private var interestText = ""
    @State private var matchedProfessors: [FacultyProfile] = []
    @State private var hasSearched = false
    @State private var selectedProfessor: FacultyProfile? = nil
    @State private var seenProfessors: [FacultyProfile] = []
    @State private var showSeeAll = false

    // GitHub-based matching state
    @State private var ghMatching = false
    @State private var ghThemes: [String] = []
    @State private var ghMatches: [GitHubMatch] = []
    @State private var ghError: String? = nil
    @State private var matchSource: MatchSource = .keyword

    enum MatchSource { case keyword, github }

    private var studentGitHub: String {
        authState.userProfile["github"] as? String ?? ""
    }

    let trendingCategories = ["Quantum Computing", "Sustainability", "FinTech", "Cybersecurity", "BioTech"]
    @State private var selectedCategory = "Quantum Computing"

    struct Spotlight {
        let badge: String
        let title: String
        let subtitle: String
        let gradient: [Color]
    }

    var spotlights: [String: Spotlight] {
        [
            "Quantum Computing": Spotlight(
                badge: "SEMINAR",
                title: "Quantum Algorithms for Optimization",
                subtitle: "Prof. Yuping Huang · Friday 4 PM, Babbio 122. Walk through Grover's algorithm + a live IBM Quantum demo.",
                gradient: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")]
            ),
            "Sustainability": Spotlight(
                badge: "LAB OPEN HOUSE",
                title: "Coastal Resilience & Climate Lab",
                subtitle: "Davidson Lab · Tour the wave tank Thursday 2 PM. Talk to PhDs on flood-modeling for Hoboken.",
                gradient: [Color(hex: "#1b4332"), Color(hex: "#2d6a4f")]
            ),
            "FinTech": Spotlight(
                badge: "WORKSHOP",
                title: "Algorithmic Trading on the Bloomberg Terminal",
                subtitle: "SGFA · Wednesday 5 PM, Babbio 220 (Trading Lab). Bring a laptop. MSFE/MS Finance focused.",
                gradient: [Color(hex: "#3d2c8d"), Color(hex: "#6b3fa0")]
            ),
            "Cybersecurity": Spotlight(
                badge: "CTF PRACTICE",
                title: "Web Exploitation — SQLi & SSRF",
                subtitle: "Stevens Cyber Defense Team · EAS 322, Mondays 7 PM. Newcomers paired with veterans before regionals.",
                gradient: [Color(hex: "#7a2e2e"), Color(hex: "#A32638")]
            ),
            "BioTech": Spotlight(
                badge: "RESEARCH TALK",
                title: "AI in Drug Discovery",
                subtitle: "Prof. Samantha Kleinberg · McLean 219, Tuesday 3 PM. ML methods for clinical decision support.",
                gradient: [Color(hex: "#0d3b4f"), Color(hex: "#1a6b9a")]
            ),
        ]
    }

    var currentSpotlight: Spotlight {
        spotlights[selectedCategory] ?? spotlights["Quantum Computing"]!
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // AI Assistant Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.stevensRed)
                            Text("Nexus AI Assistant")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        Text("Find the perfect research match for your PhD proposal or senior design project.")
                            .font(.system(size: 15))
                            .foregroundColor(.nexusSecondary)

                        HStack(spacing: 8) {
                            TextField("Explain your research interest...", text: $interestText)
                                .font(.system(size: 17))
                                .padding(.leading, 4)

                            Button(action: {
                                firebase.fetchFaculty()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    matchedProfessors = firebase.searchFaculty(query: interestText)
                                    hasSearched = true
                                    matchSource = .keyword
                                    for prof in matchedProfessors where !seenProfessors.contains(where: { $0.id == prof.id }) {
                                        seenProfessors.append(prof)
                                    }
                                }
                            }) {
                                Image(systemName: "arrow.up")
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.stevensRed)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(12)
                        .background(Color.surfaceContainerLow)
                        .cornerRadius(10)

                        // OR divider
                        HStack(spacing: 8) {
                            Rectangle().fill(Color.nexusSecondary.opacity(0.25)).frame(height: 1)
                            Text("OR")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.nexusSecondary)
                                .tracking(1)
                            Rectangle().fill(Color.nexusSecondary.opacity(0.25)).frame(height: 1)
                        }
                        .padding(.vertical, 4)

                        // GitHub-based matching button
                        Button(action: runGitHubMatch) {
                            HStack(spacing: 10) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                if ghMatching {
                                    ProgressView().tint(.white)
                                    Text("Analyzing your repos...")
                                        .font(.system(size: 14, weight: .semibold))
                                } else if studentGitHub.isEmpty {
                                    Text("Add GitHub on Profile to match")
                                        .font(.system(size: 14, weight: .semibold))
                                } else {
                                    Text("Match using my GitHub: @\(studentGitHub)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                Spacer()
                                if !ghMatching && !studentGitHub.isEmpty {
                                    Image(systemName: "sparkles").font(.system(size: 12))
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(studentGitHub.isEmpty ? Color.gray : Color.stevensRed)
                            .cornerRadius(10)
                        }
                        .disabled(studentGitHub.isEmpty || ghMatching)

                        if let err = ghError {
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)

                    // Top Matches
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Top Matches")
                                    .font(.system(size: 17, weight: .semibold))
                                Text(matchSource == .github
                                     ? "Grounded in your GitHub repositories"
                                     : "Based on your recent profile activity")
                                    .font(.system(size: 13))
                                    .foregroundColor(.nexusSecondary)
                            }
                            Spacer()
                            Button("See All") { showSeeAll = true }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.stevensRed)
                        }

                        // GitHub themes banner (only when GitHub mode active)
                        if matchSource == .github && !ghThemes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 11))
                                        .foregroundColor(.stevensRed)
                                    Text("THEMES FROM YOUR GITHUB")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.stevensRed)
                                        .tracking(1)
                                }
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(ghThemes, id: \.self) { theme in
                                            Text(theme)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.stevensRed)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Color.stevensRed.opacity(0.1))
                                                .cornerRadius(999)
                                        }
                                    }
                                }
                                Text("Powered by your last 30 public repos.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.nexusSecondary)
                            }
                            .padding(12)
                            .background(Color.stevensRed.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.stevensRed.opacity(0.2))
                            )
                            .cornerRadius(10)
                        }

                        if firebase.isLoadingFaculty {
                            ProgressView("Finding matches...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if matchSource == .github {
                            if ghMatches.isEmpty && !ghMatching {
                                Text("Tap \"Match using my GitHub\" above to see results.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.nexusSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                ForEach(ghMatches) { ghm in
                                    Button(action: { selectedProfessor = facultyProfile(for: ghm) }) {
                                        FirebaseProfessorCard(
                                            professor: facultyProfile(for: ghm),
                                            customReason: ghm.reasoning
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else if matchedProfessors.isEmpty && hasSearched {
                            Text("No matches found. Try different keywords.")
                                .font(.system(size: 14))
                                .foregroundColor(.nexusSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(matchedProfessors.isEmpty ? Array(firebase.faculty.prefix(3)) : matchedProfessors) { prof in
                                Button(action: { selectedProfessor = prof }) {
                                    FirebaseProfessorCard(professor: prof)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Trending Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trending Categories")
                            .font(.system(size: 17, weight: .semibold))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(trendingCategories, id: \.self) { cat in
                                    Button(action: { selectedCategory = cat }) {
                                        Text(cat)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(selectedCategory == cat ? .white : .nexusSecondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(selectedCategory == cat ? Color.stevensRed : Color.surfaceContainer)
                                            .cornerRadius(999)
                                    }
                                }
                            }
                        }
                    }

                    // Featured Research — changes with selected category
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: currentSpotlight.gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 180)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(currentSpotlight.badge)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.stevensRed)
                                    .cornerRadius(4)
                                Text(selectedCategory.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                                    .tracking(1)
                            }

                            Text(currentSpotlight.title)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)

                            Text(currentSpotlight.subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                        }
                        .padding(16)
                    }
                    .frame(height: 180)
                    .cornerRadius(16)
                    .animation(.easeInOut(duration: 0.25), value: selectedCategory)
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .background(Color.nexusSurface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NexusTopBar()
                }
            }
            .onAppear {
                firebase.fetchFaculty()
            }
            .sheet(item: $selectedProfessor) { prof in
                ProfessorProfileSheet(professor: prof)
                    .environmentObject(authState)
            }
            .sheet(isPresented: $showSeeAll) {
                SeeAllProfessorsSheet(
                    seen: seenProfessors,
                    all: firebase.faculty,
                    onSelect: { prof in
                        showSeeAll = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedProfessor = prof
                        }
                    }
                )
                .environmentObject(authState)
            }
        }
    }

    // MARK: - GitHub matching

    private func runGitHubMatch() {
        let username = studentGitHub
        guard !username.isEmpty else {
            ghError = "Add your GitHub username on the Profile tab to use this feature."
            return
        }
        ghError = nil
        ghMatching = true

        GitHubMatchAPIClient.shared.match(username: username) { result in
            DispatchQueue.main.async {
                ghMatching = false
                switch result {
                case .success(let resp):
                    ghThemes = resp.themes
                    ghMatches = resp.matches
                    matchSource = .github
                    for ghm in ghMatches {
                        let prof = facultyProfile(for: ghm)
                        if !seenProfessors.contains(where: { $0.id == prof.id }) {
                            seenProfessors.append(prof)
                        }
                    }
                case .failure(let err):
                    ghError = err.localizedDescription
                }
            }
        }
    }

    /// Convert a GitHub match into a FacultyProfile so we can reuse all the
    /// existing professor sheets / card layouts.
    private func facultyProfile(for ghm: GitHubMatch) -> FacultyProfile {
        var data: [String: Any] = [
            "name":               ghm.name,
            "department":         ghm.department,
            "email":              ghm.email,
            "research_interests": ghm.researchInterests,
            "bio":                ghm.activeProjects,
            "rank":               "Stevens Faculty"
        ]
        // Try to enrich with the live faculty record if available
        if let real = firebase.faculty.first(where: { $0.id == ghm.facultyID || $0.name == ghm.name }) {
            data["photo_url"]   = real.photoURL
            data["profile_url"] = real.profileURL
            data["rank"]        = real.rank
        }
        var profile = FacultyProfile(id: ghm.facultyID, data: data)
        profile.matchReason = ghm.reasoning
        profile.matchScore = ghm.matchScore
        return profile
    }
}

struct FirebaseProfessorCard: View {
    let professor: FacultyProfile
    var customReason: String? = nil

    var initials: String {
        professor.name.split(separator: " ").compactMap { $0.first }.map { String($0) }.joined()
    }

    var shortBio: String {
        let firstInterest = professor.researchInterests
            .components(separatedBy: ",")
            .first?.trimmingCharacters(in: .whitespaces) ?? ""
        let rank = professor.rank.isEmpty ? "Faculty" : professor.rank
        let dept = professor.department.isEmpty ? "Stevens" : professor.department
        if !firstInterest.isEmpty {
            return "\(rank) in \(dept) — works on \(firstInterest.lowercased())."
        }
        return "\(rank) in \(dept)."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: professor.photoURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.stevensRed)
                        .overlay(Text(String(initials.prefix(2)))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(professor.name)
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.stevensRed)
                            .font(.system(size: 14))
                    }
                    Text(professor.rank.isEmpty ? professor.department : professor.rank)
                        .font(.system(size: 13))
                        .foregroundColor(.nexusSecondary)

                    if !professor.researchInterests.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(professor.researchInterests.components(separatedBy: ",").prefix(3), id: \.self) { tag in
                                    Text(tag.trimmingCharacters(in: .whitespaces).uppercased())
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.stevensRed)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.stevensRed.opacity(0.08))
                                        .cornerRadius(999)
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 0) {
                Rectangle().fill(Color.stevensRed).frame(width: 4).cornerRadius(2)
                Text(customReason ?? shortBio)
                    .font(.system(size: 12))
                    .italic(customReason != nil)
                    .lineLimit(customReason != nil ? 4 : 1)
                    .truncationMode(.tail)
                    .padding(.leading, 10).padding(.vertical, 8)
                    .padding(.trailing, 10)
            }
            .background(Color.surfaceContainerLow)
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}


struct SeeAllProfessorsSheet: View {
    let seen: [FacultyProfile]
    let all: [FacultyProfile]
    let onSelect: (FacultyProfile) -> Void

    @State private var query: String = ""
    @Environment(\.dismiss) private var dismiss

    var filteredAll: [FacultyProfile] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return all }
        return all.filter { prof in
            prof.name.lowercased().contains(q)
                || prof.department.lowercased().contains(q)
                || prof.researchInterests.lowercased().contains(q)
                || prof.bio.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.nexusSecondary)
                        TextField("Search faculty, department, interests...", text: $query)
                            .font(.system(size: 15))
                        if !query.isEmpty {
                            Button(action: { query = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.nexusSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)

                    if !seen.isEmpty {
                        Section {
                            VStack(spacing: 12) {
                                ForEach(seen) { prof in
                                    Button(action: { onSelect(prof) }) {
                                        FirebaseProfessorCard(professor: prof)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } header: {
                            Text("RECENTLY MATCHED")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.nexusSecondary)
                                .tracking(1)
                        }
                    }

                    Section {
                        VStack(spacing: 12) {
                            ForEach(filteredAll) { prof in
                                Button(action: { onSelect(prof) }) {
                                    FirebaseProfessorCard(professor: prof)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text("ALL STEVENS FACULTY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                            .tracking(1)
                    }
                }
                .padding(16)
            }
            .background(Color.nexusSurface)
            .navigationTitle("Faculty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ResearchView()
}
