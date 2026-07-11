//
//  MarketplaceSearchService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import Foundation
import FirebaseFirestore

final class MarketplaceSearchService {
    
    static let shared = MarketplaceSearchService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Main Search
    
    func buildSearchRequest(
        query: String,
        categoryId: String? = nil,
        countryCode: String? = nil,
        city: String? = nil,
        minimumPrice: Double? = nil,
        maximumPrice: Double? = nil,
        onlyVerified: Bool = false,
        onlyProfessionalStores: Bool = false,
        sort: MarketplaceSearchSort = .relevance
    ) -> MarketplaceSearchRequest {
        
        MarketplaceSearchRequest(
            id: UUID().uuidString,
            query: query.trimmingCharacters(in: .whitespacesAndNewlines),
            categoryId: categoryId,
            countryCode: countryCode,
            city: city,
            minimumPrice: minimumPrice,
            maximumPrice: maximumPrice,
            onlyVerified: onlyVerified,
            onlyProfessionalStores: onlyProfessionalStores,
            sort: sort,
            createdAt: Timestamp()
        )
    }
    
    // MARK: - Suggestions
    
    func buildSuggestion(
        keyword: String,
        popularity: Int
    ) -> MarketplaceSearchSuggestion {
        
        MarketplaceSearchSuggestion(
            id: UUID().uuidString,
            keyword: keyword,
            popularity: popularity,
            createdAt: Timestamp()
        )
    }
    
    // MARK: - Recent Searches
    
    func saveRecentSearch(
        userId: String,
        request: MarketplaceSearchRequest
    ) async throws {
        
        try await db
            .collection(MarketplaceFirestoreService.Collection.searchHistory)
            .document()
            .setData([
                "userId": userId,
                "query": request.query,
                "categoryId": request.categoryId ?? "",
                "countryCode": request.countryCode ?? "",
                "city": request.city ?? "",
                "minimumPrice": request.minimumPrice as Any,
                "maximumPrice": request.maximumPrice as Any,
                "verifiedOnly": request.onlyVerified,
                "professionalOnly": request.onlyProfessionalStores,
                "sort": request.sort.rawValue,
                "createdAt": Timestamp()
            ])
    }
    
    // MARK: - Trending
    
    func saveTrendingKeyword(
        _ suggestion: MarketplaceSearchSuggestion
    ) async throws {
        
        try await db
            .collection(MarketplaceFirestoreService.Collection.searchSuggestions)
            .document(suggestion.id)
            .setData(from: suggestion, merge: true)
    }
    // MARK: - Smart Query Processing

    func normalizeQuery(_ query: String) -> String {
        query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    func tokenizeQuery(_ query: String) -> [String] {
        normalizeQuery(query)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    func expandQueryWithSynonyms(_ query: String) -> [String] {
        let normalized = normalizeQuery(query)
        var results: Set<String> = [normalized]

        let synonyms: [String: [String]] = [
            "perruque": ["wig", "lace wig", "cheveux", "extension"],
            "extensions": ["extension cheveux", "hair extensions", "mèches", "meches"],
            "telephone": ["phone", "smartphone", "iphone", "android"],
            "vetement": ["habit", "mode", "fashion", "clothes"],
            "chaussure": ["shoes", "sneakers", "basket"],
            "beaute": ["beauty", "makeup", "maquillage", "cosmetique"],
            "livraison": ["delivery", "shipping", "transport"],
            "mobile money": ["orange money", "wave", "mtn", "moov", "mpesa"]
        ]

        for token in tokenizeQuery(normalized) {
            if let values = synonyms[token] {
                values.forEach { results.insert($0) }
            }
        }

        return Array(results)
    }

    func detectLikelyLanguage(query: String) -> MarketplaceSearchLanguage {
        let normalized = normalizeQuery(query)

        if normalized.range(of: #"[\u0600-\u06FF]"#, options: .regularExpression) != nil {
            return .arabic
        }

        let englishMarkers = ["the", "with", "for", "phone", "hair", "delivery", "shipping", "cheap"]
        let spanishMarkers = ["con", "para", "envio", "barato", "telefono", "ropa"]
        let frenchMarkers = ["avec", "pour", "livraison", "pas cher", "telephone", "vetement"]

        if englishMarkers.contains(where: { normalized.contains($0) }) { return .english }
        if spanishMarkers.contains(where: { normalized.contains($0) }) { return .spanish }
        if frenchMarkers.contains(where: { normalized.contains($0) }) { return .french }

        return .unknown
    }

    func buildSearchKeywords(from query: String) -> [String] {
        let tokens = tokenizeQuery(query)
        let expanded = expandQueryWithSynonyms(query)

        return Array(Set(tokens + expanded))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func buildFirestoreSearchPayload(from request: MarketplaceSearchRequest) -> [String: Any] {
        let keywords = buildSearchKeywords(from: request.query)
        let language = detectLikelyLanguage(query: request.query)

        return [
            "id": request.id,
            "query": request.query,
            "normalizedQuery": normalizeQuery(request.query),
            "keywords": keywords,
            "language": language.rawValue,
            "categoryId": request.categoryId ?? "",
            "countryCode": request.countryCode ?? "",
            "city": request.city ?? "",
            "minimumPrice": request.minimumPrice as Any,
            "maximumPrice": request.maximumPrice as Any,
            "onlyVerified": request.onlyVerified,
            "onlyProfessionalStores": request.onlyProfessionalStores,
            "sort": request.sort.rawValue,
            "createdAt": request.createdAt ?? Timestamp()
        ]
    }

    func saveSmartSearchRequest(
        userId: String?,
        request: MarketplaceSearchRequest
    ) async throws {
        var payload = buildFirestoreSearchPayload(from: request)
        payload["userId"] = userId ?? ""

        try await db
            .collection(MarketplaceFirestoreService.Collection.searchHistory)
            .document(request.id)
            .setData(payload, merge: true)
    }
    // MARK: - Search Scoring

    func calculateSearchScore(
        query: String,
        productTitle: String,
        productDescription: String,
        categoryName: String?,
        sellerIsVerified: Bool,
        storeIsProfessional: Bool,
        productCountryCode: String?,
        userCountryCode: String?,
        price: Double?,
        minimumPrice: Double?,
        maximumPrice: Double?
    ) -> Double {
        let keywords = buildSearchKeywords(from: query)
        let title = normalizeQuery(productTitle)
        let description = normalizeQuery(productDescription)
        let category = normalizeQuery(categoryName ?? "")

        var score = 0.0

        for keyword in keywords {
            if title.contains(keyword) { score += 3.0 }
            if description.contains(keyword) { score += 1.2 }
            if category.contains(keyword) { score += 1.8 }
        }

        if sellerIsVerified { score += 0.8 }
        if storeIsProfessional { score += 0.6 }

        if let productCountryCode,
           let userCountryCode,
           productCountryCode.uppercased() == userCountryCode.uppercased() {
            score += 0.7
        }

        if let price {
            if let minimumPrice, price < minimumPrice {
                score -= 2.0
            }

            if let maximumPrice, price > maximumPrice {
                score -= 2.0
            }
        }

        return max(score, 0)
    }

    func passesAdvancedFilters(
        price: Double?,
        minimumPrice: Double?,
        maximumPrice: Double?,
        isVerified: Bool,
        onlyVerified: Bool,
        isProfessionalStore: Bool,
        onlyProfessionalStores: Bool,
        countryCode: String?,
        requestedCountryCode: String?,
        city: String?,
        requestedCity: String?
    ) -> Bool {
        if let price, let minimumPrice, price < minimumPrice {
            return false
        }

        if let price, let maximumPrice, price > maximumPrice {
            return false
        }

        if onlyVerified && !isVerified {
            return false
        }

        if onlyProfessionalStores && !isProfessionalStore {
            return false
        }

        if let requestedCountryCode,
           !requestedCountryCode.isEmpty,
           countryCode?.uppercased() != requestedCountryCode.uppercased() {
            return false
        }

        if let requestedCity,
           !requestedCity.isEmpty,
           let city,
           normalizeQuery(city) != normalizeQuery(requestedCity) {
            return false
        }

        return true
    }

    func sortedSearchResults<T>(
        _ results: [T],
        sort: MarketplaceSearchSort,
        score: (T) -> Double,
        price: (T) -> Double?,
        createdAt: (T) -> Date?,
        rating: (T) -> Double?,
        popularity: (T) -> Int?,
        distanceKm: (T) -> Double?
    ) -> [T] {
        switch sort {
        case .relevance:
            return results.sorted { score($0) > score($1) }

        case .newest:
            return results.sorted {
                (createdAt($0) ?? .distantPast) > (createdAt($1) ?? .distantPast)
            }

        case .oldest:
            return results.sorted {
                (createdAt($0) ?? .distantFuture) < (createdAt($1) ?? .distantFuture)
            }

        case .lowestPrice:
            return results.sorted {
                (price($0) ?? Double.greatestFiniteMagnitude) < (price($1) ?? Double.greatestFiniteMagnitude)
            }

        case .highestPrice:
            return results.sorted {
                (price($0) ?? 0) > (price($1) ?? 0)
            }

        case .bestRated:
            return results.sorted {
                (rating($0) ?? 0) > (rating($1) ?? 0)
            }

        case .mostPopular:
            return results.sorted {
                (popularity($0) ?? 0) > (popularity($1) ?? 0)
            }

        case .nearest:
            return results.sorted {
                (distanceKm($0) ?? Double.greatestFiniteMagnitude) < (distanceKm($1) ?? Double.greatestFiniteMagnitude)
            }
        }
    }

    // MARK: - Distance

    func estimateDistanceKm(
        userLatitude: Double?,
        userLongitude: Double?,
        productLatitude: Double?,
        productLongitude: Double?
    ) -> Double? {
        guard
            let userLatitude,
            let userLongitude,
            let productLatitude,
            let productLongitude
        else {
            return nil
        }

        let earthRadiusKm = 6371.0
        let dLat = degreesToRadians(productLatitude - userLatitude)
        let dLon = degreesToRadians(productLongitude - userLongitude)

        let lat1 = degreesToRadians(userLatitude)
        let lat2 = degreesToRadians(productLatitude)

        let a = sin(dLat / 2) * sin(dLat / 2)
            + sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusKm * c
    }

    private func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
    // MARK: - Search History

    func fetchRecentSearches(
        userId: String,
        limit: Int = 20
    ) async throws -> [MarketplaceSearchRequest] {

        let snapshot = try await db
            .collection(MarketplaceFirestoreService.Collection.searchHistory)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceSearchRequest.self)
        }
    }

    func deleteRecentSearch(searchId: String) async throws {
        try await db
            .collection(MarketplaceFirestoreService.Collection.searchHistory)
            .document(searchId)
            .delete()
    }

    // MARK: - Trending Searches

    func fetchTrendingKeywords(
        limit: Int = 25
    ) async throws -> [MarketplaceSearchSuggestion] {

        let snapshot = try await db
            .collection(MarketplaceFirestoreService.Collection.searchSuggestions)
            .order(by: "popularity", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceSearchSuggestion.self)
        }
    }

    // MARK: - Recommendations

    func recommendedKeywords(
        from query: String
    ) -> [String] {

        let keywords = buildSearchKeywords(from: query)

        var suggestions = Set<String>()

        for keyword in keywords {
            suggestions.insert(keyword)

            switch keyword {

            case "perruque":
                suggestions.formUnion(["lace", "frontal", "wig"])

            case "robe":
                suggestions.formUnion(["robe femme", "dress", "fashion"])

            case "telephone":
                suggestions.formUnion(["iphone", "android", "samsung"])

            case "chaussure":
                suggestions.formUnion(["basket", "nike", "adidas"])

            case "ordinateur":
                suggestions.formUnion(["macbook", "pc", "laptop"])

            default:
                break
            }
        }

        return Array(suggestions).sorted()
    }

    // MARK: - AI Search Score

    func aiSearchConfidence(
        originalQuery: String,
        normalizedQuery: String,
        resultsCount: Int
    ) -> Double {

        var score = 0.40

        if originalQuery.lowercased() == normalizedQuery.lowercased() {
            score += 0.20
        }

        if resultsCount > 0 {
            score += min(Double(resultsCount) / 100.0, 0.30)
        }

        if buildSearchKeywords(from: originalQuery).count >= 3 {
            score += 0.10
        }

        return min(score, 1.0)
    }

    // MARK: - Search Insights

    func buildSearchInsights(
        query: String,
        resultsCount: Int
    ) -> MarketplaceSearchInsights {

        MarketplaceSearchInsights(
            id: UUID().uuidString,
            query: query,
            normalizedQuery: normalizeQuery(query),
            detectedLanguage: detectLikelyLanguage(query: query),
            generatedKeywords: buildSearchKeywords(from: query),
            aiConfidence: aiSearchConfidence(
                originalQuery: query,
                normalizedQuery: normalizeQuery(query),
                resultsCount: resultsCount
            ),
            resultsCount: resultsCount,
            createdAt: Timestamp()
        )
    }
    
    
    
    
    
}
struct MarketplaceSearchRequest: Codable, Identifiable, Hashable {

    var id: String

    var query: String

    var categoryId: String?

    var countryCode: String?

    var city: String?

    var minimumPrice: Double?

    var maximumPrice: Double?

    var onlyVerified: Bool

    var onlyProfessionalStores: Bool

    var sort: MarketplaceSearchSort

    var createdAt: Timestamp?

}

struct MarketplaceSearchSuggestion: Codable, Identifiable, Hashable {

    var id: String

    var keyword: String

    var popularity: Int

    var createdAt: Timestamp?

}

enum MarketplaceSearchSort: String, Codable, CaseIterable, Identifiable {

    case relevance
    case newest
    case oldest
    case lowestPrice
    case highestPrice
    case bestRated
    case mostPopular
    case nearest

    var id: String { rawValue }

}
enum MarketplaceSearchLanguage: String, Codable, CaseIterable, Identifiable {
    case french
    case english
    case spanish
    case portuguese
    case arabic
    case german
    case italian
    case dutch
    case unknown

    var id: String { rawValue }
}
struct MarketplaceSearchInsights: Codable, Identifiable, Hashable {

    var id: String

    var query: String

    var normalizedQuery: String

    var detectedLanguage: MarketplaceSearchLanguage

    var generatedKeywords: [String]

    var aiConfidence: Double

    var resultsCount: Int

    var createdAt: Timestamp?
}
