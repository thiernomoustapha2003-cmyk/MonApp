import SwiftUI
import FirebaseAuth
import AVFoundation
import FirebaseFirestore

struct LiveViewerView: View {
    
    let live: LivePreviewModel
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatService = LiveChatService()
    @StateObject private var walletService = WalletService.shared
    
    @State private var giftsListener: ListenerRegistration?
    @State private var seenGiftIds: Set<String> = []
    
    
    @State private var myJoinRequestListener: ListenerRegistration?
    
    
    @StateObject private var agoraManager = LiveAgoraManager.shared
    
    @State private var showGifts = false
    @State private var showShop = false
    @State private var showAd = false
    
    @State private var activeGifts: [GiftItem] = []
    @State private var totalGiftsCount = 0
    @State private var floatingHearts: [ViewerFloatingHeart] = []
    @State private var tapLocation: CGPoint = .zero
    
    var body: some View {
        
        ZStack {
            
            // 1️⃣ VIDEO / FOND — derrière tout
            GeometryReader { geo in
                ZStack {
                    if agoraManager.remoteUsers.isEmpty {
                        Color.black.ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.4)
                                .tint(.white)

                            Text("Connexion au LIVE...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    } else {
                        LiveVideoGridView(
                            videos: agoraManager.remoteUsers.map {
                                .remote(uid: $0)
                            }
                        )
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                            .zIndex(0)
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .zIndex(0)
            
            // 2️⃣ DÉGRADÉ — ne bloque rien
            Color.clear
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(1)
            
            // 3️⃣ ZONE LIKE — seulement au centre, ne bloque pas boutons / input
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .frame(
                        width: geo.size.width - 105,
                        height: geo.size.height - 230
                    )
                    .position(
                        x: (geo.size.width - 105) / 2,
                        y: geo.size.height / 2
                    )
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                tapLocation = CGPoint(
                                    x: geo.size.width / 2,
                                    y: geo.size.height / 2
                                )
                                handleScreenTap()
                            }
                    )
            }
            .zIndex(5)
            
            // 4️⃣ HEADER HAUT
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.title2.bold())
                            .padding(10)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(live.creatorName)
                            .foregroundColor(.white)
                            .font(.headline.bold())
                        
                        Text("LIVE ❤️ \(formatNumber(chatService.likeCount))")
                            .foregroundColor(.red)
                            .font(.caption.bold())
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                        Text(formatNumber(chatService.viewerCount))
                    }
                    .foregroundColor(.white)
                    .font(.headline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.top, 55)
                
                Spacer()
            }
            .zIndex(50)
            
            // 5️⃣ BOUTONS DROITE
            HStack {
                Spacer()
                
                VStack(spacing: 22) {
                    Button {
                        showGifts = true
                    } label: {
                        VStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                            Text("\(totalGiftsCount)")
                                .foregroundColor(.white)
                                .font(.caption2)
                        }
                    }
                    
                    Button {
                        showShop = true
                    } label: {
                        VStack {
                            Text("🪙")
                                .font(.title2)
                            Text("\(walletService.coins)")
                                .foregroundColor(.yellow)
                                .font(.caption2)
                        }
                    }
                    
                    Button {
                        shareLive()
                    } label: {
                        VStack {
                            Image(systemName: "arrowshape.turn.up.right.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                            Text(formatNumber(chatService.shareCount))
                                .foregroundColor(.white)
                                .font(.caption2)
                        }
                    }
                    
                    Button {
                        chatService.requestToJoinLive(liveId: live.id)
                    } label: {
                        VStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.cyan)
                                .font(.title2)
                            Text("Monter \(formatNumber(chatService.joinRequestCount))")
                                .foregroundColor(.white)
                                .font(.caption2)
                        }
                    }
                }
                .padding(.trailing, 14)
            }
            .zIndex(55)
            
            // 6️⃣ CHAT
            VStack {
                Spacer()
                
                HStack {
                    LiveChatView(liveId: live.id)
                        .frame(
                            width: UIScreen.main.bounds.width * 0.62,
                            height: 260
                        )
                        .padding(.leading, 10)
                    
                    Spacer()
                }
                .padding(.bottom, 95)
            }
            .zIndex(45)
            
            // 7️⃣ INPUT
            VStack {
                Spacer()
                
                LiveChatInputView(
                    liveId: live.id,
                    chatService: chatService
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 35)
            }
            .zIndex(70)
            
            // 8️⃣ CADEAUX
            ForEach(activeGifts) { gift in
                GiftAnimationView(gift: gift.type)
            }
            .zIndex(80)
            
            // 9️⃣ CŒURS QUI MONTENT
            ForEach(floatingHearts) { heart in
                Text("❤️")
                    .font(.system(size: 34))
                    .position(x: heart.x, y: heart.y)
                    .offset(y: heart.offsetY)
                    .opacity(heart.opacity)
                    .onAppear {
                        animateHeart(heart.id)
                    }
            }
            .zIndex(90)
            
            // 🔟 SHEETS
            if showGifts {
                GiftSelectionView(
                    onSelect: { gift in
                        handleGiftPurchase(gift)
                    },
                    isPresented: $showGifts
                )
                .zIndex(999)
            }
            
            if showShop {
                PremiumCoinShopView(isPresented: $showShop)
                    .zIndex(999)
            }
            
            if showAd {
                LiveAdOverlay {
                    showAd = false
                }
                .zIndex(3000)
            }
        }
        .onAppear {
            walletService.loadCoins()
            chatService.startListening(liveId: live.id)
            chatService.joinViewer(liveId: live.id)
            chatService.sendJoin(liveId: live.id)
            LiveCoHostService.shared.startListening(liveId: live.id)
            agoraManager.joinAsViewer(channelName: live.id)
            listenLiveGifts()
            listenMyJoinRequestStatus()
        
            
        }
        .onDisappear {
            chatService.leaveViewer(liveId: live.id)
            chatService.stopAll()
            agoraManager.leaveChannel()
            giftsListener?.remove()
            myJoinRequestListener?.remove()
        }
    }
}

extension LiveViewerView {
    
    func handleScreenTap() {
        chatService.sendLikeMessageIfNeeded(liveId: live.id)
        chatService.sendLike(liveId: live.id)
        
        for _ in 0..<4 {
            floatingHearts.append(
                ViewerFloatingHeart(
                    id: UUID(),
                    x: tapLocation.x + CGFloat.random(in: -25...25),
                    y: tapLocation.y + CGFloat.random(in: -20...20)
                )
            )
        }
    }
    
    func animateHeart(_ id: UUID) {
        if let index = floatingHearts.firstIndex(where: { $0.id == id }) {
            withAnimation(.easeOut(duration: 1.2)) {
                floatingHearts[index].offsetY = -180
                floatingHearts[index].opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                floatingHearts.removeAll { $0.id == id }
            }
        }
    }
    
    func handleGiftPurchase(_ gift: Gift) {
        
        guard let user = Auth.auth().currentUser else {
            print("❌ Aucun utilisateur connecté")
            return
        }
        
        let senderName = user.displayName?.isEmpty == false ? user.displayName! : "Utilisateur"
        let senderAvatar = user.photoURL?.absoluteString ?? ""
        
        totalGiftsCount += 1
        
        let giftType = GiftType.fromGiftName(gift.name)
        let item = GiftItem(
            type: giftType,
            senderName: senderName,
            senderAvatar: senderAvatar
        )
        
        // Animation locale immédiate côté spectateur
        activeGifts.append(item)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            activeGifts.removeAll { $0.id == item.id }
        }
        
        // Enregistre transaction cadeau
        WalletService.shared.recordGiftTransaction(
            liveId: live.id,
            creatorId: live.creatorId,
            gift: gift
        ) { success in
            
            if success {
                
                // Message TikTok-style dans le chat
                chatService.sendSystemMessage(
                    liveId: live.id,
                    text: "🎁 \(senderName) a envoyé \(gift.name)"
                )
                
                // Préparation pour animation synchronisée plus tard
                Firestore.firestore()
                    .collection("lives")
                    .document(live.id)
                    .collection("gifts")
                    .addDocument(data: [
                        "senderId": user.uid,
                        "senderName": senderName,
                        "senderAvatar": senderAvatar,
                        "giftName": gift.name,
                        "giftCoins": gift.coins,
                        "createdAt": Timestamp()
                    ])
            } else {
                print("❌ Erreur enregistrement cadeau")
            }
        }
    }
    
    
    func listenMyJoinRequestStatus() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        myJoinRequestListener?.remove()
        
        myJoinRequestListener = Firestore.firestore()
            .collection("lives")
            .document(live.id)
            .collection("joinRequests")
            .document(uid)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("❌ Erreur écoute acceptation:", error.localizedDescription)
                    return
                }
                
                let status = snapshot?.data()?["status"] as? String ?? ""
                print("🙋 Statut demande spectateur =", status)
                
                if status == "accepted" {
                    LiveAgoraManager.shared.becomeCoHost()
                    
                    LiveCoHostService.shared.toggleMyCamera(liveId: live.id)
                    
                    print("🎤 ACCEPTÉ → spectateur monte dans le live")
                }
            }
    }
    
    
    
    func listenLiveGifts() {
        
        giftsListener?.remove()
        
        giftsListener = Firestore.firestore()
            .collection("lives")
            .document(live.id)
            .collection("gifts")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("❌ Erreur écoute cadeaux:", error.localizedDescription)
                    return
                }
                
                guard let changes = snapshot?.documentChanges else { return }
                
                for change in changes {
                    guard change.type == .added else { continue }
                    
                    let docId = change.document.documentID
                    
                    if seenGiftIds.contains(docId) { continue }
                    seenGiftIds.insert(docId)
                    
                    let data = change.document.data()
                    let giftName = data["giftName"] as? String ?? "Cadeau"
                    print("🎁 Cadeau reçu :", giftName)
                    
                    let giftType = GiftType.fromGiftName(giftName)
                    let senderName = data["senderName"] as? String ?? "Utilisateur"
                    let senderAvatar = data["senderAvatar"] as? String ?? ""

                    let item = GiftItem(
                        type: giftType,
                        senderName: senderName,
                        senderAvatar: senderAvatar
                    )
                    
                    DispatchQueue.main.async {
                        activeGifts.append(item)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            activeGifts.removeAll { $0.id == item.id }
                        }
                    }
                }
            }
    }
    
    
    
    func shareLive() {
        
        let liveURL = URL(string: "https://cutly.app/live/\(live.id)")!
        
        let text = "Viens regarder le LIVE de \(live.creatorName) sur Cutly ✂️🔥"
        
        let activityVC = UIActivityViewController(
            activityItems: [text, liveURL],
            applicationActivities: nil
        )
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            
            root.present(activityVC, animated: true)
        }
        
        chatService.sendShareWithMessage(liveId: live.id)
    }
    
    
    func formatNumber(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        } else {
            return "\(value)"
        }
    }
    
    
}

struct ViewerFloatingHeart: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    var offsetY: CGFloat = 0
    var opacity: Double = 1
}
