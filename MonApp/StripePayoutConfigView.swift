import SwiftUI
import FirebaseAuth

struct StripePayoutConfigView: View {

    @StateObject private var paymentService = PaymentService()
    @State private var isLoading = false
    @State private var message = ""

    var body: some View {
        VStack(spacing: 25) {

            Text("Configurer Stripe")
                .font(.title2)
                .bold()

            Text("Connectez votre compte Stripe pour recevoir vos paiements.")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if isLoading {
                ProgressView("Connexion en cours...")
            }

            Button(action: connectStripe) {
                Text("Connecter mon compte Stripe")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }

    // =====================================================
    // 🔗 CONNEXION STRIPE
    // =====================================================
    func connectStripe() {

        isLoading = true
        message = ""

        paymentService.createStripeConnectAccount { urlString in

            DispatchQueue.main.async {
                isLoading = false

                guard let urlString = urlString,
                      let finalURL = URL(string: urlString) else {

                    message = "Erreur lors de la connexion Stripe"
                    return
                }

                UIApplication.shared.open(finalURL)
            }
        }
    }
}
