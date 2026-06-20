//
//  ChatPresenceService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 19/06/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class ChatPresenceService {
    
    static let shared = ChatPresenceService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    func setTyping(conversationId: String, isTyping: Bool) {
        updatePresence(conversationId: conversationId, data: [
            "isTyping": isTyping,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    func setRecording(conversationId: String, isRecording: Bool) {
        updatePresence(conversationId: conversationId, data: [
            "isRecordingAudio": isRecording,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    func setListening(conversationId: String, messageId: String?) {
        var data: [String: Any] = [
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let messageId = messageId {
            data["listeningMessageId"] = messageId
        } else {
            data["listeningMessageId"] = FieldValue.delete()
        }
        
        updatePresence(conversationId: conversationId, data: data)
    }
    
    private func updatePresence(conversationId: String, data: [String: Any]) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("conversations")
            .document(conversationId)
            .collection("presence")
            .document(uid)
            .setData(data, merge: true)
    }
    
    func setListeningProgress(conversationId: String, messageId: String?, progress: Double) {
        var data: [String: Any] = [
            "updatedAt": Timestamp(date: Date())
        ]

        if let messageId = messageId {
            data["listeningMessageId"] = messageId
            data["listeningProgress"] = progress
        } else {
            data["listeningMessageId"] = FieldValue.delete()
            data["listeningProgress"] = FieldValue.delete()
        }

        updatePresence(conversationId: conversationId, data: data)
    }
    
    
}
