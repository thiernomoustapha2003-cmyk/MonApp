import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct InvoicesView: View {

    @State private var invoices: [QueryDocumentSnapshot] = []
    @State private var loading = true

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {

            if loading {
                ProgressView("Chargement des factures...")
                    .padding(.top, 60)
            }
            else if invoices.isEmpty {
                Text("Aucune facture disponible")
                    .foregroundColor(.gray)
                    .padding(.top, 60)
            }
            else {

                List(invoices, id: \.documentID) { doc in

                    let data = doc.data()

                    let client = data["clientName"] as? String ?? "Client"
                    let amount = data["barberPaidAmount"] as? Double ?? 0
                    let releasedAt = (data["releasedAt"] as? Timestamp)?.dateValue()

                    VStack(alignment: .leading, spacing: 8) {

                        Text(client)
                            .font(.headline)

                        if let releasedAt {
                            Text("📅 \(releasedAt.formatted(date: .abbreviated, time: .shortened))")
                                .foregroundColor(.gray)
                        }

                        Text("Montant: \(String(format: "%.2f", amount)) €")
                            .font(.subheadline)

                        Button {
                            downloadInvoice(doc: doc)
                        } label: {
                            Label("Télécharger la facture", systemImage: "arrow.down.doc")
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Factures")
        .onAppear {
            loadInvoices()
        }
    }
}

// MARK: - Firestore
extension InvoicesView {

    func loadInvoices() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        loading = true

        db.collection("bookings")
            .whereField("barberId", isEqualTo: uid)
            .whereField("paymentStatus", isEqualTo: "paid")
            .whereField("escrowStatus", isEqualTo: "released")
            .order(by: "releasedAt", descending: true)
            .getDocuments { snapshot, error in

                DispatchQueue.main.async {
                    loading = false
                }

                guard let documents = snapshot?.documents else {
                    print("❌ Pas de factures")
                    return
                }

                DispatchQueue.main.async {
                    invoices = documents
                }
            }
    }

    func downloadInvoice(doc: QueryDocumentSnapshot) {

        let data = doc.data()

        guard let urlString = data["receiptUrl"] as? String,
              let url = URL(string: urlString) else {
            print("❌ Pas de reçu Stripe")
            return
        }

        UIApplication.shared.open(url)
    }
}
