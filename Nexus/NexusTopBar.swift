import SwiftUI
import UserNotifications

struct NexusTopBar: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.stevensRed, Color.primaryContainer],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Text("N")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white)
                    )

                Text("The Stevens Nexus")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.stevensRed)
                    .tracking(-0.5)
            }
            Spacer()
            Button(action: toggleNotifications) {
                Image(systemName: notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                    .foregroundColor(.stevensRed)
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(Divider(), alignment: .bottom)
    }

    private func toggleNotifications() {
        notificationsEnabled.toggle()
        if notificationsEnabled {
            NotificationManager.shared.startDemoNotifications()
        } else {
            NotificationManager.shared.stopDemoNotifications()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
}
