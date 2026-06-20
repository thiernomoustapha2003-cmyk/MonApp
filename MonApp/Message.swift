import Foundation

struct Message: Identifiable {

    var id: String

    var senderId: String
    var senderName: String
    var senderAvatar: String?

    var text: String
    var type: String

    // 🔥 Médias
    var imageUrl: String?
    var videoUrl: String?
    var audioUrl: String?
    var audioDuration: Double?

    var timestamp: Date

    var seenBy: [String]
    var listenedBy: [String]
    var deletedFor: [String]
    
    // 🔒 Vue unique
    var isViewOnce: Bool = false
    var openedBy: [String]
    var opened: Bool = false
    var openedAt: Date?
    

    // 🔥 Réactions emoji
    var reactions: [String: String]
    var isPinned: Bool
    
    
    // 🔥 Réponse à un message
    var replyToMessageId: String?
    var replyToText: String?
    var replyToSender: String?
}
