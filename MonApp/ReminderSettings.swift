import Foundation

struct ReminderSettings: Codable {
    var enabled: Bool = true
    var hoursBefore: Int = 24
    var sendSMS: Bool = true
    var sendPush: Bool = true
}
