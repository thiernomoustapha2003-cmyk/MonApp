import SwiftUI
import StripePayments

struct PaymentBlockedView: View {

    let amount: Double
    let barberName: String
    let onConfirm: () -> Void

    @Environment(\.dismiss) var dismiss

    // ===========================
    // ✅ NOUVEAUX ÉTATS (AJOUTÉS)
    // ===========================
    @State private var isProcessingPayment = false
    @State private var paymentError: String? = nil
    @State private var showSuccessMessage = false

    var body: some View {
        VStack(spacing: 20) {

            Text("Paiement sécurisé")
                .font(.title2)
                .bold()

            Text("💳 Montant : \(amount, specifier: "%.2f") €")
                .font(.headline)

            Text("""
            L’argent sera BLOQUÉ (séquestré)  
            jusqu’à la fin de la prestation.

            Après votre coupe :
            → Vous confirmerez “Prestation OK”
            → L’argent sera ensuite versé au coiffeur.
            """)
            .multilineTextAlignment(.center)
            .padding()

            Text("Coiffeur : \(barberName)")
                .foregroundColor(.gray)

            Divider()

            // ===========================
            // 🔹 INDICATEUR DE CHARGEMENT
            // ===========================
            if isProcessingPayment {
                ProgressView("Blocage du paiement en cours…")
                    .padding()
            }

            if let error = paymentError {
                Text("❌ Erreur : \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if showSuccessMessage {
                Text("✅ Paiement bloqué avec succès !")
                    .foregroundColor(.green)
                    .bold()
            }

            // ===========================
            // ✅ TON BOUTON (GARDÉ + ADAPTÉ)
            // ===========================
            Button("Payer et bloquer l’argent") {

                isProcessingPayment = true
                paymentError = nil

                // 👉 Ici, plus tard, on branchera Stripe
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {

                    isProcessingPayment = false
                    showSuccessMessage = true

                    // 🔒 On exécute ton action (startEscrowPayment)
                    onConfirm()

                    // On ferme après 1 seconde
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        dismiss()
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)

            // ===========================
            // ✅ TON BOUTON ANNULER (GARDÉ)
            // ===========================
            Button("Annuler") {
                dismiss()
            }
            .foregroundColor(.red)
        }
        .padding()
    }
}
