//
//  GiftAnimationView.swift
//  MonApp
//

import SwiftUI

struct GiftAnimationView: View {
    
    let gift: GiftType
    
    @State private var show = false
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 0.2
    @State private var rotation: Double = 0
    @State private var offsetY: CGFloat = 0
    @State private var glow = false
    @State private var cutMove: CGFloat = -180
    
    var body: some View {
        ZStack {
            
            // ✨ Particules autour
            ForEach(0..<particleCount(), id: \.self) { index in
                Text(particleEmoji(index))
                    .font(.system(size: particleSize(index)))
                    .offset(
                        x: particleX(index),
                        y: show ? particleY(index) : 0
                    )
                    .opacity(opacity)
                    .scaleEffect(show ? 1.0 : 0.2)
            }
            
            // 🔥 Effet spécial Ciseaux Royal
            if gift == .royalScissors {
                VStack(spacing: -25) {
                    Text("✂️")
                        .font(.system(size: 115))
                        .rotationEffect(.degrees(show ? -25 : 25))
                        .offset(x: cutMove)
                    
                    Text("CUTLY ROYAL")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .shadow(color: .yellow, radius: 14)
                }
                .scaleEffect(scale)
                .opacity(opacity)
            } else {
                Text(mainEmoji())
                    .font(.system(size: mainSize()))
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .offset(y: offsetY)
                    .opacity(opacity)
                    .shadow(color: glowColor(), radius: glow ? 28 : 8)
            }
            
            // 👑 Texte premium
            if isPremiumGift() {
                Text(premiumTitle())
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .shadow(color: glowColor(), radius: 12)
                    .offset(y: 130)
                    .opacity(opacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
}

// MARK: - Animation

extension GiftAnimationView {
    
    private func startAnimation() {
        show = true
        glow = true
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) {
            scale = isPremiumGift() ? 1.25 : 1.05
            rotation = initialRotation()
        }
        
        if gift == .royalScissors {
            withAnimation(.easeInOut(duration: 0.55).repeatCount(3, autoreverses: true)) {
                cutMove = 180
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.35).repeatCount(2, autoreverses: true)) {
                    rotation = -initialRotation()
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + durationBeforeDisappear()) {
            withAnimation(.easeOut(duration: 1.0)) {
                opacity = 0
                offsetY = -230
                scale = 0.75
            }
        }
    }
}

// MARK: - Gift Visuals

extension GiftAnimationView {
    
    private func mainEmoji() -> String {
        switch gift {
        case .rose: return "🌹"
        case .like: return "❤️"
        case .clap: return "👏"
        case .comb: return "🪮"
        case .perfume: return "🧴"
        case .lipstick: return "💄"
        case .makeup: return "🎨"
        case .nails: return "💅"
        case .straightener: return "✨"
        case .sunglasses: return "🕶"
        case .hat: return "🎩"
        case .crown: return "👑"
        case .giftBox: return "🎁"
        case .fireworks: return "🎆"
        case .car: return "🏎"
        case .lion: return "🦁"
        case .universe: return "🌌"
        case .royalScissors: return "✂️"
        }
    }
    
    private func particleEmoji(_ index: Int) -> String {
        let particles: [String]
        
        switch gift {
        case .rose:
            particles = ["🌹", "💖", "✨"]
        case .like:
            particles = ["❤️", "💕", "💗"]
        case .clap:
            particles = ["👏", "✨", "🔥"]
        case .comb:
            particles = ["🪮", "✨", "💇🏾‍♀️"]
        case .perfume:
            particles = ["🧴", "💨", "✨"]
        case .lipstick:
            particles = ["💄", "💋", "✨"]
        case .makeup:
            particles = ["🎨", "✨", "💎"]
        case .nails:
            particles = ["💅", "✨", "💖"]
        case .straightener:
            particles = ["✨", "💇🏾‍♀️", "🔥"]
        case .sunglasses:
            particles = ["🕶", "😎", "✨"]
        case .hat:
            particles = ["🎩", "✨", "🔥"]
        case .crown:
            particles = ["👑", "💎", "✨"]
        case .giftBox:
            particles = ["🎁", "✨", "💰"]
        case .fireworks:
            particles = ["🎆", "🎇", "✨"]
        case .car:
            particles = ["🏎", "💨", "🔥"]
        case .lion:
            particles = ["🦁", "👑", "🔥", "💰"]
        case .universe:
            particles = ["🌌", "⭐️", "✨", "💫"]
        case .royalScissors:
            particles = ["✂️", "👑", "💎", "🔥", "💰"]
        }
        
        return particles[index % particles.count]
    }
}

// MARK: - Premium Logic

extension GiftAnimationView {
    
    private func isPremiumGift() -> Bool {
        switch gift {
        case .crown, .giftBox, .fireworks, .car, .lion, .universe, .royalScissors:
            return true
        default:
            return false
        }
    }
    
    private func premiumTitle() -> String {
        switch gift {
        case .lion:
            return "LION ROYAL"
        case .universe:
            return "UNIVERS CUTLY"
        case .royalScissors:
            return "CISEAUX ROYAL"
        case .car:
            return "STYLE SUPRÊME"
        case .fireworks:
            return "SHOW TIME"
        case .crown:
            return "ROI DU LIVE"
        default:
            return "CADEAU PREMIUM"
        }
    }
    
    private func mainSize() -> CGFloat {
        isPremiumGift() ? 125 : 90
    }
    
    private func particleCount() -> Int {
        isPremiumGift() ? 34 : 18
    }
    
    private func durationBeforeDisappear() -> Double {
        switch gift {
        case .royalScissors:
            return 3.2
        case .lion, .universe:
            return 2.8
        case .car, .fireworks:
            return 2.4
        default:
            return 1.8
        }
    }
    
    private func initialRotation() -> Double {
        switch gift {
        case .car:
            return 0
        case .royalScissors:
            return 30
        default:
            return 10
        }
    }
}

// MARK: - Particles Positions

extension GiftAnimationView {
    
    private func particleX(_ index: Int) -> CGFloat {
        let positions: [CGFloat] = [-170, -130, -95, -60, -25, 25, 60, 95, 130, 170]
        return positions[index % positions.count]
    }
    
    private func particleY(_ index: Int) -> CGFloat {
        let positions: [CGFloat] = [-260, -220, -180, -140, -100, -60, 40, 80, 120, 160]
        return positions[(index * 3) % positions.count]
    }
    
    private func particleSize(_ index: Int) -> CGFloat {
        let sizes: [CGFloat] = [22, 26, 30, 34, 38]
        return sizes[index % sizes.count]
    }
    
    private func glowColor() -> Color {
        switch gift {
        case .lion, .royalScissors, .crown:
            return .yellow
        case .universe:
            return .purple
        case .rose, .like, .lipstick, .nails:
            return .pink
        case .fireworks, .car:
            return .red
        default:
            return .white
        }
    }
}
