//
//  MarketplaceExploreViewModel.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 02/07/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreLocation
import SwiftUI
import Combine

@MainActor
final class MarketplaceExploreViewModel: ObservableObject {
    
    @Published var products: [MarketplaceHomeProduct] = []
    
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage = ""
    
    @Published var searchText = ""
    
    @Published var selectedCategory = ""
    @Published var selectedCountry = ""
    @Published var selectedCity = ""
    
    @Published var minimumPrice: Double?
    @Published var maximumPrice: Double?
    
    @Published var onlyVerified = false
    @Published var onlyPromotion = false
    @Published var onlyDelivery = false
    @Published var onlyPickup = false
    
    @Published var radiusKm: Double = 25
    
    @Published var userLatitude: Double?
    @Published var userLongitude: Double?
    
    @Published var hasMore = true
    
    @Published var selectedSort: MarketplaceExploreSort = .newest
    @Published var selectedCondition = ""
    
    
    
    private var productRawData: [String: [String: Any]] = [:]
    
    
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private var favoriteProductIds: Set<String> = []
    private var favoritesListener: ListenerRegistration?
    
    
    func startFavoritesListener() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        favoritesListener?.remove()

        favoritesListener = db.collection("marketplace_favorites")
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }

                Task { @MainActor in
                    let ids = Set(snapshot?.documents.compactMap {
                        $0.data()["productId"] as? String
                    } ?? [])

                    self.favoriteProductIds = ids

                    self.products = self.products.map { product in
                        var updated = product
                        updated.isFavorite = ids.contains(product.id)
                        return updated
                    }
                }
            }
    }
    // MARK: - Initial Load
    
    func loadProducts() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = ""
        lastDocument = nil
        hasMore = true
        
        Task {
            await fetchNextPage(reset: true)

            if radiusKm > 0,
               userLatitude != nil,
               userLongitude != nil {

                let locationManager = MarketplaceLocationManager.shared
                applyDistanceFilter(using: locationManager)
            }
        }
    }
    
    // MARK: - Pagination
    
    func loadMoreIfNeeded(current product: MarketplaceHomeProduct) {
        guard let last = products.last else { return }
        guard last.id == product.id else { return }
        guard hasMore else { return }
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            await fetchNextPage(reset: false)
        }
    }
    
    private func fetchNextPage(reset: Bool) async {
        do {
            var query: Query = db.collection("marketplace_products")
                .whereField("status", isEqualTo: "active")
                .order(by: "createdAt", descending: true)
                .limit(to: 20)
            
            if let lastDocument {
                query = query.start(afterDocument: lastDocument)
            }
            
            let snapshot = try await query.getDocuments()
            snapshot.documents.forEach { doc in
                productRawData[doc.documentID] = doc.data()
            }
            
            lastDocument = snapshot.documents.last
            hasMore = snapshot.documents.count == 20
            
            var newProducts: [MarketplaceHomeProduct] = []

            for doc in snapshot.documents {
                let product = await makeProduct(from: doc)
                newProducts.append(product)
            }
            let visibleProducts = newProducts.filter { product in
                let data = snapshot.documents.first(where: { $0.documentID == product.id })?.data() ?? [:]

                let price = data["price"] as? Double ?? 0
                let verified = data["sellerVerified"] as? Bool ?? false
                let delivery = data["allowsDelivery"] as? Bool ?? data["deliveryAvailable"] as? Bool ?? false
                let pickup = data["allowsPickup"] as? Bool ?? data["pickupAvailable"] as? Bool ?? false
                let promotion = data["hasPromotion"] as? Bool ?? false

                let minimumOK = minimumPrice == nil || price >= minimumPrice!
                let maximumOK = maximumPrice == nil || price <= maximumPrice!
                let priceOK = minimumOK && maximumOK
                let verifiedOK = onlyVerified ? verified : true
                let deliveryOK = onlyDelivery ? delivery : true
                let pickupOK = onlyPickup ? pickup : true
                let promotionOK = onlyPromotion ? promotion : true

                return priceOK && verifiedOK && deliveryOK && pickupOK && promotionOK
            }
            
            
            
            
            if reset {
                products = visibleProducts
            } else {
                products.append(contentsOf: visibleProducts)
            }
            applySort()
            
            isLoading = false
            isRefreshing = false
            
        } catch {
            isLoading = false
            isRefreshing = false
            errorMessage = error.localizedDescription
            print("❌ Marketplace Explore:", error.localizedDescription)
        }
    }
    private func makeProduct(from doc: QueryDocumentSnapshot) async -> MarketplaceHomeProduct {
        let data = doc.data()

        let sellerId = data["sellerId"] as? String ?? ""

        var finalSellerName =
            data["sellerName"] as? String
            ?? data["sellerDisplayName"] as? String
            ?? ""

        var finalSellerPhotoURL =
            data["sellerPhotoURL"] as? String
            ?? data["sellerPhoto"] as? String
            ?? data["sellerAvatarURL"] as? String
            ?? data["storeLogoURL"] as? String
            ?? ""

        var finalSellerVerified =
            data["sellerVerified"] as? Bool ?? false

        var finalRating =
            data["rating"] as? Double
            ?? data["averageRating"] as? Double
            ?? data["sellerRating"] as? Double
            ?? 0.0

        if !sellerId.isEmpty {
            do {
                let marketplaceUserDoc = try await db
                    .collection("marketplaceUsers")
                    .document(sellerId)
                    .getDocument()

                let marketplaceUserData = marketplaceUserDoc.data() ?? [:]

                if finalSellerName.isEmpty {
                    finalSellerName =
                        marketplaceUserData["displayName"] as? String
                        ?? marketplaceUserData["fullName"] as? String
                        ?? marketplaceUserData["name"] as? String
                        ?? ""
                }

                if finalSellerPhotoURL.isEmpty {
                    finalSellerPhotoURL =
                        marketplaceUserData["photoURL"] as? String
                        ?? marketplaceUserData["profileImageURL"] as? String
                        ?? marketplaceUserData["sellerPhotoURL"] as? String
                        ?? marketplaceUserData["avatarURL"] as? String
                        ?? marketplaceUserData["storeLogoURL"] as? String
                        ?? ""
                }

                finalSellerVerified =
                    marketplaceUserData["marketplaceVerified"] as? Bool == true &&
                    marketplaceUserData["badgeVisible"] as? Bool == true &&
                    marketplaceUserData["certificationStatus"] as? String == "active"

                finalRating =
                    marketplaceUserData["averageRating"] as? Double
                    ?? marketplaceUserData["rating"] as? Double
                    ?? finalRating

                if finalSellerName.isEmpty || finalSellerPhotoURL.isEmpty {
                    let userDoc = try await db
                        .collection("users")
                        .document(sellerId)
                        .getDocument()

                    let userData = userDoc.data() ?? [:]

                    if finalSellerName.isEmpty {
                        finalSellerName =
                            userData["displayName"] as? String
                            ?? userData["fullName"] as? String
                            ?? userData["name"] as? String
                            ?? "Vendeur Cutly"
                    }

                    if finalSellerPhotoURL.isEmpty {
                        finalSellerPhotoURL =
                            userData["photoURL"] as? String
                            ?? userData["profileImageURL"] as? String
                            ?? userData["avatarURL"] as? String
                            ?? ""
                    }

                    finalRating =
                        userData["averageRating"] as? Double
                        ?? userData["rating"] as? Double
                        ?? finalRating
                }

            } catch {
                print("❌ load seller profile:", error.localizedDescription)
            }
        }

        return MarketplaceHomeProduct(
            id: doc.documentID,
            title: data["title"] as? String ?? "Produit",
            priceText: data["priceText"] as? String
                ?? MarketplacePriceFormatter.format(data["price"] as? Double),
            originalPriceText: MarketplacePriceFormatter.formatOptional(
                data["originalPrice"] as? Double
            ),
            discountPercent: data["promotionPercent"] as? Int
                ?? data["discountPercent"] as? Int
                ?? data["discountPercentage"] as? Int
                ?? data["discount"] as? Int,
            country: data["country"] as? String
                ?? data["countryName"] as? String
                ?? "",
            city: data["city"] as? String
                ?? data["sellerCity"] as? String
                ?? "",
            imageURL: data["mainImageURL"] as? String
                ?? (data["imageURLs"] as? [String])?.first,
            sellerId: sellerId,
            sellerName: finalSellerName.isEmpty ? "Vendeur Cutly" : finalSellerName,
            sellerPhotoURL: finalSellerPhotoURL,
            sellerVerified: finalSellerVerified,
            rating: finalRating,
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double,
            isFavorite: favoriteProductIds.contains(doc.documentID),
            variants: [],
        )
    }
    // MARK: - Search

    func searchProducts() {

        Task {

            do {

                var query: Query = db.collection("marketplace_products")
                    .whereField("status", isEqualTo: "active")

                let cleanSearch = searchText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                    .lowercased()

                if !cleanSearch.isEmpty {
                    query = query.whereField(
                        "searchKeywords",
                        arrayContains: cleanSearch
                    )
                }

                let snapshot = try await query
                    .limit(to: 40)
                    .getDocuments()
                snapshot.documents.forEach { doc in
                    productRawData[doc.documentID] = doc.data()
                }

                var loadedProducts: [MarketplaceHomeProduct] = []

                for doc in snapshot.documents {
                    let product = await makeProduct(from: doc)
                    loadedProducts.append(product)
                }

                products = loadedProducts
                applySort()
                
            } catch {

                errorMessage = error.localizedDescription

                print(error)

            }

        }

    }
    func clearSearch() {

        searchText = ""
        products.removeAll()
        loadProducts()

    }
    // MARK: - Filters

    func applyFilters() {
        isLoading = true
        errorMessage = ""
        lastDocument = nil
        hasMore = false

        Task {
            do {
                var query: Query = db.collection("marketplace_products")
                    .whereField("status", isEqualTo: "active")

                if !selectedCategory.isEmpty {
                    query = query.whereField("categoryId", isEqualTo: selectedCategory)
                }

                if !selectedCountry.isEmpty {
                    query = query.whereField("country", isEqualTo: selectedCountry)
                }

                if !selectedCity.isEmpty {
                    query = query.whereField("city", isEqualTo: selectedCity)
                }

                if !selectedCondition.isEmpty {
                    query = query.whereField("condition", isEqualTo: selectedCondition)
                }
                
                if onlyPromotion {
                    query = query.whereField("hasPromotion", isEqualTo: true)
                }

                if onlyDelivery {
                    query = query.whereField("deliveryAvailable", isEqualTo: true)
                }

                if onlyPickup {
                    query = query.whereField("pickupAvailable", isEqualTo: true)
                }

                let snapshot = try await query
                    .limit(to: 80)
                    .getDocuments()
                snapshot.documents.forEach { doc in
                    productRawData[doc.documentID] = doc.data()
                }

                var filteredProducts: [MarketplaceHomeProduct] = []

                for doc in snapshot.documents {
                    let product = await makeProduct(from: doc)
                    filteredProducts.append(product)
                }

                filteredProducts = filteredProducts.filter { product in
                    let data = snapshot.documents.first(where: { $0.documentID == product.id })?.data() ?? [:]
                    let price = data["price"] as? Double ?? 0
                    let verified = data["sellerVerified"] as? Bool ?? false
                    let delivery = data["allowsDelivery"] as? Bool ?? data["deliveryAvailable"] as? Bool ?? false
                    let pickup = data["allowsPickup"] as? Bool ?? data["pickupAvailable"] as? Bool ?? false
                    let promotion = data["hasPromotion"] as? Bool ?? false

                    let minimumOK = minimumPrice == nil || price >= minimumPrice!
                    let maximumOK = maximumPrice == nil || price <= maximumPrice!
                    let priceOK = minimumOK && maximumOK
                    let verifiedOK = onlyVerified ? verified : true
                    let deliveryOK = onlyDelivery ? delivery : true
                    let pickupOK = onlyPickup ? pickup : true
                    let promotionOK = onlyPromotion ? promotion : true

                    return priceOK && verifiedOK && deliveryOK && pickupOK && promotionOK
                }

                products = filteredProducts
                applySort()
                isLoading = false

            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("❌ applyFilters:", error.localizedDescription)
            }
        }
    }
    func applySort() {
        switch selectedSort {
        case .newest:
            products.sort {
                timestampValue(productRawData[$0.id]?["createdAt"]) >
                timestampValue(productRawData[$1.id]?["createdAt"])
            }

        case .priceLow:
            products.sort {
                extractPrice(from: $0.priceText) < extractPrice(from: $1.priceText)
            }

        case .priceHigh:
            products.sort {
                extractPrice(from: $0.priceText) > extractPrice(from: $1.priceText)
            }

        case .popular:
            products.sort {
                popularityScore(productRawData[$0.id]) >
                popularityScore(productRawData[$1.id])
            }

        case .promotion:
            products.sort {
                let a = productRawData[$0.id]?["hasPromotion"] as? Bool ?? false
                let b = productRawData[$1.id]?["hasPromotion"] as? Bool ?? false
                return a && !b
            }
        }
    }
    private func extractPrice(from text: String) -> Double {
        let cleaned = text
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "EUR", with: "")
            .replacingOccurrences(of: "GNF", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleaned) ?? 0
    }
    private func timestampValue(_ value: Any?) -> TimeInterval {
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue().timeIntervalSince1970
        }
        return 0
    }

    private func popularityScore(_ data: [String: Any]?) -> Int {
        let views = data?["viewsCount"] as? Int ?? 0
        let favorites = data?["favoritesCount"] as? Int ?? 0
        let sales = data?["salesCount"] as? Int ?? 0

        return views + (favorites * 3) + (sales * 10)
    }
    
    func toggleFavorite(product: MarketplaceHomeProduct) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let favoriteId = "\(uid)_\(product.id)"
        let favoriteRef = db.collection("marketplace_favorites").document(favoriteId)
        let productRef = db.collection("marketplace_products").document(product.id)

        let isCurrentlyFavorite = favoriteProductIds.contains(product.id)

        if isCurrentlyFavorite {
            favoriteProductIds.remove(product.id)

            products = products.map { item in
                var updated = item
                if updated.id == product.id {
                    updated.isFavorite = false
                }
                return updated
            }

            favoriteRef.delete { error in
                if let error {
                    print("❌ remove favorite:", error.localizedDescription)
                    return
                }

                productRef.setData([
                    "favoritesCount": FieldValue.increment(Int64(-1)),
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
            }

        } else {
            favoriteProductIds.insert(product.id)

            products = products.map { item in
                var updated = item
                if updated.id == product.id {
                    updated.isFavorite = true
                }
                return updated
            }

            favoriteRef.setData([
                "id": favoriteId,
                "userId": uid,
                "productId": product.id,
                "sellerId": product.sellerId,
                "targetId": product.id,
                "targetType": "product",
                "title": product.title,
                "priceText": product.priceText,
                "imageURL": product.imageURL ?? "",
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if let error {
                    print("❌ add favorite:", error.localizedDescription)
                    return
                }

                productRef.setData([
                    "favoritesCount": FieldValue.increment(Int64(1)),
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
            }
        }
    }
    
    func resetFilters() {
        selectedCategory = ""
        selectedCountry = ""
        selectedCity = ""
        selectedCondition = ""
        minimumPrice = nil
        maximumPrice = nil
        onlyVerified = false
        onlyPromotion = false
        onlyDelivery = false
        onlyPickup = false
        radiusKm = 25

        products.removeAll()
        loadProducts()
    }
    
    // MARK: - Location

    func updateUserLocation(from locationManager: MarketplaceLocationManager) {
        userLatitude = locationManager.latitude
        userLongitude = locationManager.longitude
        selectedCity = locationManager.city
        selectedCountry = locationManager.country
    }

    func applyDistanceFilter(using locationManager: MarketplaceLocationManager) {
        guard radiusKm > 0 else { return }

        products = products.filter { product in
            locationManager.isWithinRadius(
                productLatitude: product.latitude,
                productLongitude: product.longitude,
                radiusKm: radiusKm
            )
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}

enum MarketplacePriceFormatter {
    static func format(_ price: Double?) -> String {
        guard let price else { return "0 €" }
        
        if price.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(price)) €"
        }
        
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let value = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
        return "\(value) €"
    }
    static func formatOptional(_ price: Double?) -> String? {
        guard let price else { return nil }
        return format(price)
    }
    
    
    
}






enum MarketplaceExploreSort: String, CaseIterable, Identifiable {
    case newest
    case priceLow
    case priceHigh
    case popular
    case promotion

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest: return "Nouveautés"
        case .priceLow: return "Prix bas"
        case .priceHigh: return "Prix haut"
        case .popular: return "Populaires"
        case .promotion: return "Promotions"
        }
    }
}
