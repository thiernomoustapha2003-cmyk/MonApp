import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LiveChatView: View {
    
    let liveId: String
    
    @State private var messages: [ChatMessage] = []
    @State private var listener: ListenerRegistration?
    
    // ❤️ animation hearts
    @State private var hearts: [UUID] = []
    
    // 📊 compteur
    @State private var likeCount = 0
    @State private var viewerCount = 0
    
    var body: some View {
        
        ZStack {
            
            // =========================
            // 💬 CHAT
            // =========================
            VStack {
                
                ScrollViewReader { proxy in
                    
                    ScrollView(showsIndicators: false) {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            
                            ForEach(messages) { message in
                                messageRow(message)
                                    .id(message.id)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 6)
                    }
                    .onChange(of: messages.count) { _ in
                        scrollToBottom(proxy)
                    }
                }
                
                Spacer()
            }
            
            // =========================
            // ❤️ COEURS QUI VOLENT
            // =========================
            ZStack {
                ForEach(hearts, id: \.self) { id in
                    HeartView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                hearts.removeAll { $0 == id }
                            }
                        }
                }
            }
            
        }
    }
}

//////////////////////////////////////////////////////////////
// MARK: - MESSAGE ROW
//////////////////////////////////////////////////////////////

extension LiveChatView {
    
    @ViewBuilder
    func messageRow(_ message: ChatMessage) -> some View {
        
        switch message.type {
            
        case .text:
            
            HStack(alignment: .bottom, spacing: 6) {
                
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    
                    Text(message.senderName)
                        .font(.caption2)
                        .bold() // ✅ NOM EN GRAS
                        .foregroundColor(.white)
                    
                    Text(message.text)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.45))
            .cornerRadius(12)
            .opacity(0.95)
            
            
        case .join:
            
            Text("👋 \(message.senderName) a rejoint")
                .font(.caption)
                .foregroundColor(.green)
            
            
        case .like:
            
            Text("❤️ \(message.senderName) a aimé")
                .font(.caption)
                .foregroundColor(.pink)
            
            
        case .system:
            
            Text(message.text)
                .font(.caption)
                .foregroundColor(.yellow)
        }
    }
}

//////////////////////////////////////////////////////////////
// MARK: - FIRESTORE
//////////////////////////////////////////////////////////////

extension LiveChatView {
    
    func startListening() {
        
        listener = Firestore.firestore()
            .collection("lives")
            .document(liveId)
            .collection("messages")
            .order(by: "createdAt")
            .limit(toLast: 40)
            .addSnapshotListener { snapshot, _ in
                
                guard let documents = snapshot?.documents else { return }
                
                let newMessages = documents.compactMap {
                    ChatMessage.fromFirestore(id: $0.documentID, data: $0.data())
                }
                
                withAnimation {
                    self.messages = newMessages
                }
            }
    }
    
    // ❤️ LIKE REALTIME
    func listenLikes() {
        Firestore.firestore()
            .collection("lives")
            .document(liveId)
            .collection("likes")
            .addSnapshotListener { snapshot, _ in
                
                likeCount = snapshot?.documents.count ?? 0
                
                // 💥 animation coeur
                let id = UUID()
                hearts.append(id)
            }
    }
    
    // 👀 VIEWERS REALTIME
    func listenViewers() {
        Firestore.firestore()
            .collection("lives")
            .document(liveId)
            .collection("viewers")
            .addSnapshotListener { snapshot, _ in
                
                viewerCount = snapshot?.documents.count ?? 0
            }
    }
}

//////////////////////////////////////////////////////////////
// MARK: - SCROLL
//////////////////////////////////////////////////////////////

extension LiveChatView {
    
    func scrollToBottom(_ proxy: ScrollViewProxy) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let last = messages.last?.id {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
    }
}

//////////////////////////////////////////////////////////////
// MARK: - ❤️ HEART ANIMATION
//////////////////////////////////////////////////////////////

struct HeartView: View {
    
    @State private var y: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Image(systemName: "heart.fill")
            .foregroundColor(.pink)
            .font(.system(size: 24))
            .position(x: UIScreen.main.bounds.width - 40, y: UIScreen.main.bounds.height - 100 + y)
            .opacity(opacity)
            .onAppear {
                
                withAnimation(.easeOut(duration: 1.5)) {
                    y = -300
                    opacity = 0
                }
            }
    }
}
