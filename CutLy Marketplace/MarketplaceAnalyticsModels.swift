//
//  MarketplaceAnalyticsModels.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Marketplace Analytics Period

enum MarketplaceAnalyticsPeriod: String, Codable, CaseIterable, Identifiable {
    case today
    case sevenDays
    case twentyEightDays
    case sixtyDays
    case year
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Aujourd’hui"
        case .sevenDays: return "7 jours"
        case .twentyEightDays: return "28 jours"
        case .sixtyDays: return "60 jours"
        case .year: return "1 an"
        case .custom: return "Personnalisé"
        }
    }
}

// MARK: - Marketplace Analytics KPI

struct MarketplaceAnalyticsKPI: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var value: Double
    var formattedValue: String
    var previousValue: Double?
    var changePercent: Double?
    var iconName: String
    var isPositiveTrend: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        value: Double,
        formattedValue: String,
        previousValue: Double? = nil,
        changePercent: Double? = nil,
        iconName: String = "chart.line.uptrend.xyaxis",
        isPositiveTrend: Bool = true
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.formattedValue = formattedValue
        self.previousValue = previousValue
        self.changePercent = changePercent
        self.iconName = iconName
        self.isPositiveTrend = isPositiveTrend
    }
}

// MARK: - Marketplace Revenue Point

struct MarketplaceRevenuePoint: Codable, Identifiable, Hashable {
    var id: String
    var dateKey: String
    var revenue: Double
    var ordersCount: Int
    var commission: Double
    var currency: MarketplaceCurrency

    init(
        id: String = UUID().uuidString,
        dateKey: String,
        revenue: Double = 0,
        ordersCount: Int = 0,
        commission: Double = 0,
        currency: MarketplaceCurrency = .eur
    ) {
        self.id = id
        self.dateKey = dateKey
        self.revenue = revenue
        self.ordersCount = ordersCount
        self.commission = commission
        self.currency = currency
    }
}

// MARK: - Marketplace Country Analytics

struct MarketplaceCountryAnalytics: Codable, Identifiable, Hashable {
    var id: String
    var countryCode: String
    var countryName: String

    var revenue: Double
    var ordersCount: Int
    var productsCount: Int
    var buyersCount: Int
    var sellersCount: Int
    var commission: Double

    var currency: MarketplaceCurrency

    init(
        id: String = UUID().uuidString,
        countryCode: String,
        countryName: String,
        revenue: Double = 0,
        ordersCount: Int = 0,
        productsCount: Int = 0,
        buyersCount: Int = 0,
        sellersCount: Int = 0,
        commission: Double = 0,
        currency: MarketplaceCurrency = .eur
    ) {
        self.id = id
        self.countryCode = countryCode
        self.countryName = countryName
        self.revenue = revenue
        self.ordersCount = ordersCount
        self.productsCount = productsCount
        self.buyersCount = buyersCount
        self.sellersCount = sellersCount
        self.commission = commission
        self.currency = currency
    }
}

// MARK: - Marketplace Category Analytics

struct MarketplaceCategoryAnalytics: Codable, Identifiable, Hashable {
    var id: String
    var categoryId: String
    var categoryName: String

    var revenue: Double
    var ordersCount: Int
    var viewsCount: Int
    var conversionRate: Double
    var productsCount: Int

    init(
        id: String = UUID().uuidString,
        categoryId: String,
        categoryName: String,
        revenue: Double = 0,
        ordersCount: Int = 0,
        viewsCount: Int = 0,
        conversionRate: Double = 0,
        productsCount: Int = 0
    ) {
        self.id = id
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.revenue = revenue
        self.ordersCount = ordersCount
        self.viewsCount = viewsCount
        self.conversionRate = conversionRate
        self.productsCount = productsCount
    }
}

// MARK: - Marketplace Seller Analytics

struct MarketplaceSellerAnalytics: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var sellerId: String
    var storeId: String?

    var period: MarketplaceAnalyticsPeriod

    var revenue: Double
    var ordersCount: Int
    var productsSold: Int
    var viewsCount: Int
    var favoritesCount: Int
    var messagesCount: Int
    var conversionRate: Double
    var returnRate: Double
    var disputeRate: Double
    var averageRating: Double

    var currency: MarketplaceCurrency

    var revenueTimeline: [MarketplaceRevenuePoint]
    var topProducts: [String]
    var topCategories: [MarketplaceCategoryAnalytics]

    var createdAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        sellerId: String,
        storeId: String? = nil,
        period: MarketplaceAnalyticsPeriod = .sevenDays,
        revenue: Double = 0,
        ordersCount: Int = 0,
        productsSold: Int = 0,
        viewsCount: Int = 0,
        favoritesCount: Int = 0,
        messagesCount: Int = 0,
        conversionRate: Double = 0,
        returnRate: Double = 0,
        disputeRate: Double = 0,
        averageRating: Double = 0,
        currency: MarketplaceCurrency = .eur,
        revenueTimeline: [MarketplaceRevenuePoint] = [],
        topProducts: [String] = [],
        topCategories: [MarketplaceCategoryAnalytics] = [],
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.sellerId = sellerId
        self.storeId = storeId
        self.period = period
        self.revenue = revenue
        self.ordersCount = ordersCount
        self.productsSold = productsSold
        self.viewsCount = viewsCount
        self.favoritesCount = favoritesCount
        self.messagesCount = messagesCount
        self.conversionRate = conversionRate
        self.returnRate = returnRate
        self.disputeRate = disputeRate
        self.averageRating = averageRating
        self.currency = currency
        self.revenueTimeline = revenueTimeline
        self.topProducts = topProducts
        self.topCategories = topCategories
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Marketplace Admin Analytics

struct MarketplaceAdminAnalytics: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var period: MarketplaceAnalyticsPeriod

    var grossMerchandiseValue: Double
    var platformCommission: Double
    var ordersCount: Int
    var buyersCount: Int
    var sellersCount: Int
    var storesCount: Int
    var productsCount: Int
    var disputesCount: Int
    var refundsCount: Int
    var activeCountriesCount: Int

    var currency: MarketplaceCurrency

    var revenueTimeline: [MarketplaceRevenuePoint]
    var countries: [MarketplaceCountryAnalytics]
    var categories: [MarketplaceCategoryAnalytics]

    var createdAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        period: MarketplaceAnalyticsPeriod = .sevenDays,
        grossMerchandiseValue: Double = 0,
        platformCommission: Double = 0,
        ordersCount: Int = 0,
        buyersCount: Int = 0,
        sellersCount: Int = 0,
        storesCount: Int = 0,
        productsCount: Int = 0,
        disputesCount: Int = 0,
        refundsCount: Int = 0,
        activeCountriesCount: Int = 0,
        currency: MarketplaceCurrency = .eur,
        revenueTimeline: [MarketplaceRevenuePoint] = [],
        countries: [MarketplaceCountryAnalytics] = [],
        categories: [MarketplaceCategoryAnalytics] = [],
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.period = period
        self.grossMerchandiseValue = grossMerchandiseValue
        self.platformCommission = platformCommission
        self.ordersCount = ordersCount
        self.buyersCount = buyersCount
        self.sellersCount = sellersCount
        self.storesCount = storesCount
        self.productsCount = productsCount
        self.disputesCount = disputesCount
        self.refundsCount = refundsCount
        self.activeCountriesCount = activeCountriesCount
        self.currency = currency
        self.revenueTimeline = revenueTimeline
        self.countries = countries
        self.categories = categories
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
