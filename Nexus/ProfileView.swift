import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authState: AuthStateManager
    @State private var ghostMode = false
    @State private var syncSchedule = true
    @State private var showAddFunds = false

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
                                .fill(Color.green)
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

                                Button(action: {}) {
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
                                isToggle: false, toggleValue: .constant(false)
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
        }
    }
}

struct PreferenceRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isToggle: Bool
    @Binding var toggleValue: Bool

    var body: some View {
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
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthStateManager())
}
