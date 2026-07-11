//
//  MarketplaceHomeViewModel.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 02/07/2026.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import CoreLocation



@MainActor
final class MarketplaceHomeViewModel: ObservableObject {
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    @Published var popularProducts: [MarketplaceHomeProduct] = []
    @Published var flashSales: [MarketplaceHomePromo] = []
    @Published var categories: [MarketplaceHomeCategory] = []
    @Published var aiRecommendations: [MarketplaceHomeRecommendation] = []
    
    @Published var unreadNotificationsCount = 0
    @Published var unreadMessagesCount = 0
    @Published var activeOrdersCount = 0
    @Published var favoritesCount = 0
    
    @Published var searchText = ""
    @Published var searchResults: [MarketplaceHomeProduct] = []
    @Published var isSearching = false
    @Published var recentSearches: [String] = []
    @Published var searchSuggestions: [String] = []
    
    @Published var selectedCountry = ""
    @Published var selectedCategory = ""
    @Published var selectedCondition = ""
    @Published var selectedRadiusKm: Double = 0

    @Published var minimumPrice: Double?
    @Published var maximumPrice: Double?

    @Published var onlyVerifiedSellers = false
    @Published var onlyAvailableProducts = false
    @Published var onlyFreeDelivery = false
    @Published var onlyLocalPickup = false
    @Published var onlyPromotions = false

    @Published var sortBy = "relevance"
    
    @Published var userLatitude: Double?
    @Published var userLongitude: Double?
    @Published var locationPermissionDenied = false
    
    
    
    private func cutlyPriceText(from data: [String: Any]) -> String {
        if let price = data["price"] as? Double {
            if price.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(price)) €"
            } else {
                return String(format: "%.2f €", price).replacingOccurrences(of: ".", with: ",")
            }
        }

        if let price = data["price"] as? Int {
            return "\(price) €"
        }

        if let text = data["priceText"] as? String {
            return text
                .replacingOccurrences(of: ".00 €", with: " €")
                .replacingOccurrences(of: ".00€", with: " €")
                .replacingOccurrences(of: "EUR", with: "€")
                .replacingOccurrences(of: "Euro", with: "€")
                .replacingOccurrences(of: "euros", with: "€")
        }

        return "Prix à confirmer"
    }
    
    
    private let db = Firestore.firestore()
    private var searchTask: Task<Void, Never>?
    private func makeHomeProduct(
        doc: QueryDocumentSnapshot,
        favoriteProductIds: Set<String> = []
    ) async -> MarketplaceHomeProduct {
        let data = doc.data()

        let sellerId = data["sellerId"] as? String ?? ""
        
        let variantsData = data["variants"] as? [[String: Any]] ?? []

        let variants = variantsData.compactMap { variant -> MarketplaceProductVariant? in

            guard let id = variant["id"] as? String else {
                return nil
            }

            return MarketplaceProductVariant(
                id: id,
                name: variant["colorName"] as? String
                    ?? variant["name"] as? String
                    ?? "",
                value: variant["size"] as? String
                    ?? variant["value"] as? String
                    ?? "",
                sku: variant["sku"] as? String,
                barcode: variant["barcode"] as? String,
                stock: variant["stock"] as? Int ?? 0,
                priceAdjustment: variant["priceAdjustment"] as? Double
                    ?? variant["price"] as? Double,
                imageURL: variant["imageURL"] as? String
            )
        }
        
        
        

        var sellerName = data["sellerName"] as? String ?? ""
        var sellerVerified = data["sellerVerified"] as? Bool ?? false
        var sellerPhotoURL = data["sellerPhotoURL"] as? String ?? ""

        if !sellerId.isEmpty {
            do {
                let sellerDoc = try await db.collection("marketplaceUsers")
                    .document(sellerId)
                    .getDocument()

                let sellerData = sellerDoc.data() ?? [:]

                if sellerName.isEmpty {
                    sellerName = sellerData["displayName"] as? String
                        ?? sellerData["fullName"] as? String
                        ?? sellerData["name"] as? String
                        ?? ""
                }

                if sellerPhotoURL.isEmpty {
                    sellerPhotoURL = sellerData["photoURL"] as? String
                        ?? sellerData["profileImageURL"] as? String
                        ?? ""
                }

                sellerVerified =
                    sellerData["marketplaceVerified"] as? Bool == true &&
                    sellerData["badgeVisible"] as? Bool == true &&
                    sellerData["certificationStatus"] as? String == "active"

            } catch {
                print("❌ load seller profile:", error.localizedDescription)
            }
        }

        return MarketplaceHomeProduct(
            id: doc.documentID,
            title: data["title"] as? String ?? "Produit",
            priceText: cutlyPriceText(from: data),
            originalPriceText: MarketplacePriceFormatter.formatOptional(data["originalPrice"] as? Double),
            discountPercent: data["discountPercent"] as? Int
                ?? data["discountPercentage"] as? Int
                ?? data["discount"] as? Int
                ?? data["promotionPercent"] as? Int,
            country: data["country"] as? String
                ?? data["countryName"] as? String
                ?? "",
            city: data["city"] as? String
                ?? data["sellerCity"] as? String
                ?? "",
            imageURL: data["mainImageURL"] as? String
                ?? (data["imageURLs"] as? [String])?.first,
            sellerId: sellerId,
            sellerName: sellerName.isEmpty ? "Vendeur Cutly" : sellerName,
            sellerPhotoURL: sellerPhotoURL,
            sellerVerified: sellerVerified,
            rating: data["rating"] as? Double
                ?? data["averageRating"] as? Double,
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double,
            isFavorite: favoriteProductIds.contains(doc.documentID),
            variants: variants
        )
    }
    
    
    
    func loadHome() {
        guard !isLoading else { return }
        
        loadRecentSearches()
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                async let productsTask = fetchPopularProducts()
                async let promosTask = fetchFlashSales()
                async let categoriesTask = fetchCategories()
                async let recommendationsTask = fetchAIRecommendations()
                async let countersTask = fetchCounters()
                
                let products = try await productsTask
                let promos = try await promosTask
                let loadedCategories = try await categoriesTask
                let recommendations = try await recommendationsTask
                let counters = try await countersTask
                
                self.popularProducts = products
                self.flashSales = promos
                self.categories = loadedCategories
                self.aiRecommendations = recommendations
                
                self.unreadNotificationsCount = counters.notifications
                self.unreadMessagesCount = counters.messages
                self.activeOrdersCount = counters.orders
                self.favoritesCount = counters.favorites
                
                self.isLoading = false
                
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                print("❌ MarketplaceHomeViewModel:", error.localizedDescription)
            }
        }
    }
    
    private func fetchPopularProducts() async throws -> [MarketplaceHomeProduct] {
        let uid = Auth.auth().currentUser?.uid
        
        var favoriteProductIds = Set<String>()
        
        if let uid {
            let favSnap = try await db.collection("marketplace_favorites")
                .whereField("userId", isEqualTo: uid)
                .getDocuments()
            
            favoriteProductIds = Set(
                favSnap.documents.compactMap { $0.data()["productId"] as? String }
            )
        }
        
        do {
            let snapshot = try await db.collection("marketplace_products")
                .whereField("status", isEqualTo: "active")
                .order(by: "popularityScore", descending: true)
                .limit(to: 8)
                .getDocuments()
            
            var products: [MarketplaceHomeProduct] = []

            for doc in snapshot.documents {
                let product = await makeHomeProduct(
                    doc: doc,
                    favoriteProductIds: favoriteProductIds
                )
                products.append(product)
            }

            return products
            
        } catch {
            let fallbackSnapshot = try await db.collection("marketplace_products")
                .whereField("status", isEqualTo: "active")
                .order(by: "createdAt", descending: true)
                .limit(to: 8)
                .getDocuments()
            
            var products: [MarketplaceHomeProduct] = []

            for doc in fallbackSnapshot.documents {
                let product = await makeHomeProduct(
                    doc: doc,
                    favoriteProductIds: favoriteProductIds
                )
                products.append(product)
            }

            return products
        }
    }
        
       
        
        
    
    private func fetchFlashSales() async throws -> [MarketplaceHomePromo] {
        let now = Timestamp(date: Date())

        let snapshot = try await db.collection("marketplace_promotions")
            .whereField("isActive", isEqualTo: true)
            .whereField("endsAt", isGreaterThan: now)
            .order(by: "endsAt")
            .order(by: "priority", descending: true)
            .limit(to: 8)
            .getDocuments()

        return snapshot.documents.map { doc in
            let data = doc.data()

            let discount = data["discountPercent"] as? Int
            let endsAt = (data["endsAt"] as? Timestamp)?.dateValue()

            let subtitle: String
            if let discount {
                subtitle = "Jusqu’à -\(discount)%"
            } else {
                subtitle = data["subtitle"] as? String ?? "Promotion limitée"
            }

            return MarketplaceHomePromo(
                id: doc.documentID,
                title: data["title"] as? String ?? "Offre spéciale",
                subtitle: subtitle,
                icon: data["icon"] as? String ?? "bolt.fill",
                destinationType: data["destinationType"] as? String ?? "explore",
                discountPercent: discount,
                endsAt: endsAt
            )
        }
    }
    
    private func fetchCategories() async throws -> [MarketplaceHomeCategory] {
        let snapshot = try await db.collection("marketplace_categories")
            .whereField("isActive", isEqualTo: true)
            .order(by: "position")
            .limit(to: 20)
            .getDocuments()
        
        return snapshot.documents.map { doc in
            let data = doc.data()
            
            return MarketplaceHomeCategory(
                id: doc.documentID,
                title: data["title"] as? String ?? "Catégorie",
                icon: data["icon"] as? String ?? "square.grid.2x2.fill"
            )
        }
    }
    
    private func fetchAIRecommendations() async throws -> [MarketplaceHomeRecommendation] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        
        let snapshot = try await db.collection("marketplace_ai_recommendations")
            .whereField("userId", isEqualTo: uid)
            .order(by: "score", descending: true)
            .limit(to: 3)
            .getDocuments()
        
        return snapshot.documents.map { doc in
            let data = doc.data()
            
            return MarketplaceHomeRecommendation(
                id: doc.documentID,
                title: data["title"] as? String ?? "Suggestion personnalisée",
                subtitle: data["subtitle"] as? String ?? "Recommandé pour vous.",
                icon: data["icon"] as? String ?? "wand.and.stars",
                targetId: data["targetId"] as? String ?? "",
                targetType: data["targetType"] as? String ?? "product"
            )
        }
    }
    
    private func fetchCounters() async throws -> MarketplaceHomeCounters {
        guard let uid = Auth.auth().currentUser?.uid else {
            return MarketplaceHomeCounters()
        }
        
        async let notifications = db.collection("marketplace_notifications")
            .whereField("userId", isEqualTo: uid)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        async let messages = db.collection("marketplace_conversations")
            .whereField("participantIds", arrayContains: uid)
            .getDocuments()
        
        async let orders = db.collection("marketplace_orders")
            .whereField("buyerId", isEqualTo: uid)
            .whereField("isArchived", isEqualTo: false)
            .getDocuments()
        
        async let favorites = db.collection("marketplace_favorites")
            .whereField("userId", isEqualTo: uid)
            .getDocuments()
        
        let n = try await notifications
        let m = try await messages

        let unreadMessages = m.documents.filter { document in
            let unreadFor = document.data()["unreadFor"] as? [String] ?? []
            return unreadFor.contains(uid)
        }
        let o = try await orders
        let f = try await favorites
        
        return MarketplaceHomeCounters(
            notifications: n.documents.count,
            messages: unreadMessages.count,
            orders: o.documents.count,
            favorites: f.documents.count
        )
    }
    func toggleFavorite(product: MarketplaceHomeProduct) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                let favoriteId = "\(uid)_\(product.id)"
                let favoriteRef = db.collection("marketplace_favorites").document(favoriteId)

                if product.isFavorite {
                    try await favoriteRef.delete()

                    if let index = popularProducts.firstIndex(where: { $0.id == product.id }) {
                        popularProducts[index].isFavorite = false
                    }

                    favoritesCount = max(favoritesCount - 1, 0)

                } else {
                    try await favoriteRef.setData([
                        "id": favoriteId,
                        "userId": uid,
                        "productId": product.id,
                        "targetId": product.id,
                        "targetType": "product",
                        "createdAt": FieldValue.serverTimestamp()
                    ], merge: true)

                    if let index = popularProducts.firstIndex(where: { $0.id == product.id }) {
                        popularProducts[index].isFavorite = true
                    }

                    favoritesCount += 1
                }

            } catch {
                errorMessage = error.localizedDescription
                print("❌ toggleFavorite:", error.localizedDescription)
            }
        }
    }
    func searchProducts() {
        searchTask?.cancel()

        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            if Task.isCancelled { return }

            isSearching = true

            do {
                let snapshot = try await db.collection("marketplace_products")
                    .whereField("status", isEqualTo: "active")
                    .whereField("searchKeywords", arrayContains: query)
                    .limit(to: 20)
                    .getDocuments()

                var products: [MarketplaceHomeProduct] = []

                for doc in snapshot.documents {
                    let product = await makeHomeProduct(doc: doc)
                    products.append(product)
                }

                searchResults = products

                isSearching = false

            } catch {
                isSearching = false
                errorMessage = error.localizedDescription
                print("❌ searchProducts:", error.localizedDescription)
            }
        }
    }
    func saveSearchHistory() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !query.isEmpty else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                let ref = db.collection("marketplace_search_history").document()

                try await ref.setData([
                    "id": ref.documentID,
                    "userId": uid,
                    "query": query,
                    "createdAt": FieldValue.serverTimestamp(),
                    "source": "marketplace_home"
                ])

            } catch {
                print("❌ saveSearchHistory:", error.localizedDescription)
            }
        }
    }
    func loadRecentSearches() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                let snapshot = try await db.collection("marketplace_search_history")
                    .whereField("userId", isEqualTo: uid)
                    .order(by: "createdAt", descending: true)
                    .limit(to: 10)
                    .getDocuments()

                var seen = Set<String>()
                var searches: [String] = []

                for doc in snapshot.documents {
                    let query = doc["query"] as? String ?? ""

                    if !query.isEmpty && !seen.contains(query) {
                        searches.append(query)
                        seen.insert(query)
                    }
                }

                await MainActor.run {
                    self.recentSearches = searches
                }

            } catch {
                print("❌ loadRecentSearches:", error.localizedDescription)
            }
        }
    }
    func loadSearchSuggestions() {

        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard query.count >= 2 else {
            searchSuggestions = []
            return
        }

        Task {
            do {

                let snapshot = try await db.collection("marketplace_products")
                    .whereField("status", isEqualTo: "active")
                    .limit(to: 20)
                    .getDocuments()

                let suggestions = snapshot.documents
                    .compactMap { $0["title"] as? String }
                    .filter {
                        $0.lowercased().contains(query)
                    }

                await MainActor.run {
                    self.searchSuggestions = Array(suggestions.prefix(8))
                }

            } catch {
                print("❌ searchSuggestions:", error.localizedDescription)
            }
        }
    }
    let sortOptions = [
        "relevance",
        "newest",
        "price_low",
        "price_high",
        "popularity",
        "distance"
    ]

    let conditionOptions = [
        "",
        "new",
        "very_good",
        "good",
        "acceptable"
    ]

    let radiusOptionsKm: [Double] = [
        0,
        5,
        10,
        25,
        50,
        100
    ]
    func applyLocalRadiusFilter(
        products: [MarketplaceHomeProduct],
        locationManager: MarketplaceLocationManager
    ) -> [MarketplaceHomeProduct] {
        guard selectedRadiusKm > 0 else { return products }

        return products.filter { product in
            locationManager.isWithinRadius(
                productLatitude: product.latitude,
                productLongitude: product.longitude,
                radiusKm: selectedRadiusKm
            )
        }
    }
    
    
    
    
    
    
    
}








struct MarketplaceHomeProduct: Identifiable {
    let id: String
    let title: String
    let priceText: String
    let originalPriceText: String?
    let discountPercent: Int?
    let country: String
    let city: String
    let imageURL: String?
    let sellerId: String
    let sellerName: String
    let sellerPhotoURL: String
    let sellerVerified: Bool
    let rating: Double?
    let latitude: Double?
    let longitude: Double?
    var isFavorite: Bool
    
    let variants: [MarketplaceProductVariant]
}

struct MarketplaceHomePromo: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let destinationType: String
    let discountPercent: Int?
    let endsAt: Date?
}

struct MarketplaceHomeCategory: Identifiable {
    let id: String
    let title: String
    let icon: String
}

struct MarketplaceHomeRecommendation: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let targetId: String
    let targetType: String
}

struct MarketplaceHomeCounters {
    var notifications: Int = 0
    var messages: Int = 0
    var orders: Int = 0
    var favorites: Int = 0
    
    
    
    
}
