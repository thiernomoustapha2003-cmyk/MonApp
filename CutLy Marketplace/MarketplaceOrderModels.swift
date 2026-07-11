//
//  MarketplaceOrderModels.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Marketplace Return Status

enum MarketplaceReturnStatus: String, Codable, CaseIterable, Identifiable {
    case requested
    case approved
    case rejected
    case shippedBack
    case received
    case inspected
    case refunded
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .requested: return "Retour demandé"
        case .approved: return "Retour accepté"
        case .rejected: return "Retour refusé"
        case .shippedBack: return "Retour expédié"
        case .received: return "Retour reçu"
        case .inspected: return "Produit vérifié"
        case .refunded: return "Remboursé"
        case .cancelled: return "Annulé"
        }
    }
}

// MARK: - Marketplace Refund Status

enum MarketplaceRefundStatus: String, Codable, CaseIterable, Identifiable {
    case requested
    case pending
    case approved
    case rejected
    case processing
    case refunded
    case failed
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .requested: return "Remboursement demandé"
        case .pending: return "En attente"
        case .approved: return "Approuvé"
        case .rejected: return "Refusé"
        case .processing: return "En traitement"
        case .refunded: return "Remboursé"
        case .failed: return "Échoué"
        case .cancelled: return "Annulé"
        }
    }
}

// MARK: - Marketplace Dispute Status

enum MarketplaceDisputeStatus: String, Codable, CaseIterable, Identifiable {
    case open
    case waitingBuyer
    case waitingSeller
    case underReview
    case resolvedBuyer
    case resolvedSeller
    case resolvedPartial
    case closed
    case escalated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .open: return "Litige ouvert"
        case .waitingBuyer: return "En attente acheteur"
        case .waitingSeller: return "En attente vendeur"
        case .underReview: return "Analyse en cours"
        case .resolvedBuyer: return "Résolu pour l’acheteur"
        case .resolvedSeller: return "Résolu pour le vendeur"
        case .resolvedPartial: return "Résolution partielle"
        case .closed: return "Fermé"
        case .escalated: return "Escaladé"
        }
    }
}

// MARK: - Marketplace Evidence Type

enum MarketplaceEvidenceType: String, Codable, CaseIterable, Identifiable {
    case image
    case video
    case document
    case deliveryProof
    case signature
    case trackingScreenshot
    case conversationScreenshot
    case invoice
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .image: return "Image"
        case .video: return "Vidéo"
        case .document: return "Document"
        case .deliveryProof: return "Preuve de livraison"
        case .signature: return "Signature"
        case .trackingScreenshot: return "Capture suivi"
        case .conversationScreenshot: return "Capture conversation"
        case .invoice: return "Facture"
        case .other: return "Autre"
        }
    }
}

// MARK: - Marketplace Evidence

struct MarketplaceEvidence: Codable, Identifiable, Hashable {
    var id: String
    var userId: String
    var type: MarketplaceEvidenceType

    var title: String
    var description: String?
    var fileURL: String?
    var thumbnailURL: String?

    var createdAt: Timestamp?

    init(
        id: String = UUID().uuidString,
        userId: String,
        type: MarketplaceEvidenceType,
        title: String,
        description: String? = nil,
        fileURL: String? = nil,
        thumbnailURL: String? = nil,
        createdAt: Timestamp? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.description = description
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
    }
}

// MARK: - Marketplace Refund

struct MarketplaceRefund: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var orderId: String
    var paymentId: String?
    var buyerId: String
    var sellerId: String?

    var status: MarketplaceRefundStatus
    var reason: String
    var message: String?

    var amount: MarketplacePrice
    var provider: MarketplacePaymentProvider?

    var externalRefundId: String?
    var failureReason: String?

    var evidence: [MarketplaceEvidence]

    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var requestedAt: Timestamp?
    var approvedAt: Timestamp?
    var refundedAt: Timestamp?
    var rejectedAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        orderId: String,
        paymentId: String? = nil,
        buyerId: String,
        sellerId: String? = nil,
        status: MarketplaceRefundStatus = .requested,
        reason: String,
        message: String? = nil,
        amount: MarketplacePrice,
        provider: MarketplacePaymentProvider? = nil,
        externalRefundId: String? = nil,
        failureReason: String? = nil,
        evidence: [MarketplaceEvidence] = [],
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        requestedAt: Timestamp? = nil,
        approvedAt: Timestamp? = nil,
        refundedAt: Timestamp? = nil,
        rejectedAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.orderId = orderId
        self.paymentId = paymentId
        self.buyerId = buyerId
        self.sellerId = sellerId
        self.status = status
        self.reason = reason
        self.message = message
        self.amount = amount
        self.provider = provider
        self.externalRefundId = externalRefundId
        self.failureReason = failureReason
        self.evidence = evidence
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.requestedAt = requestedAt
        self.approvedAt = approvedAt
        self.refundedAt = refundedAt
        self.rejectedAt = rejectedAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Marketplace Return

struct MarketplaceReturn: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var orderId: String
    var buyerId: String
    var sellerId: String

    var status: MarketplaceReturnStatus
    var reason: String
    var message: String?

    var items: [MarketplaceOrderItem]
    var refund: MarketplaceRefund?

    var returnAddress: MarketplaceAddress?
    var shipment: MarketplaceShipment?

    var evidence: [MarketplaceEvidence]

    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var requestedAt: Timestamp?
    var approvedAt: Timestamp?
    var shippedBackAt: Timestamp?
    var receivedAt: Timestamp?
    var inspectedAt: Timestamp?
    var closedAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        orderId: String,
        buyerId: String,
        sellerId: String,
        status: MarketplaceReturnStatus = .requested,
        reason: String,
        message: String? = nil,
        items: [MarketplaceOrderItem] = [],
        refund: MarketplaceRefund? = nil,
        returnAddress: MarketplaceAddress? = nil,
        shipment: MarketplaceShipment? = nil,
        evidence: [MarketplaceEvidence] = [],
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        requestedAt: Timestamp? = nil,
        approvedAt: Timestamp? = nil,
        shippedBackAt: Timestamp? = nil,
        receivedAt: Timestamp? = nil,
        inspectedAt: Timestamp? = nil,
        closedAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.orderId = orderId
        self.buyerId = buyerId
        self.sellerId = sellerId
        self.status = status
        self.reason = reason
        self.message = message
        self.items = items
        self.refund = refund
        self.returnAddress = returnAddress
        self.shipment = shipment
        self.evidence = evidence
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.requestedAt = requestedAt
        self.approvedAt = approvedAt
        self.shippedBackAt = shippedBackAt
        self.receivedAt = receivedAt
        self.inspectedAt = inspectedAt
        self.closedAt = closedAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Marketplace Dispute Message

struct MarketplaceDisputeMessage: Codable, Identifiable, Hashable {
    var id: String
    var senderId: String
    var senderRole: String

    var text: String
    var evidence: [MarketplaceEvidence]

    var isInternalNote: Bool
    var createdAt: Timestamp?

    init(
        id: String = UUID().uuidString,
        senderId: String,
        senderRole: String,
        text: String,
        evidence: [MarketplaceEvidence] = [],
        isInternalNote: Bool = false,
        createdAt: Timestamp? = nil
    ) {
        self.id = id
        self.senderId = senderId
        self.senderRole = senderRole
        self.text = text
        self.evidence = evidence
        self.isInternalNote = isInternalNote
        self.createdAt = createdAt
    }
}

// MARK: - Marketplace Dispute Resolution

struct MarketplaceDisputeResolution: Codable, Hashable {
    var decidedByUserId: String?
    var decision: MarketplaceDisputeStatus
    var reason: String
    var refundAmount: MarketplacePrice?
    var platformCompensation: MarketplacePrice?
    var sellerPenalty: MarketplacePrice?

    var createdAt: Timestamp?

    init(
        decidedByUserId: String? = nil,
        decision: MarketplaceDisputeStatus,
        reason: String,
        refundAmount: MarketplacePrice? = nil,
        platformCompensation: MarketplacePrice? = nil,
        sellerPenalty: MarketplacePrice? = nil,
        createdAt: Timestamp? = nil
    ) {
        self.decidedByUserId = decidedByUserId
        self.decision = decision
        self.reason = reason
        self.refundAmount = refundAmount
        self.platformCompensation = platformCompensation
        self.sellerPenalty = sellerPenalty
        self.createdAt = createdAt
    }
}

// MARK: - Marketplace Dispute

struct MarketplaceDispute: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var orderId: String
    var buyerId: String
    var sellerId: String

    var status: MarketplaceDisputeStatus
    var reason: String
    var description: String

    var messages: [MarketplaceDisputeMessage]
    var evidence: [MarketplaceEvidence]
    var resolution: MarketplaceDisputeResolution?

    var priority: Int
    var assignedAdminId: String?

    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var openedAt: Timestamp?
    var escalatedAt: Timestamp?
    var resolvedAt: Timestamp?
    var closedAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        orderId: String,
        buyerId: String,
        sellerId: String,
        status: MarketplaceDisputeStatus = .open,
        reason: String,
        description: String,
        messages: [MarketplaceDisputeMessage] = [],
        evidence: [MarketplaceEvidence] = [],
        resolution: MarketplaceDisputeResolution? = nil,
        priority: Int = 1,
        assignedAdminId: String? = nil,
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        openedAt: Timestamp? = nil,
        escalatedAt: Timestamp? = nil,
        resolvedAt: Timestamp? = nil,
        closedAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.orderId = orderId
        self.buyerId = buyerId
        self.sellerId = sellerId
        self.status = status
        self.reason = reason
        self.description = description
        self.messages = messages
        self.evidence = evidence
        self.resolution = resolution
        self.priority = priority
        self.assignedAdminId = assignedAdminId
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.openedAt = openedAt
        self.escalatedAt = escalatedAt
        self.resolvedAt = resolvedAt
        self.closedAt = closedAt
        self.updatedAt = updatedAt
    }
}
