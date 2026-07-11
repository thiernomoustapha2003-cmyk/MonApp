//
//  MarketplaceProductDetailView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import MapKit
import CoreLocation
import StripePaymentSheet
import FirebaseFunctions




struct MarketplaceProductDetailView: View {
    let product: MarketplaceHomeProduct
    @Environment(\.colorScheme) private var colorScheme
    
    
    @State private var isAdminUser = false
    
    
    @State private var selectedMediaIndex = 0
    @State private var isFavorite = false
    @State private var animateHero = false
    @State private var showGalleryHint = true
    @State private var productImages: [String] = []
    
    @State private var showFullScreenGallery = false
    
    
    @State private var productData: [String: Any] = [:]
    
    @State private var viewsCount = 0
    @State private var favoritesCount = 0
    @State private var salesCount = 0
    
    @State private var stock = 0
    
    @State private var oldPrice: Double?
    @State private var discountPercent = 0
    
    @State private var publishedDate = ""
    
    
    @State private var sellerFollowers = 0
    @State private var sellerSales = 0
    @State private var sellerRating: Double = 0
    @State private var sellerReviews = 0
    @State private var sellerResponseTime = ""
    @State private var isFollowingSeller = false
    
    @State private var showSellerProfile = false
    
    @State private var fallbackSellerId = ""
    
    @State private var navigateToConversation = false
    @State private var openedConversationId = ""
    @State private var isOpeningConversation = false
    
    @State private var navigateToMarketplaceThread = false
    @State private var targetConversationId = ""
    @State private var targetSellerId = ""
    
    @State private var navigateToCheckout = false
    @State private var selectedQuantity = 1
   
    
    
    
    
    @State private var dynamicAttributes: [String: String] = [:]
    @State private var productReviews: [MarketplaceProductReviewItem] = []
    @State private var similarProducts: [MarketplaceHomeProduct] = []
    @State private var isLoadingReviews = false
    @State private var isLoadingSimilarProducts = false
    
    @State private var reviewMessageText: [String: String] = [:]
    @State private var isSendingReviewMessage: Set<String> = []
    @State private var reviewReplies: [String: [MarketplaceReviewReplyItem]] = [:]
    
    @State private var selectedColor: String = ""
    @State private var selectedSize: String = ""
    @State private var selectedVariant: MarketplaceProductVariant?
    
    
    
    
    
    
    
    
    init(product: MarketplaceHomeProduct) {
        self.product = product
    }

    init(productId: String) {
        self.product = MarketplaceHomeProduct(
            id: productId,
            title: "Chargement...",
            priceText: "0 €",
            originalPriceText: nil,
            discountPercent: nil,
            country: "",
            city: "",
            imageURL: nil,
            sellerId: "",
            sellerName: "",
            sellerPhotoURL: "",
            sellerVerified: false,
            rating: nil,
            latitude: nil,
            longitude: nil,
            isFavorite: false,
            variants: []
        )
    }
    
    
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        productHeroSection
                        productInfoSection
                        sellerPreviewSection
                        productDetailsSection
                        shippingPaymentSection
                        reviewsQuestionsSection
                        similarProductsSection
                        reportSafetySection
                        trustBadgesSection
                        buyerProtectionSection
                        Spacer(minLength: 110)
                    }
                    .padding(.vertical, 18)
                }
                
                bottomActionBar
            }
            .navigationTitle("Détail produit")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadAdminPermissions()
                loadProductDetail()
            }
            
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            toggleFavoriteProduct()
                        } label: {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(isFavorite ? .red : .primary)
                        }
                        
                        Button {
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .font(.system(size: 18, weight: .bold))
                }
            }
        }
    }
    private func loadAdminPermissions() {

        guard let uid = Auth.auth().currentUser?.uid else {
            isAdminUser = false
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { snapshot, _ in

                guard let data = snapshot?.data() else {
                    isAdminUser = false
                    return
                }

                let owner = data["isPlatformOwner"] as? Bool ?? false
                let admin = data["isAdmin"] as? Bool ?? false
                let role = data["role"] as? String ?? ""
                let level = data["adminLevel"] as? String ?? ""

                isAdminUser =
                    owner ||
                    admin ||
                    role == "admin" ||
                    level == "owner"
            }
    }

    private func canWriteReviewMessage(_ review: MarketplaceProductReviewItem) -> Bool {
        Auth.auth().currentUser?.uid != nil
    }

    private func sendReviewMessage(_ review: MarketplaceProductReviewItem) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let cleanText = (reviewMessageText[review.id] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanText.count >= 2 else { return }

        isSendingReviewMessage.insert(review.id)

        let replyId = UUID().uuidString
        let isSeller = uid == resolvedSellerId

        Firestore.firestore()
            .collection("marketplace_reviews")
            .document(review.id)
            .collection("replies")
            .document(replyId)
            .setData([
                "id": replyId,
                "reviewId": review.id,
                "productId": product.id,
                "userId": uid,
                "authorName": isSeller ? (product.sellerName.isEmpty ? "Vendeur" : product.sellerName) : "Acheteur Cutly",
                "text": cleanText,
                "isSeller": isSeller,
                "isDeleted": false,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                isSendingReviewMessage.remove(review.id)

                if let error {
                    print("❌ sendReviewMessage:", error.localizedDescription)
                    return
                }

                reviewMessageText[review.id] = ""
                loadReviewReplies(for: review.id)
            }
    }

    private func deleteReviewAdminOnly(_ review: MarketplaceProductReviewItem) {
        guard isAdminUser else { return }

        Firestore.firestore()
            .collection("marketplace_reviews")
            .document(review.id)
            .setData([
                "status": "deletedByAdmin",
                "isDeleted": true,
                "deletedAt": FieldValue.serverTimestamp(),
                "deletedBy": Auth.auth().currentUser?.uid ?? "",
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if let error {
                    print("❌ deleteReviewAdminOnly:", error.localizedDescription)
                    return
                }

                loadProductReviews()
            }
    }

    private func deleteReplyAdminOnly(reviewId: String, replyId: String) {
        guard isAdminUser else { return }

        Firestore.firestore()
            .collection("marketplace_reviews")
            .document(reviewId)
            .collection("replies")
            .document(replyId)
            .setData([
                "isDeleted": true,
                "deletedAt": FieldValue.serverTimestamp(),
                "deletedBy": Auth.auth().currentUser?.uid ?? "",
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if let error {
                    print("❌ deleteReplyAdminOnly:", error.localizedDescription)
                    return
                }

                loadReviewReplies(for: reviewId)
            }
    }

    private func loadReviewReplies(for reviewId: String) {
        Firestore.firestore()
            .collection("marketplace_reviews")
            .document(reviewId)
            .collection("replies")
            .order(by: "createdAt", descending: false)
            .getDocuments { snapshot, _ in

                let replies = snapshot?.documents.compactMap { doc -> MarketplaceReviewReplyItem? in
                    let data = doc.data()

                    if data["isDeleted"] as? Bool == true {
                        return nil
                    }

                    return MarketplaceReviewReplyItem(
                        id: doc.documentID,
                        reviewId: reviewId,
                        authorName: data["authorName"] as? String ?? "Utilisateur",
                        text: data["text"] as? String ?? "",
                        isSeller: data["isSeller"] as? Bool ?? false,
                        createdAt: data["createdAt"] as? Timestamp
                    )
                } ?? []

                reviewReplies[reviewId] = replies
            }
    }
    
    
    private var allowsDelivery: Bool {
        productData["allowsDelivery"] as? Bool
        ?? productData["deliveryAvailable"] as? Bool
        ?? false
    }
    
    private var allowsPickup: Bool {
        productData["allowsPickup"] as? Bool
        ?? productData["pickupAvailable"] as? Bool
        ?? false
    }
    private var productDeliverySummaryText: String {
        if allowsDelivery && allowsPickup {
            return "Produit disponible avec livraison ou retrait en main propre, paiement sécurisé et protection acheteur."
        }
        
        if allowsDelivery {
            return "Produit disponible en livraison avec paiement sécurisé, suivi et protection acheteur."
        }
        
        if allowsPickup {
            return "Produit disponible en retrait sécurisé avec paiement protégé et validation dans l’application."
        }
        
        return "Les options de livraison ou de retrait seront confirmées par le vendeur."
    }
    
    
    
    private var productHeroImage: some View {
        let selectedURL = productImages.indices.contains(selectedMediaIndex)
        ? productImages[selectedMediaIndex]
        : product.imageURL
        
        return Group {
            if let selectedURL,
               let url = URL(string: selectedURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        MarketplaceSkeletonView(cornerRadius: MarketplaceUITheme.cornerXL)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        productHeroPlaceholder
                    @unknown default:
                        productHeroPlaceholder
                    }
                }
            } else {
                productHeroPlaceholder
            }
        }
        .frame(height: 390)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: MarketplaceUITheme.cornerXL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MarketplaceUITheme.cornerXL, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }
    private var productHeroPlaceholder: some View {
        RoundedRectangle(cornerRadius: MarketplaceUITheme.cornerXL, style: .continuous)
            .fill(MarketplaceUITheme.darkLuxuryGradient)
            .overlay(
                VStack(spacing: 18) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 86, weight: .black))
                        .foregroundStyle(.white.opacity(0.92))
                    
                    Text("Photos HD produit")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white.opacity(0.86))
                }
            )
    }
    private func loadProductDetail() {
        let db = Firestore.firestore()

        db.collection("marketplace_products")
            .document(product.id)
            .getDocument { snapshot, _ in
                guard let data = snapshot?.data() else { return }

                productData = data
                dynamicAttributes = data["dynamicAttributes"] as? [String: String] ?? [:]
                loadProductReviews()
                loadSimilarProducts()
                
                fallbackSellerId = data["sellerId"] as? String ?? ""

                let urls = data["imageURLs"] as? [String] ?? []
                productImages = urls.isEmpty ? [product.imageURL].compactMap { $0 } : urls

                viewsCount = data["viewsCount"] as? Int ?? 0
                favoritesCount = data["favoritesCount"] as? Int ?? 0
                salesCount = data["salesCount"] as? Int ?? 0
                stock = data["quantity"] as? Int ?? 0
                oldPrice = data["oldPrice"] as? Double
                discountPercent = data["promotionPercent"] as? Int ?? 0

                sellerFollowers = data["sellerFollowers"] as? Int ?? 0
                sellerSales = data["sellerSales"] as? Int ?? 0
                sellerRating = data["sellerRating"] as? Double ?? 0
                sellerReviews = data["sellerReviews"] as? Int ?? 0
                sellerResponseTime = data["sellerResponseTime"] as? String ?? "< 1 h"

                if let timestamp = data["createdAt"] as? Timestamp {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "fr_FR")
                    formatter.dateStyle = .medium
                    publishedDate = formatter.string(from: timestamp.dateValue())
                }

                checkFavoriteStatus()
                checkFollowStatus()
                registerUniqueProductView()
            }
    }
    private func registerUniqueProductView() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let sellerId = resolvedSellerId

        guard !sellerId.isEmpty else { return }
        guard sellerId != uid else {
            print("ℹ️ Vue non comptée : le vendeur regarde son propre produit.")
            return
        }

        let viewId = "\(uid)_\(product.id)"
        let viewRef = Firestore.firestore()
            .collection("marketplace_recently_viewed")
            .document(viewId)

        viewRef.getDocument { snapshot, _ in
            if snapshot?.exists == true {
                print("ℹ️ Vue déjà comptée pour cet utilisateur.")
                return
            }

            viewRef.setData([
                "id": viewId,
                "userId": uid,
                "productId": product.id,
                "sellerId": sellerId,
                "targetType": "product",
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if let error {
                    print("❌ registerUniqueProductView:", error.localizedDescription)
                    return
                }

                Firestore.firestore()
                    .collection("marketplace_products")
                    .document(product.id)
                    .setData([
                        "viewsCount": FieldValue.increment(Int64(1)),
                        "updatedAt": FieldValue.serverTimestamp()
                    ], merge: true)

                viewsCount += 1
            }
        }
    }
    
    private func checkFavoriteStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let favoriteId = "\(uid)_\(product.id)"
        
        Firestore.firestore()
            .collection("marketplace_favorites")
            .document(favoriteId)
            .getDocument { snapshot, _ in
                isFavorite = snapshot?.exists == true
            }
    }
    
    private func checkFollowStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let sellerId = resolvedSellerId
        guard !sellerId.isEmpty else { return }
        
        let followId = "\(uid)_\(sellerId)"
        
        Firestore.firestore()
            .collection("marketplace_followers")
            .document(followId)
            .getDocument { snapshot, _ in
                isFollowingSeller = snapshot?.exists == true
            }
    }
    
    
    
    
    
    
    private func toggleFollowSeller() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let sellerId = productData["sellerId"] as? String ?? ""
        guard !sellerId.isEmpty, sellerId != uid else { return }
        
        let followId = "\(uid)_\(sellerId)"
        let ref = Firestore.firestore()
            .collection("marketplace_followers")
            .document(followId)
        
        if isFollowingSeller {
            ref.delete { _ in
                isFollowingSeller = false
                sellerFollowers = max(sellerFollowers - 1, 0)
            }
        } else {
            ref.setData([
                "id": followId,
                "followerId": uid,
                "sellerId": sellerId,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if error == nil {
                    isFollowingSeller = true
                    sellerFollowers += 1
                }
            }
        }
    }
    private func toggleFavoriteProduct() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let sellerId = resolvedSellerId
        let favoriteId = "\(uid)_\(product.id)"
        let notificationId = "favorite_\(favoriteId)"

        let db = Firestore.firestore()
        let favoriteRef = db.collection("marketplace_favorites").document(favoriteId)
        let productRef = db.collection("marketplace_products").document(product.id)

        if isFavorite {
            favoriteRef.delete { error in
                if let error {
                    print("❌ remove favorite:", error.localizedDescription)
                    return
                }

                isFavorite = false
                favoritesCount = max(favoritesCount - 1, 0)

                productRef.setData([
                    "favoritesCount": FieldValue.increment(Int64(-1)),
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
            }

            return
        }

        favoriteRef.setData([
            "id": favoriteId,
            "userId": uid,
            "productId": product.id,
            "sellerId": sellerId,
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

            isFavorite = true
            favoritesCount += 1

            productRef.setData([
                "favoritesCount": FieldValue.increment(Int64(1)),
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)

            guard !sellerId.isEmpty, sellerId != uid else { return }

            db.collection("marketplace_notifications")
                .document(notificationId)
                .setData([
                    "id": notificationId,
                    "userId": sellerId,
                    "senderId": uid,
                    "productId": product.id,
                    "targetId": product.id,
                    "targetType": "product",
                    "type": "product_favorite",
                    "title": "Nouveau favori Cutly",
                    "body": "Quelqu’un a ajouté votre produit aux favoris : \(product.title)",
                    "priority": "normal",
                    "isRead": false,
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
        }
    }
    private func openSellerConversation() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let finalSellerId = resolvedSellerId
        guard !finalSellerId.isEmpty, finalSellerId != uid else {
            print("❌ Impossible d’ouvrir la conversation : sellerId vide ou vendeur = utilisateur")
            return
        }
        
        isOpeningConversation = true
        
        let conversationId = [uid, finalSellerId].sorted().joined(separator: "_")
        
        Firestore.firestore()
            .collection("marketplace_conversations")
            .document(conversationId)
            .setData([
                "id": conversationId,
                "participantIds": [uid, finalSellerId],
                "buyerId": uid,
                "sellerId": finalSellerId,
                "productId": product.id,
                "productTitle": product.title,
                "productImageURL": product.imageURL ?? "",
                "sellerName": product.sellerName,
                "lastMessageText": "Conversation démarrée depuis la fiche produit.",
                "lastMessageAt": FieldValue.serverTimestamp(),
                "unreadFor": [],
                "type": "buyerSeller",
                "source": "product_detail",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                isOpeningConversation = false
                
                if let error {
                    print("❌ openSellerConversation:", error.localizedDescription)
                    return
                }
                
                targetConversationId = conversationId
                targetSellerId = finalSellerId
                navigateToMarketplaceThread = true
            }
    }
    private func loadProductReviews() {
        isLoadingReviews = true

        Firestore.firestore()
            .collection("marketplace_reviews")
            .whereField("productId", isEqualTo: product.id)
            .order(by: "createdAt", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, _ in

                let reviews: [MarketplaceProductReviewItem] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()

                    if data["isDeleted"] as? Bool == true {
                        return nil
                    }

                    return MarketplaceProductReviewItem(
                        id: doc.documentID,
                        buyerName: data["buyerName"] as? String ?? "Acheteur Cutly",
                        rating: data["rating"] as? Int ?? 5,
                        comment: data["comment"] as? String ?? "",
                        createdAt: data["createdAt"] as? Timestamp
                    )
                } ?? []

                productReviews = reviews
                isLoadingReviews = false

                reviews.forEach { review in
                    loadReviewReplies(for: review.id)
                }
            }
    }

    private func loadSimilarProducts() {
        isLoadingSimilarProducts = true

        let categoryId = productData["categoryId"] as? String ?? ""
        guard !categoryId.isEmpty else {
            isLoadingSimilarProducts = false
            return
        }

        Firestore.firestore()
            .collection("marketplace_products")
            .whereField("status", isEqualTo: "active")
            .whereField("categoryId", isEqualTo: categoryId)
            .limit(to: 10)
            .getDocuments { snapshot, _ in
                similarProducts = snapshot?.documents.compactMap { doc in
                    if doc.documentID == product.id {
                        return nil
                    }

                    let data = doc.data()

                    return MarketplaceHomeProduct(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "Produit",
                        priceText: data["priceText"] as? String ?? "\(data["price"] ?? "") EUR",
                        originalPriceText: MarketplacePriceFormatter.formatOptional(data["originalPrice"] as? Double),
                        discountPercent: data["discountPercent"] as? Int
                            ?? data["discountPercentage"] as? Int
                            ?? data["discount"] as? Int,
                        country: data["country"] as? String ?? data["countryName"] as? String ?? "",
                        city: data["city"] as? String
                            ?? data["sellerCity"] as? String
                            ?? "",
                        imageURL: data["mainImageURL"] as? String ?? (data["imageURLs"] as? [String])?.first,
                        sellerId: data["sellerId"] as? String ?? "",
                        sellerName: data["sellerName"] as? String ?? "",
                        sellerPhotoURL: data["sellerPhotoURL"] as? String ?? "",
                        sellerVerified: data["sellerVerified"] as? Bool ?? false,
                        rating: data["rating"] as? Double
                            ?? data["averageRating"] as? Double,
                        latitude: data["latitude"] as? Double,
                        longitude: data["longitude"] as? Double,
                        isFavorite: false,
                        variants: [],
                    )
                } ?? []

                isLoadingSimilarProducts = false
            }
    }
    
    
    
    private var productHeroSection: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                TabView(selection: $selectedMediaIndex) {
                    
                    if displayedProductImages.isEmpty {
                        
                        productHeroPlaceholder
                            .tag(0)
                        
                    } else {
                        
                        ForEach(Array(displayedProductImages.enumerated()), id: \.offset) { index, imageURL in
                            
                            Group {
                                
                                if let url = URL(string: imageURL) {
                                    
                                    AsyncImage(url: url) { phase in
                                        
                                        switch phase {
                                            
                                        case .empty:
                                            
                                            MarketplaceSkeletonView(
                                                cornerRadius: MarketplaceUITheme.cornerXL
                                            )
                                            
                                        case .success(let image):
                                            
                                            image
                                                .resizable()
                                                .scaledToFill()
                                            
                                        case .failure:
                                            
                                            productHeroPlaceholder
                                            
                                        @unknown default:
                                            
                                            productHeroPlaceholder
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                    
                                    productHeroPlaceholder
                                    
                                }
                                
                            }
                            .tag(index)
                            
                        }
                        
                    }
                    
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 390)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: MarketplaceUITheme.cornerXL,
                        style: .continuous
                    )
                )
                .onTapGesture {
                    showFullScreenGallery = true
                }
                .fullScreenCover(isPresented: $showFullScreenGallery) {
                    MarketplaceFullScreenGalleryView(
                        images: displayedProductImages,
                        selectedIndex: $selectedMediaIndex
                    )
                }
                
                
                
                
                
                VStack {
                    HStack {
                        Spacer()
                        
                        Text("\(min(selectedMediaIndex + 1, max(displayedProductImages.count, 1)))/\(max(displayedProductImages.count, 1))")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.45))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                .padding(16)
                
                
                VStack(spacing: 10) {
                    MarketplaceProductFloatingBadge(title: "HD", icon: "photo.fill")
                    MarketplaceProductFloatingBadge(title: "360°", icon: "rotate.3d")
                }
                .padding(16)
                if showGalleryHint {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                            Text("Touchez pour ouvrir la galerie plein écran")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(.white.opacity(0.16))
                        .clipShape(Capsule())
                        .padding(.bottom, 18)
                    }
                }
            }
            .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 16)
            .padding(.horizontal, 16)
            .onAppear {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                    animateHero = true
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(displayedProductImages.enumerated()), id: \.offset) { index, imageURL in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                selectedMediaIndex = index
                            }
                        } label: {
                            Group {
                                
                                if let url = URL(string: imageURL) {
                                    
                                    AsyncImage(url: url) { phase in
                                        
                                        switch phase {
                                            
                                        case .empty:
                                            
                                            MarketplaceSkeletonView(cornerRadius: 18)
                                            
                                        case .success(let image):
                                            
                                            image
                                                .resizable()
                                                .scaledToFill()
                                            
                                        case .failure:
                                            
                                            Color.gray.opacity(0.15)
                                            
                                        @unknown default:
                                            
                                            Color.gray.opacity(0.15)
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                    
                                    Color.gray.opacity(0.15)
                                    
                                }
                                
                            }
                            .frame(width: 74, height: 74)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 18)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        index == selectedMediaIndex
                                        ? Color.orange
                                        : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var productInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.title)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .lineLimit(2)
                    
                    Text(product.country.isEmpty ? "Produit Marketplace" : product.country)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(cutlyPriceText(selectedVariantPrice))
                        .foregroundStyle(isProductSoldOut ? .red : .primary)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                    
                    if let oldPrice {
                        Text(cutlyPriceText(oldPrice))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .strikethrough()
                    }
                    
                    if discountPercent > 0 {
                        Text("-\(discountPercent)%")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.red)
                            .clipShape(Capsule())
                    }
                }
            }
            
            HStack(spacing: 10) {
                if product.sellerVerified {
                    MarketplaceProductChip(title: "Vendeur vérifié", icon: "checkmark.seal.fill")
                }
                
                if allowsDelivery {
                    MarketplaceProductChip(title: "Livraison", icon: "shippingbox.fill")
                }
                
                if allowsPickup {
                    MarketplaceProductChip(title: "Retrait", icon: "hand.raised.fill")
                }
                
                if productData["hasWarranty"] as? Bool == true {
                    MarketplaceProductChip(title: "Garantie", icon: "shield.fill")
                }
            }
            if !availableColors.isEmpty || !availableSizes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {

                    if !availableColors.isEmpty {
                        Text("Couleur")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(availableColors, id: \.self) { color in
                                    Button {

                                        selectedColor = color
                                        selectedSize = ""
                                        updateSelectedVariant()

                                    } label: {

                                        Text(color)
                                            .font(.caption.bold())
                                            .foregroundStyle(selectedColor == color ? .white : .primary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 9)
                                            .background(
                                                selectedColor == color
                                                ? AnyShapeStyle(MarketplaceUITheme.primaryGradient)
                                                : AnyShapeStyle(.thinMaterial)
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!isColorAvailable(color))
                                    .opacity(isColorAvailable(color) ? 1 : 0.35)
                                }
                            }
                        }
                    }

                    if !availableSizes.isEmpty {
                        Text("Taille")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(availableSizes, id: \.self) { size in
                                    Button {

                                        selectedSize = size
                                        updateSelectedVariant()

                                    } label: {

                                        Text(size)
                                            .font(.caption.bold())
                                            .foregroundStyle(selectedSize == size ? .white : .primary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 9)
                                            .background(
                                                selectedSize == size
                                                ? AnyShapeStyle(MarketplaceUITheme.primaryGradient)
                                                : AnyShapeStyle(.thinMaterial)
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!isSizeAvailable(size))
                                    .opacity(isSizeAvailable(size) ? 1 : 0.35)
                                }
                            }
                        }
                    }
                }
            }
            
            
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                MarketplaceProductMiniStat(title: "Vues", value: "\(viewsCount)", icon: "eye.fill")
                MarketplaceProductMiniStat(title: "Favoris", value: "\(favoritesCount)", icon: "heart.fill")
                MarketplaceProductMiniStat(title: "Ventes", value: "\(salesCount)", icon: "bag.fill")
            }
            Divider()
            
            HStack(spacing: 10) {
                Label(selectedVariantStatusText, systemImage: selectedVariantStock <= 0 ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(selectedVariantStatusColor)

                Spacer()

                if selectedVariantStock <= 0 {
                    Text("Vendu / indisponible")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.red)
                        .clipShape(Capsule())
                }
            }
            
            
            
            
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            
            Text(productDeliverySummaryText)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    private var resolvedSellerId: String {
        if let sellerId = productData["sellerId"] as? String, !sellerId.isEmpty {
            return sellerId
        }
        
        if !fallbackSellerId.isEmpty {
            return fallbackSellerId
        }
        
        return ""
    }
    private var availableColors: [String] {

        let colors = product.variants.compactMap { variant -> String? in
            let color = variant.color ?? variant.colorName ?? ""

            guard !color.isEmpty else { return nil }

            if selectedSize.isEmpty {
                return color
            }

            return variant.size == selectedSize ? color : nil
        }

        return Array(Set(colors)).sorted()
    }

    private var availableSizes: [String] {

        let sizes = product.variants.compactMap { variant -> String? in
            let size = variant.size ?? ""

            guard !size.isEmpty else { return nil }

            let color = variant.color ?? variant.colorName ?? ""

            if selectedColor.isEmpty {
                return size
            }

            return color == selectedColor ? size : nil
        }

        return Array(Set(sizes)).sorted()
    }

    private func updateSelectedVariant() {

        selectedVariant = product.variants.first { variant in

            let variantColor = (variant.color ?? variant.colorName ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            let variantSize = (variant.size ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            let wantedColor = selectedColor
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            let wantedSize = selectedSize
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            let colorOK = wantedColor.isEmpty || variantColor == wantedColor
            let sizeOK = wantedSize.isEmpty || variantSize == wantedSize

            return colorOK && sizeOK
        }

        if selectedVariantImageURL != nil {
            selectedMediaIndex = 0
        }
    }

    private func isSizeAvailable(_ size: String) -> Bool {

        product.variants.contains { variant in

            let color = variant.color ?? variant.colorName ?? ""
            let variantSize = variant.size ?? ""

            let sameColor = selectedColor.isEmpty || color == selectedColor
            let sameSize = variantSize == size

            return sameColor && sameSize && variant.stock > 0
        }
    }

    private func isColorAvailable(_ color: String) -> Bool {

        product.variants.contains { variant in

            let variantColor = variant.color ?? variant.colorName ?? ""
            let variantSize = variant.size ?? ""

            let sameColor = variantColor == color
            let sameSize = selectedSize.isEmpty || variantSize == selectedSize

            return sameColor && sameSize && variant.stock > 0
        }
    }
    
    
    
    
    
    private var baseProductPrice: Double {
        productData["price"] as? Double
        ?? Double(
            product.priceText
                .replacingOccurrences(of: "€", with: "")
                .replacingOccurrences(of: ",", with: ".")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )
        ?? 0
    }

    private var selectedVariantPrice: Double {

        guard let variant = selectedVariant else {
            return baseProductPrice
        }

        return baseProductPrice + (variant.priceAdjustment ?? 0)
    }

    private var selectedVariantStock: Int {

        guard let variant = selectedVariant else {
            return stock
        }

        return variant.stock
    }

    private var isProductSoldOut: Bool {
        selectedVariantStock <= 0 || stock <= 0
    }

    private var selectedVariantImageURL: String? {

        guard let image = selectedVariant?.imageURL,
              !image.isEmpty else {
            return nil
        }

        return image
    }
    private var displayedProductImages: [String] {
        guard let variantImage = selectedVariantImageURL, !variantImage.isEmpty else {
            return productImages
        }

        var images = productImages.filter { $0 != variantImage }
        images.insert(variantImage, at: 0)
        return images
    }
    
    
    
    private var selectedVariantStatusText: String {
        if selectedVariantStock <= 0 {
            return "Épuisé"
        }

        if selectedVariantStock == 1 {
            return "Dernier disponible"
        }

        return "\(selectedVariantStock) disponibles"
    }

    private var selectedVariantStatusColor: Color {
        selectedVariantStock <= 0 ? .red : .green
    }
    
    
    
    
    
    
    private var sellerPreviewSection: some View {
        NavigationLink {
            MarketplaceSellerProfileView(
                sellerId: resolvedSellerId
            )
        } label: {
            HStack(spacing: 14) {
                MarketplaceIconBadge(icon: "storefront.fill", size: 52)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(product.sellerName.isEmpty ? "Vendeur Marketplace" : product.sellerName)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)
                        
                        if product.sellerVerified {
                            CutlyVerifiedBadge(size: 16)
                        }
                    }
                    
                    Text(product.country.isEmpty ? "Marketplace" : product.country)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 10) {
                        Label(String(format: "%.1f", sellerRating), systemImage: "star.fill")
                        Label("\(sellerSales)", systemImage: "bag.fill")
                        Label("\(sellerFollowers)", systemImage: "person.2.fill")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    
                    Text("Répond en \(sellerResponseTime)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    toggleFollowSeller()
                } label: {
                    Text(isFollowingSeller ? "Suivi" : "Suivre")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isFollowingSeller ? Color.green : Color.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
    private var productDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MarketplaceSectionHeader(
                title: "Détails du produit",
                subtitle: "Description, état et informations réelles",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)

            Text(productData["description"] as? String ?? "Aucune description disponible.")
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(4)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                MarketplaceProductSpecCard(title: "État", value: productData["condition"] as? String ?? "Non précisé", icon: "checkmark.seal.fill")
                MarketplaceProductSpecCard(title: "Stock", value: stock > 0 ? "\(stock) disponible(s)" : "Rupture", icon: "shippingbox.fill")
                MarketplaceProductSpecCard(title: "Pays", value: productData["country"] as? String ?? product.country, icon: "globe.europe.africa.fill")

                ForEach(dynamicAttributes.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        MarketplaceProductSpecCard(
                            title: key.replacingOccurrences(of: "_", with: " ").capitalized,
                            value: value,
                            icon: "info.circle.fill"
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var shippingPaymentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MarketplaceSectionHeader(
                title: "Livraison & paiement",
                subtitle: "Options disponibles pour ce produit",
                actionTitle: "Options",
                action: {}
            )
            .padding(.horizontal, 0)
            
            VStack(spacing: 12) {
                if allowsDelivery {
                    MarketplaceShippingPaymentRow(
                        icon: "shippingbox.fill",
                        title: "Livraison disponible",
                        subtitle: "Le vendeur propose l’expédition selon le pays, la ville et les transporteurs disponibles."
                    )
                    
                    MarketplaceShippingPaymentRow(
                        icon: "mappin.and.ellipse",
                        title: "Relais, poste ou agence locale",
                        subtitle: "Compatible avec domicile, point relais, poste, agence locale ou point de repère."
                    )
                }
                
                if allowsPickup {
                    MarketplaceShippingPaymentRow(
                        icon: "hand.raised.fill",
                        title: "Remise en main propre",
                        subtitle: "L’acheteur peut récupérer le produit directement avec validation sécurisée dans l’application."
                    )
                }
                
                MarketplaceShippingPaymentRow(
                    icon: "creditcard.fill",
                    title: "Paiement sécurisé",
                    subtitle: "Le paiement est protégé et relié à la commande avant confirmation finale."
                )
                
                if !allowsDelivery && !allowsPickup {
                    MarketplaceShippingPaymentRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Livraison à confirmer",
                        subtitle: "Le vendeur doit encore préciser les options disponibles pour ce produit."
                    )
                }
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    private var reviewsQuestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MarketplaceSectionHeader(
                title: "Avis & questions",
                subtitle: "Avis réels des acheteurs et échanges publics",
                actionTitle: "Voir tout",
                action: {}
            )
            .padding(.horizontal, 0)

            if isLoadingReviews {
                ProgressView()
                    .padding()
            } else if productReviews.isEmpty {
                MarketplaceProductEmptyInfoBox(
                    icon: "star.fill",
                    title: "Aucun avis pour le moment",
                    subtitle: "Les avis apparaîtront ici après les commandes vérifiées."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(productReviews.prefix(3)) { review in
                        MarketplaceReviewPreviewRow(
                            review: review,
                            replies: reviewReplies[review.id] ?? [],
                            canWriteMessage: canWriteReviewMessage(review),
                            canDelete: isAdminUser,
                            messageText: Binding(
                                get: { reviewMessageText[review.id] ?? "" },
                                set: { reviewMessageText[review.id] = $0 }
                            ),
                            isSendingMessage: isSendingReviewMessage.contains(review.id),
                            onSendMessage: {
                                sendReviewMessage(review)
                            },
                            onDeleteReview: {
                                deleteReviewAdminOnly(review)
                            },
                            onDeleteReply: { reply in
                                deleteReplyAdminOnly(reviewId: review.id, replyId: reply.id)
                            }
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var similarProductsSection: some View {
        VStack(spacing: 14) {
            MarketplaceSectionHeader(
                title: "Produits similaires",
                subtitle: "Produits réels de la même catégorie",
                actionTitle: "Plus",
                action: {}
            )

            if similarProducts.isEmpty {
                EmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(similarProducts) { item in
                            NavigationLink {
                                MarketplaceProductDetailView(product: item)
                            } label: {
                                MarketplaceSimilarProductCard(product: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    private var reportSafetySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Sécurité",
                subtitle: "Signaler un produit ou vérifier les alertes IA",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)
            
            MarketplaceSafetyRow(
                icon: "exclamationmark.triangle.fill",
                title: "Signaler ce produit",
                subtitle: "Contrefaçon, arnaque, produit interdit, image volée ou prix suspect."
            )
            
            MarketplaceSafetyRow(
                icon: "brain.head.profile",
                title: "Analyse IA marketplace",
                subtitle: "Score vendeur, images, avis, prix et comportement de commande."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var trustBadgesSection: some View {
        VStack(spacing: 14) {
            MarketplaceSectionHeader(
                title: "Confiance Marketplace",
                subtitle: "Signaux premium visibles avant achat",
                actionTitle: nil,
                action: nil
            )
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                MarketplaceTrustBadgeCard(title: "Vendeur vérifié", icon: "checkmark.seal.fill")
                MarketplaceTrustBadgeCard(title: "Paiement protégé", icon: "lock.shield.fill")
                MarketplaceTrustBadgeCard(title: "Avis contrôlés", icon: "star.bubble.fill")
                MarketplaceTrustBadgeCard(title: "IA anti-fraude", icon: "brain.head.profile")
            }
            .padding(.horizontal, 16)
        }
    }
    
    
    
    
    
    private var buyerProtectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Protection acheteur Cutly", systemImage: "shield.lefthalf.filled")
                .font(.system(.headline, design: .rounded).weight(.bold))
            
            VStack(spacing: 10) {
                MarketplaceProtectionRow(icon: "creditcard.fill", title: "Paiement sécurisé", subtitle: "Stripe, Apple Pay, cartes et Mobile Money selon le pays.")
                MarketplaceProtectionRow(
                    icon: allowsDelivery ? "shippingbox.fill" : "hand.raised.fill",
                    title: allowsDelivery ? "Livraison protégée" : "Retrait sécurisé",
                    subtitle: allowsDelivery
                    ? "Suivi, preuve de livraison et historique de commande."
                    : "Remise en main propre avec validation sécurisée dans l’application."
                )
                MarketplaceProtectionRow(icon: "exclamationmark.shield.fill", title: "Anti-fraude IA", subtitle: "Détection contrefaçon, faux vendeur, faux avis et commandes suspectes.")
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var bottomActionBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    openSellerConversation()
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 52, height: 52)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .disabled(isOpeningConversation)

                Button {
                    toggleFavoriteProduct()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isFavorite ? .red : .primary)
                        .frame(width: 52, height: 52)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Button {
                    guard !isProductSoldOut else { return }
                    navigateToCheckout = true
                } label: {
                    Label(
                        isProductSoldOut ? "Indisponible" : "Acheter",
                        systemImage: isProductSoldOut ? "xmark.circle.fill" : "cart.fill"
                    )
                }
                .buttonStyle(MarketplacePremiumButtonStyle())
                .disabled(isProductSoldOut || resolvedSellerId.isEmpty)
                .opacity(isProductSoldOut ? 0.55 : 1)
            }

            NavigationLink(
                destination: MarketplaceCheckoutView(
                    product: product,
                    productData: productData,
                    sellerId: resolvedSellerId,
                    selectedProductVariant: selectedVariant
                ),
                isActive: $navigateToCheckout
            ) {
                EmptyView()
            }
            .hidden()

            NavigationLink(
                destination: MarketplaceConversationThreadView(
                    conversationId: targetConversationId,
                    productId: product.id,
                    sellerId: targetSellerId,
                    productTitle: product.title
                ),
                isActive: $navigateToMarketplaceThread
            ) {
                EmptyView()
            }
            .hidden()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
    }
}
// MARK: - Components

private struct MarketplaceProductFloatingBadge: View {
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
        .background(.white.opacity(0.16))
        .clipShape(Capsule())
    }
}

private struct MarketplaceProductChip: View {
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
        .padding(.vertical, 7)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

private struct MarketplaceProtectionRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}
private struct MarketplaceProductSpecCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MarketplaceIconBadge(icon: icon, size: 38)

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct MarketplaceShippingPaymentRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
private struct MarketplaceReviewPreviewRow: View {
    let review: MarketplaceProductReviewItem
    let replies: [MarketplaceReviewReplyItem]
    let canWriteMessage: Bool
    let canDelete: Bool
    @Binding var messageText: String
    let isSendingMessage: Bool
    let onSendMessage: () -> Void
    let onDeleteReview: () -> Void
    let onDeleteReply: (MarketplaceReviewReplyItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                MarketplaceIconBadge(icon: "person.fill", size: 36)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(review.buyerName.isEmpty ? "Acheteur Cutly" : review.buyerName)
                            .font(.subheadline.weight(.bold))

                        Text(String(repeating: "★", count: max(1, min(review.rating, 5))))
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }

                    Text(review.comment)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                }

                Spacer()

                if canDelete {
                    Button(role: .destructive) {
                        onDeleteReview()
                    } label: {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            if !replies.isEmpty {
                VStack(spacing: 8) {
                    ForEach(replies) { reply in
                        HStack(alignment: .top, spacing: 10) {
                            MarketplaceIconBadge(
                                icon: reply.isSeller ? "storefront.fill" : "person.fill",
                                size: 30
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(reply.isSeller ? "Vendeur" : reply.authorName)
                                        .font(.caption.bold())

                                    if reply.isSeller {
                                        Text("Réponse officielle")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(MarketplaceUITheme.primaryGradient)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(reply.text)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(5)
                            }

                            Spacer()

                            if canDelete {
                                Button(role: .destructive) {
                                    onDeleteReply(reply)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption.bold())
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(10)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }

            if canWriteMessage {
                HStack(spacing: 8) {
                    TextField("Répondre publiquement...", text: $messageText)
                        .font(.caption)
                        .padding(12)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button {
                        onSendMessage()
                    } label: {
                        if isSendingMessage {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 38, height: 38)
                    .background(MarketplaceUITheme.primaryGradient)
                    .clipShape(Circle())
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                }
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct MarketplaceSimilarProductCard: View {
    let product: MarketplaceHomeProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            productImage

            Text(product.title)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)

            Text(cutlyPriceText(product.priceText))
                .font(.headline.weight(.black))

            Text(product.country)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 150, height: 245, alignment: .top)
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var productImage: some View {
        Group {
            if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        MarketplaceSkeletonView(cornerRadius: 24)
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 130, height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(MarketplaceUITheme.primaryGradient)
            .overlay(
                Image(systemName: "bag.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
            )
    }
}

private struct MarketplaceSafetyRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
private struct MarketplaceTrustBadgeCard: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 46)

            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 122)
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}
private struct MarketplaceFullScreenGalleryView: View {
    let images: [String]
    @Binding var selectedIndex: Int

    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageURL in
                    zoomableImage(imageURL: imageURL)
                        .tag(index)
                }
            }
            .tabViewStyle(.page)
            .offset(y: dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if scale <= 1.05 && value.translation.height > 0 {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 120 {
                            dismiss()
                        } else {
                            withAnimation(.spring()) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .onChange(of: selectedIndex) { _ in
                resetZoom()
            }

            HStack {
                Text("\(min(selectedIndex + 1, max(images.count, 1)))/\(max(images.count, 1))")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.18))
                        .clipShape(Circle())
                }
            }
            .padding()
        }
    }

    private func zoomableImage(imageURL: String) -> some View {
        Group {
            if let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .onTapGesture(count: 2) {
                                withAnimation(.spring()) {
                                    scale = scale > 1 ? 1 : 2.2
                                    lastScale = scale
                                }
                            }
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = max(1, min(lastScale * value, 5))
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                    }
                            )

                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 70))
                            .foregroundStyle(.white)

                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 70))
                    .foregroundStyle(.white)
            }
        }
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        dragOffset = .zero
    }
}
private struct MarketplaceProductMiniStat: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.caption.bold())

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

private struct MarketplaceProductEmptyInfoBox: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 40)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.bold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            Spacer()
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
private struct MarketplaceProductReviewItem: Identifiable, Hashable {
    let id: String
    let buyerName: String
    let rating: Int
    let comment: String
    let createdAt: Timestamp?
}

private struct MarketplaceReviewReplyItem: Identifiable, Hashable {
    let id: String
    let reviewId: String
    let authorName: String
    let text: String
    let isSeller: Bool
    let createdAt: Timestamp?
}
private struct MarketplaceCheckoutView: View {
    let product: MarketplaceHomeProduct
    let productData: [String: Any]
    let sellerId: String
    let selectedProductVariant: MarketplaceProductVariant?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var quantity = 1
    @State private var selectedColor = ""
    @State private var selectedSize = ""
    @State private var selectedMaterial = ""
    @State private var selectedModel = ""
    @State private var selectedStorage = ""
    @State private var selectedVariant = ""
    
    @State private var stripePaymentCompleted = false
    
    
    @State private var selectedVariantImage = ""
    
    @State private var variantPriceImpact: Double = 0
    @State private var variantStock: Int = 0
    
    @State private var selectedDeliveryMethod = "Point relais"
    @State private var selectedPaymentProvider: MarketplacePaymentProviderOption = .applePay
    
    @StateObject private var locationManager = MarketplaceBuyerLocationManager()
    
    @State private var showRelayMap = false
    @State private var relaySearchText = "point relais poste pickup parcel shop"
    
    @State private var nearbyRelays: [CutlyCheckoutRelayPoint] = []
    @State private var selectedRelay: CutlyCheckoutRelayPoint?
    
    @State private var isSearchingRelays = false
    @State private var relaySearchError = ""
    
    @State private var isCreatingOrder = false
    @StateObject private var stripeCheckout = MarketplaceStripeCheckoutService.shared
    @State private var showStripePaymentSheet = false
    
    @State private var checkoutErrorMessage = ""
    @State private var createdOrderId = ""
    @State private var navigateToOrderDetail = false
    @State private var pendingOrderId = ""
    @State private var pendingOrderRef: DocumentReference?
    @State private var relayOpeningHoursText = ""
    
    
    
    
    
    
    
    private var basePrice: Double {
        productData["price"] as? Double
        ?? Double(product.priceText.replacingOccurrences(of: "€", with: "").replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines))
        ?? 0
    }
    
    private var maxQuantity: Int {
        if let selectedProductVariant {
            return max(selectedProductVariant.stock, 0)
        }

        if variantStock > 0 {
            return variantStock
        }

        return max(productData["quantity"] as? Int ?? 1, 0)
    }
    
    private var colors: [String] {
        productData["availableColors"] as? [String] ?? []
    }
    
    private var sizes: [String] {
        productData["availableSizes"] as? [String] ?? []
    }
    private var variantImages: [String: String] {
        productData["variantImages"] as? [String: String] ?? [:]
    }
    
    private var selectedVariantImageURL: String? {
        if !selectedColor.isEmpty {
            return variantImages[selectedColor]
        }
        return nil
    }
    
    private var materials: [String] {
        productData["availableMaterials"] as? [String] ?? []
    }
    
    private var models: [String] {
        productData["availableModels"] as? [String] ?? []
    }
    
    private var storages: [String] {
        productData["availableStorages"] as? [String] ?? []
    }
    
    private var productVariants: [[String: Any]] {
        productData["variants"] as? [[String: Any]]
        ?? productData["productVariants"] as? [[String: Any]]
        ?? []
    }
    
    private var displayedImageURL: String? {
        if !selectedVariantImage.isEmpty {
            return selectedVariantImage
        }

        if let imageURL = selectedProductVariant?.imageURL, !imageURL.isEmpty {
            return imageURL
        }

        return product.imageURL
    }
    
    private func updateSelectedVariant() {
        selectedVariant = [
            selectedColor.isEmpty ? nil : "Couleur : \(selectedColor)",
            selectedSize.isEmpty ? nil : "Taille : \(selectedSize)",
            selectedMaterial.isEmpty ? nil : "Matière : \(selectedMaterial)",
            selectedModel.isEmpty ? nil : "Modèle : \(selectedModel)",
            selectedStorage.isEmpty ? nil : "Stockage : \(selectedStorage)"
        ]
            .compactMap { $0 }
            .joined(separator: " • ")
        
        let match = productVariants.first { variant in
            let color = variant["color"] as? String ?? ""
            let size = variant["size"] as? String ?? ""
            let material = variant["material"] as? String ?? ""
            let model = variant["model"] as? String ?? ""
            let storage = variant["storage"] as? String ?? ""
            
            return
            (selectedColor.isEmpty || color == selectedColor) &&
            (selectedSize.isEmpty || size == selectedSize) &&
            (selectedMaterial.isEmpty || material == selectedMaterial) &&
            (selectedModel.isEmpty || model == selectedModel) &&
            (selectedStorage.isEmpty || storage == selectedStorage)
        }
        
        selectedVariantImage =
        match?["imageURL"] as? String
        ?? match?["imageUrl"] as? String
        ?? ""
        
        variantPriceImpact =
        match?["priceImpact"] as? Double
        ?? match?["extraPrice"] as? Double
        ?? 0
        
        variantStock =
        match?["stock"] as? Int
        ?? match?["quantity"] as? Int
        ?? 0
        
        if variantStock > 0 {
            quantity = min(quantity, variantStock)
        }
    }
    
    
    private var deliveryFee: Double {
        if selectedDeliveryMethod == "Retrait vendeur" {
            return 0
        }
        
        if let selectedRelay {
            return selectedRelay.price
        }
        
        switch selectedDeliveryMethod {
        case "Livraison domicile":
            return 8.90
        case "DHL / International":
            return 24.90
        case "Agence locale":
            return 5.90
        default:
            return 6.50
        }
    }
    
    private var serviceFee: Double {
        max((basePrice * Double(quantity)) * 0.03, 0.50)
    }
    
    private var subtotal: Double {
        let initialVariantPrice = selectedProductVariant?.priceAdjustment ?? 0
        let finalVariantPrice = variantPriceImpact == 0 ? initialVariantPrice : variantPriceImpact
        return (basePrice + finalVariantPrice) * Double(quantity)
    }
    
    private var total: Double {
        subtotal + deliveryFee + serviceFee
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    checkoutHeader
                    productSummary
                    variantsSection
                    quantitySection
                    deliverySection
                    paymentSection
                    totalSection
                    confirmButton
                }
                .padding()
            }
            .background(MarketplaceUITheme.softBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Acheter")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let selectedProductVariant {
                    variantPriceImpact = selectedProductVariant.priceAdjustment ?? 0
                    variantStock = selectedProductVariant.stock
                    selectedVariantImage = selectedProductVariant.imageURL ?? ""
                    selectedVariant = "\(selectedProductVariant.name) : \(selectedProductVariant.value)"
                }
            }
            
        }
    }
    
    private var checkoutHeader: some View {
        VStack(spacing: 10) {
            MarketplaceIconBadge(icon: "cart.fill", size: 66)
            
            Text("Finaliser l’achat")
                .font(.title2.bold())
            
            Text("Choisis les options, la livraison et le moyen de paiement avant validation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
    
    private var productSummary: some View {
        HStack(spacing: 12) {
            Group {
                if let displayedImageURL, let url = URL(string: displayedImageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            MarketplaceIconBadge(icon: "bag.fill", size: 62)
                        }
                    }
                } else {
                    MarketplaceIconBadge(icon: "bag.fill", size: 62)
                }
            }
            .frame(width: 62, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(product.title)
                    .font(.headline.bold())
                    .lineLimit(2)
                
                Text(cutlyPriceText(subtotal / Double(max(quantity, 1))))
                    .font(.title3.bold())
                
                Text(product.sellerName.isEmpty ? "Vendeur Cutly Market" : product.sellerName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private var variantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options du produit")
                .font(.headline.bold())
            
            if !colors.isEmpty {
                Picker("Couleur", selection: $selectedColor) {
                    Text("Choisir une couleur").tag("")
                    ForEach(colors, id: \.self) { color in
                        Text(color).tag(color)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedColor) { _ in
                    updateSelectedVariant()
                }
            }
            
            if !sizes.isEmpty {
                Picker("Taille", selection: $selectedSize) {
                    Text("Choisir une taille").tag("")
                    ForEach(sizes, id: \.self) { size in
                        Text(size).tag(size)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedSize) { _ in
                    updateSelectedVariant()
                }
            }
            
            if colors.isEmpty && sizes.isEmpty {
                Text("Aucune couleur ou taille obligatoire pour ce produit.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    private var quantitySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quantité")
                    .font(.headline.bold())
                
                Text(
                    variantStock > 0
                    ? "Stock : \(variantStock)"
                    : "Stock : \(maxQuantity)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Stepper("\(quantity)", value: $quantity, in: 1...maxQuantity)
                .labelsHidden()
            
            Text("\(quantity)")
                .font(.headline.bold())
                .frame(width: 38)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private var deliverySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Livraison")
                .font(.headline.bold())
            
            Picker("Méthode", selection: $selectedDeliveryMethod) {
                Text("Point relais").tag("Point relais")
                Text("Livraison domicile").tag("Livraison domicile")
                Text("Retrait vendeur").tag("Retrait vendeur")
                Text("Agence locale").tag("Agence locale")
            }
            .pickerStyle(.menu)
            
            if selectedDeliveryMethod == "Point relais" || selectedDeliveryMethod == "Agence locale" {
                Button {
                    locationManager.requestLocation()
                    showRelayMap = true
                } label: {
                    Label(
                        selectedRelay == nil ? "Trouver un point proche de moi" : "Changer le point choisi",
                        systemImage: "map.fill"
                    )
                    .font(.subheadline.bold())
                }
                
                if let selectedRelay {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedRelay.name)
                            .font(.subheadline.bold())
                        
                        Text(selectedRelay.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(String(format: "Distance estimée : %.1f km", selectedRelay.distanceKm))
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                    .padding(12)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            
            if !relaySearchError.isEmpty {
                Text(relaySearchError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .sheet(isPresented: $showRelayMap) {
            MarketplaceRelayMapPickerView(
                locationManager: locationManager,
                relays: $nearbyRelays,
                selectedRelay: $selectedRelay,
                isSearching: $isSearchingRelays,
                errorText: $relaySearchError
            )
        }
    }
    
    private var buyerCountryCode: String {
        productData["buyerCountryCode"] as? String
            ?? Locale.current.region?.identifier
            ?? "FR"
    }

    private var availablePaymentProviders: [MarketplacePaymentProviderOption] {
        MarketplacePaymentService.shared.recommendedPaymentProviders(
            buyerCountryCode: buyerCountryCode
        )
    }
    
    
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Paiement")
                .font(.headline.bold())
            
            Picker("Moyen de paiement", selection: $selectedPaymentProvider) {

                ForEach(availablePaymentProviders) { provider in
                    Text(provider.title)
                        .tag(provider)
                }
            }
            .pickerStyle(.menu)
            .pickerStyle(.menu)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private var totalSection: some View {
        VStack(spacing: 10) {
            amountRow("Produit", subtotal)
            amountRow("Livraison", deliveryFee)
            amountRow("Frais service Cutly", serviceFee)
            
            Divider()
            
            HStack {
                Text("Total à payer")
                    .font(.title3.bold())
                
                Spacer()
                
                Text(cutlyPriceText(total))
                    .font(.title3.bold())
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private func amountRow(_ title: String, _ amount: Double) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(cutlyPriceText(amount))
                .font(.subheadline.bold())
        }
    }
    
    private var confirmButton: some View {
        VStack(spacing: 10) {
            if !checkoutErrorMessage.isEmpty {
                Text(checkoutErrorMessage)
                    .font(.caption.bold())
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                prepareMarketplaceStripePayment()
            } label: {
                if isCreatingOrder {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Payer maintenant", systemImage: "lock.fill")
                }
            }
            .buttonStyle(MarketplacePremiumButtonStyle())
            .disabled(isCreatingOrder || sellerId.isEmpty || quantity <= 0 || maxQuantity <= 0)

            NavigationLink(
                destination: MarketplaceOrderDetailView(orderId: createdOrderId),
                isActive: $navigateToOrderDetail
            ) {
                EmptyView()
            }
            .hidden()
        }
        .background {
            if let paymentSheet = stripeCheckout.paymentSheet {
                Color.clear
                    .paymentSheet(
                        isPresented: $showStripePaymentSheet,
                        paymentSheet: paymentSheet,
                        onCompletion: { result in
                            handleMarketplacePaymentResult(result)
                        }
                    )
            }
        }
    }
    
    private func prepareMarketplaceStripePayment() {
        guard let buyer = Auth.auth().currentUser else {
            checkoutErrorMessage = "Connectez-vous pour acheter ce produit."
            return
        }

        guard !sellerId.isEmpty else {
            checkoutErrorMessage = "Vendeur introuvable."
            return
        }
        guard maxQuantity > 0 else {
            checkoutErrorMessage = "Cette variante est épuisée."
            return
        }

        guard quantity <= maxQuantity else {
            checkoutErrorMessage = "Stock insuffisant pour cette variante."
            return
        }
        
        let orderRef = Firestore.firestore()
            .collection("marketplace_orders")
            .document()

        pendingOrderRef = orderRef
        pendingOrderId = orderRef.documentID
        
        
        // ✅ Si c'est un paiement Mobile Money, on ne lance pas Stripe
        let route = MarketplacePaymentRouter.shared.route(
            provider: selectedPaymentProvider
        )

        switch route {

        case .stripe, .applePay, .bankCard:
            break

        case .orangeMoney,
             .wave,
             .mtn,
             .moov,
             .mpesa,
             .bankTransfer,
             .wallet,
             .manual,
             .paypal:

            createMarketplaceOrder()
            return
        }

        isCreatingOrder = true
        checkoutErrorMessage = ""

        stripeCheckout.prepareMarketplacePayment(
            orderId: pendingOrderId,
            amount: total,
            sellerId: sellerId,
            buyerEmail: buyer.email ?? ""
        ) { success in
            isCreatingOrder = false

            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showStripePaymentSheet = true
                }
            } else {
                checkoutErrorMessage = "Impossible de préparer le paiement."
            }
        }
    }
    
    
    
    private func handleMarketplacePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            stripePaymentCompleted = true
            createMarketplaceOrder()

        case .canceled:
            checkoutErrorMessage = "Paiement annulé."

        case .failed(let error):
            checkoutErrorMessage = "Paiement échoué : \(error.localizedDescription)"
        }
    }
    private var isMobileMoneyPayment: Bool {
        [
            "Orange Money",
            "Wave",
            "MTN Mobile Money",
            "Moov Money",
            "Airtel Money",
            "M-Pesa",
            "Free Money",
            "TMoney",
            "Flooz"
        ].contains(selectedPaymentProvider.rawValue)
    }
    
    private func createMarketplaceOrder() {
        guard let buyer = Auth.auth().currentUser else {
            checkoutErrorMessage = "Connectez-vous pour acheter ce produit."
            return
        }

        guard !sellerId.isEmpty else {
            checkoutErrorMessage = "Vendeur introuvable."
            return
        }

        if (selectedDeliveryMethod == "Point relais" || selectedDeliveryMethod == "Agence locale") && selectedRelay == nil {
            checkoutErrorMessage = "Choisissez un point relais ou une agence avant de payer."
            return
        }

        isCreatingOrder = true
        checkoutErrorMessage = ""

        let db = Firestore.firestore()
        guard let orderRef = pendingOrderRef else {
            checkoutErrorMessage = "Erreur interne de création de commande."
            return
        }

        let orderId = pendingOrderId
        let orderNumber = "CUTLY-\(Int(Date().timeIntervalSince1970))"
        let parcelNumber = "CUTLY\(orderId.prefix(10).uppercased())"

        let selectedRelayName = selectedRelay?.name ?? ""
        let selectedRelayAddress = selectedRelay?.address ?? ""
        let selectedCarrier = selectedRelay?.provider ?? selectedDeliveryMethod

        let deliveryAddressFull: String = {
            if let selectedRelay {
                return "\(selectedRelay.name)\n\(selectedRelay.address)"
            }

            return productData["deliveryAddressFull"] as? String
            ?? productData["deliveryAddressSubtitle"] as? String
            ?? "Adresse livraison à confirmer"
        }()

        let sellerName = product.sellerName.isEmpty ? "Vendeur Cutly" : product.sellerName
        let buyerName = buyer.displayName?.isEmpty == false ? buyer.displayName! : "Acheteur Cutly"

        let itemRef = db.collection("marketplace_order_items").document("\(orderId)_item_1")

        let orderData: [String: Any] = [
            "id": orderId,
            "orderNumber": orderNumber,
            "parcelNumber": parcelNumber,
            "barcodeValue": parcelNumber,

            "status": isMobileMoneyPayment
                ? "pendingMobileMoney"
                : (stripePaymentCompleted ? "paid" : "waitingStripeConfirmation"),

            "paymentStatus": isMobileMoneyPayment
                ? "pending"
                : (stripePaymentCompleted ? "paid" : "waitingConfirmation"),

            "paidAt": stripePaymentCompleted ? FieldValue.serverTimestamp() : NSNull(),
            "paymentCompleted": stripePaymentCompleted,
            "paymentVerified": stripePaymentCompleted,
            "escrowStatus": stripePaymentCompleted ? "held" : "pending",
            "workflowStatus": stripePaymentCompleted ? "ready" : "pendingPayment",
            "orderSource": isMobileMoneyPayment ? "ios_mobile_money_checkout" : "ios_stripe_checkout",
            "paymentProvider": selectedPaymentProvider.rawValue,
            "requiresMobileMoneyConfirmation": isMobileMoneyPayment,

            "buyerId": buyer.uid,
            "buyerName": buyerName,
            "buyerEmail": buyer.email ?? "",
            "buyerPhone": productData["buyerPhone"] as? String ?? "",

            "sellerId": sellerId,
            "sellerName": sellerName,
            "sellerEmail": productData["sellerEmail"] as? String ?? "",
            "sellerPhone": productData["sellerPhone"] as? String ?? "",

            "productId": product.id,
            "productTitle": product.title,
            "productImageURL": product.imageURL ?? "",

            "itemsCount": 1,
            "quantity": quantity,
            "variant": selectedVariant,

            "deliveryType": selectedDeliveryMethod,
            "shippingMethod": selectedDeliveryMethod,
            "carrierName": selectedCarrier,
            "relayPointId": selectedRelay?.id ?? "",
            "relayPointProvider": selectedRelay?.provider ?? "",
            "relayPointName": selectedRelayName,
            "relayPointAddress": selectedRelayAddress,
            "relayPointLatitude": selectedRelay?.latitude ?? 0,
            "relayPointLongitude": selectedRelay?.longitude ?? 0,
            "relayPointDistanceKm": selectedRelay?.distanceKm ?? 0,
            "relayPointOpeningHours": selectedRelay?.openingHours ?? [:],
            "deliveryAddressFull": deliveryAddressFull,

            "paymentMethod": selectedPaymentProvider.rawValue,

            "subtotal": subtotal,
            "shippingFee": deliveryFee,
            "serviceFee": serviceFee,
            "taxes": 0,
            "total": total,

            "subtotalText": cutlyPriceText(subtotal),
            "shippingFeeText": cutlyPriceText(deliveryFee),
            "serviceFeeText": cutlyPriceText(serviceFee),
            "totalText": cutlyPriceText(total),

            "pickupCode": parcelNumber,
            "trackingNumber": "",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        let itemData: [String: Any] = [
            "id": itemRef.documentID,
            "orderId": orderId,
            "productId": product.id,
            "sellerId": sellerId,
            "buyerId": buyer.uid,
            "title": product.title,
            "quantity": quantity,
            "price": basePrice + variantPriceImpact,
            "priceText": cutlyPriceText(basePrice + variantPriceImpact),
            "variant": selectedVariant,
            "imageURL": displayedImageURL ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]

        let batch = db.batch()
        batch.setData(orderData, forDocument: orderRef, merge: true)
        batch.setData(itemData, forDocument: itemRef, merge: true)

        batch.commit { error in
            isCreatingOrder = false

            if let error {
                checkoutErrorMessage = error.localizedDescription
                return
            }

            createdOrderId = orderId
            navigateToOrderDetail = true
        }
    }
    
    
    
    
}



final class MarketplaceBuyerLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationDenied = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        let status = manager.authorizationStatus

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        if status == .denied || status == .restricted {
            authorizationDenied = true
            return
        }

        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }

        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            authorizationDenied = true
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error:", error.localizedDescription)
    }
}

struct CutlyCheckoutRelayPoint: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let distanceKm: Double
    let provider: String
    let price: Double
    let openingHours: [String: String]
}

private struct MarketplaceRelayMapPickerView: View {
    @ObservedObject var locationManager: MarketplaceBuyerLocationManager

    @Binding var relays: [CutlyCheckoutRelayPoint]
    @Binding var selectedRelay: CutlyCheckoutRelayPoint?
    @Binding var isSearching: Bool
    @Binding var errorText: String

    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition = .automatic

    @MapContentBuilder
    private var relayAnnotations: some MapContent {

        if let userLocation = locationManager.userLocation {
            Annotation("Vous", coordinate: userLocation) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.20))
                        .frame(width: 44, height: 44)

                    Circle()
                        .fill(.blue)
                        .frame(width: 16, height: 16)
                }
            }
        }

        ForEach(relays) { relay in
            Annotation(
                relay.name,
                coordinate: CLLocationCoordinate2D(
                    latitude: relay.latitude,
                    longitude: relay.longitude
                )
            ) {
                Button {
                    selectedRelay = relay
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selectedRelay?.id == relay.id ? "mappin.circle.fill" : "mappin.circle")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(selectedRelay?.id == relay.id ? .green : .orange)

                        Text(relay.provider)
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.regularMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    relayAnnotations
                }
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    if isSearching {
                        ProgressView("Recherche des points proches...")
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    if let relay = selectedRelay {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(relay.name)
                                .font(.headline.bold())

                            Text(relay.address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Transporteur : \(relay.provider)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            HStack {
                                Text(String(format: "%.1f km", relay.distanceKm))
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)

                                Spacer()

                                Text(relay.provider)
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                            if !relay.openingHours.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Horaires")
                                        .font(.caption.bold())

                                    ForEach(orderedOpeningHours(relay.openingHours), id: \.day) { item in
                                        HStack {
                                            Text(item.label)
                                                .font(.caption2.bold())
                                                .frame(width: 70, alignment: .leading)

                                            Text(item.hours)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)

                                            Spacer()
                                        }
                                    }
                                }
                            }
                            
                            Button {
                                selectedRelay = relay
                                dismiss()
                            } label: {
                                Label("Valider ce point relais", systemImage: "checkmark.circle.fill")
                            }
                            .buttonStyle(MarketplacePremiumButtonStyle())
                            .disabled(selectedRelay == nil)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 18)
            }
            .navigationTitle("Points proches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        searchNearbyRelays()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                locationManager.requestLocation()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    searchNearbyRelays()
                }
            }
            .onChange(of: locationManager.userLocation?.latitude ?? 0) { _ in
                centerMap()
            }
        }
    }
    private func orderedOpeningHours(_ hours: [String: String]) -> [(day: String, label: String, hours: String)] {
        let order = [
            ("monday", "Lundi"),
            ("tuesday", "Mardi"),
            ("wednesday", "Mercredi"),
            ("thursday", "Jeudi"),
            ("friday", "Vendredi"),
            ("saturday", "Samedi"),
            ("sunday", "Dimanche")
        ]

        return order.compactMap { key, label in
            guard let value = hours[key], !value.isEmpty else { return nil }
            return (day: key, label: label, hours: value)
        }
    }
    
    
    
    private func centerMap() {
        guard let coordinate = locationManager.userLocation else { return }

        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
            )
        )
    }

    private func searchNearbyRelays() {
        guard let coordinate = locationManager.userLocation else {
            errorText = "Activez la localisation pour trouver les points proches."
            return
        }

        isSearching = true
        errorText = ""

        let functions = Functions.functions(region: "us-central1")

        let payload: [String: Any] = [
            "country": Locale.current.region?.identifier ?? "FR",
            "city": "",
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "radiusKm": 25,
            "limit": 30
        ]

        functions.httpsCallable("searchMarketplaceRelayPoints").call(payload) { result, error in
            DispatchQueue.main.async {
                isSearching = false

                if let error {
                    errorText = error.localizedDescription
                    return
                }

                guard
                    let data = result?.data as? [String: Any],
                    let points = data["points"] as? [[String: Any]]
                else {
                    errorText = "Réponse points relais invalide."
                    return
                }

                relays = points.compactMap { item in
                    let id = item["id"] as? String ?? UUID().uuidString
                    let name = item["name"] as? String ?? "Point relais"
                    let address = item["address"] as? String ?? ""
                    let provider = item["provider"] as? String ?? "Point relais"

                    let latitude = item["latitude"] as? Double ?? coordinate.latitude
                    let longitude = item["longitude"] as? Double ?? coordinate.longitude
                    let distanceKm = item["distanceKm"] as? Double ?? 0

                    let openingHours =
                        item["openingHours"] as? [String: String] ?? [:]

                    return CutlyCheckoutRelayPoint(
                        id: id,
                        name: name,
                        address: address,
                        latitude: latitude,
                        longitude: longitude,
                        distanceKm: distanceKm,
                        provider: provider,
                        price: estimateRelayPrice(distanceKm: distanceKm),
                        openingHours: openingHours
                    )
                }

                relays.sort { $0.distanceKm < $1.distanceKm }

                if relays.isEmpty {
                    errorText = "Aucun point proche trouvé autour de vous."
                }

                centerMap()
            }
        }
    }

    private func detectProvider(from name: String) -> String {
        let lower = name.lowercased()

        if lower.contains("chrono") {
            return "Chronopost"
        }

        if lower.contains("poste") || lower.contains("post") {
            return "La Poste"
        }

        if lower.contains("dhl") {
            return "DHL"
        }

        if lower.contains("ups") {
            return "UPS"
        }

        if lower.contains("mondial") {
            return "Mondial Relay"
        }

        if lower.contains("pickup") {
            return "Pickup"
        }

        return "Point relais"
    }
}
private func estimateRelayPrice(distanceKm: Double) -> Double {
    if distanceKm <= 2 { return 3.99 }
    if distanceKm <= 5 { return 4.99 }
    if distanceKm <= 10 { return 5.99 }
    return 6.99
}
private func cutlyPriceText(_ amount: Double) -> String {
    if amount.truncatingRemainder(dividingBy: 1) == 0 {
        return "\(Int(amount)) €"
    }
    return String(format: "%.2f €", amount).replacingOccurrences(of: ".", with: ",")
}

private func cutlyPriceText(_ text: String) -> String {
    let cleaned = text
        .replacingOccurrences(of: "EUR", with: "")
        .replacingOccurrences(of: "Euro", with: "")
        .replacingOccurrences(of: "€", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: ",", with: ".")

    guard let value = Double(cleaned) else {
        return text.replacingOccurrences(of: "EUR", with: "€")
    }

    return cutlyPriceText(value)
}



#Preview {
    MarketplaceProductDetailView(
        product: MarketplaceHomeProduct(
            id: "preview",
            title: "Perruque premium naturelle",
            priceText: "49 €",
            originalPriceText: "69 €",
            discountPercent: 20,
            country: "France",
            city: "Paris",
            imageURL: nil,
            sellerId: "preview_seller",
            sellerName: "Boutique officielle",
            sellerPhotoURL: "",
            sellerVerified: true,
            rating: 4.8,
            latitude: nil,
            longitude: nil,
            isFavorite: false,
            variants: []
            )
    )
}
