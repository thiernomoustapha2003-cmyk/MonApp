import Foundation

struct Client: Identifiable, Codable {
    var id: String?
    var userId: String
    var name: String
    var phone: String
    var email: String?
    var isBlacklisted: Bool
    var totalBookings: Int
    var createdAt: Date
}
