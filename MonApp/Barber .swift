import Foundation
import FirebaseFirestore

struct Barber: Identifiable, Codable {

    // 🔹 ID DU DOCUMENT FIRESTORE (TRÈS IMPORTANT)
    @DocumentID
    var id: String?

    // 🔹 ID D’AUTHENTIFICATION (CE QUE TU UTILISES POUR FILTRER LES SLOTS)
    var authId: String

    var name: String
    var city: String
    var description: String
    var price: Double

    var street: String
    var houseNumber: String
    var postalCode: String
    var phone: String
    var latitude: Double
    var longitude: Double

    // Liste des services
    var services: [String]

    var imageUrl: String?
    var isFavorite: Bool

    // =====================================================
    // ✅ NOUVEAUX CHAMPS (ON LES GARDE TOUS)
    // =====================================================

    var isPro: Bool
    var isCertified: Bool
    var acceptsOnlinePayment: Bool
    var platformCommissionRate: Double
    var stripeAccountId: String?
    var payoutEnabled: Bool

    var averageRating: Double
    var totalReviews: Int
    var isCurrentlyAvailable: Bool

    // =====================================================
    // ✅ INIT PROPRE ET COMPATIBLE FIRESTORE
    // =====================================================
    init(
        id: String? = nil,
        authId: String,
        name: String,
        city: String,
        description: String,
        price: Double,

        street: String,
        houseNumber: String,
        postalCode: String,
        phone: String,
        latitude: Double,
        longitude: Double,
        services: [String] = [],
        imageUrl: String? = nil,
        isFavorite: Bool = false,

        isPro: Bool = false,
        isCertified: Bool = false,
        acceptsOnlinePayment: Bool = false,
        platformCommissionRate: Double = 0.15,
        stripeAccountId: String? = nil,
        payoutEnabled: Bool = false,

        averageRating: Double = 0.0,
        totalReviews: Int = 0,
        isCurrentlyAvailable: Bool = true
    ) {
        self.id = id
        self.authId = authId
        self.name = name
        self.city = city
        self.description = description
        self.price = price

        self.street = street
        self.houseNumber = houseNumber
        self.postalCode = postalCode
        self.phone = phone
        self.latitude = latitude
        self.longitude = longitude
        self.services = services
        self.imageUrl = imageUrl
        self.isFavorite = isFavorite

        self.isPro = isPro
        self.isCertified = isCertified
        self.acceptsOnlinePayment = acceptsOnlinePayment
        self.platformCommissionRate = platformCommissionRate
        self.stripeAccountId = stripeAccountId
        self.payoutEnabled = payoutEnabled

        self.averageRating = averageRating
        self.totalReviews = totalReviews
        self.isCurrentlyAvailable = isCurrentlyAvailable
    }

    // =====================================================
    // ✅ CODING KEYS (POUR FIRESTORE)
    // =====================================================
    enum CodingKeys: String, CodingKey {
        case id
        case authId
        case name
        case city
        case description
        case price
        case street
        case houseNumber
        case postalCode
        case phone
        case latitude
        case longitude
        case services
        case imageUrl
        case isFavorite

        case isPro
        case isCertified
        case acceptsOnlinePayment
        case platformCommissionRate
        case stripeAccountId
        case payoutEnabled

        case averageRating
        case totalReviews
        case isCurrentlyAvailable
    }
}
