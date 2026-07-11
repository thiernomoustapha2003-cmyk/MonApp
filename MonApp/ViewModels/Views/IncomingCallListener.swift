//
//  IncomingCallListener.swift
//  MonApp
//
//  Listener global des appels entrants.
//  IMPORTANT :
//  - Sert à détecter les appels entrants même hors MessageDetailView.
//  - Ne gère pas Agora.
//  - Ne gère pas les Lives TikTok.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

final class IncomingCallListener: ObservableObject {

    static let shared = IncomingCallListener()

    @Published var incomingCallId: String?
    @Published var conversationId: String?
    @Published var callerId: String?
    @Published var callerName: String?
    @Published var callType: String?
    @Published var callStatus: String?

    private var listener: ListenerRegistration?
    private var activeCallId: String?
    private var handledCallIds = Set<String>()

    private init() {}

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ IncomingCallListener: aucun utilisateur connecté")
            return
        }

        print("📞 IncomingCallListener lancé uid =", uid)

        listener?.remove()

        listener = Firestore.firestore()
            .collection("calls")
            .whereField("receiverId", isEqualTo: uid)
            .whereField("status", isEqualTo: "ringing")
            .addSnapshotListener { snapshot, error in

                if let error = error {
                    print("❌ IncomingCallListener error:", error.localizedDescription)
                    return
                }

                guard let changes = snapshot?.documentChanges else { return }

                for change in changes {
                    guard change.type == .added || change.type == .modified else { continue }

                    let doc = change.document
                    let data = doc.data()
                    let callId = doc.documentID
                    let status = data["status"] as? String ?? ""

                    guard status == "ringing" else { continue }

                    DispatchQueue.main.async {
                        self.handleIncomingRinging(callId: callId, data: data)
                    }
                }
            }
    }

    private func handleIncomingRinging(callId: String, data: [String: Any]) {
        if handledCallIds.contains(callId) {
            print("⏭️ IncomingCallListener ignoré, déjà traité:", callId)
            return
        }

        if let activeCallId, activeCallId != callId {
            print("⏭️ Autre appel ignoré car déjà un appel actif:", activeCallId)
            return
        }

        handledCallIds.insert(callId)
        activeCallId = callId

        incomingCallId = callId
        conversationId = data["conversationId"] as? String
        callerId = data["callerId"] as? String
        callerName = data["callerName"] as? String ?? "Appel Cutly"
        callType = data["type"] as? String ?? "audio"
        callStatus = "ringing"

        print("📲 Appel entrant détecté une seule fois:", callId)
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func clearCurrentCall() {
        activeCallId = nil
        incomingCallId = nil
        conversationId = nil
        callerId = nil
        callerName = nil
        callType = nil
        callStatus = nil
    }
}
