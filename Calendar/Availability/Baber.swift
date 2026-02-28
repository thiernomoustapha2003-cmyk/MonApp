import Foundation

struct Barber: Identifiable, Codable {
    
    var id: String
    
    var name: String
    var city: String
    var description: String
    var photoURL: String
    
    var latitude: Double
    var longitude: Double
    
    var services: [BarberService]
    
    var isFavorite: Bool
    
    init(
        id: String = UUID().uuidString,
        name: String,
        city: String,
        description: String,
        photoURL: String,
        latitude: Double,
        longitude: Double,
        services: [BarberService],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.description = description
        self.photoURL = photoURL
        self.latitude = latitude
        self.longitude = longitude
        self.services = services
        self.isFavorite = isFavorite
    }
}
