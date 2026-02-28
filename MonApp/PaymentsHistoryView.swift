import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PaymentsHistoryView: View {
    @State private var history: [QueryDocumentSnapshot] = []
    @State private var bookings: [QueryDocumentSnapshot] = []
    @State private var loading = true

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {

            if loading {
                ProgressView("Chargement de l'historique...")
                    .padding(.top, 60)
            }
            else if history.isEmpty {
                Text("Aucun paiement pour le moment")
                    .foregroundColor(.gray)
                    .padding(.top, 60)
            }
            else {

                List(history, id: \.documentID) { doc in

                    let data = doc.data()

                    let client = data["clientName"] as? String ?? "Client"
                    let amount = data["barberPaidAmount"] as? Double ?? 0
                    let commission = data["platformCommission"] as? Double ?? 0
                    let paid = data["paymentStatus"] as? String ?? "pending"
                    let releaseDate = (data["releasedAt"] as? Timestamp)?.dateValue()

                    VStack(alignment: .leading, spacing: 8) {

                        HStack {
                            Text(client)
                                .font(.headline)

                            Spacer()

                            Text(paid == "paid" ? "Payé" : "En attente")
                                .font(.caption)
                                .padding(6)
                                .background(paid == "paid" ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                .cornerRadius(6)
                        }

                        if let releaseDate {
                            Text("📅 \(releaseDate.formatted(date: .abbreviated, time: .shortened))")
                                .foregroundColor(.gray)
                        }

                        HStack {
                            Text("Commission: \(String(format: "%.2f", commission)) €")
                                .font(.subheadline)

                            Spacer()

                            Text("Reçu: \(String(format: "%.2f", amount)) €")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Historique paiements")
        .onAppear {
            loadHistory()
        }
    }
}

// FIRESTORE
extension PaymentsHistoryView {
    
    func loadHistory() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        loading = true
        
        db.collection("bookings")
            .whereField("barberId", isEqualTo: uid)
            .whereField("paymentStatus", isEqualTo: "paid")
            .whereField("escrowStatus", isEqualTo: "released")
            .order(by: "releasedAt", descending: true)
            .getDocuments { snapshot, error in
                
                DispatchQueue.main.async {
                    self.loading = false
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ Aucun document")
                    return
                }
                
                print("✅ Paiements trouvés:", documents.count)
                
                DispatchQueue.main.async {
                    self.history = documents
                }
            }
    }
}
