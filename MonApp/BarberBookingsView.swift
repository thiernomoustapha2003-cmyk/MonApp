import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct BarberBookingsView: View {

    @State private var loading = false
    @State private var bookings: [QueryDocumentSnapshot] = []
    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {

            List {

                ForEach(bookings, id: \.documentID) { doc in

                    let data = doc.data()

                    let status = data["escrowStatus"] as? String ?? "held"
                    let client = data["clientName"] as? String ?? "Client"
                    let price = data["price"] as? Double ?? 0
                    let time = data["time"] as? String ?? "--:--"

                    VStack(alignment: .leading, spacing: 6) {

                        Text(client)
                            .font(.headline)

                        Text("💰 \(String(format: "%.2f", price)) €")
                            .font(.subheadline)

                        Text("⏰ \(time)")
                            .foregroundColor(.gray)

                        if status != "released" {
                            Button("Terminer la prestation") {
                                markBookingCompleted(doc: doc)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        else {
                            Text("✔️ Terminé")
                                .foregroundColor(.green)
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Rendez-vous clients")
            .onAppear(perform: loadBookings)
        }
    }
}
extension BarberBookingsView {
    
    func loadBookings() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("bookings")
            .whereField("barberId", isEqualTo: uid)
            .order(by: "date", descending: true)
            .getDocuments { snapshot, _ in
                bookings = snapshot?.documents ?? []
            }
    }
    func markBookingCompleted(doc: QueryDocumentSnapshot) {

        let bookingId = doc.documentID

        loading = true

        db.collection("bookings")
            .document(bookingId)
            .updateData([
                "status": "completed",
                "escrowStatus": "released",
                "releasedAt": Timestamp(date: Date())
            ]) { error in

                DispatchQueue.main.async {
                    loading = false
                    loadBookings()
                }

                if let error = error {
                    print("❌ Release failed:", error.localizedDescription)
                } else {
                    print("✅ Argent libéré pour le barber")
                }
            }
    }
}
