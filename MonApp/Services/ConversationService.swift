import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ConversationService: ObservableObject {

    @Published var conversations: [Conversation] = []

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func listenConversations() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener?.remove()

        listener = db.collection("conversations")
            .whereField("participants", arrayContains: uid)
            .order(by: "lastMessageDate", descending: true)
            .addSnapshotListener { snapshot, error in

                guard let documents = snapshot?.documents else {
                    print("❌ No conversations")
                    return
                }

                self.conversations = documents.compactMap { doc in
                    try? doc.data(as: Conversation.self)
                }

                print("📩 Conversations chargées:", self.conversations.count)
            }
    }

    deinit {
        listener?.remove()
    }
}
