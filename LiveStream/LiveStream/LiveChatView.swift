import SwiftUI
import FirebaseAuth

struct LiveChatView: View {
    
    let liveId: String
    
    @StateObject private var chatService = LiveChatService()
    
    @State private var isUserReadingOldMessages = false
    @State private var showGoBottomButton = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        
                        ForEach(chatService.messages) { message in
                            messageRow(message)
                                .id(message.id)
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id("BOTTOM_CHAT")
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                }
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { _ in
                            isUserReadingOldMessages = true
                            showGoBottomButton = true
                        }
                )
                .onChange(of: chatService.messages.count) { _ in
                    if !isUserReadingOldMessages {
                        scrollToBottom(proxy)
                    } else {
                        showGoBottomButton = true
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        scrollToBottom(proxy)
                    }
                }
                
                if showGoBottomButton {
                    Button {
                        isUserReadingOldMessages = false
                        showGoBottomButton = false
                        scrollToBottom(proxy)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(maxHeight: 260)
        .onAppear {
            chatService.startListening(liveId: liveId)
            print("💬 LiveChatView écoute liveId =", liveId)
        }
        .onDisappear {
            chatService.stopAll()
        }
    }
}

// MARK: - MESSAGE ROW

extension LiveChatView {
    
    @ViewBuilder
    func messageRow(_ message: ChatMessage) -> some View {
        
        switch message.type {
            
        case .text:
            normalMessageRow(message)
            
        case .join:
            compactSystemRow(
                icon: "👋",
                text: "\(message.senderName) a rejoint",
                color: .green
            )
            
        case .like:
            compactSystemRow(
                icon: "❤️",
                text: "\(message.senderName) a aimé le live",
                color: .pink
            )
            
        case .system:
            compactSystemRow(
                icon: "",
                text: message.text,
                color: .yellow
            )
            
        case .gift:
            giftMessageRow(message)
            
        case .request:
            requestMessageRow(message)
        }
    }
    
    func normalMessageRow(_ message: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 7) {
            
            avatarView(message)
            
            VStack(alignment: .leading, spacing: 3) {
                
                HStack(spacing: 5) {
                    Text(displayName(message))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(nameColor(message))
                    
                    if message.isModerator {
                        badge("MOD", color: .blue)
                    }
                    
                    if message.isVIP {
                        badge("VIP", color: .yellow)
                    }
                }
                
                Text(message.text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.48))
        .cornerRadius(14)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.66, alignment: .leading)
    }
    
    func giftMessageRow(_ message: ChatMessage) -> some View {
        HStack(spacing: 8) {
            
            avatarView(message)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(displayName(message))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.yellow)
                
                Text("a envoyé \(message.giftName ?? "un cadeau") 🎁")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.75),
                    Color.pink.opacity(0.55),
                    Color.black.opacity(0.45)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.72, alignment: .leading)
    }
    
    func requestMessageRow(_ message: ChatMessage) -> some View {
        HStack(spacing: 8) {
            
            avatarView(message)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName(message))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
                
                Text("souhaite monter dans le live 🙋")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.48))
        .cornerRadius(16)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.72, alignment: .leading)
    }
    
    func compactSystemRow(icon: String, text: String, color: Color) -> some View {
        Text("\(icon) \(text)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.72, alignment: .leading)
    }
}

// MARK: - SMALL COMPONENTS

extension LiveChatView {
    
    func avatarView(_ message: ChatMessage) -> some View {
        Group {
            if let avatar = message.senderAvatar,
               !avatar.isEmpty,
               let url = URL(string: avatar) {
                
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    avatarFallback(message)
                }
                .frame(width: 26, height: 26)
                .clipShape(Circle())
                
            } else {
                avatarFallback(message)
            }
        }
    }
    
    func avatarFallback(_ message: ChatMessage) -> some View {
        Circle()
            .fill(Color.gray.opacity(0.5))
            .frame(width: 26, height: 26)
            .overlay(
                Text(String(displayName(message).prefix(1)).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .black))
            .foregroundColor(.black)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(5)
    }
    
    func displayName(_ message: ChatMessage) -> String {
        message.senderName.isEmpty ? "Utilisateur" : message.senderName
    }
    
    func nameColor(_ message: ChatMessage) -> Color {
        if message.isModerator { return .blue }
        if message.isVIP { return .yellow }
        if message.isMine { return .cyan }
        return .white
    }
}

// MARK: - SCROLL

extension LiveChatView {
    
    func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo("BOTTOM_CHAT", anchor: .bottom)
            }
        }
    }
}
