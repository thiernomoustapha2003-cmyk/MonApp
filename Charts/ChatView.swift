import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {

    let conversationId: String

    @State private var messages: [ChatMessage] = []
    @State private var otherUserName = "..."
    @State private var messageText = ""

    var body: some View {
        VStack {

            // ===== LISTE MESSAGES =====
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {

                        ForEach(messages) { message in
                            HStack {

                                // 🔵 MESSAGE MOI (droite)
                                if message.senderId == Auth.auth().currentUser?.uid {

                                    Spacer()

                                    Text(message.text)
                                        .padding(12)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(14)
                                }

                                // ⚪️ MESSAGE AUTRE (gauche)
                                else {
                                    Text(message.text)
                                        .padding(12)
                                        .background(Color.gray.opacity(0.25))
                                        .cornerRadius(14)

                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                            .id(message.id)
                        }

                    }
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last?.id {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }

            // ===== BARRE ENVOI =====
            HStack {
                TextField("Message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)

                Button("Envoyer") {
                    sendMessage()
                }
            }
            .padding()
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            listenMessages()

            ChatUserService.fetchOtherUserName(conversationId: conversationId) { name in
                self.otherUserName = name
            }
        }
    }
}

// MARK: - FIRESTORE
extension ChatView {

    func listenMessages() {
        Firestore.firestore()
            .collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "createdAt")
            .addSnapshotListener { snapshot, _ in

                guard let documents = snapshot?.documents else { return }

                self.messages = documents.compactMap { doc in
                    ChatMessage.fromFirestore(
                        id: doc.documentID,
                        data: doc.data()
                    )
                }
            }
    }

    func sendMessage() {
        guard let user = Auth.auth().currentUser,
              !messageText.trimmingCharacters(in: .whitespaces).isEmpty
        else { return }

        let text = messageText
        messageText = ""

        let db = Firestore.firestore()

        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .addDocument(data: [
                "text": text,
                "senderId": user.uid,
                "createdAt": Timestamp(date: Date())
            ])

        // mise à jour aperçu conversation
        db.collection("conversations")
            .document(conversationId)
            .updateData([
                "lastMessage": text,
                "lastSenderId": user.uid,
                "updatedAt": Timestamp(date: Date())
            ])
    }
}
