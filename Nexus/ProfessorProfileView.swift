import SwiftUI
import MessageUI

// MARK: - Professor Profile Sheet

struct ProfessorProfileSheet: View {
    @EnvironmentObject var authState: AuthStateManager
    @Environment(\.dismiss) private var dismiss
    let professor: FacultyProfile

    @State private var showEmailDrafter = false
    @State private var userAsk: String = ""

    private var initials: String {
        professor.name.split(separator: " ").compactMap { $0.first }.map { String($0) }.prefix(2).joined()
    }

    private var interestTags: [String] {
        professor.researchInterests
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    // Hero
                    HStack(alignment: .top, spacing: 14) {
                        AsyncImage(url: URL(string: professor.photoURL)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(LinearGradient(
                                colors: [.stevensRed, .primaryContainer],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .overlay(Text(initials).font(.system(size: 24, weight: .bold)).foregroundColor(.white))
                        }
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(professor.name).font(.system(size: 20, weight: .bold))
                            Text(professor.rank).font(.system(size: 14)).foregroundColor(.nexusSecondary)
                            Text(professor.department).font(.system(size: 13)).foregroundColor(.stevensRed)
                            if !professor.email.isEmpty {
                                Text(professor.email).font(.system(size: 12)).foregroundColor(.nexusSecondary).padding(.top, 2)
                            }
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                    // Match reason if present
                    if !professor.matchReason.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles").foregroundColor(.stevensRed)
                                Text("Why this match")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.stevensRed)
                            }
                            Text(professor.matchReason).font(.system(size: 14)).italic()
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.stevensRed.opacity(0.06))
                        .cornerRadius(12)
                    }

                    // Research Interests
                    if !interestTags.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("RESEARCH INTERESTS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.nexusSecondary).tracking(1)
                            FlexibleTagFlow(tags: interestTags)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }

                    // Bio
                    if !professor.bio.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BIO")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.nexusSecondary).tracking(1)
                            Text(professor.bio).font(.system(size: 14))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }

                    // Action buttons
                    VStack(spacing: 10) {
                        Button(action: { showEmailDrafter = true }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Draft Outreach Email")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Image(systemName: "sparkles").font(.system(size: 13))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 14).padding(.horizontal, 16)
                            .background(Color.stevensRed)
                            .cornerRadius(14)
                        }

                        if !professor.profileURL.isEmpty,
                           let url = URL(string: professor.profileURL) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("View Stevens Profile")
                                        .font(.system(size: 15, weight: .medium))
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                }
                                .foregroundColor(.stevensRed)
                                .padding(.vertical, 12).padding(.horizontal, 16)
                                .background(Color.stevensRed.opacity(0.08))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.nexusSurface)
            .navigationTitle("Professor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showEmailDrafter) {
                EmailDrafterSheet(professor: professor)
                    .environmentObject(authState)
            }
        }
    }
}

// MARK: - Email Drafter

struct EmailDrafterSheet: View {
    @EnvironmentObject var authState: AuthStateManager
    @Environment(\.dismiss) private var dismiss
    let professor: FacultyProfile

    @State private var ask: String = "I'd like to discuss potential opportunities to contribute to your lab — independent study, RA position, or summer research."
    @State private var tone: Tone = .neutral
    @State private var subject: String = ""
    @State private var body_: String = ""
    @State private var isGenerating = false
    @State private var hasGenerated = false
    @State private var copyConfirmation = false

    enum Tone: String, CaseIterable, Identifiable {
        case formal = "Formal"
        case neutral = "Neutral"
        case warm = "Warm"
        var id: String { rawValue }
    }

    private var studentName: String {
        authState.userProfile["fullName"] as? String ?? "a Stevens student"
    }
    private var studentMajor: String {
        authState.userProfile["major"] as? String ?? "Computer Science"
    }
    private var studentYear: String {
        authState.userProfile["year"] as? String ?? ""
    }
    private var studentAbout: String {
        authState.userProfile["about"] as? String ?? ""
    }
    private var studentGitHub: String {
        authState.userProfile["github"] as? String ?? ""
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    if !hasGenerated {
                        composerView
                    } else {
                        outputView
                    }
                }
                .padding(16)
            }
            .background(Color.nexusSurface)
            .navigationTitle(hasGenerated ? "Email Draft" : "Compose Outreach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if hasGenerated {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit Inputs") { hasGenerated = false }
                    }
                }
            }
        }
    }

    private var composerView: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Recipient
            VStack(alignment: .leading, spacing: 4) {
                Text("TO")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.nexusSecondary).tracking(1)
                HStack {
                    Text(professor.name).font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(professor.department).font(.system(size: 12)).foregroundColor(.nexusSecondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)

            // Tone selector
            VStack(alignment: .leading, spacing: 8) {
                Text("TONE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.nexusSecondary).tracking(1)
                Picker("", selection: $tone) {
                    ForEach(Tone.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)

            // Ask
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR ASK")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.nexusSecondary).tracking(1)
                TextEditor(text: $ask)
                    .frame(minHeight: 100)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)

            // Generate
            Button(action: generate) {
                HStack {
                    if isGenerating {
                        ProgressView().tint(.white)
                        Text("Generating...")
                    } else {
                        Image(systemName: "sparkles")
                        Text("Generate Email")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ask.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.stevensRed)
                .cornerRadius(14)
            }
            .disabled(ask.trimmingCharacters(in: .whitespaces).isEmpty || isGenerating)

            Text("AI generates a concise, specific email referencing the professor's research and your background. Review and edit before sending.")
                .font(.system(size: 11))
                .foregroundColor(.nexusSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private var outputView: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Subject
            VStack(alignment: .leading, spacing: 6) {
                Text("SUBJECT").font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.nexusSecondary).tracking(1)
                TextField("", text: $subject, axis: .vertical)
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)

            // Body
            VStack(alignment: .leading, spacing: 6) {
                Text("BODY").font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.nexusSecondary).tracking(1)
                TextEditor(text: $body_)
                    .frame(minHeight: 280)
                    .font(.system(size: 14))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)

            // Send via Mail
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

            // Copy to clipboard
            Button(action: copyToClipboard) {
                HStack {
                    Image(systemName: copyConfirmation ? "checkmark" : "doc.on.doc")
                    Text(copyConfirmation ? "Copied!" : "Copy Email")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                }
                .foregroundColor(.stevensRed)
                .padding(.vertical, 12).padding(.horizontal, 16)
                .background(Color.stevensRed.opacity(0.08))
                .cornerRadius(12)
            }

            Text("Sent emails are between you and the professor — Nexus does not log them.")
                .font(.system(size: 11))
                .foregroundColor(.nexusSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
        }
    }

    private func generate() {
        isGenerating = true
        // Simulate "AI" generation locally with a strong template.
        // Backend swap point: replace this block with a POST to
        // /discover/email Cloud Function and consume `draft.subject` + `draft.body`.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let firstInterest = professor.researchInterests
                .components(separatedBy: ",").first?
                .trimmingCharacters(in: .whitespaces) ?? "your research"

            subject = generatedSubject(firstInterest: firstInterest)
            body_ = generatedBody(firstInterest: firstInterest)
            isGenerating = false
            hasGenerated = true
        }
    }

    private func generatedSubject(firstInterest: String) -> String {
        switch tone {
        case .formal:
            return "Inquiry regarding research opportunities — \(firstInterest)"
        case .neutral:
            return "Stevens \(studentMajor) student interested in \(firstInterest)"
        case .warm:
            return "Loved your work on \(firstInterest) — Stevens student reaching out"
        }
    }

    private func generatedBody(firstInterest: String) -> String {
        let greeting: String
        let opener: String
        let closer: String

        switch tone {
        case .formal:
            greeting = "Dear \(professorTitle()) \(lastName()),"
            opener = "I am \(studentName), a \(studentYear.lowercased()) \(studentMajor) student at Stevens. I am writing to express interest in your research on \(firstInterest)."
            closer = "Thank you for your time and consideration. I would welcome the opportunity to discuss this further at your convenience.\n\nSincerely,\n\(studentName)"
        case .neutral:
            greeting = "Hi \(professorTitle()) \(lastName()),"
            opener = "My name is \(studentName), a \(studentYear) \(studentMajor) student at Stevens. I came across your work on \(firstInterest) and wanted to reach out."
            closer = "Would you have 15–20 minutes in the next couple of weeks to chat? I'd love to learn more about your lab and how I might contribute.\n\nThanks,\n\(studentName)"
        case .warm:
            greeting = "Hi \(professorTitle()) \(lastName()),"
            opener = "I'm \(studentName), a \(studentYear) \(studentMajor) student at Stevens — and a fan of your research on \(firstInterest). It speaks directly to what I've been most excited about."
            closer = "I'd love to grab 15 minutes of your time to learn more and explore whether I'd be a useful contributor. Thanks so much!\n\n\(studentName)"
        }

        var middle = "\n\n\(opener)\n\n"

        // Background paragraph
        var background = "A bit about me: "
        if !studentAbout.isEmpty {
            background += studentAbout
        } else {
            background += "I'm focused on building practical systems and have been digging into the foundations of \(firstInterest) on the side. I'm comfortable picking up new tools and frameworks quickly."
        }
        if !studentGitHub.isEmpty {
            background += " You can see some of my recent work at github.com/\(studentGitHub)."
        }
        middle += background + "\n\n"

        // The ask
        middle += "Specifically: \(ask.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"

        return greeting + middle + closer
    }

    private func lastName() -> String {
        professor.name.split(separator: " ").last.map(String.init) ?? professor.name
    }

    private func professorTitle() -> String {
        let rank = professor.rank.lowercased()
        if rank.contains("professor") || rank.contains("dr") || rank.contains("phd") { return "Prof." }
        return "Prof."
    }

    private func openInMail() {
        let to = professor.email.isEmpty ? "" : professor.email
        let subjectEnc = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEnc = body_.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(to)?subject=\(subjectEnc)&body=\(bodyEnc)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = "Subject: \(subject)\n\n\(body_)"
        copyConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copyConfirmation = false
        }
    }
}

// MARK: - Tag Flow Layout

struct FlexibleTagFlow: View {
    let tags: [String]

    var body: some View {
        FlexFlow(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.stevensRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.stevensRed.opacity(0.08))
                    .cornerRadius(999)
            }
        }
    }
}

private struct FlexFlow: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: height + rowHeight)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
