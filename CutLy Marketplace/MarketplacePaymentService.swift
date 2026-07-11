//
//  MarketplacePaymentService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import Foundation
import FirebaseFirestore

final class MarketplacePaymentService {
    
    static let shared = MarketplacePaymentService()
    
    private init() {}
    
    // MARK: - Commission Cutly
    
    var defaultPlatformCommissionRate: Double {
        0.05
    }
    
    var minimumPlatformCommission: Double {
        0.10
    }
    
    func calculatePlatformCommission(amount: Double, customRate: Double? = nil) -> Double {
        let rate = customRate ?? defaultPlatformCommissionRate
        let commission = amount * rate
        return max(commission, minimumPlatformCommission)
    }
    
    func calculateSellerNetAmount(amount: Double, commissionRate: Double? = nil, providerFee: Double = 0) -> Double {
        let commission = calculatePlatformCommission(amount: amount, customRate: commissionRate)
        return max(amount - commission - providerFee, 0)
    }
    
    // MARK: - Payment Provider Selection
    
    func recommendedPaymentProviders(
        buyerCountryCode: String,
        sellerCountryCode: String? = nil
    ) -> [MarketplacePaymentProviderOption] {
        
        let country = buyerCountryCode.uppercased()
        
        switch country {
        case "FR", "ES", "IT", "DE", "BE", "NL", "PT", "IE", "LU", "US", "CA", "GB":
            return [
                .stripe,
                .applePay,
                .paypal,
                .cards,
                .bankTransfer,
                .walletCutly
            ]
            
        case "GN":
            return [
                .orangeMoney,
                .mtnMobileMoney,
                .cards,
                .bankTransfer,
                .walletCutly,
                .manual
            ]
            
        case "SN":
            return [
                .wave,
                .orangeMoney,
                .freeMoney,
                .cards,
                .bankTransfer,
                .walletCutly,
                .manual
            ]
            
        case "CI":
            return [
                .orangeMoney,
                .wave,
                .mtnMobileMoney,
                .moovMoney,
                .cards,
                .bankTransfer,
                .walletCutly,
                .manual
            ]
            
        case "ML":
            return [
                .orangeMoney,
                .moovMoney,
                .cards,
                .bankTransfer,
                .walletCutly,
                .manual
            ]
            
        case "TG":
            return [
                .tmoney,
                .flooz,
                .cards,
                .bankTransfer,
                .walletCutly,
                .manual
            ]
            
        case "BJ":
            return [
                .mtnMobileMoney,
                .moovMoney,
                .cards,
                .bankTransfer,
                .walletCutly,
                .manual
            ]
            
        case "CM", "CG", "GA", "TD":
            return [
                .orangeMoney,
                .mtnMobileMoney,
                .moovMoney,
                .cards,
                .bankTransfer,
                .walletCutly,
                .manual
            ]
            
        case "KE", "TZ":
            return [
                .mpesa,
                .airtelMoney,
                .cards,
                .bankTransfer,
                .walletCutly,
                .manual
            ]
            
        default:
            return [
                .paypal,
                .cards,
                .bankTransfer,
                .walletCutly,
                .manual
            ]
        }
    }
    
    func supportsMobileMoney(countryCode: String) -> Bool {
        let providers = recommendedPaymentProviders(buyerCountryCode: countryCode)
        return providers.contains {
            $0.isMobileMoney
        }
    }
    
    func supportsPayPal(countryCode: String) -> Bool {
        recommendedPaymentProviders(buyerCountryCode: countryCode).contains(.paypal)
    }
    
    // MARK: - Payment Draft
    
    func buildPaymentDraft(
        orderId: String,
        buyerId: String,
        sellerId: String,
        amount: Double,
        currency: MarketplaceCurrency,
        buyerCountryCode: String,
        sellerCountryCode: String?,
        selectedProvider: MarketplacePaymentProviderOption? = nil
    ) -> MarketplacePaymentDraft {
        
        let providers = recommendedPaymentProviders(
            buyerCountryCode: buyerCountryCode,
            sellerCountryCode: sellerCountryCode
        )
        
        let provider = selectedProvider ?? providers.first ?? .manual
        let providerFee = estimateProviderFee(amount: amount, provider: provider)
        let commission = calculatePlatformCommission(amount: amount)
        let sellerNet = calculateSellerNetAmount(
            amount: amount,
            providerFee: providerFee
        )
        
        return MarketplacePaymentDraft(
            id: UUID().uuidString,
            orderId: orderId,
            buyerId: buyerId,
            sellerId: sellerId,
            amount: amount,
            currency: currency,
            provider: provider,
            providerFee: providerFee,
            platformCommission: commission,
            sellerNetAmount: sellerNet,
            status: .draft,
            buyerCountryCode: buyerCountryCode,
            sellerCountryCode: sellerCountryCode,
            createdAt: Timestamp()
        )
    }
    
    func estimateProviderFee(amount: Double, provider: MarketplacePaymentProviderOption) -> Double {
        switch provider {
        case .stripe, .cards, .applePay:
            return max((amount * 0.029) + 0.30, 0.30)
        case .paypal:
            return max((amount * 0.034) + 0.35, 0.35)
        case .bankTransfer:
            return 0
        case .walletCutly:
            return 0
        case .manual:
            return 0
        default:
            return max(amount * 0.015, 0.05)
        }
    }
    
    // MARK: - Save Payment Draft

    func savePaymentDraft(_ draft: MarketplacePaymentDraft) async throws {
        try await Firestore.firestore()
            .collection(MarketplaceFirestoreService.Collection.payments)
            .document(draft.id)
            .setData([
                "id": draft.id,
                "orderId": draft.orderId,
                "buyerId": draft.buyerId,
                "sellerId": draft.sellerId,
                "amount": draft.amount,
                "currency": draft.currency.rawValue,
                "provider": draft.provider.rawValue,
                "providerFee": draft.providerFee,
                "platformCommission": draft.platformCommission,
                "sellerNetAmount": draft.sellerNetAmount,
                "status": draft.status.rawValue,
                "buyerCountryCode": draft.buyerCountryCode,
                "sellerCountryCode": draft.sellerCountryCode ?? "",
                "createdAt": draft.createdAt ?? Timestamp(),
                "updatedAt": Timestamp()
            ], merge: true)
    }

    // MARK: - Refund

    func calculateRefund(
        originalAmount: Double,
        refundPercent: Double = 1.0,
        keepPlatformFee: Bool = false
    ) -> MarketplaceRefundDraft {
        let safePercent = min(max(refundPercent, 0), 1)
        let refundAmount = originalAmount * safePercent
        let platformFeeImpact = keepPlatformFee ? 0 : calculatePlatformCommission(amount: refundAmount)

        return MarketplaceRefundDraft(
            id: UUID().uuidString,
            originalAmount: originalAmount,
            refundAmount: refundAmount,
            platformFeeImpact: platformFeeImpact,
            status: .draft,
            createdAt: Timestamp()
        )
    }

    func saveRefundDraft(
        _ draft: MarketplaceRefundDraft,
        orderId: String,
        paymentId: String,
        userId: String
    ) async throws {
        try await Firestore.firestore()
            .collection(MarketplaceFirestoreService.Collection.refunds)
            .document(draft.id)
            .setData([
                "id": draft.id,
                "orderId": orderId,
                "paymentId": paymentId,
                "userId": userId,
                "originalAmount": draft.originalAmount,
                "refundAmount": draft.refundAmount,
                "platformFeeImpact": draft.platformFeeImpact,
                "status": draft.status.rawValue,
                "createdAt": draft.createdAt ?? Timestamp(),
                "updatedAt": Timestamp()
            ], merge: true)
    }

    // MARK: - Withdrawal

    func buildWithdrawalDraft(
        userId: String,
        amount: Double,
        currency: MarketplaceCurrency,
        method: MarketplacePaymentProviderOption,
        countryCode: String
    ) -> MarketplaceWithdrawalDraft {
        let fee = estimateWithdrawalFee(amount: amount, method: method)
        let netAmount = max(amount - fee, 0)

        return MarketplaceWithdrawalDraft(
            id: UUID().uuidString,
            userId: userId,
            amount: amount,
            currency: currency,
            method: method,
            fee: fee,
            netAmount: netAmount,
            countryCode: countryCode,
            status: .draft,
            createdAt: Timestamp()
        )
    }

    func estimateWithdrawalFee(
        amount: Double,
        method: MarketplacePaymentProviderOption
    ) -> Double {
        switch method {
        case .paypal:
            return max(amount * 0.02, 0.50)
        case .bankTransfer:
            return 0
        case .walletCutly:
            return 0
        case .orangeMoney, .wave, .mtnMobileMoney, .moovMoney, .airtelMoney, .mpesa, .freeMoney, .tmoney, .flooz:
            return max(amount * 0.015, 0.10)
        default:
            return max(amount * 0.01, 0.10)
        }
    }

    func saveWithdrawalDraft(_ draft: MarketplaceWithdrawalDraft) async throws {
        try await Firestore.firestore()
            .collection(MarketplaceFirestoreService.Collection.withdrawals)
            .document(draft.id)
            .setData([
                "id": draft.id,
                "userId": draft.userId,
                "amount": draft.amount,
                "currency": draft.currency.rawValue,
                "method": draft.method.rawValue,
                "fee": draft.fee,
                "netAmount": draft.netAmount,
                "countryCode": draft.countryCode,
                "status": draft.status.rawValue,
                "createdAt": draft.createdAt ?? Timestamp(),
                "updatedAt": Timestamp()
            ], merge: true)
    }
    // MARK: - Escrow / Order Protection

    func buildEscrowRecord(
        orderId: String,
        paymentId: String,
        buyerId: String,
        sellerId: String,
        amount: Double,
        currency: MarketplaceCurrency
    ) -> MarketplaceEscrowRecord {
        MarketplaceEscrowRecord(
            id: UUID().uuidString,
            orderId: orderId,
            paymentId: paymentId,
            buyerId: buyerId,
            sellerId: sellerId,
            amount: amount,
            currency: currency,
            status: .held,
            createdAt: Timestamp()
        )
    }

    func saveEscrowRecord(_ escrow: MarketplaceEscrowRecord) async throws {
        try await Firestore.firestore()
            .collection("marketplace_escrow_records")
            .document(escrow.id)
            .setData([
                "id": escrow.id,
                "orderId": escrow.orderId,
                "paymentId": escrow.paymentId,
                "buyerId": escrow.buyerId,
                "sellerId": escrow.sellerId,
                "amount": escrow.amount,
                "currency": escrow.currency.rawValue,
                "status": escrow.status.rawValue,
                "createdAt": escrow.createdAt ?? Timestamp(),
                "updatedAt": Timestamp()
            ], merge: true)
    }

    func releaseEscrowAfterDelivery(
        escrowId: String,
        sellerId: String
    ) async throws {
        try await Firestore.firestore()
            .collection("marketplace_escrow_records")
            .document(escrowId)
            .setData([
                "status": MarketplaceEscrowStatus.released.rawValue,
                "releasedToSellerId": sellerId,
                "releasedAt": Timestamp(),
                "updatedAt": Timestamp()
            ], merge: true)
    }

    func holdEscrowForDispute(
        escrowId: String,
        disputeId: String
    ) async throws {
        try await Firestore.firestore()
            .collection("marketplace_escrow_records")
            .document(escrowId)
            .setData([
                "status": MarketplaceEscrowStatus.disputed.rawValue,
                "disputeId": disputeId,
                "updatedAt": Timestamp()
            ], merge: true)
    }
    // MARK: - Product Variants

    func finalUnitPrice(
        basePrice: Double,
        selectedVariant: MarketplaceSelectedProductVariant?
    ) -> Double {
        max(basePrice + (selectedVariant?.totalPriceImpact ?? 0), 0)
    }

    func selectedProductImageURL(
        productDefaultImageURL: String?,
        selectedVariant: MarketplaceSelectedProductVariant?
    ) -> String? {
        selectedVariant?.selectedImageURL ?? productDefaultImageURL
    }

    func canBuySelectedVariant(
        selectedVariant: MarketplaceSelectedProductVariant?,
        quantity: Int
    ) -> Bool {
        let safeQuantity = max(quantity, 1)

        guard let selectedVariant else {
            return true
        }

        guard selectedVariant.isAvailable else {
            return false
        }

        let options = [
            selectedVariant.color,
            selectedVariant.size,
            selectedVariant.material,
            selectedVariant.model,
            selectedVariant.storage
        ].compactMap { $0 } + selectedVariant.customOptions

        return options.allSatisfy { $0.stock >= safeQuantity }
    }
    
    
    
    
    // MARK: - Marketplace Order Calculator

    func calculateOrderTotal(
        productUnitPrice: Double,
        quantity: Int,
        currency: MarketplaceCurrency,
        shippingOption: MarketplaceShippingPriceOption?,
        discountAmount: Double = 0,
        couponAmount: Double = 0,
        buyerProtectionFee: Double = 0,
        estimatedTaxRate: Double = 0,
        selectedPaymentProvider: MarketplacePaymentProviderOption,
        platformCommissionRate: Double? = nil
    ) -> MarketplaceOrderCalculationResult {

        let safeQuantity = max(quantity, 1)

        let itemsSubtotal = productUnitPrice * Double(safeQuantity)

        let totalDiscount = min(
            max(discountAmount, 0) + max(couponAmount, 0),
            itemsSubtotal
        )

        let subtotalAfterDiscount = max(itemsSubtotal - totalDiscount, 0)

        let shippingFee = shippingOption?.price ?? 0

        let taxableBase = subtotalAfterDiscount + shippingFee + buyerProtectionFee

        let estimatedTaxAmount = max(taxableBase * max(estimatedTaxRate, 0), 0)

        let buyerTotal = subtotalAfterDiscount
            + shippingFee
            + buyerProtectionFee
            + estimatedTaxAmount

        let providerFee = estimateProviderFee(
            amount: buyerTotal,
            provider: selectedPaymentProvider
        )

        let platformCommission = calculatePlatformCommission(
            amount: subtotalAfterDiscount,
            customRate: platformCommissionRate
        )

        let sellerGrossAmount = subtotalAfterDiscount

        let sellerNetAmount = max(
            sellerGrossAmount - platformCommission,
            0
        )

        return MarketplaceOrderCalculationResult(
            id: UUID().uuidString,
            currency: currency,
            quantity: safeQuantity,
            productUnitPrice: productUnitPrice,
            itemsSubtotal: itemsSubtotal,
            discountAmount: totalDiscount,
            subtotalAfterDiscount: subtotalAfterDiscount,
            shippingFee: shippingFee,
            buyerProtectionFee: buyerProtectionFee,
            estimatedTaxRate: estimatedTaxRate,
            estimatedTaxAmount: estimatedTaxAmount,
            providerFee: providerFee,
            platformCommission: platformCommission,
            sellerGrossAmount: sellerGrossAmount,
            sellerNetAmount: sellerNetAmount,
            buyerTotal: buyerTotal,
            selectedPaymentProvider: selectedPaymentProvider,
            shippingOption: shippingOption,
            createdAt: Timestamp()
        )
    }

    func estimateShippingPrice(
        basePrice: Double,
        quantity: Int,
        totalWeightKg: Double,
        sameParcel: Bool = true
    ) -> Double {

        let safeBasePrice = max(basePrice, 0)
        let safeQuantity = max(quantity, 1)
        let safeWeight = max(totalWeightKg, 0)

        if sameParcel {
            switch safeWeight {
            case 0...0.5:
                return safeBasePrice
            case 0.5001...1.0:
                return safeBasePrice + 1.50
            case 1.0001...2.0:
                return safeBasePrice + 3.00
            case 2.0001...5.0:
                return safeBasePrice + 6.00
            default:
                return safeBasePrice + 10.00
            }
        } else {
            return safeBasePrice * Double(safeQuantity)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    // MARK: - Payment Risk

    func evaluatePaymentRisk(
        amount: Double,
        provider: MarketplacePaymentProviderOption,
        buyerCountryCode: String,
        sellerCountryCode: String?,
        refundHistoryCount: Int = 0,
        disputeHistoryCount: Int = 0
    ) -> MarketplacePaymentRiskResult {
        var score = 0.0
        var reasons: [String] = []

        if amount >= 500 {
            score += 0.25
            reasons.append("Montant élevé")
        }

        if provider == .manual {
            score += 0.20
            reasons.append("Traitement manuel")
        }

        if provider.isMobileMoney {
            score += 0.08
            reasons.append("Mobile Money")
        }

        if let sellerCountryCode, buyerCountryCode.uppercased() != sellerCountryCode.uppercased() {
            score += 0.12
            reasons.append("Transaction internationale")
        }

        if refundHistoryCount >= 3 {
            score += 0.25
            reasons.append("Remboursements fréquents")
        }

        if disputeHistoryCount >= 2 {
            score += 0.25
            reasons.append("Historique de litiges")
        }

        let finalScore = min(score, 1.0)

        return MarketplacePaymentRiskResult(
            id: UUID().uuidString,
            score: finalScore,
            level: MarketplacePaymentRiskLevel.level(for: finalScore),
            reasons: reasons,
            shouldRequireManualReview: finalScore >= 0.55,
            createdAt: Timestamp()
        )
    }
    
    
    
    
    
}

// MARK: - Payment Provider Option

enum MarketplacePaymentProviderOption: String, Codable, CaseIterable, Identifiable {
    case stripe
    case applePay
    case googlePay
    case paypal
    case cards
    case bankTransfer
    case walletCutly

    case orangeMoney
    case wave
    case mtnMobileMoney
    case moovMoney
    case airtelMoney
    case mpesa
    case freeMoney
    case tmoney
    case flooz

    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stripe: return "Stripe"
        case .applePay: return "Apple Pay"
        case .googlePay: return "Google Pay"
        case .paypal: return "PayPal"
        case .cards: return "Carte bancaire"
        case .bankTransfer: return "Virement bancaire"
        case .walletCutly: return "Wallet Cutly"
        case .orangeMoney: return "Orange Money"
        case .wave: return "Wave"
        case .mtnMobileMoney: return "MTN Mobile Money"
        case .moovMoney: return "Moov Money"
        case .airtelMoney: return "Airtel Money"
        case .mpesa: return "M-Pesa"
        case .freeMoney: return "Free Money"
        case .tmoney: return "TMoney"
        case .flooz: return "Flooz"
        case .manual: return "Traitement manuel"
        }
    }

    var isMobileMoney: Bool {
        switch self {
        case .orangeMoney, .wave, .mtnMobileMoney, .moovMoney, .airtelMoney, .mpesa, .freeMoney, .tmoney, .flooz:
            return true
        default:
            return false
        }
    }
}

// MARK: - Payment Draft

struct MarketplacePaymentDraft: Codable, Identifiable, Hashable {
    var id: String
    var orderId: String
    var buyerId: String
    var sellerId: String

    var amount: Double
    var currency: MarketplaceCurrency

    var provider: MarketplacePaymentProviderOption
    var providerFee: Double
    var platformCommission: Double
    var sellerNetAmount: Double

    var status: MarketplacePaymentDraftStatus

    var buyerCountryCode: String
    var sellerCountryCode: String?

    var createdAt: Timestamp?
}

enum MarketplacePaymentDraftStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case pending
    case processing
    case succeeded
    case failed
    case cancelled
    case refunded
    
    var id: String { rawValue }
    
}
struct MarketplaceRefundDraft: Codable, Identifiable, Hashable {
    var id: String
    var originalAmount: Double
    var refundAmount: Double
    var platformFeeImpact: Double
    var status: MarketplaceRefundDraftStatus
    var createdAt: Timestamp?
}

enum MarketplaceRefundDraftStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case pending
    case approved
    case processing
    case succeeded
    case failed
    case rejected

    var id: String { rawValue }
}

struct MarketplaceWithdrawalDraft: Codable, Identifiable, Hashable {
    var id: String
    var userId: String
    var amount: Double
    var currency: MarketplaceCurrency
    var method: MarketplacePaymentProviderOption
    var fee: Double
    var netAmount: Double
    var countryCode: String
    var status: MarketplaceWithdrawalDraftStatus
    var createdAt: Timestamp?
}

enum MarketplaceWithdrawalDraftStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case pending
    case reviewing
    case processing
    case succeeded
    case failed
    case rejected

    var id: String { rawValue }
}
struct MarketplaceEscrowRecord: Codable, Identifiable, Hashable {
    var id: String
    var orderId: String
    var paymentId: String
    var buyerId: String
    var sellerId: String
    var amount: Double
    var currency: MarketplaceCurrency
    var status: MarketplaceEscrowStatus
    var createdAt: Timestamp?
}

enum MarketplaceEscrowStatus: String, Codable, CaseIterable, Identifiable {
    case held
    case released
    case refunded
    case disputed
    case cancelled

    var id: String { rawValue }
}

struct MarketplacePaymentRiskResult: Codable, Identifiable, Hashable {
    var id: String
    var score: Double
    var level: MarketplacePaymentRiskLevel
    var reasons: [String]
    var shouldRequireManualReview: Bool
    var createdAt: Timestamp?
}

enum MarketplacePaymentRiskLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high
    case critical

    var id: String { rawValue }

    static func level(for score: Double) -> MarketplacePaymentRiskLevel {
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






// MARK: - Order Calculation Result

struct MarketplaceOrderCalculationResult: Codable, Identifiable, Hashable {
    var id: String

    var currency: MarketplaceCurrency
    var quantity: Int

    var productUnitPrice: Double
    var itemsSubtotal: Double

    var discountAmount: Double
    var subtotalAfterDiscount: Double

    var shippingFee: Double
    var buyerProtectionFee: Double

    var estimatedTaxRate: Double
    var estimatedTaxAmount: Double

    var providerFee: Double
    var platformCommission: Double

    var sellerGrossAmount: Double
    var sellerNetAmount: Double

    var buyerTotal: Double

    var selectedPaymentProvider: MarketplacePaymentProviderOption
    var shippingOption: MarketplaceShippingPriceOption?

    var createdAt: Timestamp?

    var totalText: String {
        String(format: "%.2f %@", buyerTotal, currency.rawValue)
    }

    var sellerNetText: String {
        String(format: "%.2f %@", sellerNetAmount, currency.rawValue)
    }

    var shippingText: String {
        String(format: "%.2f %@", shippingFee, currency.rawValue)
    }

    var taxText: String {
        String(format: "%.2f %@", estimatedTaxAmount, currency.rawValue)
    }
}

// MARK: - Shipping Price Option

struct MarketplaceShippingPriceOption: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var carrierName: String
    var deliveryType: MarketplaceDeliveryType
    var price: Double
    var estimatedDaysMin: Int
    var estimatedDaysMax: Int
    var pickupPointId: String?
    var pickupPointName: String?
    var pickupPointAddress: String?
    var isRecommended: Bool
}

enum MarketplaceDeliveryType: String, Codable, CaseIterable, Identifiable {
    case homeDelivery
    case pickupPoint
    case localPostOffice
    case agency
    case handDelivery
    case international

    var id: String { rawValue }

    var title: String {
        switch self {
        case .homeDelivery: return "Livraison à domicile"
        case .pickupPoint: return "Point relais"
        case .localPostOffice: return "Bureau de poste"
        case .agency: return "Agence locale"
        case .handDelivery: return "Remise en main propre"
        case .international: return "Livraison internationale"
        }
    }
}
// MARK: - Product Variant Selection

struct MarketplaceProductVariantOption: Codable, Identifiable, Hashable {
    var id: String
    var type: MarketplaceProductVariantType
    var title: String
    var value: String
    var imageURL: String?
    var priceImpact: Double
    var stock: Int
    var isAvailable: Bool

    var displayTitle: String {
        if priceImpact > 0 {
            return "\(title) +\(String(format: "%.2f", priceImpact))"
        }
        return title
    }
}

enum MarketplaceProductVariantType: String, Codable, CaseIterable, Identifiable {
    case color
    case size
    case material
    case model
    case storage
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .color: return "Couleur"
        case .size: return "Taille"
        case .material: return "Matière"
        case .model: return "Modèle"
        case .storage: return "Stockage"
        case .custom: return "Option"
        }
    }
}

struct MarketplaceSelectedProductVariant: Codable, Identifiable, Hashable {
    var id: String
    var color: MarketplaceProductVariantOption?
    var size: MarketplaceProductVariantOption?
    var material: MarketplaceProductVariantOption?
    var model: MarketplaceProductVariantOption?
    var storage: MarketplaceProductVariantOption?
    var customOptions: [MarketplaceProductVariantOption]

    var selectedImageURL: String? {
        color?.imageURL
        ?? model?.imageURL
        ?? material?.imageURL
        ?? customOptions.first(where: { $0.imageURL != nil })?.imageURL
    }

    var totalPriceImpact: Double {
        let sizeImpact = size?.priceImpact ?? 0
        let materialImpact = material?.priceImpact ?? 0
        let modelImpact = model?.priceImpact ?? 0
        let storageImpact = storage?.priceImpact ?? 0

        let base =
            sizeImpact +
            materialImpact +
            modelImpact +
            storageImpact

        return base + customOptions.reduce(0) { $0 + $1.priceImpact }
    }

    var isAvailable: Bool {
        let options = [color, size, material, model, storage].compactMap { $0 } + customOptions
        return options.allSatisfy { $0.isAvailable && $0.stock > 0 }
    }
}
