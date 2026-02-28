import Foundation
import UserNotifications

final class LocalNotificationManager {

    static let shared = LocalNotificationManager()
    private init() {}

    // Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("🔔 Local notification permission:", granted)
        }
    }

    // Planifier notification
    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        date: Date
    ) {

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification scheduling error:", error)
            } else {
                print("✅ Notification scheduled:", id)
            }
        }
    }

    // Supprimer notifications d’un booking
    func cancelNotifications(for bookingId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "\(bookingId)_24h",
            "\(bookingId)_2h",
            "\(bookingId)_30m"
        ])
    }
}
