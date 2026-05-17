//
//  LiveModerationService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//

//
//  LiveModerationService.swift
//  MonApp
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

final class LiveModerationService: ObservableObject {
    
    static let shared = LiveModerationService()
    
    @Published var bannedUsers: [String] = []
    @Published var mutedUsers: [String] = []
    
    private let db = Firestore.firestore()
    
    private init() {}
}

// MARK: - MUTE / BAN

extension LiveModerationService {
    
    func muteUser(liveId: String, userId: String, username: String) {
        db.collection("lives")
            .document(liveId)
            .collection("moderation")
            .document(userId)
            .setData([
                "userId": userId,
                "username": username,
                "action": "muted",
                "createdAt": Timestamp()
            ], merge: true)
        
        sendSystem(liveId: liveId, text: "🔇 \(username) a été muté")
    }
    
    func unmuteUser(liveId: String, userId: String, username: String) {
        db.collection("lives")
            .document(liveId)
            .collection("moderation")
            .document(userId)
            .setData([
                "userId": userId,
                "username": username,
                "action": "unmuted",
                "updatedAt": Timestamp()
            ], merge: true)
        
        sendSystem(liveId: liveId, text: "🎙️ \(username) peut reparler")
    }
    
    func banUser(liveId: String, userId: String, username: String) {
        db.collection("lives")
            .document(liveId)
            .collection("bannedUsers")
            .document(userId)
            .setData([
                "userId": userId,
                "username": username,
                "reason": "host_action",
                "createdAt": Timestamp()
            ])
        
        db.collection("lives")
            .document(liveId)
            .collection("viewers")
            .document(userId)
            .delete()
        
        sendSystem(liveId: liveId, text: "⛔️ \(username) a été exclu du live")
    }
    
    func removeMessage(liveId: String, messageId: String) {
        db.collection("lives")
            .document(liveId)
            .collection("messages")
            .document(messageId)
            .updateData([
                "text": "Message supprimé par la modération",
                "type": "deleted",
                "deletedAt": Timestamp()
            ])
    }
}

// MARK: - ANTI-SPAM

extension LiveModerationService {
    
    func flagSpam(liveId: String, userId: String, username: String, reason: String) {
        db.collection("lives")
            .document(liveId)
            .collection("spamReports")
            .addDocument(data: [
                "userId": userId,
                "username": username,
                "reason": reason,
                "createdAt": Timestamp()
            ])
        
        sendSystem(liveId: liveId, text: "⚠️ Activité suspecte détectée pour \(username)")
    }
    
    func slowMode(liveId: String, seconds: Int) {
        db.collection("lives")
            .document(liveId)
            .setData([
                "slowModeSeconds": seconds,
                "updatedAt": Timestamp()
            ], merge: true)
        
        sendSystem(liveId: liveId, text: "🐢 Mode lent activé : \(seconds)s entre chaque message")
    }
    
    func disableSlowMode(liveId: String) {
        db.collection("lives")
            .document(liveId)
            .setData([
                "slowModeSeconds": 0,
                "updatedAt": Timestamp()
            ], merge: true)
        
        sendSystem(liveId: liveId, text: "✅ Mode lent désactivé")
    }
}

// MARK: - HOST TOOLS

extension LiveModerationService {
    
    func lockChat(liveId: String) {
        db.collection("lives")
            .document(liveId)
            .setData([
                "chatLocked": true,
                "updatedAt": Timestamp()
            ], merge: true)
        
        sendSystem(liveId: liveId, text: "🔒 Le chat est verrouillé")
    }
    
    func unlockChat(liveId: String) {
        db.collection("lives")
            .document(liveId)
            .setData([
                "chatLocked": false,
                "updatedAt": Timestamp()
            ], merge: true)
        
        sendSystem(liveId: liveId, text: "🔓 Le chat est ouvert")
    }
    
    func clearChat(liveId: String) {
        sendSystem(liveId: liveId, text: "🧹 Le chat a été nettoyé par la modération")
    }
}

// MARK: - PRIVATE

extension LiveModerationService {
    
    private func sendSystem(liveId: String, text: String) {
        db.collection("lives")
            .document(liveId)
            .collection("messages")
            .addDocument(data: [
                "text": text,
                "senderId": "system",
                "senderName": "Modération",
                "type": "system",
                "createdAt": Timestamp()
            ])
    }
}
