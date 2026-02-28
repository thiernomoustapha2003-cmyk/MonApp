import Foundation

struct ReminderTime: Identifiable {
    let id = UUID()
    let bookingId: String
    let triggerDate: Date
    let type: String
}

final class ReminderEngine {

    static let shared = ReminderEngine()

    private init() {}

    // Calcule tous les rappels d’un RDV
    func buildReminders(
        bookingId: String,
        appointmentDate: Date,
        reminder24h: Bool,
        reminder2h: Bool,
        reminder30m: Bool
    ) -> [ReminderTime] {

        var reminders: [ReminderTime] = []

        if reminder24h {
            if let date = Calendar.current.date(byAdding: .hour, value: -24, to: appointmentDate) {
                reminders.append(ReminderTime(bookingId: bookingId, triggerDate: date, type: "24h"))
            }
        }

        if reminder2h {
            if let date = Calendar.current.date(byAdding: .hour, value: -2, to: appointmentDate) {
                reminders.append(ReminderTime(bookingId: bookingId, triggerDate: date, type: "2h"))
            }
        }

        if reminder30m {
            if let date = Calendar.current.date(byAdding: .minute, value: -30, to: appointmentDate) {
                reminders.append(ReminderTime(bookingId: bookingId, triggerDate: date, type: "30min"))
            }
        }

        return reminders
    }
}
