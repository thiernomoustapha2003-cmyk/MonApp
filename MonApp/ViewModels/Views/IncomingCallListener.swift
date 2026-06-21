//
//  IncomingCallListener.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 21/06/2026.
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
    @Published var callType: String?

    private var listener: ListenerRegistration?

    func startListening() {

        print("📞 IncomingCallListener lancé")

        guard let uid = Auth.auth().currentUser?.uid else {

            print("❌ Aucun utilisateur connecté")
            return
        }

        print("✅ UID connecté =", uid)

        listener?.remove()

        listener = Firestore.firestore()
            .collection("calls")
            .whereField("receiverId", isEqualTo: uid)
            .whereField("status", isEqualTo: "ringing")
            .addSnapshotListener { snapshot, error in

                guard let doc = snapshot?.documents.first else { return }

                let data = doc.data()

                DispatchQueue.main.async {

                    self.incomingCallId = doc.documentID
                    self.conversationId = data["conversationId"] as? String
                    self.callerId = data["callerId"] as? String
                    self.callType = data["type"] as? String

                    print("📲 APPEL ENTRANT DÉTECTÉ :", doc.documentID)
                }
            }
    }
}
