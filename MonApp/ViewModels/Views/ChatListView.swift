import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatListView: View {
    
    @StateObject private var service = ConversationService()
    
    @State private var names: [String: String] = [:]
    @State private var avatars: [String: String] = [:]
    
    var body: some View {
        NavigationStack {
            List(service.conversations) { convo in
                
                let otherId = otherParticipantId(convo)
                let unread = convo.unreadCounts?[Auth.auth().currentUser?.uid ?? ""] ?? 0
                
                NavigationLink(
                    destination: MessageDetailView(
                        conversationId: convo.id ?? "",
                        otherUserName: names[otherId] ?? "Discussion"
                    )
                ) {
                    HStack(spacing: 12) {
                        
                        AsyncImage(url: URL(string: avatars[otherId] ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(names[otherId] ?? "Chargement...")
                                .font(.headline)
                            
                            Text(convo.lastMessage.isEmpty ? "Nouveau message" : convo.lastMessage)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 6) {
                            
                            if let date = convo.lastMessageDate?.dateValue() {
                                Text(formatConversationTime(date))
                                    .font(.caption)
                                    .foregroundColor(unread > 0 ? .green : .gray)
                            }
                            
                            if unread > 0 {
                                Text("\(unread)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Messages")
            .onAppear {
                service.listenConversations()
            }
            .onReceive(service.$conversations) { conversations in
                if !conversations.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        loadNamesAndAvatars()
                    }
                }
            }
        }
    }
    
    func otherParticipantId(_ convo: Conversation) -> String {
        guard let myId = Auth.auth().currentUser?.uid else { return "" }
        return convo.participants.first(where: { $0 != myId }) ?? ""
    }
    
    func loadNamesAndAvatars() {
        let db = Firestore.firestore()
        
        for convo in service.conversations {
            let otherId = otherParticipantId(convo)
            
            if otherId.isEmpty { continue }
            
            
            db.collection("users").document(otherId).getDocument { snap, _ in
                let data = snap?.data() ?? [:]
                
                DispatchQueue.main.async {
                    self.names[otherId] = data["name"] as? String
                    ?? data["fullName"] as? String
                    ?? "Utilisateur"
                    
                    self.avatars[otherId] = data["imageUrl"] as? String
                    ?? data["profileImageUrl"] as? String
                    ?? ""
                }
            }
        }
    }
    
    func formatConversationTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")

        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "dd/MM"
        }

        return formatter.string(from: date)
    }
    
}
