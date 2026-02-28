import Foundation
import FirebaseFirestore

struct Post: Identifiable, Codable {

    @DocumentID var id: String?

    // propriétaire
    var creatorId: String
    var creatorName: String
    var creatorAvatar: String

    // contenu
    var mediaURL: String
    var thumbnailURL: String?
    var caption: String
    var type: PostType

    // stats publiques
    var likesCount: Int
    var commentsCount: Int
    var viewsCount: Int
    var savesCount: Int

    // monétisation
    var earnings: Double?
    var isMonetized: Bool?

    // meta
    @ServerTimestamp var createdAt: Date?
    
    var totalViews: Int?
        var countryStats: [String: Int]?
}

enum PostType: String, Codable {
    case image
    case video
    case liveReplay
}
