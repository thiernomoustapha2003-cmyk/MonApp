import Foundation
import FirebaseFirestore

struct Conversation: Identifiable, Codable {

    @DocumentID var id: String?

    var participants: [String]
    var lastMessage: String
    var lastMessageDate: Timestamp?
    var lastSenderId: String?

    var updatedAt: Timestamp?
    var createdAt: Timestamp?
}
