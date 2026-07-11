//
//  MarketplaceFavoritesView.swift
//  MonApp
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MarketplaceFavoritesView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedFilter: MarketplaceFavoriteFilter = .products
    @State private var searchText = ""
    @State private var animateHeader = false

    @State private var products: [MarketplaceHomeProduct] = []
    @State private var stores: [MarketplaceFavoriteItem] = []
    @State private var categories: [MarketplaceFavoriteItem] = []
    @State private var searches: [MarketplaceFavoriteItem] = []

    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var favoritesListener: ListenerRegistration?
    
    

    private let db = Firestore.firestore()

    private let filters: [MarketplaceFavoriteFilter] = [
        .products, .stores, .categories, .searches
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        favoritesHeroSection
                        searchSection
                        filtersSection
                        favoritesContentSection
                        Spacer(minLength: 120)
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Favoris")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadFavorites()
            }
            .onDisappear {
                favoritesListener?.remove()
            }
        }
    }

    private var favoritesHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Favoris Cutly")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Produits, boutiques, catégories et recherches sauvegardées.")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                MarketplaceIconBadge(icon: "heart.fill", size: 62)
            }

            HStack(spacing: 10) {
                MarketplaceFavoritesChip(title: "\(products.count) produits", icon: "bag.fill")
                MarketplaceFavoritesChip(title: "\(stores.count) boutiques", icon: "storefront.fill")
                MarketplaceFavoritesChip(title: "\(searches.count) recherches", icon: "magnifyingglass")
            }
        }
        .padding(22)
        .background(MarketplaceUITheme.darkLuxuryGradient)
        .clipShape(RoundedRectangle(cornerRadius: MarketplaceUITheme.cornerXL, style: .continuous))
        .overlay(MarketplaceUITheme.premiumStroke(colorScheme: colorScheme, cornerRadius: MarketplaceUITheme.cornerXL))
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 16)
        .padding(.horizontal, 16)
        .scaleEffect(animateHeader ? 1 : 0.97)
        .opacity(animateHeader ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                animateHeader = true
            }
        }
    }

    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.secondary)

            TextField("Rechercher dans tes favoris...", text: $searchText)
                .font(.system(.body, design: .rounded).weight(.semibold))

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(MarketplaceUITheme.glassBackground(colorScheme: colorScheme, cornerRadius: 24))
        .padding(.horizontal, 16)
    }

    private var filtersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(filters) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: filter.icon)
                            Text(filter.title)
                        }
                        .font(.caption.bold())
                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            selectedFilter == filter
                            ? AnyView(MarketplaceUITheme.primaryGradient)
                            : AnyView(Color.primary.opacity(0.06))
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var favoritesContentSection: some View {
        VStack(spacing: 14) {
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                switch selectedFilter {
                case .products:
                    favoriteProductsGrid
                case .stores:
                    favoriteItemsList(items: filteredItems(stores), emptyTitle: "Aucune boutique favorite")
                case .categories:
                    favoriteItemsList(items: filteredItems(categories), emptyTitle: "Aucune catégorie favorite")
                case .searches:
                    favoriteItemsList(items: filteredItems(searches), emptyTitle: "Aucune recherche sauvegardée")
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption.bold())
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 16)
    }

    private var favoriteProductsGrid: some View {
        let filtered = filteredProducts

        return Group {
            if filtered.isEmpty {
                MarketplaceFavoriteEmptyView(
                    title: "Aucun produit favori",
                    subtitle: "Les produits ajoutés au cœur apparaîtront ici automatiquement."
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ], spacing: 14) {
                    ForEach(filtered) { product in
                        NavigationLink {
                            MarketplaceProductDetailView(product: product)
                        } label: {
                            MarketplaceProductCard(
                                product: product,
                                onFavoriteTap: {
                                    removeProductFavorite(product)
                                }
                            )
                            .frame(height: 208)
                            .clipped()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var filteredProducts: [MarketplaceHomeProduct] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !query.isEmpty else { return products }

        return products.filter {
            $0.title.lowercased().contains(query)
            || $0.priceText.lowercased().contains(query)
            || $0.country.lowercased().contains(query)
            || $0.sellerName.lowercased().contains(query)
        }
    }

    private func filteredItems(_ items: [MarketplaceFavoriteItem]) -> [MarketplaceFavoriteItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !query.isEmpty else { return items }

        return items.filter {
            $0.title.lowercased().contains(query)
            || $0.subtitle.lowercased().contains(query)
        }
    }

    private func favoriteItemsList(items: [MarketplaceFavoriteItem], emptyTitle: String) -> some View {
        VStack(spacing: 12) {
            if items.isEmpty {
                MarketplaceFavoriteEmptyView(
                    title: emptyTitle,
                    subtitle: "Les éléments sauvegardés dans Cutly apparaîtront ici."
                )
            } else {
                ForEach(items) { item in
                    MarketplaceFavoriteRow(
                        icon: item.icon,
                        title: item.title,
                        subtitle: item.subtitle
                    )
                }
            }
        }
    }

    private func loadFavorites() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        favoritesListener?.remove()

        isLoading = true
        errorMessage = ""

        favoritesListener = db
            .collection("marketplace_favorites")
            .whereField("userId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in

                if let error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.products = []
                    self.stores = []
                    self.categories = []
                    self.isLoading = false
                    return
                }

                Task {
                    await self.reloadFavorites(from: documents)
                }
            }
    }
    private func reloadFavorites(
        from documents: [QueryDocumentSnapshot]
    ) async {

        var loadedProducts: [MarketplaceHomeProduct] = []
        var loadedStores: [MarketplaceFavoriteItem] = []
        var loadedCategories: [MarketplaceFavoriteItem] = []

        for document in documents {

            let data = document.data()

            let type = data["targetType"] as? String ?? "product"

            let productId =
                data["productId"] as? String ??
                data["targetId"] as? String ??
                ""

            if type == "product",
               !productId.isEmpty,
               let product = try? await loadProduct(productId: productId) {

                loadedProducts.append(product)
            }

            if type == "store" {

                loadedStores.append(
                    MarketplaceFavoriteItem(
                        id: document.documentID,
                        icon: "storefront.fill",
                        title: data["title"] as? String ?? "Boutique",
                        subtitle: data["subtitle"] as? String ?? ""
                    )
                )
            }

            if type == "category" {

                loadedCategories.append(
                    MarketplaceFavoriteItem(
                        id: document.documentID,
                        icon: "square.grid.2x2.fill",
                        title: data["title"] as? String ?? "Catégorie",
                        subtitle: data["subtitle"] as? String ?? ""
                    )
                )
            }
        }

        await MainActor.run {

            products = loadedProducts
            stores = loadedStores
            categories = loadedCategories
            isLoading = false
        }
    }
    
    
    

    private func loadProduct(productId: String) async throws -> MarketplaceHomeProduct? {
        let doc = try await db.collection("marketplace_products")
            .document(productId)
            .getDocument()

        guard let data = doc.data() else { return nil }

        return MarketplaceHomeProduct(
            id: doc.documentID,
            title: data["title"] as? String ?? "Produit Cutly Marketplace",
            priceText: data["priceText"] as? String ?? "\(data["price"] ?? "") €",
            originalPriceText: MarketplacePriceFormatter.formatOptional(data["originalPrice"] as? Double),
            discountPercent: data["discountPercent"] as? Int
                ?? data["discountPercentage"] as? Int
                ?? data["discount"] as? Int,
            country: data["country"] as? String ?? data["countryName"] as? String ?? "",
            city: data["city"] as? String ?? data["sellerCity"] as? String ?? "",
            imageURL: data["mainImageURL"] as? String ?? (data["imageURLs"] as? [String])?.first,
            sellerId: data["sellerId"] as? String ?? "",
            sellerName: data["sellerName"] as? String ?? "Vendeur Cutly",
            sellerPhotoURL: data["sellerPhotoURL"] as? String ?? "",
            sellerVerified: data["sellerVerified"] as? Bool ?? false,
            rating: data["rating"] as? Double ?? data["averageRating"] as? Double,
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double,
            isFavorite: true,
            variants: [],
        )
    }

    private func removeProductFavorite(_ product: MarketplaceHomeProduct) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let favoriteId = "\(uid)_\(product.id)"

        products.removeAll { $0.id == product.id }

        let db = Firestore.firestore()

        db.collection("marketplace_favorites")
            .document(favoriteId)
            .delete { error in
                if let error {
                    print("❌ remove favorite:", error.localizedDescription)
                    return
                }

                db.collection("marketplace_products")
                    .document(product.id)
                    .setData([
                        "favoritesCount": FieldValue.increment(Int64(-1)),
                        "updatedAt": FieldValue.serverTimestamp()
                    ], merge: true)
            }
    }
}

enum MarketplaceFavoriteFilter: String, CaseIterable, Identifiable {
    case products
    case stores
    case categories
    case searches

    var id: String { rawValue }

    var title: String {
        switch self {
        case .products: return "Produits"
        case .stores: return "Boutiques"
        case .categories: return "Catégories"
        case .searches: return "Recherches"
        }
    }

    var icon: String {
        switch self {
        case .products: return "bag.fill"
        case .stores: return "storefront.fill"
        case .categories: return "square.grid.2x2.fill"
        case .searches: return "magnifyingglass"
        }
    }
}

private struct MarketplaceFavoriteItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
}

private struct MarketplaceFavoritesChip: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.14))
        .clipShape(Capsule())
    }
}



private struct MarketplaceFavoriteRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

private struct MarketplaceFavoriteEmptyView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            MarketplaceIconBadge(icon: "heart.slash.fill", size: 64)

            Text(title)
                .font(.title3.bold())

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

#Preview {
    MarketplaceFavoritesView()
}
