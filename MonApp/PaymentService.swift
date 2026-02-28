import Foundation
import Combine
import Stripe
import StripePaymentSheet
import FirebaseAuth

class PaymentService: ObservableObject {

    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?

    // ✅ URL CLOUD RUN PRODUCTION
    private let paymentIntentURL = URL(string:
        "https://createpaymentintent-jzvik52b6a-uc.a.run.app"
    )!

    private let stripeConnectURL = URL(string:
        "https://createstripeaccount-jzvik52b6a-uc.a.run.app"
    )!

    // =====================================================
    // 💳 PRÉPARER LE PAIEMENT
    // =====================================================
    func preparePayment(
        amount: Int,
        bookingId: String,
        barberId: String,
        clientId: String,
        slotId: String,
        clientEmail: String,
        completion: @escaping (Bool) -> Void
    ) {

        var request = URLRequest(url: paymentIntentURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "amount": amount,
            "bookingId": bookingId,
            "barberId": barberId,
            "clientId": clientId,
            "slotId": slotId,
            "clientEmail": clientEmail
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ Erreur réseau:", error)
                DispatchQueue.main.async { completion(false) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let clientSecret = json["clientSecret"] as? String else {

                print("❌ Erreur JSON")
                DispatchQueue.main.async { completion(false) }
                return
            }

            print("✅ Client Secret reçu:", clientSecret)

            STPAPIClient.shared.publishableKey =
            "pk_test_51SvGmGPeql1aQTZ7DPBJJUOW3cb6X5oNVfD0Zx4xvUEwrCVcAjUCHKuZUTk8bVxpvVHAorcZsSabltgJoigFXu1600Eey5pria"

            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Cutly"

            DispatchQueue.main.async {
                self.paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: clientSecret,
                    configuration: configuration
                )
                completion(true)
            }

        }.resume()
    }

    // =====================================================
    // 🏦 CRÉER COMPTE STRIPE CONNECT
    // =====================================================
    func createStripeConnectAccount(completion: @escaping (String?) -> Void) {

        guard let barberId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }

        var request = URLRequest(url: stripeConnectURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "barberId": barberId
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ Erreur Stripe Connect:", error)
                completion(nil)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let urlString = json["url"] as? String else {

                print("❌ Erreur récupération URL Stripe")
                completion(nil)
                return
            }

            completion(urlString)

        }.resume()
    }
}
