import SwiftUI
import FirebaseAuth

struct BarberPayoutsView: View {
    
    @State private var nextPayoutAmount: Double = 0
    @State private var nextPayoutDate: Date?

    @State private var payouts: [Payout] = []
    @State private var totalEarned: Double = 0
    @State private var loading = true
    @State private var errorMessage: String?
    
    // NEXT PAYOUT (affichage UI)
    @State private var nextAmount: Double = 0
    @State private var nextDate: Double? = nil
    

    var body: some View {
        NavigationStack {

            Group {

                if loading {
                    ProgressView("Chargement des virements...")
                }

                else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                else if payouts.isEmpty {
                    Text("Aucun virement pour le moment")
                        .foregroundColor(.gray)
                }

                else {
                    List {

                        // 💰 TOTAL
                        Section {
                            Text("\(String(format: "%.2f", totalEarned)) €")
                                .font(.largeTitle.bold())
                                .foregroundColor(.green)
                        } header: {
                            Text("Total gagné")
                        }

                        // ==========================
                        // PROCHAIN VIREMENT STRIPE
                        // ==========================
                        if nextAmount > 0 {
                            VStack(alignment: .leading, spacing: 8) {

                                Text("Prochain virement")
                                    .font(.headline)

                                Text("\(String(format: "%.2f", nextAmount)) €")
                                    .font(.title2.bold())

                                if let nextDate {
                                    Text(Date(timeIntervalSince1970: nextDate), style: .date)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        
                        // 📄 LISTE
                        Section {
                            ForEach(payouts) { payout in
                                VStack(alignment: .leading, spacing: 6) {

                                    Text("\(String(format: "%.2f", payout.amount)) €")
                                        .font(.headline)

                                    Text(payout.client)
                                        .foregroundColor(.gray)

                                    Text(payout.formattedDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                        } header: {
                            Text("Historique des virements")
                        }
                    }
                }
            }
        }
        .navigationTitle("Mes virements")
        .onAppear {
            print("🔥 BarberPayoutsView ouverte 🔥")
            loadPayouts()
            loadNextPayout()
        }
    }
}

// MARK: - API CALL
extension BarberPayoutsView {
    
    func loadPayouts() {
        
        guard let barberId = Auth.auth().currentUser?.uid else {
            errorMessage = "Utilisateur non connecté"
            return
        }
        
        loading = true
        errorMessage = nil
        
        PayoutService.shared.fetchPayouts(barberId: barberId) { result in
            
            switch result {
                
            case .success(let response):
                
                DispatchQueue.main.async {
                    self.loading = false
                    self.totalEarned = response.totalEarned
                    self.payouts = response.payouts
                    
                    print("API RESPONSE:", response)
                    print("✅ payouts chargés")
                }
                
            case .failure(let error):
                
                DispatchQueue.main.async {
                    self.loading = false
                    self.errorMessage = "Impossible de charger les virements"
                    print("PAYOUT ERROR:", error)
                }
            }
        }
    }
    
    // PROCHAIN VIREMENT STRIPE
    func loadNextPayout() {
        
        guard let barberId = Auth.auth().currentUser?.uid else { return }
        
        print("💸 récupération prochain virement...")
        
        PayoutService.shared.fetchNextPayout(barberId: barberId) { result in
            
            DispatchQueue.main.async {
                switch result {
                    
                case .success(let payout):

                    print("✅ prochain payout:", payout.amount, payout.nextPayout as Any)

                    // centimes -> euros
                    self.nextAmount = Double(payout.amount) / 100.0

                    // timestamp -> date
                    if let ts = payout.nextPayout {
                        self.nextDate = Double(ts)
                        self.nextPayoutDate = Date(timeIntervalSince1970: TimeInterval(ts))
                    } else {
                        self.nextDate = nil
                        self.nextPayoutDate = nil
                    }
                    
                case .failure(let error):
                    print("❌ erreur prochain payout:", error.localizedDescription)
                }
            }
        }
    }
}

