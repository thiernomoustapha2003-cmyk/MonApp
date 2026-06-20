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

    // TikTok-style extra
    var isVIP: Bool
    var isModerator: Bool
    var senderLevel: Int
    var badgeText: String?
    var giftName: String?
    var giftCoins: Int?

    var isMine: Bool {
        senderId == Auth.auth().currentUser?.uid
    }

    enum MessageType: String {
        case text
        case join
        case like
        case system
        case gift
        case request
    }

    init(
        id: String,
        text: String,
        senderId: String,
        senderName: String,
        senderAvatar: String? = nil,
        type: MessageType = .text,
        createdAt: Date,
        isVIP: Bool = false,
        isModerator: Bool = false,
        senderLevel: Int = 0,
        badgeText: String? = nil,
        giftName: String? = nil,
        giftCoins: Int? = nil
    ) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.senderName = senderName
        self.senderAvatar = senderAvatar
        self.type = type
        self.createdAt = createdAt
        self.isVIP = isVIP
        self.isModerator = isModerator
        self.senderLevel = senderLevel
        self.badgeText = badgeText
        self.giftName = giftName
        self.giftCoins = giftCoins
    }

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
            createdAt: timestamp.dateValue(),
            isVIP: data["isVIP"] as? Bool ?? false,
            isModerator: data["isModerator"] as? Bool ?? false,
            senderLevel: data["senderLevel"] as? Int ?? 0,
            badgeText: data["badgeText"] as? String,
            giftName: data["giftName"] as? String,
            giftCoins: data["giftCoins"] as? Int
        )
    }
}
