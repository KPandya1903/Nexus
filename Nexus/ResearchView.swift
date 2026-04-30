import SwiftUI

struct Professor: Identifiable {
    let id = UUID()
    let name: String
    let department: String
    let tags: [String]
    let matchReason: String
    let initials: String
    let color: Color
}

struct ResearchView: View {
    @State private var interestText = ""
    @State private var isSearching = false

    let professors = [
        Professor(name: "Dr. Sarah Jenkins", department: "Dept. of Computer Science",
                  tags: ["Robotics", "AI"],
                  matchReason: "Her recent work on autonomous drone navigation aligns with your interest in edge computing.",
                  initials: "SJ", color: Color(hex: "#A32638")),
        Professor(name: "Dr. Michael Chen", department: "Dept. of Mechanical Eng.",
                  tags: ["Dynamics", "Haptics"],
                  matchReason: "His lab is currently seeking research assistants with a strong background in MATLAB modeling.",
                  initials: "MC", color: .blue),
    ]

    let trendingCategories = ["Quantum Computing", "Sustainability", "FinTech", "Cybersecurity", "BioTech"]
    @State private var selectedCategory = "Quantum Computing"

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

                            Button(action: { isSearching = true }) {
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

                        ForEach(professors) { prof in
                            ProfessorCard(professor: prof)
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

                    // Featured Research
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.7), Color.black.opacity(0.1), Color.clear],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: 180)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("SPOTLIGHT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.stevensRed)
                                .cornerRadius(4)

                            Text("The Future of AI in Urban Planning at Stevens")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)

                            Text("Join the interdisciplinary seminar this Friday at Babbio Center.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(16)
                    }
                    .frame(height: 180)
                    .cornerRadius(16)
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
        }
    }
}

struct ProfessorCard: View {
    let professor: Professor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(professor.color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(professor.initials)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(professor.name)
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.stevensRed)
                            .font(.system(size: 14))
                    }
                    Text(professor.department)
                        .font(.system(size: 13))
                        .foregroundColor(.nexusSecondary)

                    HStack(spacing: 4) {
                        ForEach(professor.tags, id: \.self) { tag in
                            Text(tag.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.stevensRed)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.stevensRed.opacity(0.08))
                                .cornerRadius(999)
                        }
                    }
                }
            }

            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.stevensRed)
                    .frame(width: 4)
                    .cornerRadius(2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Matched because...")
                        .font(.system(size: 13, weight: .bold))
                        + Text(" \"\(professor.matchReason)\"")
                        .font(.system(size: 13))
                        .italic()
                }
                .padding(.leading, 10)
                .padding(.vertical, 8)
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
