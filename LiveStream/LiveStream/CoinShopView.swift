import SwiftUI

struct CoinShopView: View {
    
    @Binding var isPresented: Bool
    
    @State private var isLoading = false
    @State private var selectedPack: CoinPack?
    @State private var errorMessage: String?
    
    var body: some View {
        
        ZStack {
            
            //////////////////////////////////////////////////////
            // 🔥 FOND (FERME UNIQUEMENT LE PANEL)
            //////////////////////////////////////////////////////
            
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isLoading {
                        isPresented = false
                    }
                }
            
            //////////////////////////////////////////////////////
            // 🔥 PANEL
            //////////////////////////////////////////////////////
            
            VStack(spacing: 16) {
                
                //////////////////////////////////////////////////////
                // 🔝 HEADER
                //////////////////////////////////////////////////////
                
                HStack {
                    Text("Acheter des coins")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        if !isLoading {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                //////////////////////////////////////////////////////
                // 🔥 LISTE PACKS
                //////////////////////////////////////////////////////
                
                ScrollView {
                    
                    VStack(spacing: 12) {
                        
                        ForEach(coinPacks) { pack in
                            
                            Button {
                                buyPack(pack)
                            } label: {
                                
                                HStack {
                                    
                                    //////////////////////////////////////////////////////
                                    // 🪙 INFOS PACK
                                    //////////////////////////////////////////////////////
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        
                                        Text("\(pack.totalCoins) coins")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                        
                                        if pack.bonus > 0 {
                                            Text("+\(pack.bonus) bonus 🎁")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    //////////////////////////////////////////////////////
                                    // 💰 PRIX
                                    //////////////////////////////////////////////////////
                                    
                                    Text(formatPrice(pack.priceEUR))
                                        .foregroundColor(.yellow)
                                        .font(.headline)
                                }
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(14)
                            }
                            .disabled(isLoading)
                        }
                    }
                    .padding()
                }
                
                //////////////////////////////////////////////////////
                // 🔥 ERREUR
                //////////////////////////////////////////////////////
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                //////////////////////////////////////////////////////
                // 🔄 LOADING
                //////////////////////////////////////////////////////
                
                if isLoading {
                    ProgressView("Paiement en cours...")
                        .foregroundColor(.white)
                        .padding(.bottom)
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding()
        }
    }
}

//////////////////////////////////////////////////////////
// 💳 ACHAT COINS (STRIPE PRO)
//////////////////////////////////////////////////////////

extension CoinShopView {
    
    func buyPack(_ pack: CoinPack) {
        
        isLoading = true
        selectedPack = pack
        errorMessage = nil
        
        //////////////////////////////////////////////////////
        // 🔥 FERMER LE SHOP D'ABORD
        //////////////////////////////////////////////////////
        
        isPresented = false
        
        //////////////////////////////////////////////////////
        // ⏳ ATTENDRE LA FIN DE L'ANIMATION
        //////////////////////////////////////////////////////
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            
            StripeService.shared.startPayment(
                amount: pack.priceEUR,
                description: "\(pack.totalCoins) coins"
            ) { success in
                
                DispatchQueue.main.async {
                    
                    isLoading = false
                    
                    if success {
                        
                        //////////////////////////////////////////////////////
                        // 🪙 AJOUT COINS
                        //////////////////////////////////////////////////////
                        
                        WalletService.shared.addCoins(pack.totalCoins)
                        
                        print("✅ Achat réussi : \(pack.totalCoins) coins")
                        
                    } else {
                        
                        //////////////////////////////////////////////////////
                        // ❌ ERREUR
                        //////////////////////////////////////////////////////
                        
                        errorMessage = "Paiement échoué. Réessaie."
                    }
                }
            }
        }
    }
    
    //////////////////////////////////////////////////////
    // 💰 FORMAT PRIX PROPRE
    //////////////////////////////////////////////////////
    
    func formatPrice(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "€\(Int(value))"
        } else {
            return String(format: "€%.2f", value)
        }
    }
}
