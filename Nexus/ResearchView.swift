import SwiftUI

struct ResearchView: View {
    @EnvironmentObject var authState: AuthStateManager
    @StateObject private var firebase = FirebaseManager.shared
    @State private var interestText = ""
    @State private var matchedProfessors: [FacultyProfile] = []
    @State private var hasSearched = false
    @State private var selectedProfessor: FacultyProfile? = nil

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
                                Text("Based on your recent profile activity")
                                    .font(.system(size: 13))
                                    .foregroundColor(.nexusSecondary)
                            }
                            Spacer()
                            Button("See All") {}
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.stevensRed)
                        }

                        if firebase.isLoadingFaculty {
                            ProgressView("Finding matches...")
                                .frame(maxWidth: .infinity)
                                .padding()
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
        }
    }
}

struct FirebaseProfessorCard: View {
    let professor: FacultyProfile

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
                Text(shortBio)
                    .font(.system(size: 12))
                    .lineLimit(1)
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


#Preview {
    ResearchView()
}
