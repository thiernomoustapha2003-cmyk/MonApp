//
//  MarketplaceReportService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import Foundation
import FirebaseFirestore

final class MarketplaceReportService {
    
    static let shared = MarketplaceReportService()
    
    private let db = Firestore.firestore()
    private let moderationService = MarketplaceModerationService.shared
    
    private init() {}
    
    // MARK: - Create Report
    
    func createReport(
        reporterId: String,
        targetId: String,
        targetType: MarketplaceReportTargetType,
        reason: MarketplaceReportReason,
        description: String,
        evidenceURLs: [String] = []
    ) -> MarketplaceReportDraft {
        
        MarketplaceReportDraft(
            id: UUID().uuidString,
            reporterId: reporterId,
            targetId: targetId,
            targetType: targetType,
            reason: reason,
            description: description,
            evidenceURLs: evidenceURLs,
            status: .open,
            priority: priority(for: reason, evidenceCount: evidenceURLs.count),
            createdAt: Timestamp()
        )
    }
    
    func saveReport(_ report: MarketplaceReportDraft) async throws {
        try await db
            .collection(MarketplaceFirestoreService.Collection.reports)
            .document(report.id)
            .setData(from: report, merge: true)
        
        let moderation = moderationService.createReportModerationResult(
            reportId: report.id,
            reporterId: report.reporterId,
            targetId: report.targetId,
            targetType: report.targetType.moderationTargetType,
            reportReason: report.description,
            evidenceURLs: report.evidenceURLs
        )
        
        try await moderationService.saveModerationResult(moderation)
    }
    
    // MARK: - Priority
    
    func priority(
        for reason: MarketplaceReportReason,
        evidenceCount: Int
    ) -> MarketplaceReportPriority {
        switch reason {
        case .fraud, .counterfeit, .dangerousProduct, .threat, .illegalProduct:
            return .urgent
            
        case .paymentIssue, .deliveryIssue, .scam, .harassment:
            return evidenceCount > 0 ? .high : .medium
            
        case .fakeReview, .spam, .wrongCategory, .misleadingDescription:
            return .medium
            
        case .other:
            return .normal
        }
    }
    // MARK: - Fetch Reports

    func fetchReports(
        status: MarketplaceReportStatus? = nil,
        limit: Int = 50
    ) async throws -> [MarketplaceReportDraft] {
        var query: Query = db
            .collection(MarketplaceFirestoreService.Collection.reports)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let status {
            query = db
                .collection(MarketplaceFirestoreService.Collection.reports)
                .whereField("status", isEqualTo: status.rawValue)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
        }

        let snapshot = try await query.getDocuments()

        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceReportDraft.self)
        }
    }

    func fetchReportsForTarget(
        targetId: String,
        limit: Int = 30
    ) async throws -> [MarketplaceReportDraft] {
        let snapshot = try await db
            .collection(MarketplaceFirestoreService.Collection.reports)
            .whereField("targetId", isEqualTo: targetId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap {
            try $0.data(as: MarketplaceReportDraft.self)
        }
    }

    // MARK: - Status / Admin Decision

    func updateReportStatus(
        reportId: String,
        status: MarketplaceReportStatus,
        adminId: String? = nil,
        note: String? = nil
    ) async throws {
        var data: [String: Any] = [
            "status": status.rawValue,
            "updatedAt": Timestamp()
        ]

        if let adminId {
            data["adminId"] = adminId
        }

        if let note {
            data["adminNote"] = note
        }

        if status == .closed || status == .rejected || status == .actionTaken {
            data["closedAt"] = Timestamp()
        }

        try await db
            .collection(MarketplaceFirestoreService.Collection.reports)
            .document(reportId)
            .setData(data, merge: true)
    }

    func applyReportDecision(
        report: MarketplaceReportDraft,
        adminId: String,
        decision: MarketplaceModerationDecision,
        note: String
    ) async throws {
        let moderation = moderationService.createReportModerationResult(
            reportId: report.id,
            reporterId: report.reporterId,
            targetId: report.targetId,
            targetType: report.targetType.moderationTargetType,
            reportReason: report.description,
            evidenceURLs: report.evidenceURLs
        )

        try await moderationService.saveModerationResult(moderation)

        let actions = moderationService.recommendedEnforcementActions(for: moderation)

        try await moderationService.saveEnforcementActions(
            moderationId: moderation.id,
            targetId: report.targetId,
            actions: actions
        )

        try await moderationService.applyAdminDecision(
            moderationId: moderation.id,
            adminId: adminId,
            decision: decision,
            note: note
        )

        try await updateReportStatus(
            reportId: report.id,
            status: .actionTaken,
            adminId: adminId,
            note: note
        )
    }
    
    
    
    
    
    
    
    
    
    
}

// MARK: - Models

struct MarketplaceReportDraft: Codable, Identifiable, Hashable {
    var id: String
    var reporterId: String
    var targetId: String
    var targetType: MarketplaceReportTargetType
    var reason: MarketplaceReportReason
    var description: String
    var evidenceURLs: [String]
    var status: MarketplaceReportStatus
    var priority: MarketplaceReportPriority
    var createdAt: Timestamp?
}

enum MarketplaceReportTargetType: String, Codable, CaseIterable, Identifiable {
    case product
    case seller
    case store
    case review
    case message
    case order
    case payment
    case dispute
    case user

    var id: String { rawValue }

    var moderationTargetType: MarketplaceModerationTargetType {
        switch self {
        case .product: return .product
        case .seller: return .seller
        case .store: return .store
        case .review: return .review
        case .message: return .message
        case .order: return .order
        case .payment: return .payment
        case .dispute: return .dispute
        case .user: return .seller
        }
    }
}

enum MarketplaceReportReason: String, Codable, CaseIterable, Identifiable {
    case fraud
    case scam
    case counterfeit
    case illegalProduct
    case dangerousProduct
    case fakeReview
    case spam
    case harassment
    case threat
    case misleadingDescription
    case wrongCategory
    case paymentIssue
    case deliveryIssue
    case other

    var id: String { rawValue }
}

enum MarketplaceReportStatus: String, Codable, CaseIterable, Identifiable {
    case open
    case reviewing
    case actionTaken
    case rejected
    case closed

    var id: String { rawValue }
}

enum MarketplaceReportPriority: String, Codable, CaseIterable, Identifiable {
    case normal
    case medium
    case high
    case urgent

    var id: String { rawValue }
}
