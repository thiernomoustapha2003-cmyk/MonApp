import Foundation
import FirebaseFirestore

struct DeviceSession: Identifiable {

    let id: String
    let deviceId: String
    let deviceName: String
    let iosVersion: String
    let lastActive: Date

    // 👇 IMPORTANT : le nom doit correspondre à la View
    var lastActiveFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Actif le \(formatter.string(from: lastActive))"
    }

    init?(document: QueryDocumentSnapshot) {

        let data = document.data()

        guard
            let deviceId = data["deviceId"] as? String,
            let name = data["deviceName"] as? String,
            let ios = data["iosVersion"] as? String,
            let timestamp = data["lastActive"] as? Timestamp
        else { return nil }

        self.id = document.documentID
        self.deviceId = deviceId
        self.deviceName = name
        self.iosVersion = ios
        self.lastActive = timestamp.dateValue()
    }
}
