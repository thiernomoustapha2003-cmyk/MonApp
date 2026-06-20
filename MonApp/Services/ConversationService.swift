import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ConversationService: ObservableObject {

    @Published var conversations: [Conversation] = []

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func listenConversations() {

        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ Aucun utilisateur connecté")
            return
        }

        listener?.remove()

        listener = db.collection("conversations")
            .whereField("participants", arrayContains: uid)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in

                if let error = error {
                    print("❌ Erreur conversations:", error.localizedDescription)
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("❌ Aucun document conversation")
                    return
                }

                DispatchQueue.main.async {
                    self.conversations = documents.compactMap { doc in
                        try? doc.data(as: Conversation.self)
                    }

                    print("📩 Conversations chargées:", self.conversations.count)
                }
            }
    }

    deinit {
        listener?.remove()
    }
}
