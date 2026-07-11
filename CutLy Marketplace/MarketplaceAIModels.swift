//
//  MarketplaceAIModels.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - AI Detection Type

enum MarketplaceAIDetectionType: String, Codable, CaseIterable, Identifiable {
    case fakeSeller
    case counterfeitProduct
    case fakeReview
    case scam
    case multipleAccounts
    case prohibitedProduct
    case moneyLaundering
    case suspiciousOrder
    case abusiveRefund
    case abnormalPrice
    case stolenImages
    case spam
    case harassment
    case unsafeConversation
    case fraudPayment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fakeSeller: return "Faux vendeur"
        case .counterfeitProduct: return "Contrefaçon"
        case .fakeReview: return "Faux avis"
        case .scam: return "Arnaque"
        case .multipleAccounts: return "Comptes multiples"
        case .prohibitedProduct: return "Produit interdit"
        case .moneyLaundering: return "Blanchiment"
        case .suspiciousOrder: return "Commande suspecte"
        case .abusiveRefund: return "Remboursement abusif"
        case .abnormalPrice: return "Prix anormal"
        case .stolenImages: return "Images volées"
        case .spam: return "Spam"
        case .harassment: return "Harcèlement"
        case .unsafeConversation: return "Conversation à risque"
        case .fraudPayment: return "Paiement frauduleux"
        }
    }
}

// MARK: - AI Decision

enum MarketplaceAIDecision: String, Codable, CaseIterable, Identifiable {
    case allow
    case warn
    case limit
    case requireReview
    case hide
    case block
    case ban

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allow: return "Autoriser"
        case .warn: return "Avertir"
        case .limit: return "Limiter"
        case .requireReview: return "Vérification requise"
        case .hide: return "Masquer"
        case .block: return "Bloquer"
        case .ban: return "Bannir"
        }
    }
}

// MARK: - AI Flag

struct MarketplaceAIFlag: Codable, Identifiable, Hashable {
    var id: String

    var type: MarketplaceAIDetectionType
    var riskLevel: MarketplaceRiskLevel
    var decision: MarketplaceAIDecision

    var title: String
    var explanation: String

    var confidence: Double
    var score: Double?

    var productId: String?
    var storeId: String?
    var sellerId: String?
    var buyerId: String?
    var orderId: String?
    var paymentId: String?
    var reviewId: String?
    var messageId: String?
    var disputeId: String?

    var evidenceURLs: [String]
    var metadata: [String: String]

    var createdAt: Timestamp?
    var reviewedAt: Timestamp?
    var reviewedByAdminId: String?

    init(
        id: String = UUID().uuidString,
        type: MarketplaceAIDetectionType,
        riskLevel: MarketplaceRiskLevel = .low,
        decision: MarketplaceAIDecision = .allow,
        title: String,
        explanation: String,
        confidence: Double = 0,
        score: Double? = nil,
        productId: String? = nil,
        storeId: String? = nil,
        sellerId: String? = nil,
        buyerId: String? = nil,
        orderId: String? = nil,
        paymentId: String? = nil,
        reviewId: String? = nil,
        messageId: String? = nil,
        disputeId: String? = nil,
        evidenceURLs: [String] = [],
        metadata: [String: String] = [:],
        createdAt: Timestamp? = nil,
        reviewedAt: Timestamp? = nil,
        reviewedByAdminId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.riskLevel = riskLevel
        self.decision = decision
        self.title = title
        self.explanation = explanation
        self.confidence = confidence
        self.score = score
        self.productId = productId
        self.storeId = storeId
        self.sellerId = sellerId
        self.buyerId = buyerId
        self.orderId = orderId
        self.paymentId = paymentId
        self.reviewId = reviewId
        self.messageId = messageId
        self.disputeId = disputeId
        self.evidenceURLs = evidenceURLs
        self.metadata = metadata
        self.createdAt = createdAt
        self.reviewedAt = reviewedAt
        self.reviewedByAdminId = reviewedByAdminId
    }
}

// MARK: - AI Moderation Result

struct MarketplaceAIModerationResult: Codable, Identifiable, Hashable {
    var id: String

    var targetId: String
    var targetType: String

    var globalRiskLevel: MarketplaceRiskLevel
    var globalScore: Double

    var flags: [MarketplaceAIFlag]
    var recommendedDecision: MarketplaceAIDecision

    var summary: String
    var shouldNotifyAdmin: Bool
    var shouldNotifyUser: Bool

    var modelVersion: String?
    var createdAt: Timestamp?

    init(
        id: String = UUID().uuidString,
        targetId: String,
        targetType: String,
        globalRiskLevel: MarketplaceRiskLevel = .low,
        globalScore: Double = 0,
        flags: [MarketplaceAIFlag] = [],
        recommendedDecision: MarketplaceAIDecision = .allow,
        summary: String = "",
        shouldNotifyAdmin: Bool = false,
        shouldNotifyUser: Bool = false,
        modelVersion: String? = nil,
        createdAt: Timestamp? = nil
    ) {
        self.id = id
        self.targetId = targetId
        self.targetType = targetType
        self.globalRiskLevel = globalRiskLevel
        self.globalScore = globalScore
        self.flags = flags
        self.recommendedDecision = recommendedDecision
        self.summary = summary
        self.shouldNotifyAdmin = shouldNotifyAdmin
        self.shouldNotifyUser = shouldNotifyUser
        self.modelVersion = modelVersion
        self.createdAt = createdAt
    }
}

// MARK: - AI Recommendation Item

struct MarketplaceAIRecommendationItem: Codable, Identifiable, Hashable {
    var id: String

    var userId: String
    var productId: String
    var storeId: String?
    var categoryId: String?

    var score: Double
    var reason: String?
    var reasonTags: [String]

    var position: Int
    var source: String

    var createdAt: Timestamp?

    init(
        id: String = UUID().uuidString,
        userId: String,
        productId: String,
        storeId: String? = nil,
        categoryId: String? = nil,
        score: Double = 0,
        reason: String? = nil,
        reasonTags: [String] = [],
        position: Int = 0,
        source: String = "ai"
    ) {
        self.id = id
        self.userId = userId
        self.productId = productId
        self.storeId = storeId
        self.categoryId = categoryId
        self.score = score
        self.reason = reason
        self.reasonTags = reasonTags
        self.position = position
        self.source = source
        self.createdAt = Timestamp()
    }
}

// MARK: - AI Search Intent

struct MarketplaceAISearchIntent: Codable, Identifiable, Hashable {
    var id: String

    var userId: String?
    var query: String

    var detectedLanguageCode: String?
    var normalizedQuery: String
    var intent: String?

    var suggestedCategoryIds: [String]
    var suggestedBrands: [String]
    var suggestedFilters: [String: String]

    var confidence: Double
    var createdAt: Timestamp?

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        query: String,
        detectedLanguageCode: String? = nil,
        normalizedQuery: String,
        intent: String? = nil,
        suggestedCategoryIds: [String] = [],
        suggestedBrands: [String] = [],
        suggestedFilters: [String: String] = [:],
        confidence: Double = 0,
        createdAt: Timestamp? = nil
    ) {
        self.id = id
        self.userId = userId
        self.query = query
        self.detectedLanguageCode = detectedLanguageCode
        self.normalizedQuery = normalizedQuery
        self.intent = intent
        self.suggestedCategoryIds = suggestedCategoryIds
        self.suggestedBrands = suggestedBrands
        self.suggestedFilters = suggestedFilters
        self.confidence = confidence
        self.createdAt = createdAt
    }
}
