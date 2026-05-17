import SwiftUI
import FirebaseAuth
import AVFoundation

struct LiveViewerView: View {
    
    let live: LivePreviewModel
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatService = LiveChatService()
    @StateObject private var walletService = WalletService.shared
    
    @State private var showGifts = false
    @State private var showShop = false
    @State private var showAd = true
    
    @State private var activeGifts: [GiftItem] = []
    @State private var totalGiftsCount = 0
    @State private var floatingHearts: [ViewerFloatingHeart] = []
    @State private var tapLocation: CGPoint = .zero
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(
                colors: [
                    Color.black,
                    Color.red.opacity(0.4),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            tapLocation = value.location
                        }
                        .onEnded { _ in
                            handleScreenTap()
                        }
                )
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading) {
                        Text(live.creatorName)
                            .foregroundColor(.white)
                            .bold()
                        
                        Text("LIVE ❤️ \(formatNumber(chatService.likeCount))")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                        Text(formatNumber(chatService.viewerCount))
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                }
                .padding()
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                Spacer()
                
                VStack(spacing: 16) {
                    
                    Spacer()
                    
                    LiveCoHostGridView(
                        liveId: live.id,
                        isHostView: false,
                        hostSession: nil,
                        selectedFilter: "",
                        currentPosition: .front
                    )
                    .frame(height: 360)
                    .padding(.horizontal, 8)
                    
                    Spacer()
                }
            }
            
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
            
            VStack {
                Spacer()
                
                HStack {
                    LiveChatView(liveId: live.id)
                        .frame(width: UIScreen.main.bounds.width * 0.65)
                    
                    Spacer()
                }
                .padding(.bottom, 90)
            }
            
            VStack {
                Spacer()
                
                LiveChatInputView(
                    liveId: live.id,
                    chatService: chatService
                )
                .padding(.bottom, 35)
            }
            
            ForEach(activeGifts) { gift in
                GiftAnimationView(gift: gift.type)
            }
            
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
            LiveAgoraManager.shared.joinAsViewer(channelName: live.id)
        }
        .onDisappear {
            chatService.leaveViewer(liveId: live.id)
            chatService.stopAll()
            LiveAgoraManager.shared.leaveChannel()
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
        totalGiftsCount += 1
        
        let giftType = GiftType.fromGiftName(gift.name)
        let item = GiftItem(type: giftType)
        
        activeGifts.append(item)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            activeGifts.removeAll { $0.id == item.id }
        }
        
        WalletService.shared.recordGiftTransaction(
            liveId: live.id,
            creatorId: live.creatorId,
            gift: gift
        ) { success in
            if success {
                chatService.sendSystemMessage(
                    liveId: live.id,
                    text: "🎁 \(gift.name) envoyé à \(live.creatorName)"
                )
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
