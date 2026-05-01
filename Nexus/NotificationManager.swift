import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleEventReminders(for event: CampusEvent) {
        guard let eventDate = parseEventDate(date: event.date, time: event.time) else { return }

        // 1 day before
        if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: eventDate),
           dayBefore > Date() {
            schedule(
                id: "\(event.id)-day",
                title: "Tomorrow: \(event.eventName)",
                body: "\(event.formattedTime) at \(event.location)",
                date: dayBefore
            )
        }

        // 1 hour before
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
