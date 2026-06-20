import Foundation
import FirebaseFirestore

struct Conversation: Identifiable, Codable {

    @DocumentID var id: String?

    var participants: [String]

    var clientId: String?
    var barberId: String?

    var lastMessage: String
    var lastMessageDate: Timestamp?
    var lastSenderId: String?

    // 🔵 Non lus / vus
    var unreadFor: [String]?
    var unreadCounts: [String: Int]?
    var seenBy: [String]?

    // 🔥 Pour futur WhatsApp-like : texte, image, vidéo, vocal, lien
    var lastMessageType: String?
    var lastMessagePreview: String?

    var updatedAt: Timestamp?
    var createdAt: Timestamp?
}
