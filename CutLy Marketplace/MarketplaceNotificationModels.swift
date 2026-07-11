//
//  MarketplaceNotificationModels.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Marketplace Notification Type

enum MarketplaceNotificationType: String, Codable, CaseIterable, Identifiable {
    case order
    case payment
    case shipment
    case delivery
    case message
    case dispute
    case refund
    case returnRequest
    case promotion
    case priceDrop
    case favorite
    case store
    case review
    case wallet
    case security
    case liveShopping
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .order: return "Commande"
        case .payment: return "Paiement"
        case .shipment: return "Expédition"
        case .delivery: return "Livraison"
        case .message: return "Message"
        case .dispute: return "Litige"
        case .refund: return "Remboursement"
        case .returnRequest: return "Retour"
        case .promotion: return "Promotion"
        case .priceDrop: return "Baisse de prix"
        case .favorite: return "Favori"
        case .store: return "Boutique"
        case .review: return "Avis"
        case .wallet: return "Portefeuille"
        case .security: return "Sécurité"
        case .liveShopping: return "Live Shopping"
        case .system: return "Système"
        }
    }
}

// MARK: - Marketplace Notification Priority

enum MarketplaceNotificationPriority: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high
    case urgent

    var id: String { rawValue }
}

// MARK: - Marketplace Notification

struct MarketplaceNotification: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var userId: String

    var type: MarketplaceNotificationType
    var priority: MarketplaceNotificationPriority

    var title: String
    var body: String

    var iconName: String?
    var imageURL: String?

    var productId: String?
    var storeId: String?
    var orderId: String?
    var paymentId: String?
    var shipmentId: String?
    var disputeId: String?
    var messageId: String?
    var walletTransactionId: String?
    var liveId: String?

    var deepLink: String?

    var isRead: Bool
    var isArchived: Bool

    var createdAt: Timestamp?
    var readAt: Timestamp?
    var expiresAt: Timestamp?

    init(
        id: String? = nil,
        userId: String,
        type: MarketplaceNotificationType,
        priority: MarketplaceNotificationPriority = .normal,
        title: String,
        body: String,
        iconName: String? = nil,
        imageURL: String? = nil,
        productId: String? = nil,
        storeId: String? = nil,
        orderId: String? = nil,
        paymentId: String? = nil,
        shipmentId: String? = nil,
        disputeId: String? = nil,
        messageId: String? = nil,
        walletTransactionId: String? = nil,
        liveId: String? = nil,
        deepLink: String? = nil,
        isRead: Bool = false,
        isArchived: Bool = false,
        createdAt: Timestamp? = nil,
        readAt: Timestamp? = nil,
        expiresAt: Timestamp? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.priority = priority
        self.title = title
        self.body = body
        self.iconName = iconName
        self.imageURL = imageURL
        self.productId = productId
        self.storeId = storeId
        self.orderId = orderId
        self.paymentId = paymentId
        self.shipmentId = shipmentId
        self.disputeId = disputeId
        self.messageId = messageId
        self.walletTransactionId = walletTransactionId
        self.liveId = liveId
        self.deepLink = deepLink
        self.isRead = isRead
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.readAt = readAt
        self.expiresAt = expiresAt
    }
}

// MARK: - Marketplace Notification Settings

struct MarketplaceNotificationSettings: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var userId: String

    var orderUpdates: Bool
    var paymentUpdates: Bool
    var shipmentUpdates: Bool
    var messageUpdates: Bool
    var disputeUpdates: Bool
    var refundUpdates: Bool
    var promotions: Bool
    var priceDrops: Bool
    var storeUpdates: Bool
    var liveShoppingAlerts: Bool
    var walletUpdates: Bool
    var securityAlerts: Bool

    var pushEnabled: Bool
    var emailEnabled: Bool
    var smsEnabled: Bool
    var whatsappEnabled: Bool

    var quietHoursEnabled: Bool
    var quietHoursStart: String?
    var quietHoursEnd: String?

    var languageCode: String

    var createdAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        userId: String,
        orderUpdates: Bool = true,
        paymentUpdates: Bool = true,
        shipmentUpdates: Bool = true,
        messageUpdates: Bool = true,
        disputeUpdates: Bool = true,
        refundUpdates: Bool = true,
        promotions: Bool = true,
        priceDrops: Bool = true,
        storeUpdates: Bool = true,
        liveShoppingAlerts: Bool = true,
        walletUpdates: Bool = true,
        securityAlerts: Bool = true,
        pushEnabled: Bool = true,
        emailEnabled: Bool = false,
        smsEnabled: Bool = false,
        whatsappEnabled: Bool = false,
        quietHoursEnabled: Bool = false,
        quietHoursStart: String? = nil,
        quietHoursEnd: String? = nil,
        languageCode: String = "fr",
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.userId = userId
        self.orderUpdates = orderUpdates
        self.paymentUpdates = paymentUpdates
        self.shipmentUpdates = shipmentUpdates
        self.messageUpdates = messageUpdates
        self.disputeUpdates = disputeUpdates
        self.refundUpdates = refundUpdates
        self.promotions = promotions
        self.priceDrops = priceDrops
        self.storeUpdates = storeUpdates
        self.liveShoppingAlerts = liveShoppingAlerts
        self.walletUpdates = walletUpdates
        self.securityAlerts = securityAlerts
        self.pushEnabled = pushEnabled
        self.emailEnabled = emailEnabled
        self.smsEnabled = smsEnabled
        self.whatsappEnabled = whatsappEnabled
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.languageCode = languageCode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
