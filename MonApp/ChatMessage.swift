import Foundation
import FirebaseFirestore
import FirebaseAuth

struct ChatMessage: Identifiable, Hashable {

    var id: String
    var text: String
    var senderId: String
    var createdAt: Date

    // 🧠 Détermine si le message vient de moi
    var isMine: Bool {
        return senderId == Auth.auth().currentUser?.uid
    }

    init(id: String, text: String, senderId: String, createdAt: Date) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.createdAt = createdAt
    }

    // 🔥 Création depuis Firestore
    static func fromFirestore(id: String, data: [String: Any]) -> ChatMessage? {

        guard
            let text = data["text"] as? String,
            let senderId = data["senderId"] as? String,
            let timestamp = data["createdAt"] as? Timestamp
        else { return nil }

        return ChatMessage(
            id: id,
            text: text,
            senderId: senderId,
            createdAt: timestamp.dateValue()
        )
    }
}
