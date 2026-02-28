import Foundation

struct Review: Identifiable {
    var id: String
    var barberId: String
    var clientName: String
    var rating: Int
    var comment: String
}
