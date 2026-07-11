//
//  MarketplaceMessageModels.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Marketplace Conversation Type

enum MarketplaceConversationType: String, Codable, CaseIterable, Identifiable {
    case buyerSeller
    case order
    case dispute
    case support
    case store
    case liveShopping

    var id: String { rawValue }

    var title: String {
        switch self {
        case .buyerSeller: return "Acheteur / Vendeur"
        case .order: return "Commande"
        case .dispute: return "Litige"
        case .support: return "Support"
        case .store: return "Boutique"
        case .liveShopping: return "Live Shopping"
        }
    }
}

// MARK: - Marketplace Message Type

enum MarketplaceMessageType: String, Codable, CaseIterable, Identifiable {
    case text
    case image
    case video
    case audio
    case file
    case product
    case order
    case offer
    case system
    case translation

    var id: String { rawValue }
}

// MARK: - Marketplace Message Status

enum MarketplaceMessageStatus: String, Codable, CaseIterable, Identifiable {
    case sending
    case sent
    case delivered
    case read
    case failed
    case removed
    case flagged

    var id: String { rawValue }
}

// MARK: - Marketplace Attachment

struct MarketplaceMessageAttachment: Codable, Identifiable, Hashable {
    var id: String
    var url: String
    var thumbnailURL: String?
    var fileName: String?
    var mimeType: String?
    var sizeBytes: Int?
    var type: MarketplaceMessageType

    init(
        id: String = UUID().uuidString,
        url: String,
        thumbnailURL: String? = nil,
        fileName: String? = nil,
        mimeType: String? = nil,
        sizeBytes: Int? = nil,
        type: MarketplaceMessageType
    ) {
        self.id = id
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.fileName = fileName
        self.mimeType = mimeType
        self.sizeBytes = sizeBytes
        self.type = type
    }
}

// MARK: - Marketplace Message

struct MarketplaceMessage: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var conversationId: String
    var senderId: String
    var receiverId: String?

    var type: MarketplaceMessageType
    var status: MarketplaceMessageStatus

    var text: String?
    var translatedText: String?
    var originalLanguageCode: String?
    var translatedLanguageCode: String?

    var attachments: [MarketplaceMessageAttachment]

    var productId: String?
    var orderId: String?
    var disputeId: String?
    var offerId: String?

    var isAutoTranslated: Bool
    var isSystemMessage: Bool
    var isFlagged: Bool
    var isDeletedForSender: Bool
    var isDeletedForReceiver: Bool

    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var createdAt: Timestamp?
    var deliveredAt: Timestamp?
    var readAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        conversationId: String,
        senderId: String,
        receiverId: String? = nil,
        type: MarketplaceMessageType = .text,
        status: MarketplaceMessageStatus = .sent,
        text: String? = nil,
        translatedText: String? = nil,
        originalLanguageCode: String? = nil,
        translatedLanguageCode: String? = nil,
        attachments: [MarketplaceMessageAttachment] = [],
        productId: String? = nil,
        orderId: String? = nil,
        disputeId: String? = nil,
        offerId: String? = nil,
        isAutoTranslated: Bool = false,
        isSystemMessage: Bool = false,
        isFlagged: Bool = false,
        isDeletedForSender: Bool = false,
        isDeletedForReceiver: Bool = false,
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        createdAt: Timestamp? = nil,
        deliveredAt: Timestamp? = nil,
        readAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.receiverId = receiverId
        self.type = type
        self.status = status
        self.text = text
        self.translatedText = translatedText
        self.originalLanguageCode = originalLanguageCode
        self.translatedLanguageCode = translatedLanguageCode
        self.attachments = attachments
        self.productId = productId
        self.orderId = orderId
        self.disputeId = disputeId
        self.offerId = offerId
        self.isAutoTranslated = isAutoTranslated
        self.isSystemMessage = isSystemMessage
        self.isFlagged = isFlagged
        self.isDeletedForSender = isDeletedForSender
        self.isDeletedForReceiver = isDeletedForReceiver
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.createdAt = createdAt
        self.deliveredAt = deliveredAt
        self.readAt = readAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Marketplace Conversation

struct MarketplaceConversation: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var type: MarketplaceConversationType
    var participantIds: [String]

    var buyerId: String?
    var sellerId: String?
    var storeId: String?
    var productId: String?
    var orderId: String?
    var disputeId: String?

    var title: String?
    var lastMessageText: String?
    var lastMessageSenderId: String?

    var unreadCountByUserId: [String: Int]

    var isArchivedByUserId: [String: Bool]
    var isMutedByUserId: [String: Bool]
    var isPinnedByUserId: [String: Bool]

    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var createdAt: Timestamp?
    var lastMessageAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        type: MarketplaceConversationType = .buyerSeller,
        participantIds: [String],
        buyerId: String? = nil,
        sellerId: String? = nil,
        storeId: String? = nil,
        productId: String? = nil,
        orderId: String? = nil,
        disputeId: String? = nil,
        title: String? = nil,
        lastMessageText: String? = nil,
        lastMessageSenderId: String? = nil,
        unreadCountByUserId: [String: Int] = [:],
        isArchivedByUserId: [String: Bool] = [:],
        isMutedByUserId: [String: Bool] = [:],
        isPinnedByUserId: [String: Bool] = [:],
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        createdAt: Timestamp? = nil,
        lastMessageAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.type = type
        self.participantIds = participantIds
        self.buyerId = buyerId
        self.sellerId = sellerId
        self.storeId = storeId
        self.productId = productId
        self.orderId = orderId
        self.disputeId = disputeId
        self.title = title
        self.lastMessageText = lastMessageText
        self.lastMessageSenderId = lastMessageSenderId
        self.unreadCountByUserId = unreadCountByUserId
        self.isArchivedByUserId = isArchivedByUserId
        self.isMutedByUserId = isMutedByUserId
        self.isPinnedByUserId = isPinnedByUserId
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.createdAt = createdAt
        self.lastMessageAt = lastMessageAt
        self.updatedAt = updatedAt
    }
}
