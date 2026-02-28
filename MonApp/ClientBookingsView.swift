import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ClientBookingsView: View {

    @State private var bookings: [Booking] = []

    var body: some View {

        List(bookings) { booking in

            HStack(spacing: 12) {

                // Pas d'image dans ton Booking → avatar par défaut
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 55, height: 55)
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 6) {

                    Text(booking.barberName)
                        .font(.headline)

                    Text("📅 \(booking.date) à \(booking.time)")
                        .font(.subheadline)

                    Text(statusText(booking.status))
                        .font(.caption2)
                        .padding(6)
                        .background(statusColor(booking.status).opacity(0.15))
                        .foregroundColor(statusColor(booking.status))
                        .cornerRadius(6)

                    // paiement
                    Text(paymentText(booking.paymentStatus))
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Mes réservations")
        .onAppear {
            loadBookings()
        }
    }

    // MARK: FIRESTORE MANUEL (SANS CODABLE)

    func loadBookings() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("bookings")
            .whereField("clientId", isEqualTo: uid)
            .getDocuments { snapshot, error in

                guard let docs = snapshot?.documents else { return }

                bookings = docs.compactMap { doc in

                    let d = doc.data()

                    return Booking(
                        id: doc.documentID,
                        barberId: d["barberId"] as? String ?? "",
                        barberName: d["barberName"] as? String ?? "",
                        clientName: d["clientName"] as? String ?? "",
                        clientId: d["clientId"] as? String ?? "",
                        date: d["date"] as? String ?? "",
                        time: d["time"] as? String ?? "",
                        status: d["status"] as? String ?? "pending",
                        paymentStatus: d["paymentStatus"] as? String ?? "not_paid",
                        escrowStatus: d["escrowStatus"] as? String ?? "not_started"
                    )
                }
            }
    }

    // MARK: UI STATUS

    func statusText(_ status: String) -> String {
        switch status {
        case "pending": return "En attente"
        case "confirmed": return "Confirmé"
        case "completed": return "Terminé"
        case "cancelled": return "Annulé"
        default: return status
        }
    }

    func statusColor(_ status: String) -> Color {
        switch status {
        case "pending": return .orange
        case "confirmed": return .blue
        case "completed": return .green
        case "cancelled": return .red
        default: return .gray
        }
    }

    func paymentText(_ payment: String) -> String {
        switch payment {
        case "paid": return "💳 Payé"
        case "not_paid": return "💰 Non payé"
        default: return payment
        }
    }
}
