import SwiftUI
import FirebaseAuth

//////////////////////////////////////////////////////////////
/// 💬 INPUT CHAT (STYLE TIKTOK PRODUCTION)
//////////////////////////////////////////////////////////////

struct LiveChatInputView: View {
    
    //////////////////////////////////////////////////////////
    /// 🔥 CONFIG
    //////////////////////////////////////////////////////////
    
    let liveId: String
    @ObservedObject var chatService: LiveChatService
    
    //////////////////////////////////////////////////////////
    /// 🧠 STATE
    //////////////////////////////////////////////////////////
    
    @State private var messageText: String = ""
    @FocusState private var isFocused: Bool
    
    @State private var showEmoji = false
    
    //////////////////////////////////////////////////////////
    /// 🎯 BODY
    //////////////////////////////////////////////////////////
    
    var body: some View {
        
        VStack(spacing: 8) {
            
            //////////////////////////////////////////////////////////
            /// 💬 INPUT BAR
            //////////////////////////////////////////////////////////
            
            HStack(spacing: 8) {
                
                //////////////////////////////////////////////////////////
                /// 😎 AVATAR
                //////////////////////////////////////////////////////////
                
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 34, height: 34)
                
                //////////////////////////////////////////////////////////
                /// ✍️ TEXTFIELD
                //////////////////////////////////////////////////////////
                
                HStack {
                    
                    TextField("Écrire un commentaire...", text: $messageText)
                        .foregroundColor(.white)
                        .focused($isFocused)
                    
                    //////////////////////////////////////////////////////////
                    /// 😀 EMOJI BUTTON
                    //////////////////////////////////////////////////////////
                    
                    Button {
                        showEmoji.toggle()
                    } label: {
                        Image(systemName: "face.smiling")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
                
                //////////////////////////////////////////////////////////
                /// 📤 SEND BUTTON
                //////////////////////////////////////////////////////////
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal)
            
            //////////////////////////////////////////////////////////
            /// 😀 EMOJI PICKER (simple)
            //////////////////////////////////////////////////////////
            
            if showEmoji {
                
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    HStack(spacing: 12) {
                        
                        ForEach(["😂","🔥","❤️","👏","😍","😎","🎉","👍"], id: \.self) { emoji in
                            
                            Text(emoji)
                                .font(.title)
                                .onTapGesture {
                                    messageText += emoji
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

//////////////////////////////////////////////////////////////
/// 🔥 SEND MESSAGE FUNCTION
//////////////////////////////////////////////////////////////

extension LiveChatInputView {
    
    func sendMessage() {
        
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        chatService.sendMessage(liveId: liveId, text: messageText)
        
        messageText = ""
    }
}
