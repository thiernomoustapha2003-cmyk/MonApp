import Foundation
import FirebaseFirestore

struct Sound: Identifiable, Codable {
    
    @DocumentID var id: String?
    
    var audioURL: String
    var creatorId: String
    var title: String
    
    var usageCount: Int
    var totalViews: Int
    var totalRevenue: Double
    
    var createdAt: Date?
}
