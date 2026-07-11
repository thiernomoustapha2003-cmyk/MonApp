//
//  MarketplaceRecommendationService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import Foundation
import FirebaseFirestore

final class MarketplaceRecommendationService {
    
    static let shared = MarketplaceRecommendationService()
    
    private let db = Firestore.firestore()
    private let searchService = MarketplaceSearchService.shared
    
    private init() {}
    
    // MARK: - Product Recommendation Score
    
    func calculateProductRecommendationScore(
        productTitle: String,
        productDescription: String,
        productCategoryId: String?,
        productCountryCode: String?,
        productPrice: Double?,
        productViews: Int,
        productFavorites: Int,
        productPurchases: Int,
        sellerIsVerified: Bool,
        storeIsProfessional: Bool,
        sellerRating: Double?,
        userPreferredCategoryIds: [String],
        userCountryCode: String?,
        userRecentKeywords: [String],
        userMinimumPrice: Double?,
        userMaximumPrice: Double?
    ) -> Double {
        
        var score = 0.0
        
        let title = searchService.normalizeQuery(productTitle)
        let description = searchService.normalizeQuery(productDescription)
        
        for keyword in userRecentKeywords {
            let cleanKeyword = searchService.normalizeQuery(keyword)
            
            if title.contains(cleanKeyword) {
                score += 3.0
            }
            
            if description.contains(cleanKeyword) {
                score += 1.2
            }
        }
        
        if let productCategoryId,
           userPreferredCategoryIds.contains(productCategoryId) {
            score += 2.4
        }
        
        if let productCountryCode,
           let userCountryCode,
           productCountryCode.uppercased() == userCountryCode.uppercased() {
            score += 1.0
        }
        
        if sellerIsVerified {
            score += 0.9
        }
        
        if storeIsProfessional {
            score += 0.6
        }
        
        if let sellerRating {
            score += min(max(sellerRating, 0), 5) * 0.25
        }
        
        score += min(Double(productViews) / 1000.0, 1.0)
        score += min(Double(productFavorites) / 300.0, 1.2)
        score += min(Double(productPurchases) / 100.0, 1.5)
        
        if let productPrice {
            if let userMinimumPrice, productPrice < userMinimumPrice {
                score -= 1.0
            }
            
            if let userMaximumPrice, productPrice > userMaximumPrice {
                score -= 1.5
            }
        }
        
        return max(score, 0)
    }
    
    // MARK: - Similarity Score
    
    func calculateSimilarityScore(
        sourceCategoryId: String?,
        targetCategoryId: String?,
        sourceKeywords: [String],
        targetTitle: String,
        targetDescription: String,
        sourcePrice: Double?,
        targetPrice: Double?
    ) -> Double {
        
        var score = 0.0
        
        if let sourceCategoryId,
           let targetCategoryId,
           sourceCategoryId == targetCategoryId {
            score += 3.0
        }
        
        let title = searchService.normalizeQuery(targetTitle)
        let description = searchService.normalizeQuery(targetDescription)
        
        for keyword in sourceKeywords {
            let cleanKeyword = searchService.normalizeQuery(keyword)
            
            if title.contains(cleanKeyword) {
                score += 2.0
            }
            
            if description.contains(cleanKeyword) {
                score += 0.8
            }
        }
        
        if let sourcePrice, let targetPrice, sourcePrice > 0 {
            let difference = abs(sourcePrice - targetPrice) / sourcePrice
            
            if difference <= 0.15 {
                score += 1.2
            } else if difference <= 0.35 {
                score += 0.6
            }
        }
        
        return max(score, 0)
    }
    
    // MARK: - User Profile
    
    func buildRecommendationProfile(
        userId: String,
        preferredCategoryIds: [String],
        preferredKeywords: [String],
        preferredCountryCodes: [String],
        averagePriceMin: Double?,
        averagePriceMax: Double?,
        lastViewedProductIds: [String],
        favoriteProductIds: [String],
        purchasedProductIds: [String]
    ) -> MarketplaceRecommendationProfileDraft {
        
        MarketplaceRecommendationProfileDraft(
            id: UUID().uuidString,
            userId: userId,
            preferredCategoryIds: preferredCategoryIds,
            preferredKeywords: preferredKeywords.map { searchService.normalizeQuery($0) },
            preferredCountryCodes: preferredCountryCodes.map { $0.uppercased() },
            averagePriceMin: averagePriceMin,
            averagePriceMax: averagePriceMax,
            lastViewedProductIds: lastViewedProductIds,
            favoriteProductIds: favoriteProductIds,
            purchasedProductIds: purchasedProductIds,
            updatedAt: Timestamp()
        )
    }
    
    func saveRecommendationProfile(
        _ profile: MarketplaceRecommendationProfileDraft
    ) async throws {
        try await db
            .collection(MarketplaceFirestoreService.Collection.recommendationProfiles)
            .document(profile.userId)
            .setData(from: profile, merge: true)
    }
    // MARK: - Trending Products

    func calculateTrendingScore(
        views: Int,
        favorites: Int,
        purchases: Int,
        shares: Int,
        averageRating: Double,
        createdAt: Date?
    ) -> Double {

        var score = 0.0

        score += min(Double(views) / 1000.0, 2.0)
        score += min(Double(favorites) / 300.0, 2.0)
        score += min(Double(purchases) / 100.0, 3.0)
        score += min(Double(shares) / 100.0, 1.5)

        score += min(max(averageRating, 0), 5) * 0.4

        if let createdAt {
            let days = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0

            if days <= 3 {
                score += 1.5
            } else if days <= 7 {
                score += 1.0
            } else if days <= 30 {
                score += 0.5
            }
        }

        return score
    }

    // MARK: - Personalized Ranking

    func rankRecommendations<T>(
        _ products: [T],
        score: (T) -> Double
    ) -> [T] {

        products.sorted {
            score($0) > score($1)
        }

    }

    // MARK: - Recommendation Explanation

    func recommendationReasons(
        isFavoriteCategory: Bool,
        sameCountry: Bool,
        verifiedSeller: Bool,
        professionalStore: Bool,
        trending: Bool,
        similarPrice: Bool
    ) -> [String] {

        var reasons: [String] = []

        if isFavoriteCategory {
            reasons.append("Correspond à vos catégories préférées")
        }

        if sameCountry {
            reasons.append("Disponible dans votre pays")
        }

        if verifiedSeller {
            reasons.append("Vendeur certifié")
        }

        if professionalStore {
            reasons.append("Boutique professionnelle")
        }

        if trending {
            reasons.append("Produit tendance")
        }

        if similarPrice {
            reasons.append("Prix similaire à vos achats")
        }

        return reasons

    }

    // MARK: - AI Recommendation

    func buildRecommendation(
        productId: String,
        sellerId: String,
        score: Double,
        reasons: [String]
    ) -> MarketplaceRecommendationResult {

        MarketplaceRecommendationResult(
            id: UUID().uuidString,
            productId: productId,
            sellerId: sellerId,
            score: score,
            reasons: reasons,
            createdAt: Timestamp()
        )

    }

    func saveRecommendation(
        _ recommendation: MarketplaceRecommendationResult
    ) async throws {

        try await db
            .collection(MarketplaceFirestoreService.Collection.aiRecommendations)
            .document(recommendation.id)
            .setData(from: recommendation, merge: true)

    }
    
    // MARK: - Home Recommendation Sections

    func buildHomeRecommendationSections(
        userId: String,
        countryCode: String?,
        preferredCategories: [String],
        recentKeywords: [String]
    ) -> [MarketplaceRecommendationSection] {
        [
            MarketplaceRecommendationSection(
                id: UUID().uuidString,
                title: "Recommandé pour vous",
                subtitle: "Basé sur vos recherches, vues, favoris et achats",
                type: .forYou,
                countryCode: countryCode,
                preferredCategories: preferredCategories,
                keywords: recentKeywords,
                createdAt: Timestamp()
            ),
            MarketplaceRecommendationSection(
                id: UUID().uuidString,
                title: "Près de vous",
                subtitle: "Produits disponibles dans votre pays ou région",
                type: .nearYou,
                countryCode: countryCode,
                preferredCategories: [],
                keywords: [],
                createdAt: Timestamp()
            ),
            MarketplaceRecommendationSection(
                id: UUID().uuidString,
                title: "Boutiques certifiées",
                subtitle: "Vendeurs vérifiés et boutiques professionnelles",
                type: .certifiedStores,
                countryCode: countryCode,
                preferredCategories: [],
                keywords: [],
                createdAt: Timestamp()
            ),
            MarketplaceRecommendationSection(
                id: UUID().uuidString,
                title: "Tendances mondiales",
                subtitle: "Produits populaires en Afrique, Europe et international",
                type: .globalTrending,
                countryCode: nil,
                preferredCategories: [],
                keywords: [],
                createdAt: Timestamp()
            )
        ]
    }

    func saveRecommendationSections(
        userId: String,
        sections: [MarketplaceRecommendationSection]
    ) async throws {
        for section in sections {
            try await db
                .collection(MarketplaceFirestoreService.Collection.recommendationSections)
                .document(section.id)
                .setData([
                    "id": section.id,
                    "userId": userId,
                    "title": section.title,
                    "subtitle": section.subtitle,
                    "type": section.type.rawValue,
                    "countryCode": section.countryCode ?? "",
                    "preferredCategories": section.preferredCategories,
                    "keywords": section.keywords,
                    "createdAt": section.createdAt ?? Timestamp()
                ], merge: true)
        }
    }

    // MARK: - Diversity / Anti Bubble

    func diversifyRecommendations<T>(
        _ items: [T],
        categoryId: (T) -> String?,
        sellerId: (T) -> String?,
        maxPerCategory: Int = 6,
        maxPerSeller: Int = 4
    ) -> [T] {
        var result: [T] = []
        var categoryCounts: [String: Int] = [:]
        var sellerCounts: [String: Int] = [:]

        for item in items {
            let category = categoryId(item) ?? "unknown"
            let seller = sellerId(item) ?? "unknown"

            if (categoryCounts[category] ?? 0) >= maxPerCategory {
                continue
            }

            if (sellerCounts[seller] ?? 0) >= maxPerSeller {
                continue
            }

            result.append(item)
            categoryCounts[category, default: 0] += 1
            sellerCounts[seller, default: 0] += 1
        }

        return result
    }
    
    // MARK: - Contextual Recommendations

    func recommendationContext(
        currentProductId: String? = nil,
        currentCategoryId: String? = nil,
        currentStoreId: String? = nil,
        userCountryCode: String? = nil,
        userRecentKeywords: [String] = [],
        source: MarketplaceRecommendationSource = .home
    ) -> MarketplaceRecommendationContext {
        MarketplaceRecommendationContext(
            id: UUID().uuidString,
            currentProductId: currentProductId,
            currentCategoryId: currentCategoryId,
            currentStoreId: currentStoreId,
            userCountryCode: userCountryCode?.uppercased(),
            userRecentKeywords: userRecentKeywords.map { searchService.normalizeQuery($0) },
            source: source,
            createdAt: Timestamp()
        )
    }

    func calculateFinalAIScore(
        baseScore: Double,
        trendingScore: Double,
        similarityScore: Double,
        sellerQualityScore: Double,
        shippingScore: Double,
        riskPenalty: Double
    ) -> Double {
        let score =
            (baseScore * 0.35) +
            (trendingScore * 0.20) +
            (similarityScore * 0.18) +
            (sellerQualityScore * 0.15) +
            (shippingScore * 0.12) -
            riskPenalty

        return max(min(score, 10.0), 0)
    }

    func sellerQualityScore(
        rating: Double?,
        completedOrders: Int,
        disputeRate: Double,
        isVerified: Bool,
        isProfessionalStore: Bool
    ) -> Double {
        var score = 0.0

        if let rating {
            score += min(max(rating, 0), 5)
        }

        score += min(Double(completedOrders) / 200.0, 2.0)

        if isVerified {
            score += 1.0
        }

        if isProfessionalStore {
            score += 0.7
        }

        score -= min(disputeRate * 3.0, 2.0)

        return max(score, 0)
    }

    func shippingAvailabilityScore(
        supportsDomestic: Bool,
        supportsInternational: Bool,
        supportsLocalPickup: Bool,
        userCountryMatchesSeller: Bool
    ) -> Double {
        var score = 0.0

        if supportsDomestic {
            score += 1.5
        }

        if supportsInternational {
            score += 1.2
        }

        if supportsLocalPickup {
            score += 0.8
        }

        if userCountryMatchesSeller {
            score += 1.0
        }

        return score
    }

    func recommendationRiskPenalty(
        aiRiskScore: Double?,
        sellerDisputeRate: Double?,
        productReportCount: Int,
        refundRate: Double?
    ) -> Double {
        var penalty = 0.0

        if let aiRiskScore {
            penalty += min(aiRiskScore * 2.0, 2.0)
        }

        if let sellerDisputeRate {
            penalty += min(sellerDisputeRate * 2.0, 1.5)
        }

        if productReportCount >= 3 {
            penalty += 1.2
        }

        if let refundRate {
            penalty += min(refundRate * 1.5, 1.5)
        }

        return penalty
    }

    func buildFinalRecommendation(
        productId: String,
        sellerId: String,
        context: MarketplaceRecommendationContext,
        finalScore: Double,
        reasons: [String]
    ) -> MarketplaceFinalRecommendation {
        MarketplaceFinalRecommendation(
            id: UUID().uuidString,
            productId: productId,
            sellerId: sellerId,
            contextId: context.id,
            source: context.source,
            finalScore: finalScore,
            reasons: reasons,
            createdAt: Timestamp()
        )
    }

    func saveFinalRecommendation(
        _ recommendation: MarketplaceFinalRecommendation
    ) async throws {
        try await db
            .collection(MarketplaceFirestoreService.Collection.aiRecommendations)
            .document(recommendation.id)
            .setData(from: recommendation, merge: true)
    }
    
    
}

// MARK: - Models

struct MarketplaceRecommendationProfileDraft: Codable, Identifiable, Hashable {
    var id: String
    var userId: String

    var preferredCategoryIds: [String]
    var preferredKeywords: [String]
    var preferredCountryCodes: [String]

    var averagePriceMin: Double?
    var averagePriceMax: Double?

    var lastViewedProductIds: [String]
    var favoriteProductIds: [String]
    var purchasedProductIds: [String]

    var updatedAt: Timestamp?
}
struct MarketplaceRecommendationResult: Codable, Identifiable, Hashable {

    var id: String

    var productId: String

    var sellerId: String

    var score: Double

    var reasons: [String]

    var createdAt: Timestamp?

}
struct MarketplaceRecommendationSection: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var type: MarketplaceRecommendationSectionType
    var countryCode: String?
    var preferredCategories: [String]
    var keywords: [String]
    var createdAt: Timestamp?
}

enum MarketplaceRecommendationSectionType: String, Codable, CaseIterable, Identifiable {
    case forYou
    case nearYou
    case certifiedStores
    case globalTrending
    case similarProducts
    case recentlyViewed
    case bestDeals
    case newArrivals

    var id: String { rawValue }
}
struct MarketplaceRecommendationContext: Codable, Identifiable, Hashable {
    var id: String
    var currentProductId: String?
    var currentCategoryId: String?
    var currentStoreId: String?
    var userCountryCode: String?
    var userRecentKeywords: [String]
    var source: MarketplaceRecommendationSource
    var createdAt: Timestamp?
}

enum MarketplaceRecommendationSource: String, Codable, CaseIterable, Identifiable {
    case home
    case productDetail
    case store
    case search
    case category
    case cart
    case checkout
    case favorites

    var id: String { rawValue }
}

struct MarketplaceFinalRecommendation: Codable, Identifiable, Hashable {
    var id: String
    var productId: String
    var sellerId: String
    var contextId: String
    var source: MarketplaceRecommendationSource
    var finalScore: Double
    var reasons: [String]
    var createdAt: Timestamp?
}
