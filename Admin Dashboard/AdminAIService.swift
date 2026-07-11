//
//  AdminAIService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

struct AdminAIRiskResult {
    let score: Int
    let category: String
    let recommendedAction: String
    let reason: String
}

@MainActor
final class AdminAIService: ObservableObject {

    static let shared = AdminAIService()

    private let db = Firestore.firestore()

    @Published var lastScore: Int = 0
    @Published var lastCategory: String = "safe"
    @Published var lastAction: String = "none"
    @Published var isAnalyzing = false

    private init() {}

    func analyzeLiveText(
        liveId: String,
        hostId: String,
        hostName: String,
        text: String
    ) {
        isAnalyzing = true

        let result = localRiskAnalysis(text)

        lastScore = result.score
        lastCategory = result.category
        lastAction = result.recommendedAction

        saveAIAlert(
            liveId: liveId,
            hostId: hostId,
            hostName: hostName,
            text: text,
            result: result
        )

        isAnalyzing = false
    }

    private func localRiskAnalysis(
        _ text: String
    ) -> AdminAIRiskResult {

        let lower = text.lowercased()

        let criticalWords = [
            "terrorisme",
            "tuer",
            "meurtre",
            "viol",
            "pédophile",
            "arme",
            "bombe"
        ]

        let highWords = [
            "arnaque",
            "escroquerie",
            "menace",
            "harcèlement",
            "insulte",
            "raciste",
            "haine"
        ]

        let mediumWords = [
            "spam",
            "faux compte",
            "fake",
            "arnaquer",
            "sexe",
            "nudité"
        ]

        if criticalWords.contains(where: { lower.contains($0) }) {
            return AdminAIRiskResult(
                score: 95,
                category: "critical",
                recommendedAction: "human_review_required",
                reason: "Contenu critique détecté. Validation humaine recommandée avant sanction lourde."
            )
        }

        if highWords.contains(where: { lower.contains($0) }) {
            return AdminAIRiskResult(
                score: 75,
                category: "high",
                recommendedAction: "limit_visibility",
                reason: "Risque élevé détecté. Réduction de visibilité recommandée."
            )
        }

        if mediumWords.contains(where: { lower.contains($0) }) {
            return AdminAIRiskResult(
                score: 45,
                category: "medium",
                recommendedAction: "warn",
                reason: "Risque moyen détecté. Avertissement recommandé."
            )
        }

        return AdminAIRiskResult(
            score: 5,
            category: "safe",
            recommendedAction: "none",
            reason: "Aucun risque important détecté."
        )
    }

    private func saveAIAlert(
        liveId: String,
        hostId: String,
        hostName: String,
        text: String,
        result: AdminAIRiskResult
    ) {
        let adminId = Auth.auth().currentUser?.uid ?? "system_ai"

        db.collection("aiModerationAlerts").addDocument(data: [
            "module": "live",
            "liveId": liveId,
            "hostId": hostId,
            "hostName": hostName,
            "text": text,
            "score": result.score,
            "category": result.category,
            "recommendedAction": result.recommendedAction,
            "reason": result.reason,
            "status": "pending",
            "createdBy": adminId,
            "createdAt": FieldValue.serverTimestamp()
        ])

        db.collection("lives").document(liveId).setData([
            "aiRiskLevel": result.score,
            "lastAIAlertAt": FieldValue.serverTimestamp(),
            "lastAIReason": result.reason
        ], merge: true)

        db.collection("adminAuditLogs").addDocument(data: [
            "module": "ai_live_moderation",
            "action": "ai_alert_created",
            "liveId": liveId,
            "hostId": hostId,
            "hostName": hostName,
            "score": result.score,
            "category": result.category,
            "recommendedAction": result.recommendedAction,
            "reason": result.reason,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
}
