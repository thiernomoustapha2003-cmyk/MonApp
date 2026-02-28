import Foundation

struct ClientNote: Identifiable, Codable {
    var id: String?
    var clientId: String
    var barberId: String
    var content: String
    var createdAt: Date
}
