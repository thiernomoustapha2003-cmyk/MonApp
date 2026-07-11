//
//  MarketplaceSellerProfileView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 02/07/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MarketplaceSellerProfileView: View {

    let sellerId: String

    @Environment(\.dismiss) private var dismiss

    @State private var seller: MarketplaceSeller?
    @State private var products: [MarketplaceHomeProduct] = []
    @State private var reviews: [MarketplaceSellerReview] = []

    @State private var isLoading = true
    @State private var isFollowing = false
    @State private var searchText = ""
    @State private var selectedFilter: SellerFilter = .all
    
    @State private var showReportSheet = false
    @State private var showShareSheet = false
    @State private var reportReason = ""
    
    @State private var sellerProductsRawData: [String: [String: Any]] = [:]
    
    
    

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            MarketplaceUITheme.softBackgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    sellerHeaderSection
                    sellerActionsSection
                    sellerShopProductsSection
                    Spacer(minLength: 80)
                }
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Boutique vendeur")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSeller()
            loadSellerProducts()
            loadReviews()
            checkIfFollowing()
        }
    }

    private func loadSeller() {
        db.collection("marketplaceUsers")
            .document(sellerId)
            .getDocument { snapshot, _ in
                let data = snapshot?.data() ?? [:]

                seller = MarketplaceSeller(
                    id: snapshot?.documentID,
                    name: data["displayName"] as? String
                        ?? data["fullName"] as? String
                        ?? data["name"] as? String
                        ?? "Utilisateur Cutly",
                    photoURL: data["photoURL"] as? String
                        ?? data["profileImageURL"] as? String
                        ?? "",
                    bannerURL: data["bannerURL"] as? String ?? "",
                    verified:
                        data["marketplaceVerified"] as? Bool == true &&
                        data["badgeVisible"] as? Bool == true &&
                        data["certificationStatus"] as? String == "active",
                    certifiedShop:
                        data["marketplaceVerified"] as? Bool == true &&
                        data["badgeVisible"] as? Bool == true &&
                        data["certificationStatus"] as? String == "active",
                    country: data["country"] as? String ?? "",
                    city: data["city"] as? String ?? "",
                    bio: data["bio"] as? String ?? "",
                    rating: data["rating"] as? Double ?? 0,
                    reviewsCount: data["reviewsCount"] as? Int ?? 0,
                    followers: data["followers"] as? Int ?? 0,
                    following: data["following"] as? Int ?? 0,
                    sales: data["sales"] as? Int ?? 0,
                    activeProducts: data["activeProducts"] as? Int ?? 0,
                    soldProducts: data["soldProducts"] as? Int ?? 0,
                    responseTime: data["responseTime"] as? String ?? "",
                    shippingTime: data["shippingTime"] as? String ?? "",
                    cancellationRate: data["cancellationRate"] as? Int ?? 0,
                    disputeRate: data["disputeRate"] as? Int ?? 0,
                    trustScore: data["trustScore"] as? Int ?? 0,
                    joinedAt: data["joinedAt"] as? Timestamp,
                    lastSeen: data["lastSeen"] as? Timestamp,
                    allowCall: data["allowCall"] as? Bool ?? false,
                    allowGPS: data["allowGPS"] as? Bool ?? false,
                    latitude: data["latitude"] as? Double,
                    longitude: data["longitude"] as? Double
                )

                isLoading = false
            }
    }

    private func loadSellerProducts() {
        db.collection("marketplace_products")
            .whereField("sellerId", isEqualTo: sellerId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }

                var rawData: [String: [String: Any]] = [:]

                products = documents.map { doc in
                    let data = doc.data()
                    rawData[doc.documentID] = data

                    let sellerId = data["sellerId"] as? String ?? seller?.id ?? ""

                    let sellerPhotoURL =
                        data["sellerPhotoURL"] as? String ??
                        data["sellerPhoto"] as? String ??
                        data["sellerAvatarURL"] as? String ??
                        data["storeLogoURL"] as? String ??
                        seller?.photoURL ??
                        ""

                    return MarketplaceHomeProduct(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "Produit",
                        priceText: data["priceText"] as? String ?? "\(data["price"] ?? "") €",
                        originalPriceText: MarketplacePriceFormatter.formatOptional(data["originalPrice"] as? Double),
                        discountPercent: data["discountPercent"] as? Int
                            ?? data["discountPercentage"] as? Int
                            ?? data["discount"] as? Int,
                        country: data["country"] as? String ?? data["countryName"] as? String ?? "",
                        city: data["city"] as? String ?? data["sellerCity"] as? String ?? "",
                        imageURL: data["mainImageURL"] as? String
                            ?? (data["imageURLs"] as? [String])?.first,
                        sellerId: sellerId,
                        sellerName: data["sellerName"] as? String ?? seller?.name ?? "",
                        sellerPhotoURL: sellerPhotoURL,
                        sellerVerified: data["sellerVerified"] as? Bool ?? seller?.verified ?? false,
                        rating: data["rating"] as? Double ?? data["averageRating"] as? Double,
                        latitude: data["latitude"] as? Double,
                        longitude: data["longitude"] as? Double,
                        isFavorite: false,
                        variants: [],
                    )
                }

                sellerProductsRawData = rawData
            }
    }
    private func loadReviews() {
        db.collection("marketplace_seller_reviews")
            .whereField("sellerId", isEqualTo: sellerId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }

                reviews = documents.map { doc in
                    let data = doc.data()

                    return MarketplaceSellerReview(
                        id: doc.documentID,
                        buyerName: data["buyerName"] as? String ?? "",
                        rating: data["rating"] as? Double ?? 5,
                        comment: data["comment"] as? String ?? "",
                        images: data["images"] as? [String] ?? [],
                        sellerReply: data["sellerReply"] as? String ?? "",
                        createdAt: data["createdAt"] as? Timestamp
                    )
                }
            }
    }

    private func checkIfFollowing() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("seller_followers")
            .document(sellerId)
            .collection("users")
            .document(uid)
            .getDocument { snapshot, _ in
                isFollowing = snapshot?.exists ?? false
            }
    }
}
private extension MarketplaceSellerProfileView {

    var sellerHeaderSection: some View {
        VStack(spacing: 0) {
            sellerBanner

            VStack(spacing: 14) {
                sellerIdentityBlock
                sellerTrustBlock
                sellerStatsGrid
            }
            .padding(18)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .padding(.horizontal, 16)
    }

    var sellerBanner: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let urlString = seller?.bannerURL,
                   !urlString.isEmpty,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        MarketplaceSkeletonView(cornerRadius: 0)
                    }
                } else {
                    MarketplaceUITheme.darkLuxuryGradient
                }
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .clipped()

            HStack(alignment: .bottom, spacing: 14) {
                sellerAvatar

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(seller?.name.isEmpty == false ? seller?.name ?? "" : "Utilisateur Cutly Market")
                            .font(.system(.title2, design: .rounded).weight(.black))
                            .foregroundStyle(.white)

                        if seller?.verified == true || seller?.certifiedShop == true {
                            CutlyVerifiedBadge(size: 18)
                        }
                    }

                    Text(locationText)
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.86))
                }

                Spacer()
            }
            .padding(18)
        }
    }

    var sellerAvatar: some View {
        Group {
            if let urlString = seller?.photoURL,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    MarketplaceSkeletonView(cornerRadius: 32)
                }
            } else {
                MarketplaceIconBadge(icon: "person.crop.circle.fill", size: 72)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 8)
    }

    var sellerIdentityBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(joinedText, systemImage: "calendar")
                Spacer()
                Label(lastSeenText, systemImage: "clock.fill")
            }
            .font(.caption.bold())
            .foregroundStyle(.secondary)

            if let bio = seller?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            } else {
                Text("Vendeur actif sur Cutly Marketplace.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var sellerTrustBlock: some View {
        HStack(spacing: 10) {
            MarketplaceSellerTrustChip(
                title: seller?.certifiedShop == true ? "Boutique certifiée" : "Boutique",
                icon: "checkmark.seal.fill"
            )

            MarketplaceSellerTrustChip(
                title: "Score IA \(seller?.trustScore ?? 0)%",
                icon: "brain.head.profile"
            )

            MarketplaceSellerTrustChip(
                title: "Réponse \(seller?.responseTime.isEmpty == false ? seller?.responseTime ?? "" : "< 1 h")",
                icon: "bolt.fill"
            )
        }
    }

    var sellerStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 10) {
            MarketplaceSellerStatCard(title: "Ventes", value: "\(seller?.sales ?? 0)", icon: "bag.fill")
            MarketplaceSellerStatCard(title: "Avis", value: "\(seller?.reviewsCount ?? 0)", icon: "star.fill")
            MarketplaceSellerStatCard(title: "Abonnés", value: "\(seller?.followers ?? 0)", icon: "person.2.fill")
            MarketplaceSellerStatCard(title: "Actifs", value: "\(seller?.activeProducts ?? products.count)", icon: "shippingbox.fill")
            MarketplaceSellerStatCard(title: "Vendus", value: "\(seller?.soldProducts ?? 0)", icon: "checkmark.circle.fill")
            MarketplaceSellerStatCard(title: "Note", value: String(format: "%.1f", seller?.rating ?? 0), icon: "star.circle.fill")
        }
    }

    var locationText: String {
        let city = seller?.city ?? ""
        let country = seller?.country ?? ""

        if !city.isEmpty && !country.isEmpty {
            return "\(city), \(country)"
        }

        if !country.isEmpty {
            return country
        }

        return "Marketplace"
    }

    var joinedText: String {
        guard let joinedAt = seller?.joinedAt else {
            return "Inscription récente"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Depuis \(formatter.string(from: joinedAt.dateValue()))"
    }

    var lastSeenText: String {
        guard let lastSeen = seller?.lastSeen else {
            return "Actif récemment"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastSeen.dateValue(), relativeTo: Date())
    }
}

private struct MarketplaceSellerTrustChip: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption.bold())
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

private struct MarketplaceSellerStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 7) {
            MarketplaceIconBadge(icon: icon, size: 34)

            Text(value)
                .font(.headline.bold())

            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
private extension MarketplaceSellerProfileView {

    var sellerActionsSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Button {
                    toggleFollowSeller()
                } label: {
                    Label(isFollowing ? "Suivi" : "Suivre", systemImage: isFollowing ? "checkmark.circle.fill" : "person.badge.plus.fill")
                }
                .buttonStyle(MarketplacePremiumButtonStyle())

                Button {
                    createSellerConversation()
                } label: {
                    Image(systemName: "message.fill")
                        .font(.headline.bold())
                        .frame(width: 54, height: 54)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                if seller?.allowCall == true {
                    MarketplaceSellerActionButton(title: "Appeler", icon: "phone.fill") {
                        print("📞 Appel vendeur:", sellerId)
                    }
                }

                MarketplaceSellerActionButton(title: "Partager", icon: "square.and.arrow.up") {
                    showShareSheet = true
                }

                if seller?.allowGPS == true {
                    MarketplaceSellerActionButton(title: "Carte", icon: "map.fill") {
                        print("🗺️ Ouvrir carte vendeur:", seller?.latitude ?? 0, seller?.longitude ?? 0)
                    }
                }

                MarketplaceSellerActionButton(title: "Signaler", icon: "flag.fill") {
                    showReportSheet = true
                }
            }

            HStack(spacing: 10) {
                Label("Expédition \(seller?.shippingTime.isEmpty == false ? seller?.shippingTime ?? "" : "à confirmer")", systemImage: "shippingbox.fill")

                Spacer()

                Label("Litiges \(seller?.disputeRate ?? 0)%", systemImage: "exclamationmark.shield.fill")
            }
            .font(.caption.bold())
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
        .sheet(isPresented: $showReportSheet) {
            sellerReportSheet
        }
        .sheet(isPresented: $showShareSheet) {
            sellerShareSheet
        }
    }

    var sellerReportSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Signaler ce vendeur")
                    .font(.title2.bold())

                TextField("Explique le problème", text: $reportReason, axis: .vertical)
                    .lineLimit(5)
                    .padding(14)
                    .background(.thinMaterial)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )

                Button {
                    reportSeller()
                    showReportSheet = false
                } label: {
                    Label("Envoyer le signalement", systemImage: "paperplane.fill")
                }
                .buttonStyle(MarketplacePremiumButtonStyle())

                Spacer()
            }
            .padding()
            .navigationTitle("Signalement")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var sellerShareSheet: some View {
        VStack(spacing: 18) {
            MarketplaceIconBadge(icon: "square.and.arrow.up", size: 70)

            Text("Partager la boutique")
                .font(.title2.bold())

            Text("Lien boutique : cutly://seller/\(sellerId)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                UIPasteboard.general.string = "cutly://seller/\(sellerId)"
                showShareSheet = false
            } label: {
                Label("Copier le lien", systemImage: "doc.on.doc.fill")
            }
            .buttonStyle(MarketplacePremiumButtonStyle())

            Spacer()
        }
        .padding()
    }

    func toggleFollowSeller() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard uid != sellerId else { return }

        let ref = db.collection("seller_followers")
            .document(sellerId)
            .collection("users")
            .document(uid)

        if isFollowing {
            ref.delete { _ in
                isFollowing = false
                seller?.followers = max((seller?.followers ?? 0) - 1, 0)
            }
        } else {
            ref.setData([
                "userId": uid,
                "sellerId": sellerId,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if error == nil {
                    isFollowing = true
                    seller?.followers += 1
                }
            }
        }
    }

    func createSellerConversation() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard uid != sellerId else { return }

        let conversationId = [uid, sellerId].sorted().joined(separator: "_")

        db.collection("marketplace_conversations")
            .document(conversationId)
            .setData([
                "id": conversationId,
                "participantIds": [uid, sellerId],
                "buyerId": uid,
                "sellerId": sellerId,
                "sellerName": seller?.name ?? "",
                "lastMessageText": "Conversation démarrée depuis la boutique vendeur.",
                "lastMessageAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    func reportSeller() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("marketplace_reports")
            .document()
            .setData([
                "reporterId": uid,
                "targetId": sellerId,
                "targetType": "seller",
                "reason": reportReason,
                "status": "open",
                "priority": "high",
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)

        reportReason = ""
    }
}
private struct MarketplaceSellerActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline.bold())

                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}
private extension MarketplaceSellerProfileView {

    var sellerShopProductsSection: some View {
        VStack(spacing: 14) {
            MarketplaceSectionHeader(
                title: "Boutique du vendeur",
                subtitle: "\(filteredProducts.count) produit(s)",
                actionTitle: nil,
                action: nil
            )

            TextField("Rechercher dans cette boutique...", text: $searchText)
                .padding(14)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SellerFilter.allCases) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            Text(filter.title)
                                .font(.caption.bold())
                                .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    selectedFilter == filter
                                    ? AnyView(MarketplaceUITheme.primaryGradient)
                                    : AnyView(Color.primary.opacity(0.08))
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            if filteredProducts.isEmpty {
                MarketplaceSellerEmptyProductsView()
                    .padding(.horizontal, 16)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ], spacing: 14) {
                    ForEach(filteredProducts) { product in
                        NavigationLink {
                            MarketplaceProductDetailView(product: product)
                        } label: {
                            MarketplaceSellerProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    var filteredProducts: [MarketplaceHomeProduct] {
        var result = products

        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()

            result = result.filter {
                $0.title.lowercased().contains(query)
                || $0.country.lowercased().contains(query)
                || $0.priceText.lowercased().contains(query)
            }
        }

        switch selectedFilter {
        case .all:
            return result

        case .available:
            return result.filter { product in
                productDataFor(product)["status"] as? String != "sold"
            }

        case .sold:
            return result.filter { product in
                productDataFor(product)["status"] as? String == "sold"
            }

        case .promotion:
            return result.filter { product in
                productDataFor(product)["hasPromotion"] as? Bool == true
            }
        }
    }

    func productDataFor(_ product: MarketplaceHomeProduct) -> [String: Any] {
        sellerProductsRawData[product.id] ?? [:]
    }
}
private struct MarketplaceSellerProductCard: View {
    let product: MarketplaceHomeProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            productImage

            HStack(spacing: 5) {
                Text(product.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)

                if product.sellerVerified {
                    CutlyVerifiedBadge(size: 14)
                }
            }

            Text(product.priceText)
                .font(.headline.bold())

            if !product.country.isEmpty {
                Text(product.country)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .clipped()
    }

    private var productImage: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let imageURL = product.imageURL,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            MarketplaceSkeletonView(cornerRadius: 22)

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()

                        case .failure:
                            placeholder

                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .clipped()

            
        }
        .frame(maxWidth: .infinity)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.gray.opacity(0.14))
            .overlay(
                Image(systemName: "bag.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.5))
            )
    }
}

private struct MarketplaceSellerEmptyProductsView: View {
    var body: some View {
        VStack(spacing: 14) {
            MarketplaceIconBadge(icon: "shippingbox.fill", size: 64)

            Text("Aucun produit trouvé")
                .font(.title3.bold())

            Text("Les produits disponibles, vendus ou en promotion apparaîtront ici automatiquement.")
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




// MARK: - Filtres

enum SellerFilter: String, CaseIterable, Identifiable {
    case all
    case available
    case sold
    case promotion

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Tous"
        case .available: return "Disponibles"
        case .sold: return "Vendus"
        case .promotion: return "Promotions"
        }
    }
}

// MARK: - Modèle vendeur

struct MarketplaceSeller: Identifiable {
    var id: String?

    var name: String = ""
    var photoURL: String = ""
    var bannerURL: String = ""
    var verified = false
    var certifiedShop = false

    var country = ""
    var city = ""
    var bio = ""

    var rating: Double = 0
    var reviewsCount = 0
    var followers = 0
    var following = 0
    var sales = 0
    var activeProducts = 0
    var soldProducts = 0

    var responseTime = ""
    var shippingTime = ""
    var cancellationRate = 0
    var disputeRate = 0
    var trustScore = 0

    var joinedAt: Timestamp?
    var lastSeen: Timestamp?

    var allowCall = false
    var allowGPS = false
    var latitude: Double?
    var longitude: Double?
}

// MARK: - Modèle avis

struct MarketplaceSellerReview: Identifiable {
    var id: String?

    var buyerName = ""
    var rating: Double = 5
    var comment = ""
    var images: [String] = []
    var sellerReply = ""
    var createdAt: Timestamp?
}
