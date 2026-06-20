import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class LiveChatService: ObservableObject {
    
    //////////////////////////////////////////////////////////
    // 📡 STATE
    //////////////////////////////////////////////////////////
    
    @Published var messages: [ChatMessage] = []
    @Published var likeCount: Int = 0
    @Published var viewerCount: Int = 0
    @Published var shareCount: Int = 0
    @Published var joinRequestCount: Int = 0
    
    
    
    private var joinRequestListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    private var messageListener: ListenerRegistration?
    private var likeListener: ListenerRegistration?
    private var viewerListener: ListenerRegistration?
    private var shareListener: ListenerRegistration?
    
    //////////////////////////////////////////////////////////
    // 🔥 START LISTENING GLOBAL
    //////////////////////////////////////////////////////////
    
    func startAll(liveId: String) {
        startMessages(liveId: liveId)
        startLikes(liveId: liveId)
        startViewers(liveId: liveId)
        startShares(liveId: liveId)
        startJoinRequests(liveId: liveId)
    }
    
    //////////////////////////////////////////////////////////
    // 💬 LISTEN MESSAGES
    //////////////////////////////////////////////////////////
    
    func startMessages(liveId: String) {
        
        messageListener?.remove()
        
        messageListener = db.collection("lives")
            .document(liveId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .limit(toLast: 40) // 🔥 optimisation
            .addSnapshotListener { snapshot, _ in
                
                guard let docs = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    self.messages = docs.compactMap {
                        ChatMessage.fromFirestore(
                            id: $0.documentID,
                            data: $0.data()
                        )
                    }
                }
            }
    }
    
    //////////////////////////////////////////////////////////
    // ❤️ LISTEN LIKES (REALTIME)
    //////////////////////////////////////////////////////////
    
    func startLikes(liveId: String) {
        
        likeListener?.remove()
        
        likeListener = db.collection("lives")
            .document(liveId)
            .collection("likes")
            .addSnapshotListener { snapshot, _ in
                
                DispatchQueue.main.async {
                    self.likeCount = snapshot?.documents.count ?? 0
                }
            }
    }
    
    //////////////////////////////////////////////////////////
    // 👀 LISTEN VIEWERS (UNIQUE)
    //////////////////////////////////////////////////////////
    
    func startViewers(liveId: String) {
        
        viewerListener?.remove()
        
        viewerListener = db.collection("lives")
            .document(liveId)
            .collection("viewers")
            .addSnapshotListener { snapshot, _ in
                
                DispatchQueue.main.async {
                    self.viewerCount = snapshot?.documents.count ?? 0
                }
            }
    }
    
    //////////////////////////////////////////////////////////
    // 📤 LISTEN SHARES
    //////////////////////////////////////////////////////////
    
    func startShares(liveId: String) {
        
        shareListener?.remove()
        
        shareListener = db.collection("lives")
            .document(liveId)
            .collection("shares")
            .addSnapshotListener { snapshot, _ in
                
                DispatchQueue.main.async {
                    self.shareCount = snapshot?.documents.count ?? 0
                }
            }
    }
    
    //////////////////////////////////////////////////////////
    // 🛑 STOP ALL
    //////////////////////////////////////////////////////////
    
    func stopAll() {
        messageListener?.remove()
        likeListener?.remove()
        viewerListener?.remove()
        shareListener?.remove()
        joinRequestListener?.remove()
    }
    
    //////////////////////////////////////////////////////////
    // ✍️ SEND MESSAGE
    //////////////////////////////////////////////////////////
    
    func sendMessage(liveId: String, text: String) {
        
        guard let user = Auth.auth().currentUser else { return }
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let data: [String: Any] = [
            "text": text,
            "senderId": user.uid,
            "senderName": user.displayName ?? "User",
            "senderAvatar": user.photoURL?.absoluteString ?? "",
            "type": "text",
            "createdAt": Timestamp()
        ]
        
        db.collection("lives")
            .document(liveId)
            .collection("messages")
            .addDocument(data: data)
    }
    
    //////////////////////////////////////////////////////////
    // 👋 JOIN
    //////////////////////////////////////////////////////////
    
    func sendJoin(liveId: String) {
        
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection("lives")
            .document(liveId)
            .collection("messages")
            .addDocument(data: [
                "text": "",
                "senderId": user.uid,
                "senderName": user.displayName ?? "User",
                "type": "join",
                "createdAt": Timestamp()
            ])
    }
    
    //////////////////////////////////////////////////////////
    // ❤️ LIKE (DOUBLE SYSTEM)
    //////////////////////////////////////////////////////////
    
    func sendLike(liveId: String) {
        
        guard let user = Auth.auth().currentUser else { return }
        
        // 1️⃣ animation chat (optionnel)
        
        
        // 2️⃣ vrai compteur
        db.collection("lives")
            .document(liveId)
            .collection("likes")
            .addDocument(data: [
                "userId": user.uid,
                "createdAt": Timestamp()
            ])
    }
    
    //////////////////////////////////////////////////////////
    // 📤 SHARE
    //////////////////////////////////////////////////////////
    
    func sendShare(liveId: String) {
        
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection("lives")
            .document(liveId)
            .collection("shares")
            .addDocument(data: [
                "userId": user.uid,
                "createdAt": Timestamp()
            ])
    }
    
    //////////////////////////////////////////////////////////
    // 👀 JOIN VIEWER (UNIQUE)
    //////////////////////////////////////////////////////////
    
    func joinViewer(liveId: String) {
        
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection("lives")
            .document(liveId)
            .collection("viewers")
            .document(user.uid) // 🔥 unique
            .setData([
                "joinedAt": Timestamp()
            ])
    }
    
    //////////////////////////////////////////////////////////
    // ⚙️ SYSTEM MESSAGE
    //////////////////////////////////////////////////////////
    
    func sendSystemMessage(liveId: String, text: String) {
        
        db.collection("lives")
            .document(liveId)
            .collection("messages")
            .addDocument(data: [
                "text": text,
                "senderId": "system",
                "senderName": "System",
                "type": "system",
                "createdAt": Timestamp()
            ])
    }
    // 🔥 COMPATIBILITÉ AVEC LE LIVE VIEW
    func startListening(liveId: String) {
        startAll(liveId: liveId)
    }
    
    //////////////////////////////////////////////////////////
    // 👀 LEAVE VIEWER
    //////////////////////////////////////////////////////////

    func leaveViewer(liveId: String) {
        
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection("lives")
            .document(liveId)
            .collection("viewers")
            .document(user.uid)
            .delete()
    }

    //////////////////////////////////////////////////////////
    // ❤️ MESSAGE LIKE LIMITÉ
    //////////////////////////////////////////////////////////

    func sendLikeMessageIfNeeded(liveId: String) {
        
        guard let user = Auth.auth().currentUser else { return }
        
        let ref = db.collection("lives")
            .document(liveId)
            .collection("likeMessagesCooldown")
            .document(user.uid)
        
        ref.getDocument { snapshot, _ in
            
            let now = Date()
            let lastDate = (snapshot?.data()?["lastSentAt"] as? Timestamp)?.dateValue()
            
            if let lastDate = lastDate,
               now.timeIntervalSince(lastDate) < 10 {
                return
            }
            
            let name = user.displayName?.isEmpty == false ? user.displayName! : "Utilisateur"
            
            self.sendSystemMessage(
                liveId: liveId,
                text: "❤️ \(name) a aimé le live"
            )
            
            ref.setData([
                "lastSentAt": Timestamp()
            ])
        }
    }

    //////////////////////////////////////////////////////////
    // 🙋 DEMANDE POUR MONTER DANS LE LIVE
    //////////////////////////////////////////////////////////

    func requestToJoinLive(liveId: String) {
        
        guard let user = Auth.auth().currentUser else { return }
        
        let username = user.displayName?.isEmpty == false
            ? user.displayName!
            : "Utilisateur"
        
        let avatar = user.photoURL?.absoluteString ?? ""
        
        db.collection("lives")
            .document(liveId)
            .collection("joinRequests")
            .document(user.uid)
            .setData([
                "userId": user.uid,
                "username": username,
                "avatar": avatar,
                "status": "pending",
                "createdAt": Timestamp(),
                "updatedAt": Timestamp()
            ]) { error in
                
                if let error = error {
                    print("❌ Erreur demande invité :", error.localizedDescription)
                    return
                }
                
                print("✅ Demande envoyée")
                
                // Notification dans le chat
                self.sendSystemMessage(
                    liveId: liveId,
                    text: "🙋 \(username) souhaite monter dans le live"
                )
            }
    }

    //////////////////////////////////////////////////////////
    // 📤 SHARE AVEC MESSAGE
    //////////////////////////////////////////////////////////

    func sendShareWithMessage(liveId: String) {
        
        guard let user = Auth.auth().currentUser else { return }
        
        sendShare(liveId: liveId)
        
        sendSystemMessage(
            liveId: liveId,
            text: "📤 \(user.displayName ?? "Un spectateur") a partagé le live"
        )
    }
    
    func startJoinRequests(liveId: String) {
        
        joinRequestListener?.remove()
        
        joinRequestListener = db.collection("lives")
            .document(liveId)
            .collection("joinRequests")
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { snapshot, _ in
                
                DispatchQueue.main.async {
                    self.joinRequestCount = snapshot?.documents.count ?? 0
                }
            }
    }
}
