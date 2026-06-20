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
                            
                            if message.type == .system || message.senderId == "system" {
                                Text(message.text)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.12))
                                    .cornerRadius(10)
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    .id(message.id)
                            } else {
                                HStack {
                                    if message.isMine {
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(message.text)
                                                .padding(12)
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(14)
                                            
                                            Text(formatMessageTime(message.createdAt))
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    } else {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(message.senderName)
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                            
                                            Text(message.text)
                                                .padding(12)
                                                .background(Color.gray.opacity(0.25))
                                                .foregroundColor(.primary)
                                                .cornerRadius(14)
                                            
                                            Text(formatMessageTime(message.createdAt))
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                                .id(message.id)
                            }
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
                "lastMessageDate": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date()),
                "unreadFor": FieldValue.arrayUnion(
                    messages.first?.senderId == user.uid ? [] : []
                )
            ])
    }
    func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "dd/MM HH:mm"
        }
        
        return formatter.string(from: date)
    }
}
