import SwiftUI
import AVFoundation
import FirebaseAuth
import FirebaseFirestore

struct LiveStreamView: View {
    
    
    
    @State private var giftsListener: ListenerRegistration?
    @State private var seenGiftIds: Set<String> = []
    
    
    @State private var cohostAutoGridEnabled = false
    
    @State private var showHostControls = false
    @State private var showModeration = false
    
    @State private var isWithdrawRequestLoading = false
    @State private var withdrawRequestSent = false
    
    
    @State private var showJoinRequests = false
    @State private var spotlightUserId: String? = nil
    @State private var showLiveSummary = false
    @State private var selectedWithdrawMethod = "Orange Money"
    @State private var scheduledWithdrawDate = Date()
    @State private var autoWithdrawEnabled = false
    @State private var estimatedRevenue: Double = 0
    @State private var topDonors: [LiveTopDonor] = []
    @State private var liveEarnedCoins: Int = 0
    
    
    @StateObject private var walletService = WalletService.shared
    @State private var showShop = false
    @State private var totalGiftsCount = 0
    
    @State private var lastLikeTime: [String: Date] = [:]
    @State private var floatingHearts: [FloatingHeart] = []
    @State private var tapLocation: CGPoint = .zero
    @State private var viewersCount: Int = 1200
    @State private var liveGoalProgress: Double = 0.45
    @State private var activeGifts: [GiftItem] = []
    
    
    
    
    @State private var likeCount = 0
    @State private var shareCount = 0
    @State private var heartTrigger = 0
    
    
    @State private var showShareSheet = false
    @State private var showGifts = false
    @State private var showViewers = false
    @State private var showOptions = false
    @State private var showCoHostGrid = false
    
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedFilter: String = ""
    @State private var selectedTab = 1
    
    @StateObject private var chatService = LiveChatService()
    @State private var liveId = UUID().uuidString
    
    @State private var session = AVCaptureSession()
    let effectsList = [

        LiveEffect(
            name: "Normal",
            filterName: "none",
            icon: "camera"
        ),

        LiveEffect(
            name: "Beauté",
            filterName: "beauty",
            icon: "sparkles"
        ),

        LiveEffect(
            name: "Peau Lisse",
            filterName: "smooth",
            icon: "face.smiling"
        ),

        LiveEffect(
            name: "Teint Clair",
            filterName: "bright",
            icon: "sun.max.fill"
        ),

        LiveEffect(
            name: "Dents Blanches",
            filterName: "white_teeth",
            icon: "mouth"
        ),

        LiveEffect(
            name: "Cute",
            filterName: "cute",
            icon: "heart.fill"
        ),

        LiveEffect(
            name: "Glamour",
            filterName: "glamour",
            icon: "star.fill"
        ),

        LiveEffect(
            name: "Snap",
            filterName: "snap",
            icon: "camera.filters"
        ),

        LiveEffect(
            name: "TikTok",
            filterName: "tiktok",
            icon: "music.note"
        ),

        LiveEffect(
            name: "Makeup",
            filterName: "makeup",
            icon: "paintbrush.fill"
        ),

        LiveEffect(
            name: "Big Eyes",
            filterName: "big_eyes",
            icon: "eye.fill"
        ),

        LiveEffect(
            name: "Face Slim",
            filterName: "face_slim",
            icon: "person.crop.circle"
        )
    ]
    
    
    
    @State private var showEffects = false
    
    
    
    // 🔥 LIVE STATE
    @State private var isStartingLive = false
    @State private var countdown = 5
    @State private var currentPosition: AVCaptureDevice.Position = .front
    @State private var isLiveStarted = false
    
    var body: some View {
        
        ZStack {
            
            if !isLiveStarted {
                
                // 🎥 CAMERA + FILTRE (PARFAIT)
                ZStack {
                    CameraPreview(session: session)
                        .allowsHitTesting(!showGifts)
                        .ignoresSafeArea()
                    
                    FilterOverlayView(
                        session: session,
                        filterName: selectedFilter,
                        currentPosition: currentPosition
                    )
                    .ignoresSafeArea()
                }
                .allowsHitTesting(!showGifts)
                
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                VStack {
                    
                    // 🔝 TOP BAR
                    HStack {
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                        
                        Spacer()
                        
                        Text("LIVE")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Spacer()
                        
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // 🧠 OPTIONS
                    VStack(spacing: 16) {
                        Text("Titre du LIVE")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Button("Ajouter un sujet") {}
                            .foregroundColor(.white)
                        
                        Button("Nouvel objectif") {}
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // 🔽 BOTTOM
                    VStack(spacing: 20) {
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 25) {
                                
                                LiveAction(icon: "lightbulb", title: "Astuces")
                                LiveAction(icon: "square.and.arrow.up", title: "Partager")
                                LiveAction(icon: "play.rectangle", title: "Centre")
                                LiveAction(icon: "heart", title: "Fan Club")
                                LiveAction(icon: "flame", title: "Promouvoir")
                                
                                // ✅ BOUTON FX ICI
                                Button {
                                    withAnimation {
                                        showEffects = true
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .font(.title2)
                                        Text("Effets")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white)
                                }
                                
                                // 🔁 ton bouton caméra reste
                                Button {
                                    switchCamera()
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                                        Text("Retourner")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Button {
                            startCountdown()
                        } label: {
                            Text("Passer en LIVE")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                        }
                        
                        HStack {
                            LiveTab(title: "Chat vocal", index: 0, selectedTab: $selectedTab)
                            LiveTab(title: "Caméra", index: 1, selectedTab: $selectedTab)
                            LiveTab(title: "Jeu mobile", index: 2, selectedTab: $selectedTab)
                            LiveTab(title: "LIVE Studio", index: 3, selectedTab: $selectedTab)
                        }
                        .foregroundColor(.white)
                    }
                    .padding()
                }
                
            } else {
                liveUI // 🔥 ICI LE SWITCH
            }
            
            // ⏱ COUNTDOWN
            if isStartingLive {
                Color.black.opacity(0.7).ignoresSafeArea()
                
                Text("\(countdown)")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white)
            }
            
            if showEffects {
                VStack {
                    Spacer()
                    
                    EffectsView(effects: effectsList) { effect in
                        selectedFilter = effect.filterName
                        withAnimation {
                            showEffects = false
                        }
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(100) // 🔥 AJOUT ICI
            }
            
        }
        .onAppear {
            checkPermissionAndSetup()
            chatService.startListening(liveId: liveId)
            chatService.sendJoin(liveId: liveId)
            walletService.loadCoins()
            listenLiveGifts()
            
            LiveCoHostService.shared.registerHost(liveId: liveId)
            LiveCoHostService.shared.startListening(liveId: liveId)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !LiveCoHostService.shared.activeGuests.isEmpty {
                    showCoHostGrid = true
                    cohostAutoGridEnabled = true
                    print("🔥 Grille cohost activée automatiquement")
                }
            }
        }
        .onDisappear {
            session.stopRunning()
            giftsListener?.remove()
        }
        .sheet(isPresented: $showJoinRequests) {
            LiveJoinRequestsSheet(liveId: liveId)
           
            
        }
        
    }
    
    // MARK: - HELPERS
    
    func updateHeart(_ id: UUID) {
        if let index = floatingHearts.firstIndex(where: { $0.id == id }) {
            
            withAnimation(.easeOut(duration: 1.2)) {
                floatingHearts[index].offsetY = -UIScreen.main.bounds.height * 0.4
                floatingHearts[index].opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                floatingHearts.removeAll { $0.id == id }
            }
        }
    }
    
    func sendGift(type: GiftType) {
        activeGifts.append(
            GiftItem(
                type: type,
                senderName: Auth.auth().currentUser?.displayName ?? "Créateur",
                senderAvatar: Auth.auth().currentUser?.photoURL?.absoluteString ?? ""
            )
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if !activeGifts.isEmpty {
                activeGifts.removeFirst()
                totalGiftsCount += 1
            }
        }
    }
    
    func formatNumber(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value)/1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fK", Double(value)/1_000)
        }
        return "\(value)"
    }
    
    func handleLike() {
        guard let user = Auth.auth().currentUser else { return }
        
        let username = user.displayName ?? "User"
        let now = Date()
        
        let cooldown: TimeInterval = 30 // 🔥 30 secondes
        
        // 🔥 Vérifie dernier like
        if let lastTime = lastLikeTime[user.uid],
           now.timeIntervalSince(lastTime) < cooldown {
            
            // ❌ on bloque le message (mais on laisse l'animation)
            heartTrigger += 1
            
            floatingHearts.append(
                FloatingHeart(
                    id: UUID(),
                    x: tapLocation.x,
                    y: tapLocation.y
                )
            )
            
            chatService.sendLike(liveId: liveId)
            return
        }
        
        // ✅ Autorisé (premier tap ou après cooldown)
        lastLikeTime[user.uid] = now
        
        chatService.sendLike(liveId: liveId)
        
        chatService.sendSystemMessage(
            liveId: liveId,
            text: "❤️ \(username) a aimé le LIVE"
        )
        
        // ❤️ animation
        heartTrigger += 1
        
        floatingHearts.append(
            FloatingHeart(
                id: UUID(),
                x: tapLocation.x,
                y: tapLocation.y
            )
        )
    }
    func handleShare() {
        guard let user = Auth.auth().currentUser else { return }
        
        let username = user.displayName ?? "User"
        
        //////////////////////////////////////////////////////
        // 🔥 OUVRIR PARTAGE IOS
        //////////////////////////////////////////////////////
        
        let url = URL(string: "https://cutly.app/live/\(liveId)")!
        
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
        
        //////////////////////////////////////////////////////
        // 🔥 FIRESTORE (1 SEUL PARTAGE RÉEL)
        //////////////////////////////////////////////////////
        
        chatService.sendShare(liveId: liveId)
        
        //////////////////////////////////////////////////////
        // 🔥 MESSAGE (OPTIONNEL)
        //////////////////////////////////////////////////////
        
        chatService.sendSystemMessage(
            liveId: liveId,
            text: "📤 \(username) a partagé le LIVE"
        )
    }
    func handleGiftPurchase(gift: Gift) {
        
        guard let user = Auth.auth().currentUser else {
            print("❌ utilisateur introuvable")
            return
        }
        
        let creatorId = user.uid
        let senderName = user.displayName?.isEmpty == false ? user.displayName! : "Créateur"
        let senderAvatar = user.photoURL?.absoluteString ?? ""
        
        totalGiftsCount += 1
        
        WalletService.shared.recordGiftTransaction(
            liveId: liveId,
            creatorId: creatorId,
            gift: gift
        ) { success in
            
            if success {
                
                chatService.sendSystemMessage(
                    liveId: liveId,
                    text: "🎁 \(senderName) a envoyé \(gift.name)"
                )
                
                Firestore.firestore()
                    .collection("lives")
                    .document(liveId)
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
    func listenLiveGifts() {
        
        giftsListener?.remove()
        
        giftsListener = Firestore.firestore()
            .collection("lives")
            .document(liveId)
            .collection("gifts")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("❌ Erreur écoute cadeaux créateur:", error.localizedDescription)
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
                        totalGiftsCount += 1
                        activeGifts.append(item)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            activeGifts.removeAll { $0.id == item.id }
                        }
                    }
                }
            }
    }
    
}

// MARK: - CAMERA VIEW


/// MARK: - CAMERA PERMISSION + SETUP
extension LiveStreamView {
    
    func checkPermissionAndSetup() {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            setupCamera()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        setupCamera()
                    }
                }
            }
            
        case .denied, .restricted:
            print("❌ caméra refusée")
            
        @unknown default:
            break
        }
    }
    
    func setupCamera() {
        
        session.beginConfiguration()
        
        // 🔥 IMPORTANT : qualité vidéo
        session.sessionPreset = .high
        
        // reset inputs
        for input in session.inputs {
            session.removeInput(input)
        }
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("❌ caméra indisponible")
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            // 🔥 RESET ZOOM (TRÈS IMPORTANT)
            device.videoZoomFactor = 1.0
            
            // 🔥 FIX FORMAT (évite zoom / déformation)
            if let format = device.formats.first(where: {
                CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            }) {
                device.activeFormat = format
            }
            
            device.unlockForConfiguration()
            
        } catch {
            print("❌ config device error")
        }
        
        session.addInput(input)
        
        do {
            try device.lockForConfiguration()
            
            // 🔥 stabilise la caméra (important)
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            // 🔥 force un rendu stable (corrige orientation / bugs)
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
            
            device.unlockForConfiguration()
            
        } catch {
            print("❌ config device error")
        }
        session.commitConfiguration()
        
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }
    
    func switchCamera() {
        currentPosition = currentPosition == .front ? .back : .front
        setupCamera()
    }
}
// MARK: - COUNTDOWN
extension LiveStreamView {
    
    func startCountdown() {
        
        countdown = 5
        isStartingLive = true
        LiveAgoraManager.shared.setupEngine()
        
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            
            if countdown > 1 {
                
                countdown -= 1
                
            } else {
                
                timer.invalidate()
                
                isStartingLive = false

                // 🔥 IMPORTANT : on arrête l’ancienne caméra AVCapture avant Agora
                if session.isRunning {
                    DispatchQueue.global(qos: .userInitiated).async {
                        session.stopRunning()
                    }
                }

                // 🔥 On passe en live puis Agora prend la caméra
                isLiveStarted = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    LiveAgoraManager.shared.joinAsHost(channelName: liveId)
                }
                
                //////////////////////////////////////////////////////
                // 🔥 CRÉATION LIVE FIRESTORE
                //////////////////////////////////////////////////////
                
                guard let user = Auth.auth().currentUser else {
                    print("❌ utilisateur non connecté")
                    return
                }
                
                let db = Firestore.firestore()
                
                db.collection("lives").document(liveId).setData([
                    
                    "creatorId": user.uid,
                    "creatorName": user.displayName ?? "Créateur",
                    "creatorImageUrl": "",
                    
                    "title": "Live coiffure Cutly",
                    
                    "isLive": true,
                    "viewersCount": 0,
                    
                    "startedAt": Timestamp(),
                    
                ]) { error in
                    
                    if let error = error {
                        print("❌ Erreur création live:", error.localizedDescription)
                    } else {
                        print("✅ LIVE créé dans Firestore")
                    }
                }
                
                print("🎥 LIVE STARTED")
            }
        }
    }
    
    var liveUI: some View {
        ZStack {
            
            //////////////////////////////////////////////////////////
            // 🎥 CAMERA
            //////////////////////////////////////////////////////////
            //////////////////////////////////////////////////////////
            // 🎥 VIDEO LIVE PRINCIPALE
            //////////////////////////////////////////////////////////

            if !showCoHostGrid {
                
                ZStack {
                    AgoraVideoView(videoType: .local, cornerRadius: 0)
                        .id("main-agora-video-fullscreen")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .background(Color.black)
                    
                    if !LiveAgoraManager.shared.remoteUsers.isEmpty {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Spacer()
                                
                                ForEach(LiveAgoraManager.shared.remoteUsers, id: \.self) { uid in
                                    AgoraVideoView(videoType: .remote(uid: uid), cornerRadius: 16)
                                        .frame(width: 110, height: 150)
                                        .clipped()
                                        .background(Color.black)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                        )
                                }
                                .padding(.trailing, 14)
                                .padding(.bottom, 210)
                            }
                        }
                    }
                }
                
            } else {
                
                LiveVideoGridView(
                    videos: [.local] + LiveAgoraManager.shared.remoteUsers.map {
                        .remote(uid: $0)
                    }
                )
                .ignoresSafeArea()
            }
            //////////////////////////////////////////////////////////
            // 🎥 COHOST GRID TIKTOK STYLE
            //////////////////////////////////////////////////////////
            
            if showCoHostGrid {
                
                ZStack {
                    
                    Color.black
                        .ignoresSafeArea()
                    
                    LiveCoHostGridView(
                        liveId: liveId,
                        isHostView: true,
                        hostSession: session,
                        selectedFilter: selectedFilter,
                        currentPosition: currentPosition,
                        onInviteTap: {
                            showJoinRequests = true
                        }
                    )
                    .id("cohost-grid-\(liveId)-\(showCoHostGrid)")
                    .transition(.opacity)
                }
                .zIndex(0)
                
            }
            
            //////////////////////////////////////////////////////////
            // ❤️ DOUBLE TAP LIKE (FIX)
            //////////////////////////////////////////////////////////
            if !showCoHostGrid {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                handleLike()
                            }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                tapLocation = value.location
                            }
                    )
            }
            
            
            //////////////////////////////////////////////////////////
            // ❤️ COEURS QUI DISPARAISSENT (FIX)
            //////////////////////////////////////////////////////////
            ForEach(floatingHearts, id: \.id) { heart in
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                    .position(x: heart.x, y: heart.y)
                    .offset(y: heart.offsetY)
                    .opacity(heart.opacity)
                    .onAppear {
                        updateHeart(heart.id)
                        
                    }
            }
            
            //////////////////////////////////////////////////////////
            // 🔝 TOP BAR TIKTOK
            //////////////////////////////////////////////////////////
            VStack {
                
                HStack(alignment: .top) {
                    
                    // 🔴 GAUCHE : PSEUDO + LIKES
                    HStack(spacing: 8) {
                        
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 36, height: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            
                            Text("TonPseudo")
                                .foregroundColor(.white)
                                .font(.caption)
                                .bold()
                            
                            HStack(spacing: 6) {
                                Text("LIVE")
                                    .foregroundColor(.red)
                                    .font(.caption2)
                                
                                Text("❤️ \(formatNumber(chatService.likeCount))")
                                    .foregroundColor(.white)
                                    .font(.caption2)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // 🔵 DROITE : VIEWERS + POWER (CÔTE À CÔTE)
                    HStack(spacing: 10) {
                        
                        // 👁 VIEWERS
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                            Text("\(formatNumber(chatService.viewerCount))")
                        }
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        
                        Button {
                            print("🔴 POWER CLICKED")
                            
                            Firestore.firestore()
                                .collection("lives")
                                .document(liveId)
                                .setData([
                                    "isLive": false,
                                    "endedAt": Timestamp()
                                ], merge: true)
                            
                            Firestore.firestore()
                                .collection("liveAnalytics")
                                .document(liveId)
                                .setData([
                                    "liveId": liveId,
                                    "creatorId": Auth.auth().currentUser?.uid ?? "",
                                    "likes": chatService.likeCount,
                                    "shares": chatService.shareCount,
                                    "viewers": chatService.viewerCount,
                                    "gifts": totalGiftsCount,
                                    "endedAt": Timestamp(),
                                    "hasReplay": true
                                ], merge: true)
                            
                            loadLiveSummaryData()
                            
                            withAnimation {
                                showLiveSummary = true
                            }
                            
                            LiveAgoraManager.shared.leaveChannel()
                            
                        } label: {
                            Image(systemName: "power")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 0) // 🔥 COLLÉ EN HAUT
                
                Spacer()
            }
            
            ////////////////////////////////////////////////////////////
            // 👉 ACTIONS DROITE (LIKE + CADEAU + COINS + SHARE)
            ////////////////////////////////////////////////////////////
            
            HStack {
                
                Spacer() // 🔥 pousse tout à droite
                
                VStack(spacing: 22) {
                    
                    //////////////////////////////////////////////////////
                    // ❤️ LIKE
                    //////////////////////////////////////////////////////
                    VStack {
                        Button {
                            handleLike()
                        } label: {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                                .font(.title2)
                        }
                        
                        Text("\(formatNumber(chatService.likeCount))")
                            .foregroundColor(.white)
                            .font(.caption2)
                    }
                    
                    //////////////////////////////////////////////////////
                    // 🎁 CADEAU
                    //////////////////////////////////////////////////////
                    VStack {
                        Button {
                            showGifts.toggle()
                        } label: {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                        }
                        
                        Text("\(formatNumber(totalGiftsCount))")
                            .foregroundColor(.white)
                            .font(.caption2)
                    }
                    
                    //////////////////////////////////////////////////////
                    // 🪙 COINS
                    //////////////////////////////////////////////////////
                    VStack {
                        Button {
                            showShop = true
                        } label: {
                            Text("🪙")
                                .font(.title2)
                        }
                        
                        Text("\(walletService.coins)")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                    }
                    
                    //////////////////////////////////////////////////////
                    // 📤 SHARE
                    //////////////////////////////////////////////////////
                    VStack {
                        Button {
                            handleShare()
                        } label: {
                            Image(systemName: "arrowshape.turn.up.right.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        
                        Text("\(formatNumber(chatService.shareCount))")
                            .foregroundColor(.white)
                            .font(.caption2)
                    }
                }
                .padding(.trailing, 12)
                .padding(.bottom, 140)
            }
            //////////////////////////////////////////////////////////
            // 💬 CHAT (GAUCHE BAS)
            //////////////////////////////////////////////////////////
            VStack {
                Spacer()
                
                HStack {
                    LiveChatView(liveId: liveId)
                        .frame(width: UIScreen.main.bounds.width * 0.6)
                    
                    Spacer()
                }
                .padding(.bottom, 90)
            }
            
            //////////////////////////////////////////////////////////
            // ✍️ INPUT
            //////////////////////////////////////////////////////////
            VStack {
                Spacer()
                
                LiveChatInputView(
                    liveId: liveId,
                    chatService: chatService
                )
                .padding(.bottom, 50)
            }
            
            //////////////////////////////////////////////////////////
            // 🎁 CADEAUX ANIMÉS
            //////////////////////////////////////////////////////////
            ForEach(activeGifts) { gift in
                GiftAnimationView(gift: gift.type)
            }
            
            
            
            //////////////////////////////////////////////////////////
            // 🔻 BARRE BAS (GROS BOUTONS)
            //////////////////////////////////////////////////////////
            VStack {
                Spacer()
                
                HStack(spacing: 25) {
                    
                    Button {
                        withAnimation {
                            showHostControls.toggle()
                        }
                    } label: {
                        LiveBottomButton(icon: "slider.horizontal.3", title: "Contrôles")
                    }
                    Button {
                        showJoinRequests = true
                    } label: {
                        LiveBottomButton(icon: "person.crop.circle.badge.plus", title: "+ Invités")
                    }
                    Button {

                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()

                        withAnimation(.easeInOut(duration: 0.22)) {
                            showCoHostGrid.toggle()
                        }

                    } label: {

                        VStack(spacing: 5) {

                            ZStack {

                                Circle()
                                    .fill(
                                        showCoHostGrid
                                        ? Color.yellow.opacity(0.18)
                                        : Color.white.opacity(0.08)
                                    )
                                    .frame(width: 42, height: 42)

                                Image(systemName:
                                        showCoHostGrid
                                      ? "square.grid.2x2.fill"
                                      : "square.grid.2x2"
                                )
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(
                                    showCoHostGrid
                                    ? .yellow
                                    : .white
                                )
                            }

                            Text(
                                showCoHostGrid
                                ? "Grille ON"
                                : "Grille OFF"
                            )
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(
                                showCoHostGrid
                                ? .yellow
                                : .white
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .zIndex(999)
                    LiveBottomButton(icon: "wand.and.stars", title: "Améliorer")
                    
                    Button {
                        showOptions.toggle()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 10)
            }
            
            
            if showGifts {
                ZStack {
                    
                    // 🔥 bloque clic arrière (mais NE FERME PAS le live)
                    Color.black.opacity(0.01)
                        .ignoresSafeArea()
                    
                    GiftSelectionView(
                        onSelect: { gift in
                            handleGiftPurchase(gift: gift)
                        },
                        isPresented: $showGifts
                    )
                }
                .transition(.move(edge: .bottom))
                .zIndex(999)
                }
            
            if showHostControls {
                
                VStack {
                    Spacer()
                    
                    LiveHostControlPanel(
                        liveId: liveId,
                        spotlightUserId: $spotlightUserId,
                        showJoinRequests: $showJoinRequests,
                        showModeration: $showModeration
                    )
                    .padding(.bottom, 90)
                }
                .transition(.move(edge: .bottom))
                .zIndex(2000)
            }
            
            ////////////////////////////////////////////////////////////
            // 🪙 COIN SHOP (AFFICHAGE PROPRE)
            ////////////////////////////////////////////////////////////
            
            if showShop {
                ZStack {
                    
                    // 🔥 bloque les clics derrière (IMPORTANT)
                    Color.black.opacity(0.01)
                        .ignoresSafeArea()
                    
                    CoinShopView(isPresented: $showShop)
                }
                .zIndex(999)
            }
            //////////////////////////////////////////////////////////
            // 📊 LIVE SUMMARY PRO
            //////////////////////////////////////////////////////////

            if showLiveSummary {
                
                ZStack {
                    
                    Color.black.opacity(0.96)
                        .ignoresSafeArea()
                    
                    ScrollView(showsIndicators: false) {
                        
                        VStack(spacing: 22) {
                            
                            //////////////////////////////////////////////////////
                            // HEADER
                            //////////////////////////////////////////////////////
                            
                            VStack(spacing: 10) {
                                
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .font(.system(size: 44))
                                    .foregroundColor(.red)
                                
                                Text("LIVE terminé")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Résumé complet de votre LIVE")
                                    .foregroundColor(.white.opacity(0.75))
                                    .font(.subheadline)
                            }
                            .padding(.top, 30)
                            
                            //////////////////////////////////////////////////////
                            // STATS
                            //////////////////////////////////////////////////////
                            
                            VStack(spacing: 14) {
                                
                                summaryRow(
                                    icon: "heart.fill",
                                    color: .pink,
                                    title: "Likes",
                                    value: "\(chatService.likeCount)"
                                )
                                
                                summaryRow(
                                    icon: "gift.fill",
                                    color: .yellow,
                                    title: "Cadeaux reçus",
                                    value: "\(totalGiftsCount)"
                                )
                                
                                summaryRow(
                                    icon: "eye.fill",
                                    color: .blue,
                                    title: "Spectateurs",
                                    value: "\(chatService.viewerCount)"
                                )
                                
                                summaryRow(
                                    icon: "arrowshape.turn.up.right.fill",
                                    color: .green,
                                    title: "Partages",
                                    value: "\(chatService.shareCount)"
                                )
                            }
                            
                            //////////////////////////////////////////////////////
                            // REVENUS
                            //////////////////////////////////////////////////////
                            
                            VStack(alignment: .leading, spacing: 18) {
                                
                                Text("💰 Revenus LIVE")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 14) {
                                    
                                    revenueCard(
                                        title: "Coins gagnés pendant ce LIVE",
                                        value: "\(liveEarnedCoins)",
                                        color: .yellow
                                    )
                                    
                                    revenueCard(
                                        title: "Estimation €",
                                        value: "\(String(format: "%.2f", estimatedRevenue)) €",
                                        color: .green
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            //////////////////////////////////////////////////////////
                            // 🏆 TOP DONATEURS FIRESTORE
                            //////////////////////////////////////////////////////////

                            VStack(alignment: .leading, spacing: 18) {
                                
                                Text("🏆 Top donateurs")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 12) {
                                    
                                    //////////////////////////////////////////////////////
                                    // 🔥 AUCUN DONATEUR
                                    //////////////////////////////////////////////////////
                                    
                                    if topDonors.isEmpty {
                                        
                                        VStack(spacing: 10) {
                                            
                                            Image(systemName: "gift")
                                                .font(.system(size: 30))
                                                .foregroundColor(.white.opacity(0.5))
                                            
                                            Text("Aucun donateur pour ce LIVE")
                                                .foregroundColor(.white.opacity(0.6))
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(18)
                                        
                                    } else {
                                        
                                        //////////////////////////////////////////////////////
                                        // 🔥 FIRESTORE DONATORS
                                        //////////////////////////////////////////////////////
                                        
                                        ForEach(
                                            Array(topDonors.enumerated()),
                                            id: \.element.id
                                        ) { index, donor in
                                            
                                            donorRow(
                                                rank: index + 1,
                                                name: donor.name,
                                                amount: "\(donor.coins) coins"
                                            )
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            //////////////////////////////////////////////////////
                            // RETRAIT
                            //////////////////////////////////////////////////////
                            
                            VStack(alignment: .leading, spacing: 18) {
                                
                                Text("🏦 Retrait")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                withdrawMethodButton("Orange Money")
                                withdrawMethodButton("Wave")
                                withdrawMethodButton("MTN Money")
                                withdrawMethodButton("Moov Money")
                                withdrawMethodButton("Carte Bancaire")
                                withdrawMethodButton("PayPal")
                                
                                Toggle(isOn: $autoWithdrawEnabled) {
                                    
                                    Text("Retrait automatique")
                                        .foregroundColor(.white)
                                }
                                
                                DatePicker(
                                    "Date du retrait",
                                    selection: $scheduledWithdrawDate,
                                    displayedComponents: [.date]
                                )
                                .colorScheme(.dark)
                                
                                Button {
                                    
                                    guard !isWithdrawRequestLoading && !withdrawRequestSent else { return }
                                    
                                    createLiveWithdrawRequest()
                                    
                                } label: {
                                    
                                    HStack {
                                        
                                        if isWithdrawRequestLoading {
                                            ProgressView()
                                                .tint(.black)
                                        } else {
                                            Image(systemName: withdrawRequestSent ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                                        }
                                        
                                        Text(
                                            isWithdrawRequestLoading
                                            ? "Envoi en cours..."
                                            : withdrawRequestSent
                                            ? "Demande envoyée"
                                            : "Retirer maintenant"
                                        )
                                        .fontWeight(.bold)
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(withdrawRequestSent ? Color.gray : Color.green)
                                    .cornerRadius(18)
                                }
                                .disabled(isWithdrawRequestLoading || withdrawRequestSent)
                            }
                            
                            //////////////////////////////////////////////////////
                            // REPLAY
                            //////////////////////////////////////////////////////
                            
                            VStack(alignment: .leading, spacing: 16) {
                                
                                Text("🎥 Replay LIVE")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Button {
                                    print("Replay")
                                } label: {
                                    
                                    HStack {
                                        
                                        Image(systemName: "play.circle.fill")
                                        
                                        Text("Voir le replay")
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.85))
                                    .cornerRadius(18)
                                }
                            }
                            
                            //////////////////////////////////////////////////////
                            // CLOSE
                            //////////////////////////////////////////////////////
                            
                            Button {

                                LiveAgoraManager.shared.leaveChannel()

                                isLiveStarted = false

                                dismiss()

                            } label: {
                                
                                Text("Fermer")
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(18)
                            }
                            .padding(.bottom, 40)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .zIndex(99999)
            }
        }
    }
    
    
    
    
    
    func summaryRow(
        icon: String,
        color: Color,
        title: String,
        value: String
    ) -> some View {
        
        HStack {
            
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.white)
                .bold()
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }
    func revenueCard(
        title: String,
        value: String,
        color: Color
    ) -> some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Text(title)
                .foregroundColor(.white.opacity(0.75))
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(18)
    }

    func donorRow(
        rank: Int,
        name: String,
        amount: String
    ) -> some View {
        
        HStack {
            
            Text("#\(rank)")
                .foregroundColor(.yellow)
                .bold()
                .frame(width: 40)
            
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 38, height: 38)
            
            VStack(alignment: .leading) {
                
                Text(name)
                    .foregroundColor(.white)
                    .bold()
                
                Text(amount)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    func withdrawMethodButton(_ method: String) -> some View {
        
        Button {
            selectedWithdrawMethod = method
        } label: {
            
            HStack {
                
                Text(method)
                    .foregroundColor(.white)
                
                Spacer()
                
                if selectedWithdrawMethod == method {
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.white.opacity(0.06))
            .cornerRadius(16)
        }
    }
            
            func loadLiveSummaryData() {
                
                let db = Firestore.firestore()
                
                db.collection("giftTransactions")
                    .whereField("liveId", isEqualTo: liveId)
                    .whereField("creatorId", isEqualTo: Auth.auth().currentUser?.uid ?? "")
                    .getDocuments { snapshot, error in
                        
                        if let error = error {
                            print("❌ Erreur chargement top donateurs:", error.localizedDescription)
                            return
                        }
                        
                        var donors: [String: (name: String, coins: Int)] = [:]
                        var totalCoins = 0
                        
                        snapshot?.documents.forEach { doc in
                            let data = doc.data()
                            
                            let senderId = data["senderId"] as? String ?? doc.documentID
                            let senderName = data["senderName"] as? String ?? "Spectateur"
                            let coins = data["totalCoins"] as? Int ?? 0
                            
                            totalCoins += coins
                            
                            let current = donors[senderId] ?? (name: senderName, coins: 0)
                            donors[senderId] = (
                                name: current.name,
                                coins: current.coins + coins
                            )
                        }
                        
                        let sorted = donors.map { key, value in
                            LiveTopDonor(
                                id: key,
                                name: value.name,
                                coins: value.coins
                            )
                        }
                        .sorted { $0.coins > $1.coins }
                        .prefix(10)
                        
                        DispatchQueue.main.async {
                            self.topDonors = Array(sorted)
                            self.liveEarnedCoins = totalCoins
                            self.estimatedRevenue = Double(totalCoins) / 100.0
                        }
                    }
            }
            
    func createLiveWithdrawRequest() {
        isWithdrawRequestLoading = true
        
        guard let user = Auth.auth().currentUser else {
            print("❌ Aucun utilisateur connecté")
            return
        }
        
        let db = Firestore.firestore()
        
        let data: [String: Any] = [
            "liveId": liveId,
            "creatorId": user.uid,
            "creatorName": user.displayName ?? "Créateur",
            "coins": liveEarnedCoins,
            "estimatedRevenue": estimatedRevenue,
            "withdrawMethod": selectedWithdrawMethod,
            "autoWithdrawEnabled": autoWithdrawEnabled,
            "scheduledWithdrawDate": Timestamp(date: scheduledWithdrawDate),
            "status": "pending",
            "createdAt": Timestamp()
        ]
        
        db.collection("lives")
            .document(liveId)
            .collection("withdrawRequests")
            .addDocument(data: data) { error in
                
                if let error = error {
                    print("❌ Erreur demande retrait:", error.localizedDescription)
                } else {
                    print("✅ Demande retrait enregistrée Firestore")
                    
                    DispatchQueue.main.async {
                        self.isWithdrawRequestLoading = false
                        self.withdrawRequestSent = true
                        self.isWithdrawRequestLoading = false
                    }
                }
            }
    }
    
    struct FloatingHeart: Identifiable {
        let id: UUID
        let x: CGFloat
        let y: CGFloat
        var offsetY: CGFloat = 0
        var opacity: Double = 1
    }
}
   
struct LiveBottomButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(title)
                .font(.caption2)
        }
        .foregroundColor(.white)
    }
    
}
struct LiveTopDonor: Identifiable {
    let id: String
    let name: String
    let coins: Int
}
