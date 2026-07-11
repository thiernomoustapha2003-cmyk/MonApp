//
//  MarketplaceShippingService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import Foundation
import FirebaseFirestore
import CoreLocation

final class MarketplaceShippingService {
    static let shared = MarketplaceShippingService()
    private init() {}
    
    func buildShippingQuote(
        orderId: String,
        sellerCountryCode: String,
        buyerCountryCode: String,
        packageWeightKg: Double,
        packageLengthCm: Double,
        packageWidthCm: Double,
        packageHeightCm: Double,
        preferredMethod: MarketplaceDeliveryMethod? = nil
    ) -> MarketplaceShippingQuote {
        
        let zone = resolveShippingZone(
            sellerCountryCode: sellerCountryCode,
            buyerCountryCode: buyerCountryCode
        )
        
        let method = preferredMethod ?? recommendedMethods(
            sellerCountryCode: sellerCountryCode,
            buyerCountryCode: buyerCountryCode
        ).first ?? .manualLocal
        
        let volumetricWeight = calculateVolumetricWeightKg(
            lengthCm: packageLengthCm,
            widthCm: packageWidthCm,
            heightCm: packageHeightCm
        )
        
        let billableWeight = max(packageWeightKg, volumetricWeight)
        
        let estimatedPrice = estimateShippingPrice(
            zone: zone,
            method: method,
            billableWeightKg: billableWeight
        )
        
        let estimatedDays = estimateDeliveryDays(zone: zone, method: method)
        
        return MarketplaceShippingQuote(
            id: UUID().uuidString,
            orderId: orderId,
            sellerCountryCode: sellerCountryCode.uppercased(),
            buyerCountryCode: buyerCountryCode.uppercased(),
            zone: zone,
            method: method,
            packageWeightKg: packageWeightKg,
            volumetricWeightKg: volumetricWeight,
            billableWeightKg: billableWeight,
            estimatedPrice: estimatedPrice,
            estimatedDaysMin: estimatedDays.min,
            estimatedDaysMax: estimatedDays.max,
            status: .draft,
            createdAt: Timestamp()
        )
    }
    
    func resolveShippingZone(
        sellerCountryCode: String,
        buyerCountryCode: String
    ) -> MarketplaceShippingZone {
        let seller = sellerCountryCode.uppercased()
        let buyer = buyerCountryCode.uppercased()
        
        if seller == buyer { return .domestic }
        
        if continent(for: seller) == continent(for: buyer) {
            return .sameContinent
        }
        
        return .international
    }
    
    func continent(for countryCode: String) -> MarketplaceWorldRegion {
        let code = countryCode.uppercased()
        
        if MarketplaceCountryGroups.africa.contains(code) { return .africa }
        if MarketplaceCountryGroups.europe.contains(code) { return .europe }
        if MarketplaceCountryGroups.northAmerica.contains(code) { return .northAmerica }
        if MarketplaceCountryGroups.southAmerica.contains(code) { return .southAmerica }
        if MarketplaceCountryGroups.asia.contains(code) { return .asia }
        if MarketplaceCountryGroups.oceania.contains(code) { return .oceania }
        
        return .unknown
    }
    
    func recommendedMethods(
        sellerCountryCode: String,
        buyerCountryCode: String
    ) -> [MarketplaceDeliveryMethod] {
        let buyer = buyerCountryCode.uppercased()
        let zone = resolveShippingZone(
            sellerCountryCode: sellerCountryCode,
            buyerCountryCode: buyerCountryCode
        )
        
        if zone == .domestic {
            if MarketplaceCountryGroups.africa.contains(buyer) {
                return [.localCourier, .pickupPoint, .localAgency, .busAgency, .postOffice, .handDelivery, .gpsLandmark, .manualLocal]
            }
            
            return [.homeDelivery, .pickupPoint, .postOffice, .localCourier, .handDelivery]
        }
        
        if zone == .sameContinent {
            if MarketplaceCountryGroups.africa.contains(buyer) {
                return [.regionalCarrier, .postOffice, .localAgency, .busAgency, .pickupPoint, .manualLocal]
            }
            
            return [.regionalCarrier, .homeDelivery, .pickupPoint, .postOffice]
        }
        
        return [.dhl, .ups, .fedex, .ems, .internationalPost, .manualInternational]
    }
    
    func calculateVolumetricWeightKg(
        lengthCm: Double,
        widthCm: Double,
        heightCm: Double
    ) -> Double {
        max((lengthCm * widthCm * heightCm) / 5000.0, 0)
    }
    
    func estimateShippingPrice(
        zone: MarketplaceShippingZone,
        method: MarketplaceDeliveryMethod,
        billableWeightKg: Double
    ) -> Double {
        let base: Double = switch zone {
        case .domestic: 3.50
        case .sameContinent: 9.90
        case .international: 24.90
        }
        
        let multiplier: Double = switch method {
        case .handDelivery: 0.40
        case .gpsLandmark, .pickupPoint, .postOffice: 0.75
        case .localCourier, .localAgency, .busAgency: 0.85
        case .regionalCarrier, .internationalPost, .ems: 1.0
        case .dhl, .ups, .fedex: 1.45
        case .homeDelivery: 1.10
        case .manualLocal, .manualInternational: 1.0
        }
        
        return max((base + (billableWeightKg * 1.75)) * multiplier, 0)
    }
    
    func estimateDeliveryDays(
        zone: MarketplaceShippingZone,
        method: MarketplaceDeliveryMethod
    ) -> (min: Int, max: Int) {
        switch method {
        case .handDelivery: return (0, 1)
        case .gpsLandmark, .localCourier: return (1, 3)
        case .pickupPoint, .postOffice, .localAgency: return (2, 6)
        case .busAgency: return (1, 5)
        case .regionalCarrier: return (3, 10)
        case .homeDelivery: return zone == .domestic ? (1, 5) : (5, 14)
        case .internationalPost, .ems: return (7, 21)
        case .dhl, .ups, .fedex: return (3, 10)
        case .manualLocal: return (1, 7)
        case .manualInternational: return (7, 30)
        }
    }
    
    func saveShippingQuote(_ quote: MarketplaceShippingQuote) async throws {
        try await Firestore.firestore()
            .collection(MarketplaceFirestoreService.Collection.shipments)
            .document(quote.id)
            .setData([
                "id": quote.id,
                "orderId": quote.orderId,
                "sellerCountryCode": quote.sellerCountryCode,
                "buyerCountryCode": quote.buyerCountryCode,
                "zone": quote.zone.rawValue,
                "method": quote.method.rawValue,
                "packageWeightKg": quote.packageWeightKg,
                "volumetricWeightKg": quote.volumetricWeightKg,
                "billableWeightKg": quote.billableWeightKg,
                "estimatedPrice": quote.estimatedPrice,
                "estimatedDaysMin": quote.estimatedDaysMin,
                "estimatedDaysMax": quote.estimatedDaysMax,
                "status": quote.status.rawValue,
                "createdAt": quote.createdAt ?? Timestamp(),
                "updatedAt": Timestamp()
            ], merge: true)
    }
    
    func createTracking(
        orderId: String,
        shipmentId: String,
        carrier: MarketplaceCarrier,
        trackingNumber: String
    ) -> MarketplaceTrackingRecord {
        MarketplaceTrackingRecord(
            id: UUID().uuidString,
            orderId: orderId,
            shipmentId: shipmentId,
            carrier: carrier,
            trackingNumber: trackingNumber,
            currentStatus: .preparing,
            currentLatitude: nil,
            currentLongitude: nil,
            proofImageURL: nil,
            signatureURL: nil,
            qrValidationCode: UUID().uuidString,
            createdAt: Timestamp()
        )
    }
    
    func saveTracking(_ tracking: MarketplaceTrackingRecord) async throws {
        try await Firestore.firestore()
            .collection(MarketplaceFirestoreService.Collection.trackingEvents)
            .document(tracking.id)
            .setData(from: tracking, merge: true)
    }
    
    func updateTrackingStatus(
        trackingId: String,
        status: MarketplaceShipmentTrackingStatus,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async throws {
        var data: [String: Any] = [
            "currentStatus": status.rawValue,
            "updatedAt": Timestamp()
        ]
        
        if let latitude { data["currentLatitude"] = latitude }
        if let longitude { data["currentLongitude"] = longitude }
        
        try await Firestore.firestore()
            .collection(MarketplaceFirestoreService.Collection.trackingEvents)
            .document(trackingId)
            .setData(data, merge: true)
    }
    
    func generateDeliveryPIN() -> String {
        String(format: "%06d", Int.random(in: 0...999999))
    }
    
    func generateQRCodeValue() -> String {
        UUID().uuidString
    }
    
    func generateTrackingNumber(carrier: MarketplaceCarrier) -> String {
        let random = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12)
        return "\(carrier.prefix)-\(random)"
    }
    // MARK: - Customs / Insurance / Delivery Proof

    func estimateCustomsRequired(
        sellerCountryCode: String,
        buyerCountryCode: String
    ) -> Bool {
        resolveShippingZone(
            sellerCountryCode: sellerCountryCode,
            buyerCountryCode: buyerCountryCode
        ) == .international
    }

    func estimateInsuranceFee(
        declaredValue: Double,
        method: MarketplaceDeliveryMethod
    ) -> Double {
        guard declaredValue > 0 else { return 0 }

        switch method {
        case .dhl, .ups, .fedex:
            return max(declaredValue * 0.015, 1.50)
        case .internationalPost, .ems, .regionalCarrier:
            return max(declaredValue * 0.01, 1.00)
        default:
            return max(declaredValue * 0.005, 0.50)
        }
    }

    func buildDeliveryProof(
        orderId: String,
        shipmentId: String,
        proofType: MarketplaceDeliveryProofType,
        photoURL: String? = nil,
        signatureURL: String? = nil,
        receiverName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> MarketplaceDeliveryProof {
        MarketplaceDeliveryProof(
            id: UUID().uuidString,
            orderId: orderId,
            shipmentId: shipmentId,
            proofType: proofType,
            photoURL: photoURL,
            signatureURL: signatureURL,
            receiverName: receiverName,
            latitude: latitude,
            longitude: longitude,
            createdAt: Timestamp()
        )
    }

    func saveDeliveryProof(_ proof: MarketplaceDeliveryProof) async throws {
        try await Firestore.firestore()
            .collection(MarketplaceFirestoreService.Collection.evidence)
            .document(proof.id)
            .setData(from: proof, merge: true)
    }

    func evaluateShippingRisk(
        sellerCountryCode: String,
        buyerCountryCode: String,
        method: MarketplaceDeliveryMethod,
        declaredValue: Double,
        hasTracking: Bool,
        hasPhoneNumber: Bool
    ) -> MarketplaceShippingRiskResult {
        var score = 0.0
        var reasons: [String] = []

        if estimateCustomsRequired(sellerCountryCode: sellerCountryCode, buyerCountryCode: buyerCountryCode) {
            score += 0.18
            reasons.append("Livraison internationale / douane")
        }

        if declaredValue >= 300 {
            score += 0.20
            reasons.append("Valeur élevée")
        }

        if !hasTracking {
            score += 0.25
            reasons.append("Aucun suivi colis")
        }

        if !hasPhoneNumber {
            score += 0.15
            reasons.append("Téléphone manquant")
        }

        if method == .manualLocal || method == .manualInternational {
            score += 0.18
            reasons.append("Traitement manuel")
        }

        let finalScore = min(score, 1.0)

        return MarketplaceShippingRiskResult(
            id: UUID().uuidString,
            score: finalScore,
            level: MarketplaceShippingRiskLevel.level(for: finalScore),
            reasons: reasons,
            shouldRequireManualReview: finalScore >= 0.55,
            createdAt: Timestamp()
        )
    }
    
    
    
}

// MARK: - Models

struct MarketplaceShippingQuote: Codable, Identifiable, Hashable {
    var id: String
    var orderId: String
    var sellerCountryCode: String
    var buyerCountryCode: String
    var zone: MarketplaceShippingZone
    var method: MarketplaceDeliveryMethod
    var packageWeightKg: Double
    var volumetricWeightKg: Double
    var billableWeightKg: Double
    var estimatedPrice: Double
    var estimatedDaysMin: Int
    var estimatedDaysMax: Int
    var status: MarketplaceShippingQuoteStatus
    var createdAt: Timestamp?
}

enum MarketplaceShippingZone: String, Codable, CaseIterable, Identifiable {
    case domestic
    case sameContinent
    case international
    var id: String { rawValue }
}

enum MarketplaceShippingQuoteStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case selected
    case confirmed
    case cancelled
    var id: String { rawValue }
}

enum MarketplaceWorldRegion: String, Codable, CaseIterable, Identifiable {
    case africa
    case europe
    case northAmerica
    case southAmerica
    case asia
    case oceania
    case unknown
    var id: String { rawValue }
}

enum MarketplaceDeliveryMethod: String, Codable, CaseIterable, Identifiable {
    case homeDelivery
    case pickupPoint
    case postOffice
    case localAgency
    case busAgency
    case localCourier
    case gpsLandmark
    case handDelivery
    case regionalCarrier
    case internationalPost
    case ems
    case dhl
    case ups
    case fedex
    case manualLocal
    case manualInternational

    var id: String { rawValue }
}

struct MarketplaceTrackingRecord: Codable, Identifiable, Hashable {
    var id: String
    var orderId: String
    var shipmentId: String
    var carrier: MarketplaceCarrier
    var trackingNumber: String
    var currentStatus: MarketplaceShipmentTrackingStatus
    var currentLatitude: Double?
    var currentLongitude: Double?
    var proofImageURL: String?
    var signatureURL: String?
    var qrValidationCode: String
    var createdAt: Timestamp?
}

enum MarketplaceShipmentTrackingStatus: String, Codable, CaseIterable, Identifiable {
    case preparing
    case pickedUp
    case inTransit
    case customs
    case localAgency
    case outForDelivery
    case delivered
    case returned
    case cancelled
    case dispute

    var id: String { rawValue }
}

enum MarketplaceCarrier: String, Codable, CaseIterable, Identifiable {
    case dhl
    case ups
    case fedex
    case ems
    case chronopost
    case colissimo
    case mondialRelay
    case localPost
    case localCourier
    case busAgency
    case partnerShop
    case manual

    var id: String { rawValue }

    var prefix: String {
        switch self {
        case .dhl: return "DHL"
        case .ups: return "UPS"
        case .fedex: return "FDX"
        case .ems: return "EMS"
        case .chronopost: return "CHR"
        case .colissimo: return "COL"
        case .mondialRelay: return "MR"
        case .localPost: return "POST"
        case .localCourier: return "COUR"
        case .busAgency: return "BUS"
        case .partnerShop: return "SHOP"
        case .manual: return "MAN"
        }
    }
}

enum MarketplaceCountryGroups {
    static let africa: Set<String> = [
        "DZ","AO","BJ","BW","BF","BI","CM","CV","CF","TD","KM","CG","CD","CI","DJ","EG","GQ","ER","SZ","ET","GA","GM","GH","GN","GW","KE","LS","LR","LY","MG","MW","ML","MR","MU","MA","MZ","NA","NE","NG","RW","ST","SN","SC","SL","SO","ZA","SS","SD","TZ","TG","TN","UG","ZM","ZW"
    ]

    static let europe: Set<String> = [
        "FR","ES","PT","IT","DE","BE","NL","LU","GB","IE","CH","AT","SE","NO","DK","FI","PL","CZ","SK","HU","RO","BG","GR","HR","SI","RS","AL","BA","ME","MK","UA","MD","EE","LV","LT","IS","MT","CY"
    ]

    static let northAmerica: Set<String> = ["US","CA","MX"]
    static let southAmerica: Set<String> = ["BR","AR","CL","CO","PE","VE","EC","BO","PY","UY","GY","SR"]
    static let asia: Set<String> = ["CN","JP","KR","IN","PK","BD","ID","MY","SG","TH","VN","PH","SA","AE","QA","KW","TR","IR","IQ","IL","JO","LB"]
    static let oceania: Set<String> = ["AU","NZ","FJ","PG"]
}
struct MarketplaceDeliveryProof: Codable, Identifiable, Hashable {
    var id: String
    var orderId: String
    var shipmentId: String
    var proofType: MarketplaceDeliveryProofType
    var photoURL: String?
    var signatureURL: String?
    var receiverName: String?
    var latitude: Double?
    var longitude: Double?
    var createdAt: Timestamp?
}

enum MarketplaceDeliveryProofType: String, Codable, CaseIterable, Identifiable {
    case qrCode
    case pinCode
    case signature
    case photo
    case gps
    case handDelivery
    case agencyPickup

    var id: String { rawValue }
}

struct MarketplaceShippingRiskResult: Codable, Identifiable, Hashable {
    var id: String
    var score: Double
    var level: MarketplaceShippingRiskLevel
    var reasons: [String]
    var shouldRequireManualReview: Bool
    var createdAt: Timestamp?
}

enum MarketplaceShippingRiskLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high
    case critical

    var id: String { rawValue }

    static func level(for score: Double) -> MarketplaceShippingRiskLevel {
        switch score {
        case 0..<0.30:
            return .low
        case 0.30..<0.55:
            return .medium
        case 0.55..<0.80:
            return .high
        default:
            return .critical
        }
    }
}
