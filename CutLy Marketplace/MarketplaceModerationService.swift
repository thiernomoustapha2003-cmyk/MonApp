//
//  MarketplaceModerationService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import Foundation
import FirebaseFirestore

final class MarketplaceModerationService {
    
    static let shared = MarketplaceModerationService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Product Moderation
    
    func moderateProduct(
        productId: String,
        sellerId: String,
        title: String,
        description: String,
        categoryId: String?,
        price: Double?,
        imageURLs: [String],
        sellerIsVerified: Bool
    ) -> MarketplaceModerationResult {
        
        var score = 0.0
        var reasons: [String] = []
        
        let normalizedTitle = normalize(title)
        let normalizedDescription = normalize(description)
        let text = "\(normalizedTitle) \(normalizedDescription)"
        
        let prohibitedKeywords = [
            "arme", "weapon", "gun", "pistolet",
            "drogue", "drug", "cocaine", "weed",
            "faux papier", "fake id", "passport fake",
            "contrefacon", "fake brand", "replica",
            "pirate", "hacked", "stolen"
        ]
        
        for keyword in prohibitedKeywords {
            if text.contains(keyword) {
                score += 0.35
                reasons.append("Mot-clé sensible détecté : \(keyword)")
            }
        }
        
        if imageURLs.isEmpty {
            score += 0.15
            reasons.append("Aucune image produit")
        }
        
        if let price, price <= 0 {
            score += 0.25
            reasons.append("Prix invalide")
        }
        
        if !sellerIsVerified {
            score += 0.10
            reasons.append("Vendeur non certifié")
        }
        
        let finalScore = min(score, 1.0)
        
        return MarketplaceModerationResult(
            id: UUID().uuidString,
            targetId: productId,
            targetType: .product,
            userId: sellerId,
            riskScore: finalScore,
            riskLevel: MarketplaceModerationRiskLevel.level(for: finalScore),
            decision: MarketplaceModerationDecision.decision(for: finalScore),
            reasons: reasons,
            createdAt: Timestamp()
        )
    }
    
    // MARK: - Seller Moderation
    
    func moderateSeller(
        sellerId: String,
        isVerified: Bool,
        totalProducts: Int,
        reportCount: Int,
        disputeCount: Int,
        refundRate: Double,
        averageRating: Double?
    ) -> MarketplaceModerationResult {
        
        var score = 0.0
        var reasons: [String] = []
        
        if !isVerified {
            score += 0.10
            reasons.append("Vendeur non vérifié")
        }
        
        if reportCount >= 3 {
            score += 0.25
            reasons.append("Signalements fréquents")
        }
        
        if disputeCount >= 2 {
            score += 0.25
            reasons.append("Litiges fréquents")
        }
        
        if refundRate >= 0.25 {
            score += 0.20
            reasons.append("Taux de remboursement élevé")
        }
        
        if let averageRating, averageRating < 3 {
            score += 0.15
            reasons.append("Note vendeur faible")
        }
        
        if totalProducts > 200 && !isVerified {
            score += 0.15
            reasons.append("Grand volume sans certification")
        }
        
        let finalScore = min(score, 1.0)
        
        return MarketplaceModerationResult(
            id: UUID().uuidString,
            targetId: sellerId,
            targetType: .seller,
            userId: sellerId,
            riskScore: finalScore,
            riskLevel: MarketplaceModerationRiskLevel.level(for: finalScore),
            decision: MarketplaceModerationDecision.decision(for: finalScore),
            reasons: reasons,
            createdAt: Timestamp()
        )
    }
    
    // MARK: - Save
    
    func saveModerationResult(_ result: MarketplaceModerationResult) async throws {
        try await db
            .collection(MarketplaceFirestoreService.Collection.aiModerationResults)
            .document(result.id)
            .setData(from: result, merge: true)
    }
    
    private func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    // MARK: - Review Moderation

    func moderateReview(
        reviewId: String,
        userId: String,
        text: String,
        rating: Int,
        isVerifiedPurchase: Bool,
        reportCount: Int
    ) -> MarketplaceModerationResult {
        var score = 0.0
        var reasons: [String] = []

        let cleanText = normalize(text)

        let spamWords = ["fake", "arnaque", "scam", "mensonge", "spam", "copier coller"]
        for word in spamWords where cleanText.contains(word) {
            score += 0.12
            reasons.append("Mot sensible dans l’avis : \(word)")
        }

        if !isVerifiedPurchase {
            score += 0.18
            reasons.append("Avis sans achat vérifié")
        }

        if rating <= 1 && cleanText.count < 12 {
            score += 0.18
            reasons.append("Avis très court avec note très basse")
        }

        if reportCount >= 3 {
            score += 0.25
            reasons.append("Avis souvent signalé")
        }

        let finalScore = min(score, 1.0)

        return MarketplaceModerationResult(
            id: UUID().uuidString,
            targetId: reviewId,
            targetType: .review,
            userId: userId,
            riskScore: finalScore,
            riskLevel: MarketplaceModerationRiskLevel.level(for: finalScore),
            decision: MarketplaceModerationDecision.decision(for: finalScore),
            reasons: reasons,
            createdAt: Timestamp()
        )
    }

    // MARK: - Message Moderation

    func moderateMessage(
        messageId: String,
        userId: String,
        text: String,
        attachmentURLs: [String]
    ) -> MarketplaceModerationResult {
        var score = 0.0
        var reasons: [String] = []

        let cleanText = normalize(text)

        let riskyWords = [
            "whatsapp hors application",
            "paiement direct",
            "western union",
            "arnaque",
            "scam",
            "menace",
            "insulte",
            "password",
            "mot de passe"
        ]

        for word in riskyWords where cleanText.contains(word) {
            score += 0.18
            reasons.append("Message potentiellement risqué : \(word)")
        }

        if attachmentURLs.count >= 8 {
            score += 0.12
            reasons.append("Nombre élevé de pièces jointes")
        }

        let finalScore = min(score, 1.0)

        return MarketplaceModerationResult(
            id: UUID().uuidString,
            targetId: messageId,
            targetType: .message,
            userId: userId,
            riskScore: finalScore,
            riskLevel: MarketplaceModerationRiskLevel.level(for: finalScore),
            decision: MarketplaceModerationDecision.decision(for: finalScore),
            reasons: reasons,
            createdAt: Timestamp()
        )
    }

    // MARK: - Payment / Order Moderation

    func moderatePayment(
        paymentId: String,
        userId: String,
        amount: Double,
        provider: MarketplacePaymentProviderOption,
        refundHistoryCount: Int,
        disputeHistoryCount: Int
    ) -> MarketplaceModerationResult {
        var score = 0.0
        var reasons: [String] = []

        if amount >= 500 {
            score += 0.22
            reasons.append("Paiement montant élevé")
        }

        if provider == .manual {
            score += 0.18
            reasons.append("Paiement manuel")
        }

        if provider.isMobileMoney {
            score += 0.08
            reasons.append("Paiement Mobile Money")
        }

        if refundHistoryCount >= 3 {
            score += 0.25
            reasons.append("Historique remboursements fréquent")
        }

        if disputeHistoryCount >= 2 {
            score += 0.25
            reasons.append("Historique litiges fréquent")
        }

        let finalScore = min(score, 1.0)

        return MarketplaceModerationResult(
            id: UUID().uuidString,
            targetId: paymentId,
            targetType: .payment,
            userId: userId,
            riskScore: finalScore,
            riskLevel: MarketplaceModerationRiskLevel.level(for: finalScore),
            decision: MarketplaceModerationDecision.decision(for: finalScore),
            reasons: reasons,
            createdAt: Timestamp()
        )
    }

    func moderateOrder(
        orderId: String,
        buyerId: String,
        amount: Double,
        isInternational: Bool,
        hasTracking: Bool,
        sellerDisputeRate: Double,
        buyerRefundCount: Int
    ) -> MarketplaceModerationResult {
        var score = 0.0
        var reasons: [String] = []

        if amount >= 500 {
            score += 0.18
            reasons.append("Commande de montant élevé")
        }

        if isInternational {
            score += 0.12
            reasons.append("Commande internationale")
        }

        if !hasTracking {
            score += 0.20
            reasons.append("Commande sans suivi colis")
        }

        if sellerDisputeRate >= 0.15 {
            score += 0.20
            reasons.append("Taux litige vendeur élevé")
        }

        if buyerRefundCount >= 3 {
            score += 0.22
            reasons.append("Acheteur avec remboursements fréquents")
        }

        let finalScore = min(score, 1.0)

        return MarketplaceModerationResult(
            id: UUID().uuidString,
            targetId: orderId,
            targetType: .order,
            userId: buyerId,
            riskScore: finalScore,
            riskLevel: MarketplaceModerationRiskLevel.level(for: finalScore),
            decision: MarketplaceModerationDecision.decision(for: finalScore),
            reasons: reasons,
            createdAt: Timestamp()
        )
    }
    // MARK: - Dispute Moderation

    func moderateDispute(
        disputeId: String,
        userId: String,
        orderId: String,
        reason: String,
        evidenceCount: Int,
        messageCount: Int,
        refundRequested: Bool
    ) -> MarketplaceModerationResult {
        var score = 0.0
        var reasons: [String] = []

        let cleanReason = normalize(reason)

        if cleanReason.contains("contrefacon") || cleanReason.contains("fake") {
            score += 0.25
            reasons.append("Suspicion contrefaçon")
        }

        if cleanReason.contains("non recu") || cleanReason.contains("not received") {
            score += 0.18
            reasons.append("Commande non reçue")
        }

        if evidenceCount == 0 {
            score += 0.15
            reasons.append("Aucune preuve ajoutée")
        }

        if messageCount >= 30 {
            score += 0.12
            reasons.append("Conversation longue avant litige")
        }

        if refundRequested {
            score += 0.10
            reasons.append("Remboursement demandé")
        }

        let finalScore = min(score, 1.0)

        return MarketplaceModerationResult(
            id: UUID().uuidString,
            targetId: disputeId,
            targetType: .dispute,
            userId: userId,
            riskScore: finalScore,
            riskLevel: MarketplaceModerationRiskLevel.level(for: finalScore),
            decision: MarketplaceModerationDecision.decision(for: finalScore),
            reasons: reasons,
            createdAt: Timestamp()
        )
    }

    // MARK: - Report Moderation

    func createReportModerationResult(
        reportId: String,
        reporterId: String,
        targetId: String,
        targetType: MarketplaceModerationTargetType,
        reportReason: String,
        evidenceURLs: [String]
    ) -> MarketplaceModerationResult {
        var score = 0.0
        var reasons: [String] = []

        let cleanReason = normalize(reportReason)

        if cleanReason.contains("fraude") || cleanReason.contains("scam") || cleanReason.contains("arnaque") {
            score += 0.30
            reasons.append("Signalement fraude/arnaque")
        }

        if cleanReason.contains("contrefacon") || cleanReason.contains("fake") {
            score += 0.25
            reasons.append("Signalement contrefaçon")
        }

        if cleanReason.contains("danger") || cleanReason.contains("menace") {
            score += 0.25
            reasons.append("Signalement danger ou menace")
        }

        if evidenceURLs.isEmpty {
            score += 0.08
            reasons.append("Signalement sans preuve")
        }

        let finalScore = min(score, 1.0)

        return MarketplaceModerationResult(
            id: UUID().uuidString,
            targetId: targetId,
            targetType: targetType,
            userId: reporterId,
            riskScore: finalScore,
            riskLevel: MarketplaceModerationRiskLevel.level(for: finalScore),
            decision: MarketplaceModerationDecision.decision(for: finalScore),
            reasons: reasons,
            createdAt: Timestamp()
        )
    }

    // MARK: - Admin Decision

    func applyAdminDecision(
        moderationId: String,
        adminId: String,
        decision: MarketplaceModerationDecision,
        note: String
    ) async throws {
        try await db
            .collection(MarketplaceFirestoreService.Collection.aiModerationResults)
            .document(moderationId)
            .setData([
                "decision": decision.rawValue,
                "adminId": adminId,
                "adminNote": note,
                "reviewedAt": Timestamp(),
                "updatedAt": Timestamp()
            ], merge: true)
    }
    // MARK: - Global Decision Helpers

    func shouldAutoBlock(_ result: MarketplaceModerationResult) -> Bool {
        result.decision == .block || result.riskLevel == .critical
    }

    func shouldRequireAdminReview(_ result: MarketplaceModerationResult) -> Bool {
        result.decision == .review || result.decision == .restrict || result.riskLevel == .high
    }

    func recommendedEnforcementActions(
        for result: MarketplaceModerationResult
    ) -> [MarketplaceModerationEnforcementAction] {
        switch result.decision {
        case .allow:
            return [.none]

        case .review:
            return [.manualReview]

        case .restrict:
            switch result.targetType {
            case .product:
                return [.hideProduct, .manualReview]
            case .seller, .store:
                return [.limitSeller, .manualReview]
            case .review:
                return [.hideReview, .manualReview]
            case .message:
                return [.flagMessage, .manualReview]
            case .payment, .order:
                return [.holdPayment, .manualReview]
            case .dispute:
                return [.escalateDispute, .manualReview]
            }

        case .block:
            switch result.targetType {
            case .product:
                return [.removeProduct, .manualReview]
            case .seller, .store:
                return [.suspendAccount, .manualReview]
            case .review:
                return [.removeReview, .manualReview]
            case .message:
                return [.blockMessage, .manualReview]
            case .payment, .order:
                return [.holdPayment, .escalateDispute, .manualReview]
            case .dispute:
                return [.escalateDispute, .manualReview]
            }
        }
    }

    func saveEnforcementActions(
        moderationId: String,
        targetId: String,
        actions: [MarketplaceModerationEnforcementAction]
    ) async throws {
        let ref = db
            .collection(MarketplaceFirestoreService.Collection.moderationActions)
            .document(moderationId)

        try await ref.setData([
            "id": moderationId,
            "targetId": targetId,
            "actions": actions.map { $0.rawValue },
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ], merge: true)
    }
    
    
    
    
    
}

// MARK: - Models

struct MarketplaceModerationResult: Codable, Identifiable, Hashable {
    var id: String
    var targetId: String
    var targetType: MarketplaceModerationTargetType
    var userId: String
    var riskScore: Double
    var riskLevel: MarketplaceModerationRiskLevel
    var decision: MarketplaceModerationDecision
    var reasons: [String]
    var createdAt: Timestamp?
}

enum MarketplaceModerationTargetType: String, Codable, CaseIterable, Identifiable {
    case product
    case seller
    case store
    case review
    case message
    case payment
    case order
    case dispute

    var id: String { rawValue }
}

enum MarketplaceModerationRiskLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high
    case critical

    var id: String { rawValue }

    static func level(for score: Double) -> MarketplaceModerationRiskLevel {
        switch score {
        case 0..<0.30:
            return .low
        case 0.30..<0.55:
            return .medium
        case 0.55..<0.80:
            return .high
        default:
            return .critical
        }
    }
}

enum MarketplaceModerationDecision: String, Codable, CaseIterable, Identifiable {
    case allow
    case review
    case restrict
    case block

    var id: String { rawValue }

    static func decision(for score: Double) -> MarketplaceModerationDecision {
        switch score {
        case 0..<0.30:
            return .allow
        case 0.30..<0.55:
            return .review
        case 0.55..<0.80:
            return .restrict
        default:
            return .block
        }
    }
}
enum MarketplaceModerationEnforcementAction: String, Codable, CaseIterable, Identifiable {
    case none
    case manualReview
    case hideProduct
    case removeProduct
    case limitSeller
    case suspendAccount
    case hideReview
    case removeReview
    case flagMessage
    case blockMessage
    case holdPayment
    case escalateDispute

    var id: String { rawValue }
}
