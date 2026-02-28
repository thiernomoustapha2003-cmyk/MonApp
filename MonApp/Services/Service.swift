import Foundation
import FirebaseFirestore


struct Service: Identifiable, Codable {
    var id: String?
    var name: String
    var price: Double
    var duration: Int
    var description: String
    var imageURLs: [String]
    var isPremium: Bool = false
    var isActive: Bool
    
    // ❤️ NOUVEAU
    var likesCount: Int = 0
    var likedBy: [String] = []
}
