import Foundation

struct BarberService: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var minPrice: Double
    var maxPrice: Double
}
