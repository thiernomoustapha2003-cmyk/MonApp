//
//  MarketplaceReviewModels.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Review Target Type

enum MarketplaceReviewTargetType: String, Codable, CaseIterable, Identifiable {
    case product
    case store
    case seller
    case buyer
    case order

    var id: String { rawValue }

    var title: String {
        switch self {
        case .product: return "Produit"
        case .store: return "Boutique"
        case .seller: return "Vendeur"
        case .buyer: return "Acheteur"
        case .order: return "Commande"
        }
    }
}

// MARK: - Review Media

struct MarketplaceReviewMedia: Codable, Identifiable, Hashable {
    var id: String
    var url: String
    var thumbnailURL: String?
    var type: MarketplaceMediaType
    var position: Int

    init(
        id: String = UUID().uuidString,
        url: String,
        thumbnailURL: String? = nil,
        type: MarketplaceMediaType = .image,
        position: Int = 0
    ) {
        self.id = id
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.type = type
        self.position = position
    }
}

// MARK: - Marketplace Review Status

enum MarketplaceReviewStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case published
    case hidden
    case flagged
    case removed
    case underReview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "En attente"
        case .published: return "Publié"
        case .hidden: return "Masqué"
        case .flagged: return "Signalé"
        case .removed: return "Supprimé"
        case .underReview: return "En vérification"
        }
    }
}

// MARK: - Marketplace Review

struct MarketplaceReview: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var targetType: MarketplaceReviewTargetType
    var targetId: String

    var orderId: String?
    var productId: String?
    var storeId: String?

    var reviewerId: String
    var reviewerName: String?
    var reviewerAvatarURL: String?

    var sellerId: String?
    var buyerId: String?

    var rating: Int
    var title: String?
    var comment: String?

    var media: [MarketplaceReviewMedia]

    var usefulCount: Int
    var reportCount: Int

    var isVerifiedPurchase: Bool
    var isEdited: Bool
    var status: MarketplaceReviewStatus

    var aiAuthenticityScore: Double?
    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var createdAt: Timestamp?
    var updatedAt: Timestamp?
    var editedAt: Timestamp?

    init(
        id: String? = nil,
        targetType: MarketplaceReviewTargetType,
        targetId: String,
        orderId: String? = nil,
        productId: String? = nil,
        storeId: String? = nil,
        reviewerId: String,
        reviewerName: String? = nil,
        reviewerAvatarURL: String? = nil,
        sellerId: String? = nil,
        buyerId: String? = nil,
        rating: Int,
        title: String? = nil,
        comment: String? = nil,
        media: [MarketplaceReviewMedia] = [],
        usefulCount: Int = 0,
        reportCount: Int = 0,
        isVerifiedPurchase: Bool = false,
        isEdited: Bool = false,
        status: MarketplaceReviewStatus = .pending,
        aiAuthenticityScore: Double? = nil,
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil,
        editedAt: Timestamp? = nil
    ) {
        self.id = id
        self.targetType = targetType
        self.targetId = targetId
        self.orderId = orderId
        self.productId = productId
        self.storeId = storeId
        self.reviewerId = reviewerId
        self.reviewerName = reviewerName
        self.reviewerAvatarURL = reviewerAvatarURL
        self.sellerId = sellerId
        self.buyerId = buyerId
        self.rating = rating
        self.title = title
        self.comment = comment
        self.media = media
        self.usefulCount = usefulCount
        self.reportCount = reportCount
        self.isVerifiedPurchase = isVerifiedPurchase
        self.isEdited = isEdited
        self.status = status
        self.aiAuthenticityScore = aiAuthenticityScore
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.editedAt = editedAt
    }
}

// MARK: - Marketplace Review Summary

struct MarketplaceReviewSummary: Codable, Hashable {
    var averageRating: Double
    var totalReviews: Int

    var fiveStars: Int
    var fourStars: Int
    var threeStars: Int
    var twoStars: Int
    var oneStar: Int

    var photoReviewsCount: Int
    var videoReviewsCount: Int
    var verifiedPurchaseCount: Int

    init(
        averageRating: Double = 0,
        totalReviews: Int = 0,
        fiveStars: Int = 0,
        fourStars: Int = 0,
        threeStars: Int = 0,
        twoStars: Int = 0,
        oneStar: Int = 0,
        photoReviewsCount: Int = 0,
        videoReviewsCount: Int = 0,
        verifiedPurchaseCount: Int = 0
    ) {
        self.averageRating = averageRating
        self.totalReviews = totalReviews
        self.fiveStars = fiveStars
        self.fourStars = fourStars
        self.threeStars = threeStars
        self.twoStars = twoStars
        self.oneStar = oneStar
        self.photoReviewsCount = photoReviewsCount
        self.videoReviewsCount = videoReviewsCount
        self.verifiedPurchaseCount = verifiedPurchaseCount
    }
}

// MARK: - Marketplace Review Vote

struct MarketplaceReviewVote: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var reviewId: String
    var userId: String
    var isUseful: Bool

    var createdAt: Timestamp?

    init(
        id: String? = nil,
        reviewId: String,
        userId: String,
        isUseful: Bool = true,
        createdAt: Timestamp? = nil
    ) {
        self.id = id
        self.reviewId = reviewId
        self.userId = userId
        self.isUseful = isUseful
        self.createdAt = createdAt
    }
}
