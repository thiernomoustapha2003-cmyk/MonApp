//
//  PaymentMethodCard.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY on 17/05/2026.
//

import SwiftUI

struct PaymentMethodCard: View {
    
    let method: PaymentMethod
    let isSelected: Bool
    
    var body: some View {
        
        ZStack {
            
            //////////////////////////////////////////////////////
            // 🔥 BACKGROUND
            //////////////////////////////////////////////////////
            
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: backgroundColors(),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            isSelected
                            ? Color.white.opacity(0.9)
                            : Color.white.opacity(0.08),
                            lineWidth: isSelected ? 2.5 : 1
                        )
                )
                .shadow(
                    color: method.color.opacity(0.35),
                    radius: isSelected ? 22 : 10
                )
            
            //////////////////////////////////////////////////////
            // ✨ PREMIUM LIGHT
            //////////////////////////////////////////////////////
            
            Circle()
                .fill(
                    method.color.opacity(0.18)
                )
                .frame(width: 180, height: 180)
                .blur(radius: 30)
                .offset(x: 120, y: -120)
            
            //////////////////////////////////////////////////////
            // 🔥 CONTENT
            //////////////////////////////////////////////////////
            
            VStack(alignment: .leading, spacing: 18) {
                
                //////////////////////////////////////////////////////
                // 🔝 TOP
                //////////////////////////////////////////////////////
                
                HStack(alignment: .top) {
                    
                    //////////////////////////////////////////////////////
                    // 🌍 ICON
                    //////////////////////////////////////////////////////
                    
                    ZStack {
                        
                        Circle()
                            .fill(method.color.opacity(0.22))
                            .frame(width: 62, height: 62)
                        
                        Image(systemName: method.icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(method.color)
                    }
                    
                    Spacer()
                    
                    //////////////////////////////////////////////////////
                    // 🏷 BADGES
                    //////////////////////////////////////////////////////
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        
                        badge(
                            text: method.badgeText,
                            color: badgeColor()
                        )
                        
                        if method.requiresExternalApp {
                            badge(
                                text: "App externe",
                                color: .orange
                            )
                        }
                    }
                }
                
                //////////////////////////////////////////////////////
                // 💳 INFOS
                //////////////////////////////////////////////////////
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    Text(method.title)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text(method.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.72))
                        .multilineTextAlignment(.leading)
                }
                
                //////////////////////////////////////////////////////
                // 🌍 FOOTER
                //////////////////////////////////////////////////////
                
                HStack {
                    
                    //////////////////////////////////////////////////////
                    // 💱 CURRENCY
                    //////////////////////////////////////////////////////
                    
                    HStack(spacing: 6) {
                        
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                        
                        Text(method.currencyCode)
                            .foregroundColor(.white.opacity(0.85))
                            .font(.caption.bold())
                    }
                    
                    Spacer()
                    
                    //////////////////////////////////////////////////////
                    // ⚡ SPEED
                    //////////////////////////////////////////////////////
                    
                    HStack(spacing: 6) {
                        
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.green)
                        
                        Text(method.processingTime)
                            .foregroundColor(.white.opacity(0.85))
                            .font(.caption.bold())
                    }
                }
            }
            .padding(20)
        }
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(.spring(response: 0.35), value: isSelected)
    }
}

//////////////////////////////////////////////////////////
// 🏷 BADGE
//////////////////////////////////////////////////////////

extension PaymentMethodCard {
    
    @ViewBuilder
    func badge(
        text: String,
        color: Color
    ) -> some View {
        
        Text(text)
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.9))
            )
    }
}

//////////////////////////////////////////////////////////
// 🎨 COLORS
//////////////////////////////////////////////////////////

extension PaymentMethodCard {
    
    func backgroundColors() -> [Color] {
        
        switch method.type {
            
        //////////////////////////////////////////////////////
        // 🍎 APPLE PAY
        //////////////////////////////////////////////////////
            
        case .applePay:
            return [
                Color.black,
                Color.gray.opacity(0.7)
            ]
            
        //////////////////////////////////////////////////////
        // 💳 CARD
        //////////////////////////////////////////////////////
            
        case .stripeCard:
            return [
                Color.blue.opacity(0.9),
                Color.indigo
            ]
            
        //////////////////////////////////////////////////////
        // 🟠 ORANGE
        //////////////////////////////////////////////////////
            
        case .orangeMoney:
            return [
                Color.orange,
                Color.orange.opacity(0.6)
            ]
            
        //////////////////////////////////////////////////////
        // 🌊 WAVE
        //////////////////////////////////////////////////////
            
        case .wave:
            return [
                Color.cyan,
                Color.blue
            ]
            
        //////////////////////////////////////////////////////
        // 📱 MOBILE
        //////////////////////////////////////////////////////
            
        case .mobileMoney:
            return [
                Color.green,
                Color.mint
            ]
            
        //////////////////////////////////////////////////////
        // 🟡 MTN
        //////////////////////////////////////////////////////
            
        case .mtnMoney:
            return [
                Color.yellow.opacity(0.9),
                Color.orange
            ]
            
        //////////////////////////////////////////////////////
        // 🟣 MOOV
        //////////////////////////////////////////////////////
            
        case .moovMoney:
            return [
                Color.purple,
                Color.indigo
            ]
            
        //////////////////////////////////////////////////////
        // 🔮 FUTURE
        //////////////////////////////////////////////////////
            
        default:
            return [
                Color.gray,
                Color.black
            ]
        }
    }
    
    func badgeColor() -> Color {
        
        if !method.isAvailable {
            return .gray
        }
        
        if method.isRecommended {
            return .pink
        }
        
        return .green
    }
}
