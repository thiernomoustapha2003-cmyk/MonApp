//
//  AdminDashboardLiveFirestore.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

extension AdminDashboardLive {
    
    func warnLive(_ live: AdminLiveItem) {
        updateLiveModeration(
            live: live,
            action: "warn",
            severity: "low",
            liveData: [
                "warningsCount": FieldValue.increment(Int64(1)),
                "lastWarningAt": FieldValue.serverTimestamp(),
                "moderationStatus": "warned"
            ],
            userData: [
                "liveWarningsCount": FieldValue.increment(Int64(1)),
                "lastLiveWarningAt": FieldValue.serverTimestamp()
            ],
            reason: "Votre live a reçu un avertissement pour non-respect des règles."
        )
    }
    
    func limitLiveVisibility(_ live: AdminLiveItem) {
        updateLiveModeration(
            live: live,
            action: "limit_visibility",
            severity: "medium",
            liveData: [
                "isVisibilityLimited": true,
                "visibilityLevel": "reduced",
                "visibilityLimitedAt": FieldValue.serverTimestamp(),
                "moderationStatus": "visibility_limited"
            ],
            userData: [
                "liveVisibilityRestricted": true,
                "liveVisibilityRestrictedAt": FieldValue.serverTimestamp()
            ],
            reason: "La visibilité de votre live a été réduite suite à une activité contraire aux règles."
        )
    }
    
    func suspendLive(_ live: AdminLiveItem) {
        let until = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        updateLiveModeration(
            live: live,
            action: "suspend_live",
            severity: "high",
            liveData: [
                "status": "suspended",
                "suspendedAt": FieldValue.serverTimestamp(),
                "moderationStatus": "suspended"
            ],
            userData: [
                "canStartLive": false,
                "liveSuspendedUntil": Timestamp(date: until)
            ],
            reason: "Votre accès au live est suspendu pendant 7 jours."
        )
    }
    
    func stopLive(_ live: AdminLiveItem) {
        updateLiveModeration(
            live: live,
            action: "stop_live",
            severity: "high",
            liveData: [
                "status": "ended_by_admin",
                "endedAt": FieldValue.serverTimestamp(),
                "moderationStatus": "ended_by_admin"
            ],
            userData: [:],
            reason: "Votre live a été arrêté par l'administration."
        )
    }
    
    func restrictLiveHost(_ live: AdminLiveItem) {
        updateLiveModeration(
            live: live,
            action: "restrict_host",
            severity: "high",
            liveData: [
                "hostRestrictedAt": FieldValue.serverTimestamp(),
                "moderationStatus": "host_restricted"
            ],
            userData: [
                "isRestricted": true,
                "restrictedAt": FieldValue.serverTimestamp(),
                "restrictionReason": "Violation des règles Live"
            ],
            reason: "Votre compte a été restreint suite à une violation des règles Live."
        )
    }
    
    func banLiveHost(_ live: AdminLiveItem) {
        updateLiveModeration(
            live: live,
            action: "ban_host",
            severity: "critical",
            liveData: [
                "hostBannedAt": FieldValue.serverTimestamp(),
                "moderationStatus": "host_banned"
            ],
            userData: [
                "isBanned": true,
                "bannedAt": FieldValue.serverTimestamp(),
                "banReason": "Violation grave des règles Live"
            ],
            reason: "Votre compte a été banni suite à une violation grave des règles Live."
        )
    }
    
    private func updateLiveModeration(
        live: AdminLiveItem,
        action: String,
        severity: String,
        liveData: [String: Any],
        userData: [String: Any],
        reason: String
    ) {
        let adminId = Auth.auth().currentUser?.uid ?? "unknown_admin"
        let batch = db.batch()
        
        let liveRef = db.collection("lives").document(live.id)
        batch.setData(liveData, forDocument: liveRef, merge: true)
        
        if !live.hostId.isEmpty && !userData.isEmpty {
            let userRef = db.collection("users").document(live.hostId)
            batch.setData(userData, forDocument: userRef, merge: true)
        }
        
        let auditRef = db.collection("adminAuditLogs").document()
        batch.setData([
            "module": "live",
            "action": action,
            "severity": severity,
            "reason": reason,
            "platform": "Cutly",
            "version": 1,
            "liveId": live.id,
            "hostId": live.hostId,
            "hostName": live.hostName,
            "adminId": adminId,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: auditRef)
        
        let notificationRef = db.collection("notifications").document()
        batch.setData([
            "userId": live.hostId,
            "type": "live_moderation",
            "title": "Action sur votre live",
            "message": reason,
            "liveId": live.id,
            "action": action,
            "severity": severity,
            "isRead": false,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: notificationRef)
        
        batch.commit { error in
            if let error = error {
                print("❌ Action Live admin error:", error.localizedDescription)
            } else {
                print("✅ Action Live admin réussie:", action)
                Task {
                    await loadLives()
                }
            }
        }
    }
    func startLiveRealtimeListener() {
        stopLiveRealtimeListener()

        liveListener = db.collection("lives")
            .addSnapshotListener { snapshot, error in

                if let error = error {
                    print("❌ Live realtime error:", error.localizedDescription)
                    return
                }

                guard let documents = snapshot?.documents else { return }

                var loaded: [AdminLiveItem] = []
                let unique = Set(documents.map(\.documentID))
                if unique.count != documents.count {
                    print("⚠️ Doublons détectés dans Firestore.")
                }
                var revenue: Double = 0
                var viewers = 0
                var reports = 0

                for document in documents {
                    let data = document.data()

                    let item = AdminLiveItem(
                        id: document.documentID,
                        hostId: data["hostId"] as? String ?? "",
                        hostName: data["hostName"] as? String ?? "Créateur",
                        hostAvatar: data["hostAvatar"] as? String ?? "",
                        title: data["title"] as? String ?? "Live",
                        category: data["category"] as? String ?? "Général",
                        viewers: data["viewers"] as? Int ?? 0,
                        likes: data["likes"] as? Int ?? 0,
                        gifts: data["gifts"] as? Int ?? 0,
                        revenue: data["revenue"] as? Double ?? 0,
                        reports: data["reports"] as? Int ?? 0,
                        duration: data["duration"] as? Double ?? 0,
                        country: data["country"] as? String ?? "",
                        startedAt: (data["startedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        isFeatured: data["isFeatured"] as? Bool ?? false,
                        isRestricted: data["isRestricted"] as? Bool ?? false,
                        aiRiskLevel: data["aiRiskLevel"] as? Int ?? 0
                    )

                    loaded.append(item)
                    revenue += item.revenue
                    viewers += item.viewers
                    reports += item.reports
                }

                loaded.sort {
                    $0.startedAt > $1.startedAt
                }
                DispatchQueue.main.async {
                    
                    withAnimation(.easeInOut(duration: 0.30)) {
                        self.lives = loaded
                        self.totalLives = loaded.count
                        self.totalRevenue = revenue
                        self.totalViewers = viewers
                        self.totalReports = reports
                        self.aiAlerts = loaded.filter { $0.aiRiskLevel >= 70 }.count
                        self.loading = false
                    }
                }
            }
    }

    func stopLiveRealtimeListener() {
        liveListener?.remove()
        liveListener = nil
    }
    
    
}
