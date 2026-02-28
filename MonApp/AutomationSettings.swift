import Foundation
import FirebaseFirestore

struct AutomationSettings: Codable {

    var autoReminder: Bool = false
    var autoConfirm: Bool = false
    var afterMessage: Bool = false
    var autoBlockSlots: Bool = false
    var calendarSync: Bool = false
    var aiAnalysis: Bool = false

    init() {}

    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }

        self.autoReminder = data["autoReminder"] as? Bool ?? false
        self.autoConfirm = data["autoConfirm"] as? Bool ?? false
        self.afterMessage = data["afterMessage"] as? Bool ?? false
        self.autoBlockSlots = data["autoBlockSlots"] as? Bool ?? false
        self.calendarSync = data["calendarSync"] as? Bool ?? false
        self.aiAnalysis = data["aiAnalysis"] as? Bool ?? false
    }

    var dictionary: [String: Any] {
        return [
            "autoReminder": autoReminder,
            "autoConfirm": autoConfirm,
            "afterMessage": afterMessage,
            "autoBlockSlots": autoBlockSlots,
            "calendarSync": calendarSync,
            "aiAnalysis": aiAnalysis
        ]
    }
}
