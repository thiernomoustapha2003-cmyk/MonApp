import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ClientBookingDetailView: View {

    let booking: Booking
    let barberImageUrl: String

    @Environment(\.dismiss) var dismiss
    @State private var showConfirmAlert = false
    @State private var actionMessage = ""

    private let db = Firestore.firestore()

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {

                AsyncImage(url: URL(string: barberImageUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())

                Text(booking.barberName)
                    .font(.largeTitle)
                    .bold()

                VStack(alignment: .leading, spacing: 14) {
                    infoRow("📅 Date", booking.date)
                    infoRow("⏰ Heure", booking.time)
                    infoRow("📌 Statut", statusText(booking.status))
                    infoRow("💳 Paiement", paymentText(booking.paymentStatus))
                    infoRow("🔒 Sécurité", escrowText(booking.escrowStatus))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.08), radius: 8)

                Button("💬 Contacter le coiffeur") {
                    print("Ouvrir message avec \(booking.barberName)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(14)

                Button(actionButtonTitle()) {
                    showConfirmAlert = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(actionButtonColor())
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .padding()
        }
        .navigationTitle("Détail réservation")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .alert(actionButtonTitle(), isPresented: $showConfirmAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Confirmer", role: .destructive) {
                handleBookingAction()
            }
        } message: {
            Text(actionAlertMessage())
        }
    }

    func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundColor(.gray)
            Spacer()
            Text(value).bold()
        }
    }

    func actionButtonTitle() -> String {
        if booking.status == "completed" || booking.escrowStatus == "released" {
            return "⚠️ Signaler un problème"
        }

        if booking.paymentStatus == "paid" || booking.escrowStatus == "held" {
            return "💸 Demander un remboursement"
        }

        return "❌ Annuler la réservation"
    }

    func actionButtonColor() -> Color {
        if booking.status == "completed" || booking.escrowStatus == "released" {
            return .orange
        }

        if booking.paymentStatus == "paid" || booking.escrowStatus == "held" {
            return .purple
        }

        return .red
    }

    func actionAlertMessage() -> String {
        if booking.status == "completed" || booking.escrowStatus == "released" {
            return "La prestation est terminée. Vous pouvez signaler un problème, mais l’annulation directe n’est plus possible."
        }

        if booking.paymentStatus == "paid" || booking.escrowStatus == "held" {
            return "Votre paiement a déjà été effectué. Une demande de remboursement sera envoyée."
        }

        return "Cette réservation n’est pas encore payée. Elle sera annulée immédiatement."
    }

    func handleBookingAction() {
        if booking.status == "completed" || booking.escrowStatus == "released" {
            reportProblem()
        } else if booking.paymentStatus == "paid" || booking.escrowStatus == "held" {
            requestRefund()
        } else {
            cancelUnpaidBooking()
        }
    }

    func cancelUnpaidBooking() {
        db.collection("bookings").document(booking.id).updateData([
            "status": "cancelled",
            "paymentStatus": "not_paid",
            "escrowStatus": "not_started",
            "cancelledBy": Auth.auth().currentUser?.uid ?? "",
            "cancelledAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Erreur annulation:", error.localizedDescription)
                return
            }

            if !booking.slotId.isEmpty {

                db.collection("slots")
                    .document(booking.slotId)
                    .updateData([
                        "status": "available"
                    ]) { error in

                        if let error = error {
                            print("❌ Erreur libération slot:", error.localizedDescription)
                        } else {
                            print("✅ Slot remis disponible")
                        }
                    }
            }
            
            print("✅ Réservation annulée")
            dismiss()
        }
    }

    func requestRefund() {
        db.collection("bookings").document(booking.id).updateData([
            "status": "refund_requested",
            "paymentStatus": "refund_pending",
            "escrowStatus": "refund_requested",
            "refundRequestedBy": Auth.auth().currentUser?.uid ?? "",
            "refundRequestedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Erreur demande remboursement:", error.localizedDescription)
                return
            }

            print("✅ Demande de remboursement envoyée")
            dismiss()
        }
    }

    func reportProblem() {
        db.collection("bookings").document(booking.id).updateData([
            "status": "dispute_opened",
            "disputeBy": Auth.auth().currentUser?.uid ?? "",
            "disputeCreatedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Erreur signalement:", error.localizedDescription)
                return
            }

            print("✅ Problème signalé")
            dismiss()
        }
    }

    func statusText(_ status: String) -> String {
        switch status {
        case "pending": return "En attente"
        case "pending_payment": return "Paiement en attente"
        case "confirmed": return "Confirmé"
        case "completed": return "Terminé"
        case "cancelled": return "Annulé"
        case "refund_requested": return "Remboursement demandé"
        case "dispute_opened": return "Réclamation ouverte"
        default: return status
        }
    }

    func paymentText(_ payment: String) -> String {
        switch payment {
        case "paid": return "Payé"
        case "not_paid": return "Non payé"
        case "refund_pending": return "Remboursement en attente"
        case "refunded": return "Remboursé"
        default: return payment
        }
    }

    func escrowText(_ escrow: String) -> String {
        switch escrow {
        case "held": return "Argent sécurisé"
        case "released": return "Paiement libéré"
        case "not_started": return "Pas encore démarré"
        case "refund_requested": return "Remboursement demandé"
        default: return escrow
        }
    }
}
