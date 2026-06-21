//
//  CallService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 21/06/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class CallService {
    static let shared = CallService()
    private let db = Firestore.firestore()

    private init() {}

    func startCall(conversationId: String, receiverName: String, type: String, completion: @escaping (String?) -> Void = { _ in }) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }

        db.collection("conversations").document(conversationId).getDocument { snap, _ in
            let data = snap?.data() ?? [:]
            let participants = data["participants"] as? [String] ?? []
            let receiverId = participants.first(where: { $0 != uid }) ?? ""

            guard !receiverId.isEmpty else {
                completion(nil)
                return
            }

            let callId = UUID().uuidString

            self.db.collection("calls").document(callId).setData([
                "callId": callId,
                "conversationId": conversationId,
                "callerId": uid,
                "receiverId": receiverId,
                "type": type,
                "status": "ringing",
                "startedAt": Timestamp(date: Date()),
                "createdAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("❌ startCall:", error.localizedDescription)
                    completion(nil)
                } else {
                    completion(callId)
                }
            }
        }
    }

    func acceptCall(callId: String) {
        db.collection("calls").document(callId).updateData([
            "status": "accepted",
            "acceptedAt": Timestamp(date: Date())
        ])
    }

    func declineCall(callId: String) {
        db.collection("calls").document(callId).updateData([
            "status": "declined",
            "endedAt": Timestamp(date: Date())
        ])
    }

    func endCall(callId: String, conversationId: String, type: String, duration: Int) {
        db.collection("calls").document(callId).updateData([
            "status": "ended",
            "duration": duration,
            "endedAt": Timestamp(date: Date())
        ])

        saveCallMessage(
            conversationId: conversationId,
            type: type,
            duration: duration
        )
    }

    func saveMissedCall(conversationId: String, type: String) {
        saveCallMessage(
            conversationId: conversationId,
            type: type,
            duration: 0,
            missed: true
        )
    }

    private func saveCallMessage(conversationId: String, type: String, duration: Int, missed: Bool = false) {
        let messageId = UUID().uuidString
        let now = Timestamp(date: Date())

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd/MM/yyyy à HH:mm"

        let dateText = formatter.string(from: Date())

        let text: String
        if missed {
            text = type == "video"
            ? "🎥 Appel vidéo manqué • \(dateText)"
            : "📞 Appel audio manqué • \(dateText)"
        } else {
            let min = duration / 60
            let sec = duration % 60

            text = type == "video"
            ? "🎥 Appel vidéo terminé • \(min)m \(sec)s • \(dateText)"
            : "📞 Appel audio terminé • \(min)m \(sec)s • \(dateText)"
        }

        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .setData([
                "senderId": "system",
                "senderName": "system",
                "text": text,
                "type": "system",
                "createdAt": now,
                "seenBy": []
            ])

        db.collection("conversations")
            .document(conversationId)
            .updateData([
                "lastMessage": text,
                "lastMessagePreview": text,
                "lastMessageType": "call",
                "updatedAt": now
            ])
    }
}
