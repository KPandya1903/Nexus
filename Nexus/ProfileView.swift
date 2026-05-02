import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var authState: AuthStateManager
    @AppStorage("ghostMode") private var ghostMode = false
    @State private var syncSchedule = true
    @State private var showTransactions = false
    @State private var showAddFunds = false
    @State private var showPeerConnect = false
    @State private var showEditProfile = false

    var fullName: String { authState.userProfile["fullName"] as? String ?? "Stevens Student" }
    var major: String { authState.userProfile["major"] as? String ?? "Computer Science" }
    var year: String { authState.userProfile["year"] as? String ?? "" }
    var gradSemester: String { authState.userProfile["gradSemester"] as? String ?? "" }
    var github: String { authState.userProfile["github"] as? String ?? "" }
    var about: String { authState.userProfile["about"] as? String ?? "" }
    var walletBalance: Double { authState.userProfile["walletBalance"] as? Double ?? 20.0 }

    var initials: String {
        fullName.split(separator: " ").compactMap { $0.first }.map { String($0) }.prefix(2).joined()
    }

    var subtitle: String {
        [major, year, gradSemester].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Profile Hero
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.stevensRed, Color.primaryContainer],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 88, height: 88)
                                .overlay(
                                    Text(initials.isEmpty ? "?" : initials)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(color: .stevensRed.opacity(0.3), radius: 8, y: 4)

                            Circle()
                                .fill(ghostMode ? Color.red : Color.green)
                                .frame(width: 18, height: 18)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }

                        Text(fullName)
                            .font(.system(size: 20, weight: .semibold))

                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.nexusSecondary)
                            .multilineTextAlignment(.center)

                        if !github.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .font(.system(size: 12))
                                Text("github.com/\(github)")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.stevensRed)
                        }

                        if !about.isEmpty {
                            Text(about)
                                .font(.system(size: 14))
                                .foregroundColor(.nexusSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 8)

                    // Wallet Card
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 130, height: 130)
                            .blur(radius: 25)
                            .offset(x: 20, y: -20)

                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("NEXUS WALLET")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .tracking(2)

                                    Text(String(format: "$%.2f", walletBalance))
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Image(systemName: "wallet.pass")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(10)
                            }

                            Spacer().frame(height: 20)

                            HStack(spacing: 12) {
                                Button(action: { showAddFunds = true }) {
                                    Label("Add Funds", systemImage: "plus.circle.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.stevensRed)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .cornerRadius(999)
                                }

                                Button(action: { showTransactions = true }) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(999)
                                }
                            }
                        }
                        .padding(20)
                    }
                    .background(Color.primaryContainer)
                    .cornerRadius(16)
                    .shadow(color: .stevensRed.opacity(0.2), radius: 10, y: 5)

                    // Find Peers card
                    Button(action: { showPeerConnect = true }) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "person.2.wave.2.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Find Stevens Peers")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Match by major, events, and GitHub themes")
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
                                colors: [Color(hex: "#1a6b9a"), Color(hex: "#0d3b4f")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "#1a6b9a").opacity(0.3), radius: 8, y: 4)
                    }

                    // Preferences
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences")
                            .font(.system(size: 17, weight: .semibold))

                        VStack(spacing: 0) {
                            PreferenceRow(
                                icon: "eye.slash", title: "Ghost Mode",
                                subtitle: "Hide location from campus map",
                                isToggle: true, toggleValue: $ghostMode
                            )
                            Divider().padding(.leading, 60)

                            PreferenceRow(
                                icon: "arrow.triangle.2.circlepath", title: "Sync Schedule",
                                subtitle: "Auto-update from Workday",
                                isToggle: true, toggleValue: $syncSchedule
                            )
                            Divider().padding(.leading, 60)

                            PreferenceRow(
                                icon: "gearshape.circle", title: "Edit Profile",
                                subtitle: nil,
                                isToggle: false, toggleValue: .constant(false),
                                onTap: { showEditProfile = true }
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }

                    // Sign Out
                    Button(action: { authState.signOut() }) {
                        Text("Sign Out")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.stevensRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .padding(.bottom, 8)
                }
                .padding(16)
            }
            .background(Color.nexusSurface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NexusTopBar()
                }
            }
            .sheet(isPresented: $showAddFunds) {
                AddFundsSheet(currentBalance: walletBalance)
            }
            .sheet(isPresented: $showPeerConnect) {
                PeerConnectView()
                    .environmentObject(authState)
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet()
                    .environmentObject(authState)
            }
            .sheet(isPresented: $showTransactions) {
                TransactionHistorySheet(currentBalance: walletBalance)
            }
        }
    }
}

// MARK: - Transaction History Sheet

struct TransactionHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let currentBalance: Double

    private let transactions: [(String, String, Double, Color)] = [
        ("Add Funds (Card)",        "Today · 11:08 PM",     50.00,  Color(hex: "#2D6A4F")),
        ("Lease Verification — Hudson St", "2 days ago",    -15.00, .stevensRed),
        ("Bounty Earned — Pierce Rd",      "5 days ago",     20.00, Color(hex: "#2D6A4F")),
        ("Add Funds (Apple Pay)",         "1 week ago",      25.00, Color(hex: "#2D6A4F")),
        ("Lease Verification — Park Ave",  "2 weeks ago",   -10.00, .stevensRed),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CURRENT BALANCE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .tracking(1)
                        Text(String(format: "$%.2f", currentBalance))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(LinearGradient(colors: [.stevensRed, .primaryContainer],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(16)

                    VStack(spacing: 0) {
                        ForEach(0..<transactions.count, id: \.self) { i in
                            let t = transactions[i]
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.0).font(.system(size: 14, weight: .medium))
                                    Text(t.1).font(.system(size: 12)).foregroundColor(.nexusSecondary)
                                }
                                Spacer()
                                Text(String(format: "%@$%.2f", t.2 >= 0 ? "+" : "", t.2))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(t.3)
                            }
                            .padding(14)
                            if i != transactions.count - 1 {
                                Divider().padding(.leading, 14)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }
                .padding(16)
            }
            .background(Color.nexusSurface)
            .navigationTitle("Transaction History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct PreferenceRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isToggle: Bool
    @Binding var toggleValue: Bool
    var onTap: (() -> Void)? = nil

    private var rowContent: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.nexusSecondary)
                .frame(width: 38, height: 38)
                .background(Color.surfaceContainerLow)
                .cornerRadius(999)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.nexusSecondary)
                }
            }

            Spacer()

            if isToggle {
                Toggle("", isOn: $toggleValue)
                    .labelsHidden()
                    .tint(.stevensRed)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.4))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    var body: some View {
        if !isToggle, let onTap = onTap {
            Button(action: onTap) { rowContent }
                .buttonStyle(.plain)
        } else {
            rowContent
        }
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @EnvironmentObject var authState: AuthStateManager
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var major: String = ""
    @State private var year: String = "Junior"
    @State private var gradSemester: String = "Spring 2026"
    @State private var github: String = ""
    @State private var about: String = ""
    @State private var isSaving = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Basic
                    FormSection(title: "Basic Info") {
                        FormField(icon: "person", placeholder: "Full Name", text: $fullName)

                        Divider().padding(.leading, 40)

                        HStack {
                            Image(systemName: "graduationcap")
                                .foregroundColor(.nexusSecondary)
                                .frame(width: 20)
                            Picker("Major", selection: $major) {
                                Text("Select Major").tag("")
                                ForEach(majorOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(.stevensRed)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)

                        Divider().padding(.leading, 40)

                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.nexusSecondary)
                                .frame(width: 20)
                            Picker("Year", selection: $year) {
                                ForEach(yearOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(.stevensRed)

                            Divider().frame(height: 20)

                            Picker("Graduation", selection: $gradSemester) {
                                ForEach(gradOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(.stevensRed)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }

                    // GitHub
                    FormSection(title: "Links") {
                        HStack {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .foregroundColor(.nexusSecondary)
                                .frame(width: 20)
                            TextField("GitHub username (e.g. jhanvi07)", text: $github)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        .padding(14)
                    }

                    // About
                    FormSection(title: "About You") {
                        HStack(alignment: .top) {
                            Image(systemName: "text.quote")
                                .foregroundColor(.nexusSecondary)
                                .frame(width: 20)
                                .padding(.top, 4)
                            TextField("Tell your peers about yourself, your interests, projects...",
                                      text: $about, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        .padding(14)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }

                    Button(action: save) {
                        Group {
                            if isSaving {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save Changes")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSave ? Color.stevensRed : Color.gray)
                        .cornerRadius(14)
                    }
                    .disabled(!canSave || isSaving)
                    .padding(.bottom, 12)
                }
                .padding(16)
            }
            .background(Color.nexusSurface)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { populateFromAuthState() }
        }
    }

    private var canSave: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !major.isEmpty
    }

    private func populateFromAuthState() {
        fullName = authState.userProfile["fullName"] as? String ?? ""
        major = authState.userProfile["major"] as? String ?? ""
        year = authState.userProfile["year"] as? String ?? "Junior"
        gradSemester = authState.userProfile["gradSemester"] as? String ?? "Spring 2026"
        github = authState.userProfile["github"] as? String ?? ""
        about = authState.userProfile["about"] as? String ?? ""
    }

    private func save() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Not signed in."
            return
        }
        isSaving = true
        errorMessage = ""

        let data: [String: Any] = [
            "fullName":     fullName,
            "major":        major,
            "year":         year,
            "gradSemester": gradSemester,
            "github":       github,
            "about":        about
        ]

        Firestore.firestore().collection("users").document(uid).updateData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                // Mutate locally so the UI updates instantly + re-fetch for safety
                for (k, v) in data { authState.userProfile[k] = v }
                authState.fetchProfile(uid: uid)
                dismiss()
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthStateManager())
}
