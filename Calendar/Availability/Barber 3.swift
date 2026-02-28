import Foundation

struct Barber: Identifiable, Codable {
    
    var id: String = UUID().uuidString
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
    
    // Liste des services (nom des services)
    var services: [String]
    
    var imageUrl: String?
    var isFavorite: Bool

    // =====================================================
    // ✅ NOUVEAUX CHAMPS (AJOUTÉS — SANS RIEN SUPPRIMER)
    // =====================================================

    /// ✅ Coiffeur PRO ou non (important pour paiement en ligne)
    var isPro: Bool

    /// ✅ Coiffeur certifié (documents vérifiés par toi)
    var isCertified: Bool

    /// ✅ Autorise le paiement en ligne (seulement si Pro + Certifié)
    var acceptsOnlinePayment: Bool

    /// ✅ Pourcentage que TU prends sur chaque paiement (ex: 15%)
    var platformCommissionRate: Double

    /// ✅ Compte Stripe du coiffeur (sera rempli plus tard)
    var stripeAccountId: String?

    /// ✅ Indique si le coiffeur peut être payé automatiquement
    var payoutEnabled: Bool

    // =====================================================
    // ✅ NOUVEAUX CHAMPS (IMPORTANTS POUR TON APP)
    // =====================================================

    /// ⭐ Note moyenne du coiffeur (ex : 4.5)
    var averageRating: Double

    /// 💬 Nombre total d’avis reçus
    var totalReviews: Int

    /// 🟢 Indique si le coiffeur est actuellement disponible
    var isCurrentlyAvailable: Bool

    // =====================================================
    // ✅ INIT COMPLET (PROPRE) — TOUT CONSERVÉ + AJOUTS
    // =====================================================
    init(
        id: String = UUID().uuidString,
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

        // 🔽 NOUVEAUX PARAMÈTRES (AVEC VALEURS PAR DÉFAUT)
        isPro: Bool = false,
        isCertified: Bool = false,
        acceptsOnlinePayment: Bool = false,
        platformCommissionRate: Double = 0.15,
        stripeAccountId: String? = nil,
        payoutEnabled: Bool = false,

        // 🔽 AJOUTS POUR TON DASHBOARD PRO
        averageRating: Double = 0.0,
        totalReviews: Int = 0,
        isCurrentlyAvailable: Bool = true
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.description = description
        self.price = price
        self.phone = phone
        
        self.street = street
        self.houseNumber = houseNumber
        self.postalCode = postalCode
    
        self.latitude = latitude
        self.longitude = longitude
        self.services = services
        self.imageUrl = imageUrl
        self.isFavorite = isFavorite

        // 🔽 ASSIGNATION DES NOUVEAUX CHAMPS (TA VERSION — GARDÉE)
        self.isPro = isPro
        self.isCertified = isCertified
        self.acceptsOnlinePayment = acceptsOnlinePayment
        self.platformCommissionRate = platformCommissionRate
        self.stripeAccountId = stripeAccountId
        self.payoutEnabled = payoutEnabled

        // 🔽 ASSIGNATION DES AJOUTS (POUR TON APP PRO)
        self.averageRating = averageRating
        self.totalReviews = totalReviews
        self.isCurrentlyAvailable = isCurrentlyAvailable
    }

    // =====================================================
    // ✅ CODING KEYS (IMPORTANT POUR FIRESTORE)
    // =====================================================
    enum CodingKeys: String, CodingKey {
        case id
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
