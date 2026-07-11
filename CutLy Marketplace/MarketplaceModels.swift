//
//  MarketplaceModels.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Marketplace Root Namespace

enum MarketplaceNamespace {
    static let version = "1.0.0"
    static let moduleName = "Cutly Marketplace"
}

// MARK: - Product Status

enum MarketplaceProductStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case active
    case paused
    case soldOut
    case underReview
    case rejected
    case banned
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draft: return "Brouillon"
        case .active: return "Actif"
        case .paused: return "En pause"
        case .soldOut: return "Rupture"
        case .underReview: return "En vérification"
        case .rejected: return "Refusé"
        case .banned: return "Banni"
        case .archived: return "Archivé"
        }
    }
}

// MARK: - Product Condition

enum MarketplaceProductCondition: String, Codable, CaseIterable, Identifiable {
    case new
    case likeNew
    case veryGood
    case good
    case fair
    case refurbished

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: return "Neuf"
        case .likeNew: return "Comme neuf"
        case .veryGood: return "Très bon état"
        case .good: return "Bon état"
        case .fair: return "Correct"
        case .refurbished: return "Reconditionné"
        }
    }
}

// MARK: - Currency

enum MarketplaceCurrency: String, Codable, CaseIterable, Identifiable {
    case eur = "EUR"
    case usd = "USD"
    case gbp = "GBP"
    case gnf = "GNF"
    case xof = "XOF"
    case xaf = "XAF"
    case mad = "MAD"
    case ngn = "NGN"
    case ghs = "GHS"
    case kes = "KES"
    case zar = "ZAR"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .eur: return "€"
        case .usd: return "$"
        case .gbp: return "£"
        case .gnf: return "GNF"
        case .xof: return "XOF"
        case .xaf: return "XAF"
        case .mad: return "MAD"
        case .ngn: return "₦"
        case .ghs: return "₵"
        case .kes: return "KSh"
        case .zar: return "R"
        }
    }
}

// MARK: - Marketplace Price

struct MarketplacePrice: Codable, Hashable {
    var amount: Double
    var currency: MarketplaceCurrency
    var originalAmount: Double?
    var discountPercent: Double?
    var isNegotiable: Bool

    init(
        amount: Double,
        currency: MarketplaceCurrency = .eur,
        originalAmount: Double? = nil,
        discountPercent: Double? = nil,
        isNegotiable: Bool = false
    ) {
        self.amount = amount
        self.currency = currency
        self.originalAmount = originalAmount
        self.discountPercent = discountPercent
        self.isNegotiable = isNegotiable
    }

    var formatted: String {
        let cleanAmount = amount.truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.0f", amount)
        : String(format: "%.2f", amount)

        switch currency {
        case .eur, .usd, .gbp:
            return "\(cleanAmount) \(currency.symbol)"
        default:
            return "\(cleanAmount) \(currency.rawValue)"
        }
    }
}

// MARK: - Product Image / Media

enum MarketplaceMediaType: String, Codable, CaseIterable, Identifiable {
    case image
    case video
    case threeSixty
    case thumbnail

    var id: String { rawValue }
}

struct MarketplaceProductMedia: Codable, Identifiable, Hashable {
    var id: String
    var url: String
    var thumbnailURL: String?
    var type: MarketplaceMediaType
    var position: Int
    var isMain: Bool
    var width: Double?
    var height: Double?
    var duration: Double?
    var aiQualityScore: Double?
    var aiWarning: String?

    init(
        id: String = UUID().uuidString,
        url: String,
        thumbnailURL: String? = nil,
        type: MarketplaceMediaType = .image,
        position: Int = 0,
        isMain: Bool = false,
        width: Double? = nil,
        height: Double? = nil,
        duration: Double? = nil,
        aiQualityScore: Double? = nil,
        aiWarning: String? = nil
    ) {
        self.id = id
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.type = type
        self.position = position
        self.isMain = isMain
        self.width = width
        self.height = height
        self.duration = duration
        self.aiQualityScore = aiQualityScore
        self.aiWarning = aiWarning
    }
}

// MARK: - Product Variant

struct MarketplaceProductVariant: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var value: String

    var color: String?
    var colorName: String?
    var colorHex: String?
    var size: String?

    var sku: String?
    var barcode: String?
    var stock: Int
    var priceAdjustment: Double?
    var imageURL: String?
    var imageURLs: [String]?

    init(
        id: String = UUID().uuidString,
        name: String,
        value: String,
        color: String? = nil,
        colorName: String? = nil,
        colorHex: String? = nil,
        size: String? = nil,
        sku: String? = nil,
        barcode: String? = nil,
        stock: Int = 0,
        priceAdjustment: Double? = nil,
        imageURL: String? = nil,
        imageURLs: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.color = color
        self.colorName = colorName
        self.colorHex = colorHex
        self.size = size
        self.sku = sku
        self.barcode = barcode
        self.stock = stock
        self.priceAdjustment = priceAdjustment
        self.imageURL = imageURL
        self.imageURLs = imageURLs
    }
}

// MARK: - Product Dimensions

struct MarketplaceProductDimensions: Codable, Hashable {
    var weightKg: Double?
    var lengthCm: Double?
    var widthCm: Double?
    var heightCm: Double?

    init(
        weightKg: Double? = nil,
        lengthCm: Double? = nil,
        widthCm: Double? = nil,
        heightCm: Double? = nil
    ) {
        self.weightKg = weightKg
        self.lengthCm = lengthCm
        self.widthCm = widthCm
        self.heightCm = heightCm
    }
}
// MARK: - Marketplace Product

struct MarketplaceProduct: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var sellerId: String
    var storeId: String?

    var title: String
    var subtitle: String?
    var description: String

    var categoryId: String
    var subcategoryId: String?
    var categoryName: String?
    var subcategoryName: String?

    var price: MarketplacePrice
    var condition: MarketplaceProductCondition
    var status: MarketplaceProductStatus

    var media: [MarketplaceProductMedia]
    var variants: [MarketplaceProductVariant]
    var dimensions: MarketplaceProductDimensions?

    var stock: Int
    var sku: String?
    var barcode: String?

    var brand: String?
    var colors: [String]
    var sizes: [String]
    var tags: [String]

    var countryCode: String?
    var countryName: String?
    var city: String?
    var latitude: Double?
    var longitude: Double?

    var allowsPickup: Bool
    var allowsDelivery: Bool
    var allowsNegotiation: Bool
    var isBoosted: Bool
    var isFeatured: Bool
    var isLiveShoppingEnabled: Bool

    var viewCount: Int
    var favoriteCount: Int
    var soldCount: Int
    var shareCount: Int

    var aiScore: Double?
    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var createdAt: Timestamp?
    var updatedAt: Timestamp?
    var publishedAt: Timestamp?

    init(
        id: String? = nil,
        sellerId: String,
        storeId: String? = nil,
        title: String,
        subtitle: String? = nil,
        description: String,
        categoryId: String,
        subcategoryId: String? = nil,
        categoryName: String? = nil,
        subcategoryName: String? = nil,
        price: MarketplacePrice,
        condition: MarketplaceProductCondition = .new,
        status: MarketplaceProductStatus = .draft,
        media: [MarketplaceProductMedia] = [],
        variants: [MarketplaceProductVariant] = [],
        dimensions: MarketplaceProductDimensions? = nil,
        stock: Int = 1,
        sku: String? = nil,
        barcode: String? = nil,
        brand: String? = nil,
        colors: [String] = [],
        sizes: [String] = [],
        tags: [String] = [],
        countryCode: String? = nil,
        countryName: String? = nil,
        city: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        allowsPickup: Bool = true,
        allowsDelivery: Bool = true,
        allowsNegotiation: Bool = false,
        isBoosted: Bool = false,
        isFeatured: Bool = false,
        isLiveShoppingEnabled: Bool = false,
        viewCount: Int = 0,
        favoriteCount: Int = 0,
        soldCount: Int = 0,
        shareCount: Int = 0,
        aiScore: Double? = nil,
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil,
        publishedAt: Timestamp? = nil
    ) {
        self.id = id
        self.sellerId = sellerId
        self.storeId = storeId
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.categoryId = categoryId
        self.subcategoryId = subcategoryId
        self.categoryName = categoryName
        self.subcategoryName = subcategoryName
        self.price = price
        self.condition = condition
        self.status = status
        self.media = media
        self.variants = variants
        self.dimensions = dimensions
        self.stock = stock
        self.sku = sku
        self.barcode = barcode
        self.brand = brand
        self.colors = colors
        self.sizes = sizes
        self.tags = tags
        self.countryCode = countryCode
        self.countryName = countryName
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.allowsPickup = allowsPickup
        self.allowsDelivery = allowsDelivery
        self.allowsNegotiation = allowsNegotiation
        self.isBoosted = isBoosted
        self.isFeatured = isFeatured
        self.isLiveShoppingEnabled = isLiveShoppingEnabled
        self.viewCount = viewCount
        self.favoriteCount = favoriteCount
        self.soldCount = soldCount
        self.shareCount = shareCount
        self.aiScore = aiScore
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.publishedAt = publishedAt
    }
}

// MARK: - Store Status

enum MarketplaceStoreStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case active
    case suspended
    case verified
    case rejected
    case closed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "En attente"
        case .active: return "Active"
        case .suspended: return "Suspendue"
        case .verified: return "Vérifiée"
        case .rejected: return "Refusée"
        case .closed: return "Fermée"
        }
    }
}

// MARK: - Store Type

enum MarketplaceStoreType: String, Codable, CaseIterable, Identifiable {
    case individual
    case professional
    case brand
    case partner
    case official

    var id: String { rawValue }

    var title: String {
        switch self {
        case .individual: return "Particulier"
        case .professional: return "Professionnel"
        case .brand: return "Marque"
        case .partner: return "Partenaire"
        case .official: return "Officiel"
        }
    }
}

// MARK: - Risk Level

enum MarketplaceRiskLevel: String, Codable, CaseIterable, Identifiable {
    case none
    case low
    case medium
    case high
    case critical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "Aucun risque"
        case .low: return "Risque faible"
        case .medium: return "Risque moyen"
        case .high: return "Risque élevé"
        case .critical: return "Risque critique"
        }
    }
}

// MARK: - Marketplace Store

struct MarketplaceStore: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var ownerId: String

    var name: String
    var slug: String
    var description: String?
    var logoURL: String?
    var coverURL: String?

    var type: MarketplaceStoreType
    var status: MarketplaceStoreStatus

    var countryCode: String?
    var countryName: String?
    var city: String?

    var followersCount: Int
    var productsCount: Int
    var ordersCount: Int
    var ratingAverage: Double
    var ratingCount: Int

    var isVerified: Bool
    var isOfficial: Bool
    var isPremiumSeller: Bool
    var hasLiveShopping: Bool

    var responseRate: Double?
    var averageResponseTimeMinutes: Int?
    var cancellationRate: Double?
    var returnRate: Double?

    var aiTrustScore: Double?
    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var createdAt: Timestamp?
    var updatedAt: Timestamp?
    var verifiedAt: Timestamp?

    init(
        id: String? = nil,
        ownerId: String,
        name: String,
        slug: String,
        description: String? = nil,
        logoURL: String? = nil,
        coverURL: String? = nil,
        type: MarketplaceStoreType = .individual,
        status: MarketplaceStoreStatus = .pending,
        countryCode: String? = nil,
        countryName: String? = nil,
        city: String? = nil,
        followersCount: Int = 0,
        productsCount: Int = 0,
        ordersCount: Int = 0,
        ratingAverage: Double = 0,
        ratingCount: Int = 0,
        isVerified: Bool = false,
        isOfficial: Bool = false,
        isPremiumSeller: Bool = false,
        hasLiveShopping: Bool = false,
        responseRate: Double? = nil,
        averageResponseTimeMinutes: Int? = nil,
        cancellationRate: Double? = nil,
        returnRate: Double? = nil,
        aiTrustScore: Double? = nil,
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil,
        verifiedAt: Timestamp? = nil
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.slug = slug
        self.description = description
        self.logoURL = logoURL
        self.coverURL = coverURL
        self.type = type
        self.status = status
        self.countryCode = countryCode
        self.countryName = countryName
        self.city = city
        self.followersCount = followersCount
        self.productsCount = productsCount
        self.ordersCount = ordersCount
        self.ratingAverage = ratingAverage
        self.ratingCount = ratingCount
        self.isVerified = isVerified
        self.isOfficial = isOfficial
        self.isPremiumSeller = isPremiumSeller
        self.hasLiveShopping = hasLiveShopping
        self.responseRate = responseRate
        self.averageResponseTimeMinutes = averageResponseTimeMinutes
        self.cancellationRate = cancellationRate
        self.returnRate = returnRate
        self.aiTrustScore = aiTrustScore
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.verifiedAt = verifiedAt
    }
}

// MARK: - Marketplace Category

struct MarketplaceCategory: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var icon: String
    var gradientStartHex: String
    var gradientEndHex: String
    var subcategories: [MarketplaceSubcategory]
    var position: Int
    var isFeatured: Bool
    var isActive: Bool

    init(
        id: String,
        name: String,
        icon: String,
        gradientStartHex: String = "#111827",
        gradientEndHex: String = "#374151",
        subcategories: [MarketplaceSubcategory] = [],
        position: Int = 0,
        isFeatured: Bool = false,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.gradientStartHex = gradientStartHex
        self.gradientEndHex = gradientEndHex
        self.subcategories = subcategories
        self.position = position
        self.isFeatured = isFeatured
        self.isActive = isActive
    }
}

// MARK: - Marketplace Subcategory

struct MarketplaceSubcategory: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var icon: String?
    var position: Int
    var isActive: Bool

    init(
        id: String,
        name: String,
        icon: String? = nil,
        position: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.position = position
        self.isActive = isActive
    }
}
// MARK: - Address Type

enum MarketplaceAddressType: String, Codable, CaseIterable, Identifiable {
    case fullAddress
    case landmark
    case gps
    case pickupPoint
    case postalOffice
    case partnerShop
    case localAgency
    case handDelivery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullAddress: return "Adresse complète"
        case .landmark: return "Point de repère"
        case .gps: return "Coordonnées GPS"
        case .pickupPoint: return "Point relais"
        case .postalOffice: return "Bureau de poste"
        case .partnerShop: return "Commerçant partenaire"
        case .localAgency: return "Agence locale"
        case .handDelivery: return "Remise en main propre"
        }
    }
}

// MARK: - Marketplace Address

struct MarketplaceAddress: Codable, Identifiable, Hashable {
    var id: String

    var userId: String?
    var label: String

    var type: MarketplaceAddressType

    var fullName: String
    var phoneNumber: String
    var secondaryPhoneNumber: String?

    var countryCode: String
    var countryName: String
    var city: String
    var region: String?
    var postalCode: String?

    var streetLine1: String?
    var streetLine2: String?
    var landmarkDescription: String?

    var latitude: Double?
    var longitude: Double?

    var pickupPointId: String?
    var pickupPointName: String?
    var pickupPointPhone: String?

    var deliveryInstructions: String?
    var isDefault: Bool
    var isVerified: Bool

    var createdAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        label: String = "Adresse principale",
        type: MarketplaceAddressType = .fullAddress,
        fullName: String,
        phoneNumber: String,
        secondaryPhoneNumber: String? = nil,
        countryCode: String,
        countryName: String,
        city: String,
        region: String? = nil,
        postalCode: String? = nil,
        streetLine1: String? = nil,
        streetLine2: String? = nil,
        landmarkDescription: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        pickupPointId: String? = nil,
        pickupPointName: String? = nil,
        pickupPointPhone: String? = nil,
        deliveryInstructions: String? = nil,
        isDefault: Bool = false,
        isVerified: Bool = false,
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.userId = userId
        self.label = label
        self.type = type
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.secondaryPhoneNumber = secondaryPhoneNumber
        self.countryCode = countryCode
        self.countryName = countryName
        self.city = city
        self.region = region
        self.postalCode = postalCode
        self.streetLine1 = streetLine1
        self.streetLine2 = streetLine2
        self.landmarkDescription = landmarkDescription
        self.latitude = latitude
        self.longitude = longitude
        self.pickupPointId = pickupPointId
        self.pickupPointName = pickupPointName
        self.pickupPointPhone = pickupPointPhone
        self.deliveryInstructions = deliveryInstructions
        self.isDefault = isDefault
        self.isVerified = isVerified
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Shipping Carrier Type

enum MarketplaceShippingCarrierType: String, Codable, CaseIterable, Identifiable {
    case international
    case nationalPost
    case pickupRelay
    case localCourier
    case busAgency
    case localTransportAgency
    case partnerShop
    case handDelivery
    case sellerManaged

    var id: String { rawValue }

    var title: String {
        switch self {
        case .international: return "Transporteur international"
        case .nationalPost: return "Poste nationale"
        case .pickupRelay: return "Point relais"
        case .localCourier: return "Coursier local"
        case .busAgency: return "Agence de bus"
        case .localTransportAgency: return "Agence locale"
        case .partnerShop: return "Commerçant partenaire"
        case .handDelivery: return "Remise en main propre"
        case .sellerManaged: return "Géré par le vendeur"
        }
    }
}

// MARK: - Shipping Carrier

struct MarketplaceShippingCarrier: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var type: MarketplaceShippingCarrierType

    var logoURL: String?
    var websiteURL: String?
    var trackingURLTemplate: String?

    var supportedCountryCodes: [String]
    var supportsInternational: Bool
    var supportsTracking: Bool
    var supportsPickupPoints: Bool
    var supportsCashOnDelivery: Bool
    var supportsProofOfDelivery: Bool

    var isActive: Bool
    var position: Int

    init(
        id: String,
        name: String,
        type: MarketplaceShippingCarrierType,
        logoURL: String? = nil,
        websiteURL: String? = nil,
        trackingURLTemplate: String? = nil,
        supportedCountryCodes: [String] = [],
        supportsInternational: Bool = false,
        supportsTracking: Bool = false,
        supportsPickupPoints: Bool = false,
        supportsCashOnDelivery: Bool = false,
        supportsProofOfDelivery: Bool = false,
        isActive: Bool = true,
        position: Int = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.logoURL = logoURL
        self.websiteURL = websiteURL
        self.trackingURLTemplate = trackingURLTemplate
        self.supportedCountryCodes = supportedCountryCodes
        self.supportsInternational = supportsInternational
        self.supportsTracking = supportsTracking
        self.supportsPickupPoints = supportsPickupPoints
        self.supportsCashOnDelivery = supportsCashOnDelivery
        self.supportsProofOfDelivery = supportsProofOfDelivery
        self.isActive = isActive
        self.position = position
    }
}

// MARK: - Shipping Method

enum MarketplaceShippingMethodType: String, Codable, CaseIterable, Identifiable {
    case homeDelivery
    case pickupPoint
    case postOffice
    case partnerShop
    case localCourier
    case agencyPickup
    case handDelivery
    case internationalDelivery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .homeDelivery: return "Livraison à domicile"
        case .pickupPoint: return "Point relais"
        case .postOffice: return "Bureau de poste"
        case .partnerShop: return "Commerçant partenaire"
        case .localCourier: return "Coursier local"
        case .agencyPickup: return "Retrait en agence"
        case .handDelivery: return "Remise en main propre"
        case .internationalDelivery: return "Livraison internationale"
        }
    }
}

struct MarketplaceShippingMethod: Codable, Identifiable, Hashable {
    var id: String

    var carrierId: String?
    var carrierName: String?

    var type: MarketplaceShippingMethodType
    var title: String
    var description: String?

    var estimatedMinDays: Int?
    var estimatedMaxDays: Int?

    var price: MarketplacePrice
    var isFree: Bool
    var isRecommended: Bool

    var requiresPhoneNumber: Bool
    var requiresGPS: Bool
    var requiresSignature: Bool
    var requiresPickupCode: Bool

    var availableCountryCodes: [String]
    var unavailableCityNames: [String]

    init(
        id: String = UUID().uuidString,
        carrierId: String? = nil,
        carrierName: String? = nil,
        type: MarketplaceShippingMethodType,
        title: String,
        description: String? = nil,
        estimatedMinDays: Int? = nil,
        estimatedMaxDays: Int? = nil,
        price: MarketplacePrice = MarketplacePrice(amount: 0),
        isFree: Bool = false,
        isRecommended: Bool = false,
        requiresPhoneNumber: Bool = true,
        requiresGPS: Bool = false,
        requiresSignature: Bool = false,
        requiresPickupCode: Bool = false,
        availableCountryCodes: [String] = [],
        unavailableCityNames: [String] = []
    ) {
        self.id = id
        self.carrierId = carrierId
        self.carrierName = carrierName
        self.type = type
        self.title = title
        self.description = description
        self.estimatedMinDays = estimatedMinDays
        self.estimatedMaxDays = estimatedMaxDays
        self.price = price
        self.isFree = isFree
        self.isRecommended = isRecommended
        self.requiresPhoneNumber = requiresPhoneNumber
        self.requiresGPS = requiresGPS
        self.requiresSignature = requiresSignature
        self.requiresPickupCode = requiresPickupCode
        self.availableCountryCodes = availableCountryCodes
        self.unavailableCityNames = unavailableCityNames
    }
}

// MARK: - Tracking Status

enum MarketplaceTrackingStatus: String, Codable, CaseIterable, Identifiable {
    case created
    case pendingPickup
    case pickedUp
    case inTransit
    case arrivedAtHub
    case outForDelivery
    case readyForPickup
    case delivered
    case deliveryFailed
    case returnedToSender
    case lost
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .created: return "Créé"
        case .pendingPickup: return "En attente de collecte"
        case .pickedUp: return "Collecté"
        case .inTransit: return "En transit"
        case .arrivedAtHub: return "Arrivé au centre"
        case .outForDelivery: return "En cours de livraison"
        case .readyForPickup: return "Prêt au retrait"
        case .delivered: return "Livré"
        case .deliveryFailed: return "Échec de livraison"
        case .returnedToSender: return "Retourné au vendeur"
        case .lost: return "Perdu"
        case .cancelled: return "Annulé"
        }
    }
}

// MARK: - Tracking Event

struct MarketplaceTrackingEvent: Codable, Identifiable, Hashable {
    var id: String
    var status: MarketplaceTrackingStatus
    var title: String
    var message: String?

    var countryCode: String?
    var city: String?
    var locationName: String?

    var latitude: Double?
    var longitude: Double?

    var createdAt: Timestamp?

    init(
        id: String = UUID().uuidString,
        status: MarketplaceTrackingStatus,
        title: String,
        message: String? = nil,
        countryCode: String? = nil,
        city: String? = nil,
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        createdAt: Timestamp? = nil
    ) {
        self.id = id
        self.status = status
        self.title = title
        self.message = message
        self.countryCode = countryCode
        self.city = city
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }
}

// MARK: - Shipment

struct MarketplaceShipment: Codable, Identifiable, Hashable {
    var id: String

    var orderId: String
    var carrierId: String?
    var carrierName: String?

    var trackingNumber: String?
    var trackingURL: String?
    var qrCodeURL: String?

    var status: MarketplaceTrackingStatus
    var events: [MarketplaceTrackingEvent]

    var originAddress: MarketplaceAddress?
    var destinationAddress: MarketplaceAddress?

    var proofOfDeliveryURL: String?
    var signatureURL: String?
    var deliveredToName: String?

    var estimatedDeliveryAt: Timestamp?
    var shippedAt: Timestamp?
    var deliveredAt: Timestamp?
    var createdAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String = UUID().uuidString,
        orderId: String,
        carrierId: String? = nil,
        carrierName: String? = nil,
        trackingNumber: String? = nil,
        trackingURL: String? = nil,
        qrCodeURL: String? = nil,
        status: MarketplaceTrackingStatus = .created,
        events: [MarketplaceTrackingEvent] = [],
        originAddress: MarketplaceAddress? = nil,
        destinationAddress: MarketplaceAddress? = nil,
        proofOfDeliveryURL: String? = nil,
        signatureURL: String? = nil,
        deliveredToName: String? = nil,
        estimatedDeliveryAt: Timestamp? = nil,
        shippedAt: Timestamp? = nil,
        deliveredAt: Timestamp? = nil,
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.orderId = orderId
        self.carrierId = carrierId
        self.carrierName = carrierName
        self.trackingNumber = trackingNumber
        self.trackingURL = trackingURL
        self.qrCodeURL = qrCodeURL
        self.status = status
        self.events = events
        self.originAddress = originAddress
        self.destinationAddress = destinationAddress
        self.proofOfDeliveryURL = proofOfDeliveryURL
        self.signatureURL = signatureURL
        self.deliveredToName = deliveredToName
        self.estimatedDeliveryAt = estimatedDeliveryAt
        self.shippedAt = shippedAt
        self.deliveredAt = deliveredAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
// MARK: - Order Status

enum MarketplaceOrderStatus: String, Codable, CaseIterable, Identifiable {
    case pendingPayment
    case paid
    case preparing
    case shipped
    case delivered
    case completed
    case cancelled
    case returnRequested
    case returned
    case disputed
    case refunded

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pendingPayment: return "Paiement en attente"
        case .paid: return "Payée"
        case .preparing: return "En préparation"
        case .shipped: return "Expédiée"
        case .delivered: return "Livrée"
        case .completed: return "Terminée"
        case .cancelled: return "Annulée"
        case .returnRequested: return "Retour demandé"
        case .returned: return "Retournée"
        case .disputed: return "Litige"
        case .refunded: return "Remboursée"
        }
    }
}

// MARK: - Payment Provider

enum MarketplacePaymentProvider: String, Codable, CaseIterable, Identifiable {
    case stripe
    case applePay
    case googlePay
    case paypal
    case orangeMoney
    case wave
    case mtnMobileMoney
    case moovMoney
    case airtelMoney
    case mpesa
    case freeMoney
    case tmoney
    case flooz
    case cinetpay
    case wallet
    case cashOnDelivery
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stripe: return "Stripe"
        case .applePay: return "Apple Pay"
        case .googlePay: return "Google Pay"
        case .paypal: return "PayPal"
        case .orangeMoney: return "Orange Money"
        case .wave: return "Wave"
        case .mtnMobileMoney: return "MTN Mobile Money"
        case .moovMoney: return "Moov Money"
        case .airtelMoney: return "Airtel Money"
        case .mpesa: return "M-Pesa"
        case .freeMoney: return "Free Money"
        case .tmoney: return "TMoney"
        case .flooz: return "Flooz"
        case .cinetpay: return "CinetPay"
        case .wallet: return "Portefeuille Cutly"
        case .cashOnDelivery: return "Paiement à la livraison"
        case .manual: return "Paiement manuel"
        }
    }
}

// MARK: - Payment Status

enum MarketplacePaymentStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case authorized
    case paid
    case failed
    case cancelled
    case partiallyRefunded
    case refunded
    case underReview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "En attente"
        case .authorized: return "Autorisé"
        case .paid: return "Payé"
        case .failed: return "Échoué"
        case .cancelled: return "Annulé"
        case .partiallyRefunded: return "Partiellement remboursé"
        case .refunded: return "Remboursé"
        case .underReview: return "En vérification"
        }
    }
}

// MARK: - Marketplace Payment

struct MarketplacePayment: Codable, Identifiable, Hashable {
    var id: String

    var orderId: String?
    var buyerId: String
    var sellerId: String?

    var provider: MarketplacePaymentProvider
    var status: MarketplacePaymentStatus

    var amount: MarketplacePrice
    var platformFee: MarketplacePrice?
    var sellerAmount: MarketplacePrice?
    var taxAmount: MarketplacePrice?
    var shippingAmount: MarketplacePrice?

    var externalPaymentId: String?
    var externalCustomerId: String?
    var externalTransferId: String?

    var phoneNumber: String?
    var countryCode: String?
    var failureReason: String?

    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var createdAt: Timestamp?
    var paidAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String = UUID().uuidString,
        orderId: String? = nil,
        buyerId: String,
        sellerId: String? = nil,
        provider: MarketplacePaymentProvider,
        status: MarketplacePaymentStatus = .pending,
        amount: MarketplacePrice,
        platformFee: MarketplacePrice? = nil,
        sellerAmount: MarketplacePrice? = nil,
        taxAmount: MarketplacePrice? = nil,
        shippingAmount: MarketplacePrice? = nil,
        externalPaymentId: String? = nil,
        externalCustomerId: String? = nil,
        externalTransferId: String? = nil,
        phoneNumber: String? = nil,
        countryCode: String? = nil,
        failureReason: String? = nil,
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        createdAt: Timestamp? = nil,
        paidAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.orderId = orderId
        self.buyerId = buyerId
        self.sellerId = sellerId
        self.provider = provider
        self.status = status
        self.amount = amount
        self.platformFee = platformFee
        self.sellerAmount = sellerAmount
        self.taxAmount = taxAmount
        self.shippingAmount = shippingAmount
        self.externalPaymentId = externalPaymentId
        self.externalCustomerId = externalCustomerId
        self.externalTransferId = externalTransferId
        self.phoneNumber = phoneNumber
        self.countryCode = countryCode
        self.failureReason = failureReason
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.createdAt = createdAt
        self.paidAt = paidAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Marketplace Order Item

struct MarketplaceOrderItem: Codable, Identifiable, Hashable {
    var id: String

    var productId: String
    var sellerId: String
    var storeId: String?

    var title: String
    var imageURL: String?
    var quantity: Int

    var unitPrice: MarketplacePrice
    var totalPrice: MarketplacePrice

    var selectedVariantIds: [String]
    var selectedVariantSummary: String?

    var sku: String?
    var status: MarketplaceOrderStatus

    init(
        id: String = UUID().uuidString,
        productId: String,
        sellerId: String,
        storeId: String? = nil,
        title: String,
        imageURL: String? = nil,
        quantity: Int = 1,
        unitPrice: MarketplacePrice,
        totalPrice: MarketplacePrice,
        selectedVariantIds: [String] = [],
        selectedVariantSummary: String? = nil,
        sku: String? = nil,
        status: MarketplaceOrderStatus = .pendingPayment
    ) {
        self.id = id
        self.productId = productId
        self.sellerId = sellerId
        self.storeId = storeId
        self.title = title
        self.imageURL = imageURL
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.selectedVariantIds = selectedVariantIds
        self.selectedVariantSummary = selectedVariantSummary
        self.sku = sku
        self.status = status
    }
}

// MARK: - Marketplace Order

struct MarketplaceOrder: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var orderNumber: String

    var buyerId: String
    var sellerIds: [String]
    var storeIds: [String]

    var items: [MarketplaceOrderItem]

    var status: MarketplaceOrderStatus
    var paymentStatus: MarketplacePaymentStatus

    var subtotal: MarketplacePrice
    var shippingTotal: MarketplacePrice
    var platformFeeTotal: MarketplacePrice?
    var taxTotal: MarketplacePrice?
    var discountTotal: MarketplacePrice?
    var total: MarketplacePrice

    var payment: MarketplacePayment?
    var shippingMethod: MarketplaceShippingMethod?
    var shipment: MarketplaceShipment?

    var buyerAddress: MarketplaceAddress?
    var buyerNote: String?
    var sellerNote: String?

    var hasDispute: Bool
    var hasReturnRequest: Bool
    var isInternational: Bool
    var requiresManualReview: Bool

    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var createdAt: Timestamp?
    var paidAt: Timestamp?
    var preparedAt: Timestamp?
    var shippedAt: Timestamp?
    var deliveredAt: Timestamp?
    var completedAt: Timestamp?
    var cancelledAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        orderNumber: String,
        buyerId: String,
        sellerIds: [String],
        storeIds: [String] = [],
        items: [MarketplaceOrderItem],
        status: MarketplaceOrderStatus = .pendingPayment,
        paymentStatus: MarketplacePaymentStatus = .pending,
        subtotal: MarketplacePrice,
        shippingTotal: MarketplacePrice = MarketplacePrice(amount: 0),
        platformFeeTotal: MarketplacePrice? = nil,
        taxTotal: MarketplacePrice? = nil,
        discountTotal: MarketplacePrice? = nil,
        total: MarketplacePrice,
        payment: MarketplacePayment? = nil,
        shippingMethod: MarketplaceShippingMethod? = nil,
        shipment: MarketplaceShipment? = nil,
        buyerAddress: MarketplaceAddress? = nil,
        buyerNote: String? = nil,
        sellerNote: String? = nil,
        hasDispute: Bool = false,
        hasReturnRequest: Bool = false,
        isInternational: Bool = false,
        requiresManualReview: Bool = false,
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        createdAt: Timestamp? = nil,
        paidAt: Timestamp? = nil,
        preparedAt: Timestamp? = nil,
        shippedAt: Timestamp? = nil,
        deliveredAt: Timestamp? = nil,
        completedAt: Timestamp? = nil,
        cancelledAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.buyerId = buyerId
        self.sellerIds = sellerIds
        self.storeIds = storeIds
        self.items = items
        self.status = status
        self.paymentStatus = paymentStatus
        self.subtotal = subtotal
        self.shippingTotal = shippingTotal
        self.platformFeeTotal = platformFeeTotal
        self.taxTotal = taxTotal
        self.discountTotal = discountTotal
        self.total = total
        self.payment = payment
        self.shippingMethod = shippingMethod
        self.shipment = shipment
        self.buyerAddress = buyerAddress
        self.buyerNote = buyerNote
        self.sellerNote = sellerNote
        self.hasDispute = hasDispute
        self.hasReturnRequest = hasReturnRequest
        self.isInternational = isInternational
        self.requiresManualReview = requiresManualReview
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.createdAt = createdAt
        self.paidAt = paidAt
        self.preparedAt = preparedAt
        self.shippedAt = shippedAt
        self.deliveredAt = deliveredAt
        self.completedAt = completedAt
        self.cancelledAt = cancelledAt
        self.updatedAt = updatedAt
    }
}
