//
//  MarketplaceFirestoreService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class MarketplaceFirestoreService {
    
    static let shared = MarketplaceFirestoreService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Collections
    
    enum Collection {
        static let marketplaceSystem = "marketplace_system"
        
        static let products = "marketplace_products"
        static let stores = "marketplace_stores"
        static let categories = "marketplace_categories"
        static let orders = "marketplace_orders"
        static let orderItems = "marketplace_order_items"
        static let payments = "marketplace_payments"
        static let shipments = "marketplace_shipments"
        static let trackingEvents = "marketplace_tracking_events"
        
        static let carts = "marketplace_carts"
        static let favorites = "marketplace_favorites"
        static let recentlyViewed = "marketplace_recently_viewed"
        
        static let reviews = "marketplace_reviews"
        static let reviewVotes = "marketplace_review_votes"
        
        static let conversations = "marketplace_conversations"
        static let messages = "marketplace_messages"
        
        static let wallets = "marketplace_wallets"
        static let walletTransactions = "marketplace_wallet_transactions"
        static let withdrawalAccounts = "marketplace_withdrawal_accounts"
        static let withdrawals = "marketplace_withdrawals"
        
        static let refunds = "marketplace_refunds"
        static let returns = "marketplace_returns"
        static let disputes = "marketplace_disputes"
        static let evidence = "marketplace_evidence"
        
        static let notifications = "marketplace_notifications"
        static let notificationSettings = "marketplace_notification_settings"
        
        static let userActions = "marketplace_user_actions"
        static let recommendationProfiles = "marketplace_recommendation_profiles"
        static let aiFlags = "marketplace_ai_flags"
        static let aiModerationResults = "marketplace_ai_moderation_results"
        static let aiRecommendations = "marketplace_ai_recommendations"
        static let aiSearchIntents = "marketplace_ai_search_intents"
        
        static let sellerAnalytics = "marketplace_seller_analytics"
        static let adminAnalytics = "marketplace_admin_analytics"
        
        static let supportTickets = "marketplace_support_tickets"
        static let legalDocuments = "marketplace_legal_documents"
        
        static let shippingCarriers = "marketplace_shipping_carriers"
        static let paymentProviders = "marketplace_payment_providers"
        static let certificationRequests = "marketplace_certification_requests"
        
        static let overviewAnalytics = "marketplace_overview_analytics"
        static let productAnalytics = "marketplace_product_analytics"
        
        
        static let countryAnalytics = "marketplace_country_analytics"
        static let paymentAnalytics = "marketplace_payment_analytics"
        static let shippingAnalytics = "marketplace_shipping_analytics"
        static let aiAnalytics = "marketplace_ai_analytics"
        
        
        static let searchHistory = "marketplace_search_history"
        static let searchSuggestions = "marketplace_search_suggestions"
        
        static let recommendationSections = "marketplace_recommendation_sections"
        
        static let moderationActions = "marketplace_moderation_actions"
        static let reports = "marketplace_reports"
        static let adminNotifications = "marketplace_admin_notifications"
        static let systemLogs = "marketplace_system_logs"
        
    }
    
    // MARK: - Bootstrap Collections
    
    func bootstrapMarketplaceCollections() async throws {
        let now = Timestamp()
        
        let collections: [String] = [
            Collection.marketplaceSystem,
            Collection.products,
            Collection.stores,
            Collection.categories,
            Collection.orders,
            Collection.orderItems,
            Collection.payments,
            Collection.shipments,
            Collection.trackingEvents,
            Collection.carts,
            Collection.favorites,
            Collection.recentlyViewed,
            Collection.reviews,
            Collection.reviewVotes,
            Collection.conversations,
            Collection.messages,
            Collection.wallets,
            Collection.walletTransactions,
            Collection.withdrawalAccounts,
            Collection.withdrawals,
            Collection.refunds,
            Collection.returns,
            Collection.disputes,
            Collection.evidence,
            Collection.notifications,
            Collection.notificationSettings,
            Collection.userActions,
            Collection.recommendationProfiles,
            Collection.aiFlags,
            Collection.aiModerationResults,
            Collection.aiRecommendations,
            Collection.aiSearchIntents,
            Collection.sellerAnalytics,
            Collection.adminAnalytics,
            Collection.supportTickets,
            Collection.legalDocuments,
            Collection.shippingCarriers,
            Collection.paymentProviders,
            Collection.certificationRequests,
            Collection.overviewAnalytics,
            Collection.productAnalytics,
            Collection.countryAnalytics,
            Collection.paymentAnalytics,
            Collection.shippingAnalytics,
            Collection.aiAnalytics,
            Collection.recommendationSections,
            Collection.moderationActions,
            Collection.reports,
            Collection.adminNotifications,
            Collection.systemLogs,
            
            
        ]
        
        for collectionName in collections {
            try await db.collection(collectionName)
                .document("_schema")
                .setData([
                    "collectionName": collectionName,
                    "module": "marketplace",
                    "createdAutomatically": true,
                    "createdAt": now,
                    "updatedAt": now,
                    "version": 1,
                    "environment": "development",
                    "note": "Document système créé automatiquement pour initialiser la collection Marketplace."
                ], merge: true)
        }
        
        try await seedDefaultCategories()
        try await seedDefaultPaymentProviders()
        try await seedDefaultShippingCarriers()
        try await markBootstrapCompleted()
    }
    
    private func markBootstrapCompleted() async throws {
        try await db.collection(Collection.marketplaceSystem)
            .document("bootstrap")
            .setData([
                "isCompleted": true,
                "completedAt": Timestamp(),
                "module": "marketplace",
                "version": 1
            ], merge: true)
    }
    
    // MARK: - Default Categories
    
    private func seedDefaultCategories() async throws {
        let now = Timestamp()
        
        let categories: [[String: Any]] = [
            ["id": "beauty", "name": "Beauté", "icon": "sparkles"],
            ["id": "hair", "name": "Cheveux & Coiffure", "icon": "scissors"],
            ["id": "wigs_extensions", "name": "Perruques & Extensions", "icon": "person.crop.circle"],
            ["id": "fashion_women", "name": "Mode Femme", "icon": "tshirt.fill"],
            ["id": "fashion_men", "name": "Mode Homme", "icon": "figure.stand"],
            ["id": "phones", "name": "Téléphones", "icon": "iphone"],
            ["id": "electronics", "name": "Électronique", "icon": "desktopcomputer"],
            ["id": "home", "name": "Maison", "icon": "house.fill"],
            ["id": "cars", "name": "Voitures", "icon": "car.fill"],
            ["id": "local_products", "name": "Produits locaux", "icon": "leaf.fill"],
            ["id": "african_craft", "name": "Artisanat africain", "icon": "globe.europe.africa.fill"],
            ["id": "services", "name": "Services", "icon": "person.2.fill"]
        ]
        
        for category in categories {
            guard let id = category["id"] as? String else { continue }
            
            try await db.collection(Collection.categories)
                .document(id)
                .setData([
                    "id": id,
                    "name": category["name"] ?? "",
                    "icon": category["icon"] ?? "square.grid.2x2.fill",
                    "isActive": true,
                    "isFeatured": true,
                    "createdAt": now,
                    "updatedAt": now
                ], merge: true)
        }
    }
    
    // MARK: - Default Payment Providers
    
    private func seedDefaultPaymentProviders() async throws {
        let now = Timestamp()
        
        let providers: [[String: Any]] = [
            ["id": "stripe", "name": "Stripe", "region": "Europe / International"],
            ["id": "apple_pay", "name": "Apple Pay", "region": "International"],
            ["id": "paypal", "name": "PayPal", "region": "International"],
            ["id": "cards", "name": "Visa / Mastercard / AmEx", "region": "International"],
            ["id": "orange_money", "name": "Orange Money", "region": "Afrique"],
            ["id": "wave", "name": "Wave", "region": "Afrique de l’Ouest"],
            ["id": "mtn_mobile_money", "name": "MTN Mobile Money", "region": "Afrique"],
            ["id": "moov_money", "name": "Moov Money", "region": "Afrique"],
            ["id": "airtel_money", "name": "Airtel Money", "region": "Afrique"],
            ["id": "mpesa", "name": "M-Pesa", "region": "Afrique"],
            ["id": "free_money", "name": "Free Money", "region": "Sénégal"],
            ["id": "tmoney", "name": "TMoney", "region": "Togo"],
            ["id": "flooz", "name": "Flooz", "region": "Afrique"],
            ["id": "bank_transfer", "name": "Virement bancaire", "region": "International"],
            ["id": "wallet_cutly", "name": "Wallet Cutly", "region": "International"],
            ["id": "manual", "name": "Traitement manuel", "region": "Pays sensibles / partenaires"]
        ]
        
        for provider in providers {
            guard let id = provider["id"] as? String else { continue }
            
            try await db.collection(Collection.paymentProviders)
                .document(id)
                .setData([
                    "id": id,
                    "name": provider["name"] ?? "",
                    "region": provider["region"] ?? "",
                    "isActive": true,
                    "createdAt": now,
                    "updatedAt": now
                ], merge: true)
        }
    }
    
    // MARK: - Default Shipping Carriers
    
    private func seedDefaultShippingCarriers() async throws {
        let now = Timestamp()
        
        let carriers: [[String: Any]] = [
            ["id": "dhl", "name": "DHL", "type": "international"],
            ["id": "ups", "name": "UPS", "type": "international"],
            ["id": "fedex", "name": "FedEx", "type": "international"],
            ["id": "chronopost", "name": "Chronopost", "type": "international"],
            ["id": "colissimo", "name": "Colissimo", "type": "international"],
            ["id": "mondial_relay", "name": "Mondial Relay", "type": "relay"],
            ["id": "dpd", "name": "DPD", "type": "international"],
            ["id": "ems", "name": "EMS", "type": "postal"],
            ["id": "local_post", "name": "Poste locale", "type": "africa"],
            ["id": "bus_agency", "name": "Agence de bus", "type": "africa"],
            ["id": "local_courier", "name": "Coursier local", "type": "africa"],
            ["id": "partner_shop", "name": "Commerçant partenaire", "type": "pickup"],
            ["id": "hand_delivery", "name": "Remise en main propre", "type": "local"]
        ]
        
        for carrier in carriers {
            guard let id = carrier["id"] as? String else { continue }
            
            try await db.collection(Collection.shippingCarriers)
                .document(id)
                .setData([
                    "id": id,
                    "name": carrier["name"] ?? "",
                    "type": carrier["type"] ?? "",
                    "isActive": true,
                    "supportsTracking": true,
                    "supportsProofOfDelivery": true,
                    "createdAt": now,
                    "updatedAt": now
                ], merge: true)
        }
    }
    
    // MARK: - Products
    
    func createProduct(_ product: MarketplaceProduct) async throws -> String {
        let ref = db.collection(Collection.products).document()
        var newProduct = product
        newProduct.id = ref.documentID
        try ref.setData(from: newProduct, merge: true)
        return ref.documentID
    }
    
    func fetchProducts(limit: Int = 30) async throws -> [MarketplaceProduct] {
        let snapshot = try await db.collection(Collection.products)
            .whereField("status", isEqualTo: MarketplaceProductStatus.active.rawValue)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceProduct.self)
        }
    }
    
    func fetchProduct(productId: String) async throws -> MarketplaceProduct? {
        try await db.collection(Collection.products)
            .document(productId)
            .getDocument(as: MarketplaceProduct.self)
    }
    
    // MARK: - Stores
    
    func createStore(_ store: MarketplaceStore) async throws -> String {
        let ref = db.collection(Collection.stores).document()
        var newStore = store
        newStore.id = ref.documentID
        try ref.setData(from: newStore, merge: true)
        return ref.documentID
    }
    
    func fetchStore(storeId: String) async throws -> MarketplaceStore? {
        try await db.collection(Collection.stores)
            .document(storeId)
            .getDocument(as: MarketplaceStore.self)
    }
    
    // MARK: - Favorites
    
    func addFavorite(_ favorite: MarketplaceFavorite) async throws -> String {
        let ref = db.collection(Collection.favorites).document()
        var newFavorite = favorite
        newFavorite.id = ref.documentID
        try ref.setData(from: newFavorite, merge: true)
        return ref.documentID
    }
    
    func fetchUserFavorites(userId: String) async throws -> [MarketplaceFavorite] {
        let snapshot = try await db.collection(Collection.favorites)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceFavorite.self)
        }
    }
    
    func removeFavorite(favoriteId: String) async throws {
        try await db.collection(Collection.favorites)
            .document(favoriteId)
            .delete()
    }
    
    // MARK: - Orders
    
    func createOrder(_ order: MarketplaceOrder) async throws -> String {
        let ref = db.collection(Collection.orders).document()
        var newOrder = order
        newOrder.id = ref.documentID
        try ref.setData(from: newOrder, merge: true)
        return ref.documentID
    }
    
    func fetchOrdersForUser(userId: String) async throws -> [MarketplaceOrder] {
        let buyerSnapshot = try await db.collection(Collection.orders)
            .whereField("buyerId", isEqualTo: userId)
            .getDocuments()
        
        let sellerSnapshot = try await db.collection(Collection.orders)
            .whereField("sellerId", isEqualTo: userId)
            .getDocuments()
        
        let buyerOrders = try buyerSnapshot.documents.compactMap {
            try $0.data(as: MarketplaceOrder.self)
        }
        
        let sellerOrders = try sellerSnapshot.documents.compactMap {
            try $0.data(as: MarketplaceOrder.self)
        }
        
        let allOrders = buyerOrders + sellerOrders
        
        return Array(
            Dictionary(grouping: allOrders, by: { $0.id ?? UUID().uuidString })
                .compactMap { $0.value.first }
        )
    }
    
    func updateOrderStatus(orderId: String, status: MarketplaceOrderStatus) async throws {
        try await db.collection(Collection.orders)
            .document(orderId)
            .setData([
                "status": status.rawValue,
                "updatedAt": Timestamp()
            ], merge: true)
    }
    
    // MARK: - Notifications
    
    func createNotification(_ notification: MarketplaceNotification) async throws -> String {
        let ref = db.collection(Collection.notifications).document()
        var newNotification = notification
        newNotification.id = ref.documentID
        try ref.setData(from: newNotification, merge: true)
        return ref.documentID
    }
    
    func fetchUserNotifications(userId: String, limit: Int = 50) async throws -> [MarketplaceNotification] {
        let snapshot = try await db.collection(Collection.notifications)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceNotification.self)
        }
    }
    
    func markNotificationAsRead(notificationId: String) async throws {
        try await db.collection(Collection.notifications)
            .document(notificationId)
            .setData([
                "isRead": true,
                "readAt": Timestamp()
            ], merge: true)
    }
    
    // MARK: - Conversations & Messages
    
    func createConversation(_ conversation: MarketplaceConversation) async throws -> String {
        let ref = db.collection(Collection.conversations).document()
        var newConversation = conversation
        newConversation.id = ref.documentID
        try ref.setData(from: newConversation, merge: true)
        return ref.documentID
    }
    
    func fetchUserConversations(userId: String) async throws -> [MarketplaceConversation] {
        let snapshot = try await db.collection(Collection.conversations)
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceConversation.self)
        }
    }
    
    func sendMessage(_ message: MarketplaceMessage) async throws -> String {
        let ref = db.collection(Collection.messages).document()
        var newMessage = message
        newMessage.id = ref.documentID
        try ref.setData(from: newMessage, merge: true)
        
        try await db.collection(Collection.conversations)
            .document(message.conversationId)
            .setData([
                "lastMessageText": message.text ?? "",
                "lastMessageSenderId": message.senderId,
                "lastMessageAt": Timestamp(),
                "updatedAt": Timestamp()
            ], merge: true)
        
        return ref.documentID
    }
    
    func fetchMessages(conversationId: String, limit: Int = 60) async throws -> [MarketplaceMessage] {
        let snapshot = try await db.collection(Collection.messages)
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "createdAt", descending: false)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceMessage.self)
        }
    }
    // MARK: - Wallet

    func createOrUpdateWallet(_ wallet: MarketplaceWallet) async throws {
        let walletId = wallet.id ?? wallet.userId

        try db.collection(Collection.wallets)
            .document(walletId)
            .setData(from: wallet, merge: true)
    }

    func fetchWallet(userId: String) async throws -> MarketplaceWallet? {
        try await db.collection(Collection.wallets)
            .document(userId)
            .getDocument(as: MarketplaceWallet.self)
    }

    func createWalletTransaction(_ transaction: MarketplaceWalletTransaction) async throws -> String {
        let ref = db.collection(Collection.walletTransactions).document()
        var newTransaction = transaction
        newTransaction.id = ref.documentID
        try ref.setData(from: newTransaction, merge: true)
        return ref.documentID
    }

    // MARK: - Reviews

    func createReview(_ review: MarketplaceReview) async throws -> String {
        let ref = db.collection(Collection.reviews).document()
        var newReview = review
        newReview.id = ref.documentID
        try ref.setData(from: newReview, merge: true)
        return ref.documentID
    }

    func fetchReviews(targetId: String, limit: Int = 50) async throws -> [MarketplaceReview] {
        let snapshot = try await db.collection(Collection.reviews)
            .whereField("targetId", isEqualTo: targetId)
            .whereField("status", isEqualTo: MarketplaceReviewStatus.published.rawValue)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceReview.self)
        }
    }

    // MARK: - Tracking

    func createShipment(_ shipment: MarketplaceShipment) async throws -> String {
        let ref = db.collection(Collection.shipments).document()
        var newShipment = shipment
        newShipment.id = ref.documentID
        try ref.setData(from: newShipment, merge: true)
        return ref.documentID
    }

    func fetchShipment(orderId: String) async throws -> MarketplaceShipment? {
        let snapshot = try await db.collection(Collection.shipments)
            .whereField("orderId", isEqualTo: orderId)
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first?.data(as: MarketplaceShipment.self)
    }

    func addTrackingEvent(_ event: MarketplaceTrackingEvent) async throws -> String {
        let ref = db.collection(Collection.trackingEvents).document()
        var newEvent = event
        newEvent.id = ref.documentID
        try ref.setData(from: newEvent, merge: true)
        return ref.documentID
    }

    func fetchTrackingEvents(shipmentId: String) async throws -> [MarketplaceTrackingEvent] {
        let snapshot = try await db.collection(Collection.trackingEvents)
            .whereField("shipmentId", isEqualTo: shipmentId)
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceTrackingEvent.self)
        }
    }

    // MARK: - Support

    func createSupportTicket(
        userId: String,
        subject: String,
        message: String,
        category: String,
        priority: String = "normal"
    ) async throws -> String {
        let ref = db.collection(Collection.supportTickets).document()

        try await ref.setData([
            "id": ref.documentID,
            "userId": userId,
            "subject": subject,
            "message": message,
            "category": category,
            "priority": priority,
            "status": "open",
            "createdAt": Timestamp(),
            "updatedAt": Timestamp(),
            "source": "marketplace"
        ], merge: true)

        return ref.documentID
    }

    // MARK: - Certification

    func createCertificationRequest(
        userId: String,
        targetType: String,
        targetId: String?,
        note: String?
    ) async throws -> String {
        let ref = db.collection(Collection.certificationRequests).document()

        try await ref.setData([
            "id": ref.documentID,
            "userId": userId,
            "targetType": targetType,
            "targetId": targetId ?? "",
            "note": note ?? "",
            "status": "pending",
            "isPaid": false,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ], merge: true)

        return ref.documentID
    }
    // MARK: - User Actions

    func recordUserAction(_ action: MarketplaceUserAction) async throws -> String {
        let ref = db.collection(Collection.userActions).document()
        var newAction = action
        newAction.id = ref.documentID
        try ref.setData(from: newAction, merge: true)
        return ref.documentID
    }

    func createOrUpdateRecommendationProfile(_ profile: MarketplaceRecommendationProfile) async throws {
        let profileId = profile.id ?? profile.userId

        try db.collection(Collection.recommendationProfiles)
            .document(profileId)
            .setData(from: profile, merge: true)
    }

    // MARK: - AI

    func createAIFlag(_ flag: MarketplaceAIFlag) async throws -> String {
        let ref = db.collection(Collection.aiFlags).document()

        let data: [String: Any] = [
            "id": ref.documentID,
            "type": flag.type.rawValue,
            "riskLevel": flag.riskLevel.rawValue,
            "decision": flag.decision.rawValue,
            "title": flag.title,
            "explanation": flag.explanation,
            "confidence": flag.confidence,
            "score": flag.score ?? 0,
            "productId": flag.productId ?? "",
            "storeId": flag.storeId ?? "",
            "sellerId": flag.sellerId ?? "",
            "buyerId": flag.buyerId ?? "",
            "orderId": flag.orderId ?? "",
            "paymentId": flag.paymentId ?? "",
            "reviewId": flag.reviewId ?? "",
            "messageId": flag.messageId ?? "",
            "disputeId": flag.disputeId ?? "",
            "evidenceURLs": flag.evidenceURLs,
            "metadata": flag.metadata,
            "createdAt": Timestamp(),
            "reviewedAt": flag.reviewedAt ?? NSNull(),
            "reviewedByAdminId": flag.reviewedByAdminId ?? ""
        ]

        try await ref.setData(data, merge: true)

        return ref.documentID
    }

    func saveAIModerationResult(_ result: MarketplaceAIModerationResult) async throws {
        try db.collection(Collection.aiModerationResults)
            .document(result.id)
            .setData(from: result, merge: true)
    }

    func saveAIRecommendation(_ recommendation: MarketplaceAIRecommendationItem) async throws {
        try db.collection(Collection.aiRecommendations)
            .document(recommendation.id)
            .setData(from: recommendation, merge: true)
    }

    func saveAISearchIntent(_ intent: MarketplaceAISearchIntent) async throws {
        try db.collection(Collection.aiSearchIntents)
            .document(intent.id)
            .setData(from: intent, merge: true)
    }

    // MARK: - Analytics

    func saveSellerAnalytics(_ analytics: MarketplaceSellerAnalytics) async throws {
        let analyticsId = analytics.id ?? "\(analytics.sellerId)_\(analytics.period.rawValue)"

        try db.collection(Collection.sellerAnalytics)
            .document(analyticsId)
            .setData(from: analytics, merge: true)
    }

    func saveAdminAnalytics(_ analytics: MarketplaceAdminAnalytics) async throws {
        let analyticsId = analytics.id ?? "admin_\(analytics.period.rawValue)"

        try db.collection(Collection.adminAnalytics)
            .document(analyticsId)
            .setData(from: analytics, merge: true)
    }

    // MARK: - Legal Documents

    func saveLegalDocument(
        id: String,
        languageCode: String,
        title: String,
        content: String,
        version: Int
    ) async throws {
        try await db.collection(Collection.legalDocuments)
            .document(id)
            .setData([
                "id": id,
                "languageCode": languageCode,
                "title": title,
                "content": content,
                "version": version,
                "isActive": true,
                "updatedAt": Timestamp()
            ], merge: true)
    }

    // MARK: - Current User Helpers

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func requireCurrentUserId() throws -> String {
        guard let userId = currentUserId else {
            throw MarketplaceFirestoreError.notAuthenticated
        }

        return userId
    }
}

// MARK: - Firestore Error

enum MarketplaceFirestoreError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Utilisateur non connecté."
        }
    }
}
    
    
    
    

