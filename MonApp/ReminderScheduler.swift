import Foundation

final class ReminderScheduler {

    static let shared = ReminderScheduler()
    private init() {}

    func scheduleReminders(
        bookingId: String,
        barberId: String,
        appointmentDate: Date
    ) {

        let now = Date()

        // 24h avant
        if let d1 = Calendar.current.date(byAdding: .hour, value: -24, to: appointmentDate),
           d1 > now {

            LocalNotificationManager.shared.scheduleNotification(
                id: "\(bookingId)_24h",
                title: "Rappel rendez-vous",
                body: "Vous avez rendez-vous demain ✂️",
                date: d1
            )
        }

        // 2h avant
        if let d2 = Calendar.current.date(byAdding: .hour, value: -2, to: appointmentDate),
           d2 > now {

            LocalNotificationManager.shared.scheduleNotification(
                id: "\(bookingId)_2h",
                title: "Rappel rendez-vous",
                body: "Votre rendez-vous est dans 2 heures ✂️",
                date: d2
            )
        }

        // 30 min avant
        if let d3 = Calendar.current.date(byAdding: .minute, value: -30, to: appointmentDate),
           d3 > now {

            LocalNotificationManager.shared.scheduleNotification(
                id: "\(bookingId)_30m",
                title: "C’est bientôt !",
                body: "Votre rendez-vous commence dans 30 minutes ⏰",
                date: d3
            )
        }

        print("🔔 Rappels programmés pour", bookingId)
    }
}
