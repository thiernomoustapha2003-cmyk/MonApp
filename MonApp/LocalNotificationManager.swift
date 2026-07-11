import Foundation
import UserNotifications

final class LocalNotificationManager {

    static let shared = LocalNotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized ||
               settings.authorizationStatus == .provisional ||
               settings.authorizationStatus == .ephemeral {

                print("✅ Local notifications déjà autorisées")
                return
            }

            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in

                if let error = error {
                    print("❌ Local notification permission error:", error.localizedDescription)
                    return
                }

                print("🔔 Local notification permission:", granted)
            }
        }
    }

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

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification scheduling error:", error.localizedDescription)
            } else {
                print("✅ Notification scheduled:", id)
            }
        }
    }

    func cancelNotifications(for bookingId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "\(bookingId)_24h",
                "\(bookingId)_2h",
                "\(bookingId)_30m"
            ]
        )
    }
}
