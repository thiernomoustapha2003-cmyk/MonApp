import SwiftUI
import AVKit
import AVFoundation

struct GiftAnimationView: View {
    
    let gift: GiftType
    
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 0.92
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.opacity(isPremiumGift ? 0.35 : 0.12)
                .ignoresSafeArea()
                .opacity(opacity)
            
            if let url = Bundle.main.url(forResource: gift.assetName, withExtension: "mp4") {
                GiftVideoPlayer(player: AVPlayer(url: url))
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .onAppear {
                        playSound()
                    }
            } else {
                fallbackPremiumView
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .onAppear {
                        playSound()
                    }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            startAnimation()
        }
    }
}

extension GiftAnimationView {
    
    private func startAnimation() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            scale = 1
            opacity = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + gift.duration) {
            withAnimation(.easeOut(duration: 0.45)) {
                opacity = 0
                scale = 1.08
            }
        }
    }
    
    private func playSound() {
        guard let url = Bundle.main.url(forResource: gift.soundName, withExtension: "mp3") else {
            print("⚠️ Son introuvable:", gift.soundName)
            return
        }
        
        var soundId: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundId)
        AudioServicesPlaySystemSound(soundId)
    }
}

extension GiftAnimationView {
    
    private var fallbackPremiumView: some View {
        VStack(spacing: 14) {
            Text(gift.emoji)
                .font(.system(size: isPremiumGift ? 120 : 80))
                .shadow(color: gift.glowColor, radius: 30)
            
            Text(gift.title)
                .font(isPremiumGift ? .largeTitle.bold() : .title3.bold())
                .foregroundColor(.white)
                .shadow(color: gift.glowColor, radius: 18)
        }
        .padding()
    }
    
    private var isPremiumGift: Bool {
        switch gift {
        case .crown, .giftBox, .fireworks, .car, .lion, .universe, .royalScissors:
            return true
        default:
            return false
        }
    }
}

struct GiftVideoPlayer: UIViewRepresentable {
    
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.backgroundColor = UIColor.clear.cgColor
        layer.frame = UIScreen.main.bounds
        
        view.layer.addSublayer(layer)
        
        DispatchQueue.main.async {
            player.seek(to: .zero)
            player.play()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
