import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatListView: View {

    @StateObject private var service = ConversationService()
    @State private var names: [String: String] = [:]   // uid -> name cache

    var body: some View {
        NavigationStack {
            
            List(service.conversations) { convo in
                
                NavigationLink(
                    destination: MessageDetailView(
                        conversationId: convo.id ?? "",
                        otherUserName: otherParticipantName(convo)
                    )
                ) {
                    
                    VStack(alignment: .leading, spacing: 6) {
                        
                        Text(otherParticipantName(convo))
                            .font(.headline)
                        
                        Text(convo.lastMessage.isEmpty ? "Nouveau message" : convo.lastMessage)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Messages")
            .onAppear {
                service.listenConversations()
                loadNames()
            }
            .onAppear {
                print("MY UID =", Auth.auth().currentUser?.uid ?? "NO USER")
                service.listenConversations()
                loadNames()
            }
            
        }
    }

    // MARK: - Nom réel utilisateur
    func otherParticipantName(_ convo: Conversation) -> String {
        guard let myId = Auth.auth().currentUser?.uid else { return "Discussion" }

        let otherId = convo.participants.first(where: { $0 != myId }) ?? ""

        if let name = names[otherId] {
            return name
        }

        return "Chargement..."
    }

    // MARK: - Charger noms depuis Firestore
    private func loadNames() {

        let db = Firestore.firestore()

        for convo in service.conversations {

            for uid in convo.participants {

                if names[uid] != nil { continue }

                db.collection("users").document(uid).getDocument { snap, _ in
                    if let data = snap?.data() {
                        let name = data["name"] as? String
                        DispatchQueue.main.async {
                            names[uid] = name ?? "Utilisateur"
                        }
                    }
                }
            }
        }
    }
}
