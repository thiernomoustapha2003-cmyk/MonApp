//
//  AfricanPaymentSheet.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY on 17/05/2026.
//

import SwiftUI

struct AfricanPaymentSheet: View {
    
    //////////////////////////////////////////////////////
    // 🌍 STATE
    //////////////////////////////////////////////////////
    
    @Binding var isPresented: Bool
    
    let amountEUR: Double
    let coinsAmount: Int
    
    //////////////////////////////////////////////////////
    // 💳 SERVICES
    //////////////////////////////////////////////////////
    
    @StateObject private var mobileService =
    MobileMoneyService.shared
    
    //////////////////////////////////////////////////////
    // 💳 UI
    //////////////////////////////////////////////////////
    
    @State private var selectedMethod:
    PaymentMethod?
    
    @State private var showSuccess = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    //////////////////////////////////////////////////////
    // 🎨 ANIMATION
    //////////////////////////////////////////////////////
    
    @State private var appear = false
    
    //////////////////////////////////////////////////////
    // 🌍 METHODS
    //////////////////////////////////////////////////////
    
    private let methods =
    PaymentMethod.defaultMethods
    
    //////////////////////////////////////////////////////
    // 🔥 BODY
    //////////////////////////////////////////////////////
    
    var body: some View {
        
        ZStack {
            
            //////////////////////////////////////////////////////
            // 🌑 BACKGROUND
            //////////////////////////////////////////////////////
            
            LinearGradient(
                colors: [
                    Color.black,
                    Color.black.opacity(0.92),
                    Color.indigo.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            //////////////////////////////////////////////////////
            // ✨ GLOW
            //////////////////////////////////////////////////////
            
            Circle()
                .fill(
                    Color.blue.opacity(0.25)
                )
                .frame(width: 320)
                .blur(radius: 60)
                .offset(y: -260)
            
            //////////////////////////////////////////////////////
            // 🔥 CONTENT
            //////////////////////////////////////////////////////
            
            VStack(spacing: 0) {
                
                //////////////////////////////////////////////////////
                // 🔝 HEADER
                //////////////////////////////////////////////////////
                
                header
                
                //////////////////////////////////////////////////////
                // 💰 PRICE
                //////////////////////////////////////////////////////
                
                premiumAmountCard
                
                //////////////////////////////////////////////////////
                // 🌍 METHODS
                //////////////////////////////////////////////////////
                
                methodsList
                
                //////////////////////////////////////////////////////
                // 🔥 BUTTON
                //////////////////////////////////////////////////////
                
                paymentButton
                
                Spacer(minLength: 20)
            }
            
            //////////////////////////////////////////////////////
            // 🔄 LOADING
            //////////////////////////////////////////////////////
            
            if isLoading {
                
                loadingOverlay
            }
            
            //////////////////////////////////////////////////////
            // ✅ SUCCESS
            //////////////////////////////////////////////////////
            
            if showSuccess {
                
                successOverlay
            }
        }
        .onAppear {
            withAnimation(.spring()) {
                appear = true
            }
        }
    }
}

//////////////////////////////////////////////////////////
// 🔝 HEADER
//////////////////////////////////////////////////////////

extension AfricanPaymentSheet {
    
    var header: some View {
        
        HStack {
            
            VStack(alignment: .leading, spacing: 8) {
                
                Text("Paiement sécurisé")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text("Achetez des coins partout dans le monde")
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button {
                isPresented = false
            } label: {
                
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding()
    }
}

//////////////////////////////////////////////////////////
// 💰 AMOUNT CARD
//////////////////////////////////////////////////////////

extension AfricanPaymentSheet {
    
    var premiumAmountCard: some View {
        
        VStack(spacing: 16) {
            
            //////////////////////////////////////////////////////
            // 🪙 COINS
            //////////////////////////////////////////////////////
            
            Text("🪙 \(coinsAmount)")
                .font(.system(size: 42, weight: .heavy))
                .foregroundColor(.yellow)
            
            //////////////////////////////////////////////////////
            // 🌍 LOCALIZED PRICE
            //////////////////////////////////////////////////////
            
            Text(
                CurrencyConverter.shared
                    .localizedPrice(
                        eurAmount: amountEUR
                    )
            )
            .font(.title.bold())
            .foregroundColor(.white)
            
            //////////////////////////////////////////////////////
            // 💶 BASE EUR
            //////////////////////////////////////////////////////
            
            Text(
                CurrencyConverter.shared
                    .formatEUR(amountEUR)
            )
            .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.25),
                            Color.yellow.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding()
    }
}

//////////////////////////////////////////////////////////
// 🌍 METHODS LIST
//////////////////////////////////////////////////////////

extension AfricanPaymentSheet {
    
    var methodsList: some View {
        
        ScrollView(showsIndicators: false) {
            
            LazyVStack(spacing: 16) {
                
                ForEach(methods) { method in
                    
                    Button {
                        
                        if method.isAvailable {
                            
                            withAnimation(.spring()) {
                                selectedMethod = method
                            }
                        }
                        
                    } label: {
                        
                        PaymentMethodCard(
                            method: method,
                            isSelected:
                                selectedMethod?.id == method.id
                        )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(
                        appear ? 1 : 0.92
                    )
                    .opacity(
                        appear ? 1 : 0
                    )
                }
            }
            .padding()
        }
    }
}

//////////////////////////////////////////////////////////
// 🔥 PAYMENT BUTTON
//////////////////////////////////////////////////////////

extension AfricanPaymentSheet {
    
    var paymentButton: some View {
        
        Button {
            startPayment()
        } label: {
            
            HStack(spacing: 12) {
                
                Image(systemName: "lock.fill")
                
                Text(buttonTitle())
                    .font(.headline.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: selectedMethod == nil
                            ? [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.3)
                            ]
                            : [
                                Color.pink,
                                Color.orange
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .padding()
        }
        .disabled(selectedMethod == nil || isLoading)
    }
}

//////////////////////////////////////////////////////////
// 🔄 LOADING
//////////////////////////////////////////////////////////

extension AfricanPaymentSheet {
    
    var loadingOverlay: some View {
        
        ZStack {
            
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 22) {
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(
                    mobileService.currentStatus.title
                )
                .foregroundColor(.white)
                .font(.headline)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black.opacity(0.92))
            )
        }
    }
}

//////////////////////////////////////////////////////////
// ✅ SUCCESS
//////////////////////////////////////////////////////////

extension AfricanPaymentSheet {
    
    var successOverlay: some View {
        
        ZStack {
            
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 22) {
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 90))
                    .foregroundColor(.green)
                
                Text("Paiement confirmé")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("Vos coins ont été ajoutés")
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.black)
            )
        }
    }
}

//////////////////////////////////////////////////////////
// 🚀 START PAYMENT
//////////////////////////////////////////////////////////

extension AfricanPaymentSheet {
    
    func startPayment() {
        
        guard let method = selectedMethod else {
            return
        }
        
        isLoading = true
        
        //////////////////////////////////////////////////////
        // 🍎 APPLE PAY / CARD
        //////////////////////////////////////////////////////
        
        if method.type == .applePay ||
            method.type == .stripeCard {
            
            StripeService.shared.startPayment(
                amount: amountEUR,
                description: "\(coinsAmount) coins"
            ) { success in
                
                handleResult(success)
            }
            
            return
        }
        
        //////////////////////////////////////////////////////
        // 🟠 ORANGE
        //////////////////////////////////////////////////////
        
        if method.type == .orangeMoney {
            
            mobileService.startOrangeMoneyPayment(
                amountEUR: amountEUR
            ) { success in
                
                handleResult(success)
            }
            
            return
        }
        
        //////////////////////////////////////////////////////
        // 🌊 WAVE
        //////////////////////////////////////////////////////
        
        if method.type == .wave {
            
            mobileService.startWavePayment(
                amountEUR: amountEUR
            ) { success in
                
                handleResult(success)
            }
            
            return
        }
        
        //////////////////////////////////////////////////////
        // 📱 MOBILE MONEY
        //////////////////////////////////////////////////////
        
        mobileService.startMobileMoneyPayment(
            amountEUR: amountEUR
        ) { success in
            
            handleResult(success)
        }
    }
    
    //////////////////////////////////////////////////////
    // ✅ RESULT
    //////////////////////////////////////////////////////
    
    func handleResult(_ success: Bool) {
        
        DispatchQueue.main.async {
            
            isLoading = false
            
            if success {
                
                //////////////////////////////////////////////////////
                // 🪙 ADD COINS
                //////////////////////////////////////////////////////
                
                WalletService.shared
                    .addCoins(coinsAmount)
                
                //////////////////////////////////////////////////////
                // ✅ SUCCESS UI
                //////////////////////////////////////////////////////
                
                withAnimation(.spring()) {
                    showSuccess = true
                }
                
                //////////////////////////////////////////////////////
                // 🔥 CLOSE
                //////////////////////////////////////////////////////
                
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 2.2
                ) {
                    
                    showSuccess = false
                    isPresented = false
                }
                
            } else {
                
                errorMessage =
                "Paiement échoué"
            }
        }
    }
}

//////////////////////////////////////////////////////////
// 🔥 BUTTON TITLE
//////////////////////////////////////////////////////////

extension AfricanPaymentSheet {
    
    func buttonTitle() -> String {
        
        guard let method = selectedMethod else {
            return "Choisir une méthode"
        }
        
        switch method.type {
            
        case .applePay:
            return "Payer avec Apple Pay"
            
        case .stripeCard:
            return "Payer par carte"
            
        case .orangeMoney:
            return "Payer avec Orange Money"
            
        case .wave:
            return "Payer avec Wave"
            
        case .mobileMoney:
            return "Payer avec Mobile Money"
            
        case .mtnMoney:
            return "Payer avec MTN Money"
            
        case .moovMoney:
            return "Payer avec Moov Money"
            
        default:
            return "Continuer"
        }
    }
}
