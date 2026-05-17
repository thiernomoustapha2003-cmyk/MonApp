import SwiftUI
import FirebaseFirestore
import FirebaseAuth

//////////////////////////////////////////////////////////////
/// 🔥 LIVE ACTION (STYLE TIKTOK COMPLET)
//////////////////////////////////////////////////////////////

struct LiveAction: View {
    
    //////////////////////////////////////////////////////////
    /// 🎯 CONFIG
    //////////////////////////////////////////////////////////
    
    let icon: String
    let title: String
    var color: Color = .white
    var badge: String? = nil
    
    /// 👉 ACTION (ex: like, share, etc)
    var action: (() -> Void)? = nil
    
    //////////////////////////////////////////////////////////
    /// ❤️ HEART ANIMATION (LOCAL)
    //////////////////////////////////////////////////////////
    
    @State private var hearts: [UUID] = []
    
    //////////////////////////////////////////////////////////
    /// 📊 COUNTERS
    //////////////////////////////////////////////////////////
    
    var body: some View {
        
        ZStack {
            
            //////////////////////////////////////////////////////////
            /// 🎯 BOUTON PRINCIPAL
            //////////////////////////////////////////////////////////
            
            Button {
                
                //////////////////////////////////////////////////////////
                /// 🔥 ACTION PRINCIPALE
                //////////////////////////////////////////////////////////
                
                action?()
                
                //////////////////////////////////////////////////////////
                /// ❤️ SI C'EST UN LIKE → ANIMATION
                //////////////////////////////////////////////////////////
                
                if icon.contains("heart") {
                    spawnHeart()
                }
                
            } label: {
                
                VStack(spacing: 4) {
                    
                    ZStack {
                        
                        //////////////////////////////////////////////////////////
                        /// 🔥 ICON
                        //////////////////////////////////////////////////////////
                        
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                        
                        //////////////////////////////////////////////////////////
                        /// 🔴 BADGE (ex: cadeaux)
                        //////////////////////////////////////////////////////////
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 12, y: -12)
                        }
                    }
                    
                    //////////////////////////////////////////////////////////
                    /// 🔤 TEXTE
                    //////////////////////////////////////////////////////////
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            
            //////////////////////////////////////////////////////////
            /// ❤️ COEURS QUI VOLENT (OVERLAY)
            //////////////////////////////////////////////////////////
            
            ZStack {
                ForEach(hearts, id: \.self) { id in
                    LiveActionFloatingHeart()
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
/// ❤️ FONCTION SPAWN HEART
//////////////////////////////////////////////////////////////

extension LiveAction {
    
    func spawnHeart() {
        let id = UUID()
        hearts.append(id)
    }
}

//////////////////////////////////////////////////////////////
/// ❤️ ANIMATION COEUR (STYLE TIKTOK)
//////////////////////////////////////////////////////////////

struct LiveActionFloatingHeart: View {
    
    @State private var y: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var xOffset: CGFloat = CGFloat.random(in: -20...20)
    
    var body: some View {
        
        Image(systemName: "heart.fill")
            .foregroundColor(.pink)
            .font(.system(size: 22))
            .offset(x: xOffset, y: y)
            .opacity(opacity)
            .onAppear {
                
                withAnimation(.easeOut(duration: 1.5)) {
                    y = -250
                    opacity = 0
                }
            }
    }
}

//////////////////////////////////////////////////////////////
/// 🔥 FIRESTORE ACTIONS (UTILS)
//////////////////////////////////////////////////////////////

class LiveActionService {
    
    //////////////////////////////////////////////////////////
    /// ❤️ LIKE (INFINI STYLE TIKTOK)
    //////////////////////////////////////////////////////////
    
    static func sendLike(liveId: String) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "userId": uid,
            "createdAt": Timestamp()
        ]
        
        Firestore.firestore()
            .collection("lives")
            .document(liveId)
            .collection("likes")
            .addDocument(data: data)
    }
    
    //////////////////////////////////////////////////////////
    /// 📤 SHARE (INFINI)
    //////////////////////////////////////////////////////////
    
    static func sendShare(liveId: String) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "userId": uid,
            "createdAt": Timestamp()
        ]
        
        Firestore.firestore()
            .collection("lives")
            .document(liveId)
            .collection("shares")
            .addDocument(data: data)
    }
    
    //////////////////////////////////////////////////////////
    /// 👀 VIEWER (UNIQUE)
    //////////////////////////////////////////////////////////
    
    static func joinLive(liveId: String) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "joinedAt": Timestamp()
        ]
        
        Firestore.firestore()
            .collection("lives")
            .document(liveId)
            .collection("viewers")
            .document(uid)
            .setData(data)
    }
    
    //////////////////////////////////////////////////////////
    /// 💬 MESSAGE
    //////////////////////////////////////////////////////////
    
    static func sendMessage(liveId: String, text: String) {
        
        guard let user = Auth.auth().currentUser else { return }
        
        let data: [String: Any] = [
            "senderId": user.uid,
            "senderName": user.displayName ?? "User",
            "text": text,
            "type": "text",
            "createdAt": Timestamp()
        ]
        
        Firestore.firestore()
            .collection("lives")
            .document(liveId)
            .collection("messages")
            .addDocument(data: data)
    }
}
