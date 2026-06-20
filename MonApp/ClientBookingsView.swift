import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ClientBookingsView: View {

    @State private var bookings: [Booking] = []
    @State private var barberImages: [String: String] = [:]

    var body: some View {

        List(bookings) { booking in
            
            NavigationLink {
                ClientBookingDetailView(
                    booking: booking,
                    barberImageUrl: barberImages[booking.barberId] ?? ""
                )
            } label: {
                HStack(spacing: 12) {
                    
                    // Pas d'image dans ton Booking → avatar par défaut
                    AsyncImage(url: URL(string: barberImages[booking.barberId] ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    
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

                if let error = error {
                    print("❌ Erreur chargement réservations:", error.localizedDescription)
                    return
                }

                guard let docs = snapshot?.documents else { return }

                let loadedBookings = docs.compactMap { doc -> Booking? in

                    let d = doc.data()

                    let startDate = (d["startTime"] as? Timestamp)?.dateValue()

                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "fr_FR")
                    dateFormatter.dateFormat = "dd/MM/yyyy"

                    let timeFormatter = DateFormatter()
                    timeFormatter.locale = Locale(identifier: "fr_FR")
                    timeFormatter.dateFormat = "HH:mm"

                    let cleanDate = d["date"] as? String
                        ?? (startDate != nil ? dateFormatter.string(from: startDate!) : "")

                    let cleanTime = d["time"] as? String
                        ?? (startDate != nil ? timeFormatter.string(from: startDate!) : "")

                    return Booking(
                        id: doc.documentID,
                        barberId: d["barberId"] as? String ?? "",
                        barberName: d["barberName"] as? String ?? "Coiffeur",
                        clientName: d["clientName"] as? String ?? "",
                        clientId: d["clientId"] as? String ?? "",
                        date: cleanDate,
                        time: cleanTime,
                        status: d["status"] as? String ?? "pending",
                        slotId: d["slotId"] as? String ?? "",
                        paymentStatus: d["paymentStatus"] as? String ?? "not_paid",
                        escrowStatus: d["escrowStatus"] as? String ?? "not_started"
                    )
                }

                DispatchQueue.main.async {
                    self.bookings = loadedBookings
                    self.loadBarberImages()
                }
            }
    }

    func loadBarberImages() {
        let db = Firestore.firestore()

        for booking in bookings {
            db.collection("users")
                .document(booking.barberId)
                .getDocument { snap, _ in
                    let imageUrl = snap?.data()?["imageUrl"] as? String ?? ""

                    DispatchQueue.main.async {
                        barberImages[booking.barberId] = imageUrl
                    }
                }
        }
    }
    
    // MARK: UI STATUS

    func statusText(_ status: String) -> String {
        switch status {
        case "pending": return "En attente"
        case "pending_payment": return "Paiement en attente"
        case "confirmed": return "Confirmé"
        case "completed": return "Terminé"
        case "cancelled": return "Annulé"
        default: return status
        }
    }

    func statusColor(_ status: String) -> Color {
        switch status {
        case "pending", "pending_payment": return .orange
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
