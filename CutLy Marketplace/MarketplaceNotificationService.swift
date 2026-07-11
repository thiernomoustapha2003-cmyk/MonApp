//
//  MarketplaceNotificationService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import Foundation
import FirebaseFirestore

final class MarketplaceNotificationService {
    
    static let shared = MarketplaceNotificationService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Create Notification
    
    func buildNotification(
        userId: String,
        type: MarketplaceNotificationServiceType,
        title: String,
        body: String,
        targetId: String? = nil,
        targetType: MarketplaceNotificationServiceTargetType? = nil,
        priority:MarketplaceNotificationServicePriority = .normal
    ) -> MarketplaceNotificationDraft {
        MarketplaceNotificationDraft(
            id: UUID().uuidString,
            userId: userId,
            type: type,
            title: title,
            body: body,
            targetId: targetId,
            targetType: targetType,
            priority: priority,
            isRead: false,
            createdAt: Timestamp()
        )
    }
    
    func saveNotification(_ notification: MarketplaceNotificationDraft) async throws {
        try await db
            .collection(MarketplaceFirestoreService.Collection.notifications)
            .document(notification.id)
            .setData(from: notification, merge: true)
    }
    
    // MARK: - Quick Notifications
    
    func notifyOrderPaid(
        buyerId: String,
        sellerId: String,
        orderId: String,
        amount: Double,
        currency: MarketplaceCurrency
    ) async throws {
        let buyerNotification = buildNotification(
            userId: buyerId,
            type: .orderPaid,
            title: "Commande payée",
            body: "Votre commande a été payée avec succès.",
            targetId: orderId,
            targetType: .order
        )
        
        let sellerNotification = buildNotification(
            userId: sellerId,
            type: .orderPaid,
            title: "Nouvelle vente",
            body: "Vous avez reçu une commande de \(amount) \(currency.rawValue).",
            targetId: orderId,
            targetType: .order,
            priority: .high
        )
        
        try await saveNotification(buyerNotification)
        try await saveNotification(sellerNotification)
    }
    
    func notifyShipmentUpdated(
        userId: String,
        orderId: String,
        statusText: String
    ) async throws {
        let notification = buildNotification(
            userId: userId,
            type: .shippingUpdated,
            title: "Suivi colis mis à jour",
            body: statusText,
            targetId: orderId,
            targetType: .shipment
        )
        
        try await saveNotification(notification)
    }
    
    func notifyNewMessage(
        userId: String,
        conversationId: String,
        senderName: String
    ) async throws {
        let notification = buildNotification(
            userId: userId,
            type: .newMessage,
            title: "Nouveau message",
            body: "\(senderName) vous a envoyé un message.",
            targetId: conversationId,
            targetType: .conversation
        )
        
        try await saveNotification(notification)
    }
    
    func notifyDisputeOpened(
        userId: String,
        disputeId: String,
        orderId: String
    ) async throws {
        let notification = buildNotification(
            userId: userId,
            type: .disputeOpened,
            title: "Litige ouvert",
            body: "Un litige a été ouvert sur une commande.",
            targetId: disputeId,
            targetType: .dispute,
            priority: .high
        )
        
        try await saveNotification(notification)
    }
    
    func notifySecurityAlert(
        userId: String,
        alertTitle: String,
        alertBody: String,
        targetId: String?
    ) async throws {
        let notification = buildNotification(
            userId: userId,
            type: .securityAlert,
            title: alertTitle,
            body: alertBody,
            targetId: targetId,
            targetType: .security,
            priority: .urgent
        )
        
        try await saveNotification(notification)
    }
    // MARK: - Fetch / Read

    func fetchUserNotifications(
        userId: String,
        limit: Int = 50
    ) async throws -> [MarketplaceNotificationDraft] {
        let snapshot = try await db
            .collection(MarketplaceFirestoreService.Collection.notifications)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceNotificationDraft.self)
        }
    }

    func markAsRead(notificationId: String) async throws {
        try await db
            .collection(MarketplaceFirestoreService.Collection.notifications)
            .document(notificationId)
            .setData([
                "isRead": true,
                "readAt": Timestamp(),
                "updatedAt": Timestamp()
            ], merge: true)
    }

    func markAllAsRead(userId: String) async throws {
        let snapshot = try await db
            .collection(MarketplaceFirestoreService.Collection.notifications)
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        for document in snapshot.documents {
            try await document.reference.setData([
                "isRead": true,
                "readAt": Timestamp(),
                "updatedAt": Timestamp()
            ], merge: true)
        }
    }

    // MARK: - Extra Quick Notifications

    func notifyWithdrawalUpdated(
        userId: String,
        withdrawalId: String,
        statusText: String
    ) async throws {
        let notification = buildNotification(
            userId: userId,
            type: .withdrawalUpdated,
            title: "Retrait mis à jour",
            body: statusText,
            targetId: withdrawalId,
            targetType: .wallet,
            priority: .high
        )

        try await saveNotification(notification)
    }

    func notifyCertificationUpdated(
        userId: String,
        certificationId: String,
        statusText: String
    ) async throws {
        let notification = buildNotification(
            userId: userId,
            type: .certificationUpdated,
            title: "Certification Cutly",
            body: statusText,
            targetId: certificationId,
            targetType: .certification,
            priority: .normal
        )

        try await saveNotification(notification)
    }

    func notifySupportReply(
        userId: String,
        ticketId: String
    ) async throws {
        let notification = buildNotification(
            userId: userId,
            type: .supportReply,
            title: "Réponse du support",
            body: "Le support Cutly a répondu à votre ticket.",
            targetId: ticketId,
            targetType: .support,
            priority: .normal
        )

        try await saveNotification(notification)
    }
    
    
    
    
    
    
    
    
}

// MARK: - Models

struct MarketplaceNotificationDraft: Codable, Identifiable, Hashable {
    var id: String
    var userId: String
    var type: MarketplaceNotificationServiceType
    var title: String
    var body: String
    var targetId: String?
    var targetType: MarketplaceNotificationServiceTargetType?
    var priority: MarketplaceNotificationServicePriority
    var isRead: Bool
    var createdAt: Timestamp?
}

enum MarketplaceNotificationServiceType: String, Codable, CaseIterable, Identifiable {
    case orderPaid
    case orderCancelled
    case orderDelivered
    case shippingUpdated
    case paymentReceived
    case withdrawalUpdated
    case refundUpdated
    case newMessage
    case newReview
    case favoritePriceDrop
    case storePromotion
    case disputeOpened
    case disputeUpdated
    case certificationUpdated
    case securityAlert
    case aiAlert
    case supportReply

    var id: String { rawValue }
}

enum MarketplaceNotificationServiceTargetType: String, Codable, CaseIterable, Identifiable {
    case order
    case payment
    case shipment
    case conversation
    case review
    case product
    case store
    case dispute
    case wallet
    case certification
    case support
    case security

    var id: String { rawValue }
}

enum MarketplaceNotificationServicePriority: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high
    case urgent

    var id: String { rawValue }
}
