//
//  PremiumCoinShopView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//
//
//
//

import SwiftUI

struct PremiumCoinShopView: View {
    
    @Binding var isPresented: Bool
    
    @State private var selectedPack: CoinPack?
    
    @State private var animateHeader = false
    
    var body: some View {
        ZStack {
            background
            
            VStack(spacing: 0) {
                header
                balanceCard
                packsList
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                animateHeader = true
            }
        }
        .fullScreenCover(item: $selectedPack) { pack in
            AfricanPaymentSheet(
                isPresented: Binding(
                    get: { selectedPack != nil },
                    set: { value in
                        if value == false {
                            selectedPack = nil
                        }
                    }
                ),
                amountEUR: pack.priceEUR,
                coinsAmount: pack.totalCoins
            )
        }
    }
}

extension PremiumCoinShopView {
    
    var background: some View {
        LinearGradient(
            colors: [
                Color.black,
                Color.purple.opacity(0.75),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("CUTLY COINS")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text("Achète des coins et soutiens tes créateurs préférés")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }
            
            Spacer()
            
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    var balanceCard: some View {
        VStack(spacing: 10) {
            Text("🪙")
                .font(.system(size: 50))
                .scaleEffect(animateHeader ? 1.12 : 1)
            
            Text("\(WalletService.shared.coins) coins")
                .font(.title.bold())
                .foregroundColor(.yellow)
            
            Text("Solde actuel")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.yellow.opacity(0.35), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    var packsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                
                Text("Choisis ton pack")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                ForEach(coinPacks) { pack in
                    PremiumCoinPackCard(
                        pack: pack,
                        badge: badgeForPack(pack)
                    ) {
                        selectedPack = pack
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    func badgeForPack(_ pack: CoinPack) -> String? {
        
        switch pack.totalCoins {
            
        case 40000...:
            return "ULTIME 👑"
            
        case 14500...:
            return "VIP ⭐️"
            
        case 6750...:
            return "POPULAIRE 🔥"
            
        case 3200...:
            return "BON PLAN 💎"
            
        case 1200...:
            return "BONUS 🎁"
            
        default:
            return nil
        }
    }
    
    struct PremiumCoinPackCard: View {
        
        let pack: CoinPack
        let badge: String?
        let action: () -> Void
        
        var body: some View {
            Button {
                action()
            } label: {
                ZStack(alignment: .topTrailing) {
                    
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.18))
                                .frame(width: 64, height: 64)
                            
                            Text("🪙")
                                .font(.system(size: 34))
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(pack.totalCoins) coins")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            if pack.bonus > 0 {
                                Text("+\(pack.bonus) bonus offert 🎁")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("Pack standard")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            
                            Text(CurrencyConverter.shared.localizedPrice(eurAmount: pack.priceEUR))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(CurrencyConverter.shared.formatEUR(pack.priceEUR))
                                .font(.headline.bold())
                                .foregroundColor(.yellow)
                            
                            Text("Apple Pay • Carte • Orange Money • Wave • MTN Money")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.12),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.yellow)
                            .cornerRadius(10)
                            .padding(.trailing, 28)
                            .padding(.top, -6)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}
