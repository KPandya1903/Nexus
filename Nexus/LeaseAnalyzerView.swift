import SwiftUI
import UniformTypeIdentifiers

// MARK: - Banner shown on Housing tab

struct LeaseAnalyzerBanner: View {
    @State private var showAnalyzer = false

    var body: some View {
        Button(action: { showAnalyzer = true }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Lease Verifier")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("AI scans your PDF for red flags & savings")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color.stevensRed, Color.primaryContainer],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .stevensRed.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAnalyzer) {
            LeaseAnalyzerSheet()
        }
    }
}

// MARK: - Main analyzer sheet

struct LeaseAnalyzerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var pickedURL: URL? = nil
    @State private var showPicker = false
    @State private var isAnalyzing = false
    @State private var brief: LeaseBrief? = nil
    @State private var errorMessage: String? = nil
    @State private var isOnF1 = false
    @State private var isFirstLease = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let brief = brief {
                        LeaseBriefView(brief: brief)
                    } else {
                        uploadView
                    }
                }
                .padding(16)
            }
            .background(Color.nexusSurface)
            .navigationTitle(brief == nil ? "Lease Verifier" : "Your Lease Brief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if brief != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("New Lease") {
                            brief = nil
                            pickedURL = nil
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showPicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        let _ = url.startAccessingSecurityScopedResource()
                        pickedURL = url
                    }
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }

    private var uploadView: some View {
        VStack(alignment: .leading, spacing: 18) {

            // Hero
            VStack(alignment: .leading, spacing: 8) {
                Text("Sign safer.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.stevensRed)
                Text("Upload your NJ lease PDF — we'll surface red flags, hidden costs, and statute conflicts so you can negotiate from a stronger position.")
                    .font(.system(size: 15))
                    .foregroundColor(.nexusSecondary)
            }

            // Tenant context
            VStack(alignment: .leading, spacing: 0) {
                Text("Your Context")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.nexusSecondary)
                    .tracking(1)
                    .padding(.bottom, 8)

                contextToggle("Are you on F-1 visa?", isOn: $isOnF1)
                Divider().padding(.leading, 16)
                contextToggle("First U.S. lease", isOn: $isFirstLease)
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

            // File picker
            VStack(spacing: 12) {
                if let url = pickedURL {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.stevensRed)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.lastPathComponent)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                            Text("Ready to analyze")
                                .font(.system(size: 12))
                                .foregroundColor(.nexusSecondary)
                        }
                        Spacer()
                        Button(action: { pickedURL = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.nexusSecondary)
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                } else {
                    Button(action: { showPicker = true }) {
                        VStack(spacing: 10) {
                            Image(systemName: "arrow.up.doc")
                                .font(.system(size: 32))
                                .foregroundColor(.stevensRed)
                            Text("Upload Lease PDF")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.stevensRed)
                            Text("Tap to choose from Files")
                                .font(.system(size: 12))
                                .foregroundColor(.nexusSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.stevensRed.opacity(0.3),
                                              style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        )
                        .cornerRadius(14)
                    }
                }
            }

            // Analyze button
            Button(action: analyze) {
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Analyzing...")
                    } else {
                        Image(systemName: "sparkles")
                        Text("Analyze My Lease")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(pickedURL == nil ? Color.gray : Color.stevensRed)
                .cornerRadius(14)
            }
            .disabled(pickedURL == nil || isAnalyzing)

            if isAnalyzing {
                Text("This can take 30 – 90 seconds. We're reading every clause and cross-referencing NJ statutes.")
                    .font(.system(size: 12))
                    .foregroundColor(.nexusSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(10)
            }

            Text("⚖️ Legal information, not legal advice. Consult a NJ attorney for any signed dispute.")
                .font(.system(size: 11))
                .foregroundColor(.nexusSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }

    private func contextToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label).font(.system(size: 15))
        }
        .tint(.stevensRed)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func analyze() {
        guard let url = pickedURL else { return }
        isAnalyzing = true
        errorMessage = nil

        LeaseAPIClient.shared.parseLease(
            pdfURL: url,
            isStudent: true,
            isInternational: isOnF1,
            isFirstUSLease: isFirstLease
        ) { result in
            DispatchQueue.main.async {
                isAnalyzing = false
                switch result {
                case .success(let b):
                    brief = b
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }
}

// MARK: - Brief result view

struct LeaseBriefView: View {
    let brief: LeaseBrief

    var scoreColor: Color {
        if brief.consentClarityScore >= 75 { return Color(hex: "#2D6A4F") }
        if brief.consentClarityScore >= 50 { return Color(hex: "#c47c1a") }
        return .stevensRed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Score Card
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CONSENT CLARITY SCORE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .tracking(1)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(brief.consentClarityScore)")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.white)
                            Text("/100")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    Spacer()
                }
                Text(brief.scoreMeaning)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.95))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(scoreColor)
            .cornerRadius(16)

            // 5-bullet summary
            sectionCard(title: "Plain-English Summary", icon: "text.bubble") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(brief.plainEnglishSummary, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(Color.stevensRed).frame(width: 5, height: 5).padding(.top, 7)
                            Text(line).font(.system(size: 14))
                        }
                    }
                }
            }

            // Money Map
            sectionCard(title: "Money Map", icon: "dollarsign.circle") {
                VStack(spacing: 10) {
                    moneyRow("Annual Base Rent", value: brief.moneyMap.baseRentAnnual)
                    moneyRow("Security Deposit", value: brief.moneyMap.securityDeposit)
                    if let af = brief.moneyMap.applicationFees, af > 0 {
                        moneyRow("Application Fees", value: af)
                    }
                    if let bf = brief.moneyMap.brokerFees, bf > 0 {
                        moneyRow("Broker Fees", value: bf)
                    }
                    if brief.moneyMap.lastMonthRequired, let lm = brief.moneyMap.lastMonthAmount {
                        moneyRow("Last Month Up Front", value: lm)
                    }
                    Divider()
                    moneyRow("Estimated Total / Year",
                             value: brief.moneyMap.estimatedTotalAnnual,
                             bold: true)

                    VStack(alignment: .leading, spacing: 6) {
                        infoLine(label: "Late Fees", value: brief.moneyMap.lateFeeStructure)
                        infoLine(label: "Utilities", value: brief.moneyMap.utilityResponsibilities)
                        if !brief.moneyMap.notes.isEmpty {
                            infoLine(label: "Notes", value: brief.moneyMap.notes)
                        }
                    }
                    .padding(.top, 6)
                }
            }

            // Red Flags
            if !brief.redFlags.isEmpty {
                sectionCard(title: "Red Flags (\(brief.redFlags.count))", icon: "exclamationmark.triangle.fill", iconColor: .stevensRed) {
                    VStack(spacing: 12) {
                        ForEach(brief.redFlags) { flag in
                            redFlagCard(flag)
                        }
                    }
                }
            }

            // Negotiation Openings
            if !brief.negotiationOpenings.isEmpty {
                sectionCard(title: "Negotiation Openings", icon: "bubble.left.and.bubble.right") {
                    VStack(spacing: 12) {
                        ForEach(brief.negotiationOpenings) { neg in
                            negotiationCard(neg)
                        }
                    }
                }
            }

            // Closing Notes
            sectionCard(title: "Closing Notes", icon: "info.circle") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(brief.closingNotes.notLegalAdviceDisclaimer)
                        .font(.system(size: 12))
                        .foregroundColor(.nexusSecondary)
                    Text(brief.closingNotes.whenToConsultAttorney)
                        .font(.system(size: 13))
                    if !brief.closingNotes.referrals.isEmpty {
                        Text("Free legal help in NJ:")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.top, 4)
                        ForEach(brief.closingNotes.referrals) { ref in
                            if let url = URL(string: ref.url) {
                                Link(destination: url) {
                                    HStack(spacing: 4) {
                                        Text(ref.name).font(.system(size: 13))
                                        Image(systemName: "arrow.up.right").font(.system(size: 10))
                                    }
                                    .foregroundColor(.stevensRed)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionCard<Content: View>(title: String,
                                            icon: String,
                                            iconColor: Color = .stevensRed,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(iconColor)
                Text(title).font(.system(size: 16, weight: .semibold))
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    @ViewBuilder
    private func moneyRow(_ label: String, value: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: bold ? .semibold : .regular))
                .foregroundColor(bold ? .primary : .nexusSecondary)
            Spacer()
            Text(String(format: "$%.0f", value))
                .font(.system(size: 14, weight: bold ? .bold : .medium))
                .foregroundColor(bold ? .stevensRed : .primary)
        }
    }

    @ViewBuilder
    private func infoLine(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.nexusSecondary)
                .tracking(0.5)
            Text(value).font(.system(size: 13))
        }
    }

    @ViewBuilder
    private func redFlagCard(_ flag: RedFlag) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(flag.risk.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(flag.risk == "high" ? Color.stevensRed : Color(hex: "#c47c1a"))
                    .cornerRadius(999)
                Text(flag.label.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.nexusSecondary)
                Spacer()
            }
            Text(flag.headline).font(.system(size: 14, weight: .semibold))
            Text(flag.explanation).font(.system(size: 13)).foregroundColor(.primary)
            Text("\u{201C}\(flag.verbatimText)\u{201D}")
                .font(.system(size: 12, design: .serif))
                .italic()
                .foregroundColor(.nexusSecondary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding(12)
        .background(Color.stevensRed.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.stevensRed.opacity(0.2)))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func negotiationCard(_ neg: NegotiationOpening) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(neg.headline).font(.system(size: 14, weight: .semibold))
            Text(neg.draftMessage)
                .font(.system(size: 13))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#d8f3dc"))
                .cornerRadius(8)
            Text("Ask: \(neg.counterPosition)")
                .font(.system(size: 12))
                .foregroundColor(.nexusSecondary)
        }
        .padding(12)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#2D6A4F").opacity(0.2)))
        .cornerRadius(10)
    }
}

#Preview {
    LeaseAnalyzerSheet()
}
