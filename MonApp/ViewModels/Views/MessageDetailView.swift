import SwiftUI
import Firebase
import FirebaseAuth

struct MessageDetailView: View {

    let conversationId: String
    let otherUserName: String

    @State private var messageText = ""
    @State private var messages: [Message] = []

    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var body: some View {
        VStack {

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {

                        ForEach(messages) { message in

                            HStack {

                                if message.senderId == currentUserId {
                                    Spacer()
                                }

                                Text(message.text)
                                    .padding(12)
                                    .background(message.senderId == currentUserId ? Color.blue : Color.gray.opacity(0.25))
                                    .foregroundColor(message.senderId == currentUserId ? .white : .black)
                                    .cornerRadius(14)
                                    .frame(maxWidth: 260, alignment: message.senderId == currentUserId ? .trailing : .leading)

                                if message.senderId != currentUserId {
                                    Spacer()
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            HStack {

                TextField("Message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Envoyer") {
                    sendMessage()
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            listenMessages()
        }
    }
}

// MARK: - FIRESTORE

extension MessageDetailView {

    func listenMessages() {

        let db = Firestore.firestore()

        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "createdAt")
            .addSnapshotListener { snapshot, _ in

                guard let docs = snapshot?.documents else { return }

                self.messages = docs.map { doc in
                    let data = doc.data()

                    return Message(
                        id: doc.documentID,
                        senderId: data["senderId"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        timestamp: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
            }
    }
    
    
    func sendMessage() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let db = Firestore.firestore()

        let messageId = UUID().uuidString

        let messageData: [String: Any] = [
            "senderId": currentUserId,
            "text": text,
            "createdAt": Timestamp(date: Date())
        ]

        do {
            db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .document(messageId)
                .setData(messageData)
            db.collection("conversations")
                .document(conversationId)
                .updateData([
                    "lastMessage": text,
                    "lastSenderId": currentUserId,
                    "updatedAt": Timestamp()
                ])

            messageText = ""

        } catch {
            print("Erreur envoi message:", error)
        }
    }
}

