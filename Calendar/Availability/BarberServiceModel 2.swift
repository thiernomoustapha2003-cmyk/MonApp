import Foundation

struct BarberServiceModel: Identifiable, Codable {

    var id: String
    var name: String
    var price: Double

    init(id: String = UUID().uuidString, name: String, price: Double) {
        self.id = id
        self.name = name
        self.price = price
    }
}
