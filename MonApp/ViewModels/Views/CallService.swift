//
//  CallService.swift
//  MonApp
//
//  Service Firestore UNIQUEMENT pour la signalisation des appels.
//  IMPORTANT :
//  - CallService = statut appel / Firestore / historique
//  - CallAgoraManager = audio/vidéo Agora
//  - LiveAgoraManager = lives TikTok uniquement
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class CallService {

    static let shared = CallService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - START CALL

    func startCall(
        conversationId: String,
        receiverName: String,
        type: String,
        completion: @escaping (String?) -> Void = { _ in }
    ) {
        guard let callerId = Auth.auth().currentUser?.uid else {
            print("❌ startCall: utilisateur non connecté")
            completion(nil)
            return
        }

        let conversationRef = db.collection("conversations").document(conversationId)
        let callRef = db.collection("calls").document()
        let callId = callRef.documentID
        let now = Timestamp(date: Date())

        db.runTransaction({ transaction, errorPointer in

            let conversationSnapshot: DocumentSnapshot

            do {
                conversationSnapshot = try transaction.getDocument(conversationRef)
            } catch let error {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let data = conversationSnapshot.data() ?? [:]

            // 🔒 ANTI-DOUBLE APPEL PROPRE
            if let activeCallId = data["activeCallId"] as? String,
               !activeCallId.isEmpty {

                let activeCallRef = self.db.collection("calls").document(activeCallId)

                do {
                    let activeCallSnapshot = try transaction.getDocument(activeCallRef)
                    let activeCallData = activeCallSnapshot.data() ?? [:]
                    let activeStatus = activeCallData["status"] as? String ?? ""

                    if activeCallSnapshot.exists &&
                        ["ringing", "accepted", "ongoing"].contains(activeStatus) {

                        errorPointer?.pointee = NSError(
                            domain: "CallService",
                            code: 409,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Un appel est déjà en cours dans cette conversation"
                            ]
                        )
                        return nil
                    }

                    // ✅ L'ancien activeCallId est mort/terminé, on le nettoie
                    transaction.updateData([
                        "activeCallId": FieldValue.delete(),
                        "activeCallType": FieldValue.delete(),
                        "activeCallStatus": FieldValue.delete(),
                        "activeCallUpdatedAt": FieldValue.delete()
                    ], forDocument: conversationRef)

                } catch let error {
                    print("⚠️ activeCall introuvable, nettoyage:", error.localizedDescription)

                    transaction.updateData([
                        "activeCallId": FieldValue.delete(),
                        "activeCallType": FieldValue.delete(),
                        "activeCallStatus": FieldValue.delete(),
                        "activeCallUpdatedAt": FieldValue.delete()
                    ], forDocument: conversationRef)
                }
            }

            let participants = data["participants"] as? [String] ?? []
            let receiverId = participants.first(where: { $0 != callerId }) ?? ""

            guard !receiverId.isEmpty else {
                errorPointer?.pointee = NSError(
                    domain: "CallService",
                    code: 400,
                    userInfo: [
                        NSLocalizedDescriptionKey: "receiverId introuvable"
                    ]
                )
                return nil
            }

            let callData: [String: Any] = [
                "callId": callId,
                "conversationId": conversationId,
                "callerId": callerId,
                "receiverId": receiverId,
                "receiverName": receiverName,
                "callerName": Auth.auth().currentUser?.displayName
                    ?? Auth.auth().currentUser?.email
                    ?? "Utilisateur Cutly",
                "type": type,
                "status": "ringing",
                "duration": 0,
                "createdAt": now,
                "ringingAt": now,
                "acceptedAt": NSNull(),
                "startedAt": NSNull(),
                "endedAt": NSNull(),
                "historyMessageSaved": false,
                "missedMessageSaved": false
            ]

            transaction.setData(callData, forDocument: callRef)

            transaction.updateData([
                "activeCallId": callId,
                "activeCallType": type,
                "activeCallStatus": "ringing",
                "activeCallUpdatedAt": now
            ], forDocument: conversationRef)

            return callId

        }) { result, error in

            if let error = error {
                print("❌ startCall:", error.localizedDescription)
                completion(nil)
                return
            }

            let createdCallId = result as? String ?? callId

            print("📞 Appel créé sans doublon:", createdCallId)

            self.scheduleMissedCallCheck(
                callId: createdCallId,
                conversationId: conversationId,
                type: type
            )

            completion(createdCallId)
        }
    }
    // MARK: - ACCEPT CALL

    func acceptCall(callId: String) {
        let callRef = db.collection("calls").document(callId)

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot

            do {
                snapshot = try transaction.getDocument(callRef)
            } catch let error {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let data = snapshot.data() ?? [:]
            let status = data["status"] as? String ?? ""
            let conversationId = data["conversationId"] as? String ?? ""

            if status == "accepted" || status == "ongoing" {
                print("⏭️ acceptCall ignoré, déjà accepté:", status)
                return nil
            }

            if status == "ended" || status == "declined" || status == "missed" {
                print("⏭️ acceptCall impossible, appel déjà terminé:", status)
                return nil
            }

            let now = Timestamp(date: Date())

            transaction.updateData([
                "status": "accepted",
                "acceptedAt": now,
                "startedAt": now
            ], forDocument: callRef)

            if !conversationId.isEmpty {
                let conversationRef = self.db.collection("conversations").document(conversationId)

                transaction.updateData([
                    "activeCallId": callId,
                    "activeCallStatus": "accepted",
                    "activeCallUpdatedAt": now
                ], forDocument: conversationRef)
            }

            return nil

        }) { _, error in
            if let error = error {
                print("❌ acceptCall:", error.localizedDescription)
            } else {
                print("✅ Appel accepté")
            }
        }
    }
    // MARK: - DECLINE CALL

    func declineCall(callId: String) {
        let callRef = db.collection("calls").document(callId)

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot

            do {
                snapshot = try transaction.getDocument(callRef)
            } catch let error {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let data = snapshot.data() ?? [:]
            let status = data["status"] as? String ?? ""
            let conversationId = data["conversationId"] as? String ?? ""

            if status == "ended" || status == "declined" || status == "missed" {
                print("⏭️ declineCall ignoré, déjà terminé:", status)
                return nil
            }

            let now = Timestamp(date: Date())

            transaction.updateData([
                "status": "declined",
                "duration": 0,
                "endedAt": now
            ], forDocument: callRef)

            if !conversationId.isEmpty {
                let conversationRef = self.db.collection("conversations").document(conversationId)

                transaction.updateData([
                    "activeCallId": FieldValue.delete(),
                    "activeCallType": FieldValue.delete(),
                    "activeCallStatus": FieldValue.delete(),
                    "activeCallUpdatedAt": FieldValue.delete()
                ], forDocument: conversationRef)
            }

            return nil

        }) { _, error in
            if let error = error {
                print("❌ declineCall:", error.localizedDescription)
            } else {
                print("📴 Appel refusé")
            }
        }
    }

    // MARK: - END CALL

    func endCall(
        callId: String,
        conversationId: String,
        type: String,
        duration: Int
    ) {
        let callRef = db.collection("calls").document(callId)
        let conversationRef = db.collection("conversations").document(conversationId)
        let safeDuration = max(0, duration)

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot

            do {
                snapshot = try transaction.getDocument(callRef)
            } catch let error {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let data = snapshot.data() ?? [:]
            let status = data["status"] as? String ?? ""
            let alreadySaved = data["historyMessageSaved"] as? Bool ?? false

            if status == "ended" {
                print("⏭️ endCall ignoré, déjà ended")
                return false
            }

            let now = Timestamp(date: Date())

            transaction.updateData([
                "status": "ended",
                "duration": safeDuration,
                "endedAt": now,
                "historyMessageSaved": true
            ], forDocument: callRef)

            transaction.updateData([
                "activeCallId": FieldValue.delete(),
                "activeCallType": FieldValue.delete(),
                "activeCallStatus": FieldValue.delete(),
                "activeCallUpdatedAt": FieldValue.delete()
            ], forDocument: conversationRef)

            return !alreadySaved

        }) { result, error in
            if let error = error {
                print("❌ endCall:", error.localizedDescription)
                return
            }

            let shouldSaveMessage = result as? Bool ?? false

            if shouldSaveMessage {
                self.saveCallMessage(
                    conversationId: conversationId,
                    type: type,
                    duration: safeDuration,
                    missed: false
                )
            }

            print("📴 Appel terminé")
        }
    }
    // MARK: - MISSED CALL CHECK

    private func scheduleMissedCallCheck(
        callId: String,
        conversationId: String,
        type: String
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) {
            let callRef = self.db.collection("calls").document(callId)

            self.db.runTransaction({ transaction, errorPointer in
                let snapshot: DocumentSnapshot

                do {
                    snapshot = try transaction.getDocument(callRef)
                } catch let error {
                    errorPointer?.pointee = error as NSError
                    return nil
                }

                let data = snapshot.data() ?? [:]
                let status = data["status"] as? String ?? ""
                let missedSaved = data["missedMessageSaved"] as? Bool ?? false

                guard status == "ringing" else {
                    print("⏭️ Appel déjà traité:", status)
                    return false
                }

                let now = Timestamp(date: Date())
                let conversationRef = self.db.collection("conversations").document(conversationId)

                transaction.updateData([
                    "status": "missed",
                    "duration": 0,
                    "endedAt": now,
                    "missedMessageSaved": true,
                    "historyMessageSaved": true
                ], forDocument: callRef)

                transaction.updateData([
                    "activeCallId": FieldValue.delete(),
                    "activeCallType": FieldValue.delete(),
                    "activeCallStatus": FieldValue.delete(),
                    "activeCallUpdatedAt": FieldValue.delete()
                ], forDocument: conversationRef)

                return !missedSaved

            }) { result, error in
                if let error = error {
                    print("❌ missed check:", error.localizedDescription)
                    return
                }

                let shouldSaveMessage = result as? Bool ?? false

                if shouldSaveMessage {
                    print("☎️ Appel manqué automatiquement")
                    self.saveMissedCall(
                        conversationId: conversationId,
                        type: type
                    )
                }
            }
        }
    }

    // MARK: - SAVE MISSED CALL

    func saveMissedCall(conversationId: String, type: String) {
        saveCallMessage(
            conversationId: conversationId,
            type: type,
            duration: 0,
            missed: true
        )
    }

    // MARK: - HISTORY MESSAGE

    private func saveCallMessage(
        conversationId: String,
        type: String,
        duration: Int,
        missed: Bool = false
    ) {
        let messageId = UUID().uuidString
        let now = Timestamp(date: Date())

        let text: String

        if missed {
            text = type == "video"
            ? "📹 Appel vidéo manqué"
            : "📞 Appel audio manqué"
        } else {
            text = type == "video"
            ? "📹 Appel vidéo • \(formatDuration(duration))"
            : "📞 Appel audio • \(formatDuration(duration))"
        }

        let messageData: [String: Any] = [
            "senderId": "system",
            "senderName": "system",

            // UI WhatsApp-like : plus court
            "text": text,

            // IMPORTANT :
            // type = call pour pouvoir afficher une bulle compacte plus tard
            "type": "call",

            "callType": type,
            "callStatus": missed ? "missed" : "ended",
            "callDuration": duration,

            "createdAt": now,
            "seenBy": []
        ]

        let conversationRef = db.collection("conversations").document(conversationId)

        conversationRef
            .collection("messages")
            .document(messageId)
            .setData(messageData)

        conversationRef.updateData([
            "lastMessage": text,
            "lastMessagePreview": text,
            "lastMessageType": "call",
            "updatedAt": now
        ])

        print("✅ Historique appel enregistré:", text)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let safe = max(0, seconds)
        let h = safe / 3600
        let m = (safe % 3600) / 60
        let s = safe % 60

        if h > 0 {
            return String(format: "%dh %02dm %02ds", h, m, s)
        }

        if m > 0 {
            return String(format: "%dm %02ds", m, s)
        }

        return "\(s)s"
    }
}
