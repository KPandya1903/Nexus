import UserNotifications
import UIKit

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private var demoTimer: Timer?
    private var demoIndex = 0

    func requestPermission() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                let userDefaults = UserDefaults.standard
                let shouldStart = userDefaults.object(forKey: "notificationsEnabled") == nil ||
                                  userDefaults.bool(forKey: "notificationsEnabled")
                if shouldStart {
                    DispatchQueue.main.async {
                        self.startDemoNotifications()
                    }
                }
            }
        }
    }

    // Make banners visible while app is in foreground (demo)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    // MARK: - Per-event reminders (registered events)

    func scheduleEventReminders(for event: CampusEvent) {
        guard let eventDate = parseEventDate(date: event.date, time: event.time) else { return }

        if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: eventDate),
           dayBefore > Date() {
            schedule(
                id: "\(event.id)-day",
                title: "Tomorrow: \(event.eventName)",
                body: "\(event.formattedTime) at \(event.location)",
                date: dayBefore
            )
        }
        if let hourBefore = Calendar.current.date(byAdding: .hour, value: -1, to: eventDate),
           hourBefore > Date() {
            schedule(
                id: "\(event.id)-hour",
                title: "Starting soon: \(event.eventName)",
                body: "In 1 hour at \(event.location)",
                date: hourBefore
            )
        }
    }

    func cancelReminders(for eventID: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["\(eventID)-day", "\(eventID)-hour"]
        )
    }

    // MARK: - Demo: fire one notification every 20 seconds, rotating content

    func startDemoNotifications() {
        demoTimer?.invalidate()
        demoIndex = 0
        // Fire first one quickly so judges see one within ~5s of opening the app
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.fireNextDemoNotification()
        }
        demoTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            self?.fireNextDemoNotification()
        }
    }

    func stopDemoNotifications() {
        demoTimer?.invalidate()
        demoTimer = nil
    }

    private func fireNextDemoNotification() {
        let item = demoNotifications[demoIndex % demoNotifications.count]
        demoIndex += 1

        let content = UNMutableNotificationContent()
        content.title = item.title
        content.body = item.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "demo-\(demoIndex)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Internals

    private func schedule(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func parseEventDate(date: String, time: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: "\(date) \(time)")
    }
}

// MARK: - Demo notification rotation

private struct DemoNotification {
    let title: String
    let body: String
}

private let demoNotifications: [DemoNotification] = [
    // Reminders for registered events
    DemoNotification(
        title: "🎯 Tomorrow: Career Fair",
        body: "Walker Gymnasium · 11:00 AM. 60+ employers. Bring 20 résumés."
    ),
    DemoNotification(
        title: "⏰ Starting in 1 hour",
        body: "AI Paper Reading Group — Carnegie Lab 315. You're registered."
    ),
    // Friends registered
    DemoNotification(
        title: "👥 7 friends just registered",
        body: "Priya, Marcus, and 5 others are going to South Asian Cultural Night — Mehfil this Saturday."
    ),
    DemoNotification(
        title: "👥 5 friends registered",
        body: "Aisha, Sofia, Raj, and 2 others are attending the Robotics Showcase."
    ),
    // Limited seats
    DemoNotification(
        title: "🔥 Only 3 seats left",
        body: "Quant Interview Mock Series — Brain Teasers at Babbio 122. Sign up before it fills."
    ),
    DemoNotification(
        title: "🔥 Filling fast: 8 spots remaining",
        body: "SWiCS End-of-Semester Brunch — full-time CS seniors will be there."
    ),
    // Upcoming
    DemoNotification(
        title: "📅 New event near you",
        body: "Therapy Dogs at UCC Lobby starts in 2 hours. No registration needed."
    ),
    DemoNotification(
        title: "🎤 Tonight at 7 PM",
        body: "Goldman Sachs Quant Strategist talk — Babbio 122. MSFE alumni speaker."
    ),
    // Friends interested
    DemoNotification(
        title: "✨ 9 friends are interested",
        body: "Spring Carnival on May 23 — Castle Point Lawn. Food trucks, live music, free swag."
    ),
    DemoNotification(
        title: "🎫 Registration closes in 24h",
        body: "AIChE Pre-Industry Networking Dinner — BASF, Merck, Pfizer alumni attending."
    ),
    // Generic but useful
    DemoNotification(
        title: "🆕 Lisa Fu posted a new lab opening",
        body: "Real-time mobile event pipelines — RA position. Tap to view profile."
    ),
    DemoNotification(
        title: "📍 Sofia is in your building",
        body: "Sofia Martinez (CS Junior) is currently in Babbio. Say hi?"
    ),
]
