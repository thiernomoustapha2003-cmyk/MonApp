import Foundation

struct Barber: Identifiable, Codable {
    var price: Double


    var id: String
    var name: String
    var city: String
    var description: String

    var photoURL: String?
    var imageURL: String?

    var latitude: Double
    var longitude: Double

    var services: [BarberServiceModel]?
    var isFavorite: Bool?

    init(
        id: String = UUID().uuidString,
        name: String,
        city: String,
        description: String,
        prince: Double,
        photoURL: String? = nil,
        imageURL: String? = nil,
        latitude: Double,
        longitude: Double,
        services: [BarberServiceModel]? = nil,
        isFavorite: Bool? = false
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.description = description
        self.price = prince
        self.photoURL = photoURL
        self.imageURL = imageURL
        self.latitude = latitude
        self.longitude = longitude
        self.services = services
        self.isFavorite = isFavorite
    }
}
