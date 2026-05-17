import SwiftUI

struct GiftSelectionView: View {
    
    var onSelect: (Gift) -> Void
    @Binding var isPresented: Bool
    
    // 🔥 ETAT PAIEMENT
    @State private var selectedGift: Gift? = nil
    @State private var showPaymentSheet = false
    
    // 🔥 devise dynamique
    let conversionRateUSD: Double = 1.08
    let conversionRateGNF: Double = 9300
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            //////////////////////////////////////////////////////
            // 🔥 FOND (SEULEMENT EN DEHORS)
            //////////////////////////////////////////////////////
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            //////////////////////////////////////////////////////
            // 🔥 PANEL CADEAUX (NE FERME PAS)
            //////////////////////////////////////////////////////
            VStack(spacing: 10) {
                
                // 🔝 HEADER
                HStack {
                    Text("Envoyer un cadeau")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        isPresented = false
                    
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                
                //////////////////////////////////////////////////////
                // 🔥 LISTE CADEAUX
                //////////////////////////////////////////////////////
                
                ScrollView {
                    
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 16
                    ) {
                        
                        ForEach(giftCatalog) { gift in
                            
                            Button {
                                handlePurchase(gift)
                            } label: {
                                
                                VStack(spacing: 6) {
                                    
                                    Text(gift.emoji)
                                        .font(.system(size: 40))
                                    
                                    Text(gift.name)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    
                                    Text("\(gift.coins) coins")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    
                                    Text(formatPriceMulti(gift.priceEUR))
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            // 🔥 TRÈS IMPORTANT (empêche fermeture quand tu touches dedans)
            .onTapGesture {
                // ne rien faire → bloque la propagation
            }
        }
        
        //////////////////////////////////////////////////////
        // 💳 SHEET PAIEMENT (PROPRE)
        //////////////////////////////////////////////////////
        .sheet(isPresented: $showPaymentSheet) {
            
            if let gift = selectedGift {
                
                VStack(spacing: 20) {
                    
                    Text("Acheter \(gift.name)")
                        .font(.title2)
                    
                    Text("Prix : \(formatClean(gift.priceEUR, symbol: "€"))")
                    
                    Text("Achète d’abord des coins pour envoyer ce cadeau.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button("🪙 Payer avec coins") {
                        WalletService.shared.spendCoins(gift.coins) { success in
                            
                            if success {
                                onSelect(gift)
                            } else {
                                print("❌ Pas assez de coins")
                            }
                            
                            showPaymentSheet = false
                        }
                    }
                    
                    Button("❌ Annuler") {
                        showPaymentSheet = false
                    }
                }
                .padding()
            }
        }
    }
}

//////////////////////////////////////////////////////////
// 🔥 LOGIQUE ACHAT
//////////////////////////////////////////////////////////

extension GiftSelectionView {
    
    func handlePurchase(_ gift: Gift) {
        selectedGift = gift
        showPaymentSheet = true
    }
    
    func startStripePayment(_ gift: Gift) {
        
        StripeService.shared.startPayment(
            amount: gift.priceEUR,
            description: gift.name
        ) { success in
            
            if success {
                onSelect(gift)
            }
            
            showPaymentSheet = false
        }
    }
}

//////////////////////////////////////////////////////////
// 🔥 FORMAT PRIX MULTI-DEVISE
//////////////////////////////////////////////////////////

extension GiftSelectionView {
    
    func formatPriceMulti(_ value: Double) -> String {
        
        let eur = value
        let usd = value * conversionRateUSD
        let gnf = value * conversionRateGNF
        
        return "\(formatClean(eur, symbol: "€"))\n\(formatClean(usd, symbol: "$"))\n\(formatGNF(gnf))"
    }
    
    func formatClean(_ value: Double, symbol: String) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(symbol)\(Int(value))"
        } else {
            return String(format: "\(symbol)%.2f", value)
        }
    }
    
    func formatGNF(_ value: Double) -> String {
        return "\(Int(value)) GNF"
    }
}
