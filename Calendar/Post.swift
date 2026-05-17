import Foundation
import FirebaseFirestore
import FirebaseFirestore

struct Post: Identifiable, Codable {

    @DocumentID var id: String?

    // MARK: - Owner
    var creatorId: String?
    var creatorName: String?
    var creatorAvatar: String?

    // MARK: - Content
    var soundId: String?
    var mediaURL: String
    var thumbnailURL: String?
    var caption: String
    var type: PostType?

    // MARK: - Stats
    var likesCount: Int?
    var commentsCount: Int?
    var viewsCount: Int?
    var savesCount: Int?
    var sharesCount: Int?

    // MARK: - Monetization
    var earnings: Double?
    var isMonetized: Bool?

    var followersCount: Int?
    var engagementScore: Double?

    // MARK: - Meta
    @ServerTimestamp var createdAt: Date?
    var totalViews: Int?
    var countryStats: [String: Int]?


    // ================= SAFE HELPERS =================

    var safeCreatorId: String {
        creatorId ?? ""
    }

    var safeCreatorName: String {
        creatorName ?? "Utilisateur"
    }

    var safeCreatorAvatar: String {
        creatorAvatar ?? ""
    }

    var safeType: PostType {
        type ?? .video
    }

    var safeLikes: Int {
        likesCount ?? 0
    }

    var safeViews: Int {
        viewsCount ?? 0
    }

    var safeComments: Int {
        commentsCount ?? 0
    }

    var safeShares: Int {
        sharesCount ?? 0
    }
}

enum PostType: String, Codable {
    case image
    case video
    case liveReplay
}
