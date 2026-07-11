//
//  MarketplaceAnalyticsService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import Foundation
import FirebaseFirestore

final class MarketplaceAnalyticsService {
    
    static let shared = MarketplaceAnalyticsService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Marketplace Overview
    
    func buildMarketplaceOverview(
        totalOrders: Int,
        completedOrders: Int,
        cancelledOrders: Int,
        totalRevenue: Double,
        platformRevenue: Double,
        activeProducts: Int,
        activeStores: Int,
        activeUsers: Int
    ) -> MarketplaceOverviewAnalytics {
        
        let completionRate: Double
        
        if totalOrders == 0 {
            completionRate = 0
        } else {
            completionRate = Double(completedOrders) / Double(totalOrders)
        }
        
        let cancellationRate: Double
        
        if totalOrders == 0 {
            cancellationRate = 0
        } else {
            cancellationRate = Double(cancelledOrders) / Double(totalOrders)
        }
        
        return MarketplaceOverviewAnalytics(
            id: UUID().uuidString,
            totalOrders: totalOrders,
            completedOrders: completedOrders,
            cancelledOrders: cancelledOrders,
            completionRate: completionRate,
            cancellationRate: cancellationRate,
            totalRevenue: totalRevenue,
            platformRevenue: platformRevenue,
            activeProducts: activeProducts,
            activeStores: activeStores,
            activeUsers: activeUsers,
            createdAt: Timestamp()
        )
    }
    
    // MARK: - Seller Dashboard
    
    func buildSellerAnalytics(
        sellerId: String,
        productsCount: Int,
        totalViews: Int,
        totalSales: Int,
        totalRevenue: Double,
        averageRating: Double,
        followers: Int
    ) -> MarketplaceSellerDashboardAnalytics {
        
        let conversionRate: Double
        
        if totalViews == 0 {
            conversionRate = 0
        } else {
            conversionRate = Double(totalSales) / Double(totalViews)
        }
        
        return MarketplaceSellerDashboardAnalytics(
            id: UUID().uuidString,
            sellerId: sellerId,
            productsCount: productsCount,
            totalViews: totalViews,
            totalSales: totalSales,
            totalRevenue: totalRevenue,
            conversionRate: conversionRate,
            averageRating: averageRating,
            followers: followers,
            createdAt: Timestamp()
        )
    }
    
    // MARK: - Product Analytics
    
    func buildProductAnalytics(
        productId: String,
        views: Int,
        favorites: Int,
        purchases: Int,
        shares: Int
    ) -> MarketplaceProductAnalytics {
        
        let conversionRate: Double
        
        if views == 0 {
            conversionRate = 0
        } else {
            conversionRate = Double(purchases) / Double(views)
        }
        
        return MarketplaceProductAnalytics(
            id: UUID().uuidString,
            productId: productId,
            views: views,
            favorites: favorites,
            purchases: purchases,
            shares: shares,
            conversionRate: conversionRate,
            createdAt: Timestamp()
        )
    }
    
    // MARK: - Save
    
    func saveOverview(_ analytics: MarketplaceOverviewAnalytics) async throws {
        try db.collection(MarketplaceFirestoreService.Collection.overviewAnalytics)
            .document(analytics.id)
            .setData(from: analytics, merge: true)
    }
    
    func saveSellerAnalytics(_ analytics: MarketplaceSellerDashboardAnalytics) async throws {
        try db.collection(MarketplaceFirestoreService.Collection.sellerAnalytics)
            .document(analytics.id)
            .setData(from: analytics, merge: true)
    }
    
    func saveProductAnalytics(_ analytics: MarketplaceProductAnalytics) async throws {
        try db.collection(MarketplaceFirestoreService.Collection.productAnalytics)
            .document(analytics.id)
            .setData(from: analytics, merge: true)
    }
    // MARK: - Country Analytics

    func buildCountryAnalytics(
        countryCode: String,
        orders: Int,
        revenue: Double,
        buyers: Int,
        sellers: Int
    ) -> MarketplaceCountryMarketAnalytics {

        MarketplaceCountryMarketAnalytics(
            id: UUID().uuidString,
            countryCode: countryCode.uppercased(),
            orders: orders,
            revenue: revenue,
            buyers: buyers,
            sellers: sellers,
            createdAt: Timestamp()
        )
    }

    // MARK: - Payment Analytics

    func buildPaymentAnalytics(
        provider: MarketplacePaymentProviderOption,
        successfulPayments: Int,
        failedPayments: Int,
        refundedPayments: Int,
        volume: Double
    ) -> MarketplacePaymentAnalytics {

        let successRate: Double

        let total = successfulPayments + failedPayments

        if total == 0 {
            successRate = 0
        } else {
            successRate = Double(successfulPayments) / Double(total)
        }

        return MarketplacePaymentAnalytics(
            id: UUID().uuidString,
            provider: provider,
            successfulPayments: successfulPayments,
            failedPayments: failedPayments,
            refundedPayments: refundedPayments,
            volume: volume,
            successRate: successRate,
            createdAt: Timestamp()
        )
    }

    // MARK: - Shipping Analytics

    func buildShippingAnalytics(
        carrier: MarketplaceCarrier,
        delivered: Int,
        delayed: Int,
        returned: Int,
        averageDays: Double
    ) -> MarketplaceShippingAnalytics {

        MarketplaceShippingAnalytics(
            id: UUID().uuidString,
            carrier: carrier,
            delivered: delivered,
            delayed: delayed,
            returned: returned,
            averageDeliveryDays: averageDays,
            createdAt: Timestamp()
        )
    }

    // MARK: - AI Analytics

    func buildAIAnalytics(
        detectedFrauds: Int,
        blockedProducts: Int,
        blockedAccounts: Int,
        suspiciousPayments: Int
    ) -> MarketplaceAIAnalytics {

        MarketplaceAIAnalytics(
            id: UUID().uuidString,
            detectedFrauds: detectedFrauds,
            blockedProducts: blockedProducts,
            blockedAccounts: blockedAccounts,
            suspiciousPayments: suspiciousPayments,
            createdAt: Timestamp()
        )
    }

    // MARK: - Save

    func saveCountryAnalytics(_ analytics: MarketplaceCountryMarketAnalytics) async throws {
        try db.collection(MarketplaceFirestoreService.Collection.countryAnalytics)
            .document(analytics.id)
            .setData(from: analytics, merge: true)
    }

    func savePaymentAnalytics(_ analytics: MarketplacePaymentAnalytics) async throws {
        try db.collection(MarketplaceFirestoreService.Collection.paymentAnalytics)
            .document(analytics.id)
            .setData(from: analytics, merge: true)
    }

    func saveShippingAnalytics(_ analytics: MarketplaceShippingAnalytics) async throws {
        try db.collection(MarketplaceFirestoreService.Collection.shippingAnalytics)
            .document(analytics.id)
            .setData(from: analytics, merge: true)
    }

    func saveAIAnalytics(_ analytics: MarketplaceAIAnalytics) async throws {
        try db.collection(MarketplaceFirestoreService.Collection.aiAnalytics)
            .document(analytics.id)
            .setData(from: analytics, merge: true)
    }
    // MARK: - Event Tracking

    func trackEvent(
        userId: String?,
        eventType: MarketplaceAnalyticsEventType,
        targetId: String?,
        targetType: String?,
        metadata: [String: String] = [:]
    ) async throws {
        let ref = db.collection(MarketplaceFirestoreService.Collection.userActions).document()

        try await ref.setData([
            "id": ref.documentID,
            "userId": userId ?? "",
            "eventType": eventType.rawValue,
            "targetId": targetId ?? "",
            "targetType": targetType ?? "",
            "metadata": metadata,
            "createdAt": Timestamp(),
            "source": "marketplace"
        ], merge: true)
    }

    func trackProductView(
        userId: String?,
        productId: String,
        sellerId: String?
    ) async throws {
        try await trackEvent(
            userId: userId,
            eventType: .productView,
            targetId: productId,
            targetType: "product",
            metadata: [
                "sellerId": sellerId ?? ""
            ]
        )
    }

    func trackFavorite(
        userId: String,
        productId: String
    ) async throws {
        try await trackEvent(
            userId: userId,
            eventType: .favorite,
            targetId: productId,
            targetType: "product"
        )
    }

    func trackShare(
        userId: String?,
        targetId: String,
        targetType: String
    ) async throws {
        try await trackEvent(
            userId: userId,
            eventType: .share,
            targetId: targetId,
            targetType: targetType
        )
    }

    func trackPurchase(
        buyerId: String,
        sellerId: String,
        orderId: String,
        amount: Double,
        currency: MarketplaceCurrency
    ) async throws {
        try await trackEvent(
            userId: buyerId,
            eventType: .purchase,
            targetId: orderId,
            targetType: "order",
            metadata: [
                "sellerId": sellerId,
                "amount": "\(amount)",
                "currency": currency.rawValue
            ]
        )
    }

    func trackSearch(
        userId: String?,
        query: String
    ) async throws {
        try await trackEvent(
            userId: userId,
            eventType: .search,
            targetId: nil,
            targetType: "search",
            metadata: [
                "query": query
            ]
        )
    }

    func trackConversion(
        userId: String,
        productId: String,
        orderId: String,
        amount: Double
    ) async throws {
        try await trackEvent(
            userId: userId,
            eventType: .conversion,
            targetId: productId,
            targetType: "product",
            metadata: [
                "orderId": orderId,
                "amount": "\(amount)"
            ]
        )
    }
    
    
    
}

// MARK: - Models

struct MarketplaceOverviewAnalytics: Codable, Identifiable, Hashable {

    var id: String

    var totalOrders: Int
    var completedOrders: Int
    var cancelledOrders: Int

    var completionRate: Double
    var cancellationRate: Double

    var totalRevenue: Double
    var platformRevenue: Double

    var activeProducts: Int
    var activeStores: Int
    var activeUsers: Int

    var createdAt: Timestamp?
}

struct MarketplaceSellerDashboardAnalytics: Codable, Identifiable, Hashable {

    var id: String

    var sellerId: String

    var productsCount: Int

    var totalViews: Int
    var totalSales: Int

    var totalRevenue: Double

    var conversionRate: Double

    var averageRating: Double

    var followers: Int

    var createdAt: Timestamp?
}

struct MarketplaceProductAnalytics: Codable, Identifiable, Hashable {

    var id: String

    var productId: String

    var views: Int
    var favorites: Int
    var purchases: Int
    var shares: Int

    var conversionRate: Double

    var createdAt: Timestamp?
}
struct MarketplaceCountryMarketAnalytics: Codable, Identifiable, Hashable {
    var id: String
    var countryCode: String
    var orders: Int
    var revenue: Double
    var buyers: Int
    var sellers: Int
    var createdAt: Timestamp?
}

struct MarketplacePaymentAnalytics: Codable, Identifiable, Hashable {
    var id: String
    var provider: MarketplacePaymentProviderOption
    var successfulPayments: Int
    var failedPayments: Int
    var refundedPayments: Int
    var volume: Double
    var successRate: Double
    var createdAt: Timestamp?
}

struct MarketplaceShippingAnalytics: Codable, Identifiable, Hashable {
    var id: String
    var carrier: MarketplaceCarrier
    var delivered: Int
    var delayed: Int
    var returned: Int
    var averageDeliveryDays: Double
    var createdAt: Timestamp?
}

struct MarketplaceAIAnalytics: Codable, Identifiable, Hashable {
    var id: String
    var detectedFrauds: Int
    var blockedProducts: Int
    var blockedAccounts: Int
    var suspiciousPayments: Int
    var createdAt: Timestamp?
}
enum MarketplaceAnalyticsEventType: String, Codable, CaseIterable, Identifiable {
    case productView
    case storeView
    case favorite
    case unfavorite
    case share
    case search
    case addToCart
    case checkoutStarted
    case purchase
    case conversion
    case messageSeller
    case reviewCreated
    case disputeOpened
    case refundRequested
    case trackingOpened

    var id: String { rawValue }
}
