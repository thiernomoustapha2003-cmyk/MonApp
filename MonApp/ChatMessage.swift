import Foundation
import FirebaseFirestore
import FirebaseAuth

struct ChatMessage: Identifiable, Hashable {

    var id: String
    var text: String
    var senderId: String
    var senderName: String
    var senderAvatar: String?
    var type: MessageType
    var createdAt: Date

    // 🧠 message venant de moi
    var isMine: Bool {
        senderId == Auth.auth().currentUser?.uid
    }

    // 🎯 TYPES (comme TikTok)
    enum MessageType: String {
        case text
        case join
        case like
        case system
    }

    init(
        id: String,
        text: String,
        senderId: String,
        senderName: String,
        senderAvatar: String? = nil,
        type: MessageType = .text,
        createdAt: Date
    ) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.senderName = senderName
        self.senderAvatar = senderAvatar
        self.type = type
        self.createdAt = createdAt
    }

    // 🔥 FIRESTORE → MODEL
    static func fromFirestore(id: String, data: [String: Any]) -> ChatMessage? {

        guard
            let senderId = data["senderId"] as? String,
            let timestamp = data["createdAt"] as? Timestamp
        else { return nil }

        let text = data["text"] as? String ?? ""
        let senderName = data["senderName"] as? String ?? "Utilisateur"
        let senderAvatar = data["senderAvatar"] as? String
        let typeRaw = data["type"] as? String ?? "text"

        let type = MessageType(rawValue: typeRaw) ?? .text

        return ChatMessage(
            id: id,
            text: text,
            senderId: senderId,
            senderName: senderName,
            senderAvatar: senderAvatar,
            type: type,
            createdAt: timestamp.dateValue()
        )
    }
}
