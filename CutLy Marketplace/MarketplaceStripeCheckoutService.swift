//
//  MarketplaceStripeCheckoutService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 07/07/2026.
//

//
//  MarketplaceStripeCheckoutService.swift
//  MonApp
//

import Foundation
import FirebaseAuth
import Stripe
import Combine
import StripePaymentSheet

final class MarketplaceStripeCheckoutService: ObservableObject {

    static let shared = MarketplaceStripeCheckoutService()

    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?

    private init() {}

    private let marketplacePaymentIntentURL = URL(string:
        "https://createmarketplacepaymentintent-jzvik52b6a-uc.a.run.app"
    )!

    func prepareMarketplacePayment(
        orderId: String,
        amount: Double,
        sellerId: String,
        buyerEmail: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard let buyer = Auth.auth().currentUser else {
            completion(false)
            return
        }

        var request = URLRequest(url: marketplacePaymentIntentURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "amount": Int(amount * 100),
            "orderId": orderId,
            "sellerId": sellerId,
            "buyerId": buyer.uid,
            "clientEmail": buyerEmail,
            "source": "cutly_marketplace"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                print("❌ Marketplace Stripe réseau:", error.localizedDescription)
                DispatchQueue.main.async { completion(false) }
                return
            }

            guard let data else {
                print("❌ Aucune donnée renvoyée")
                DispatchQueue.main.async { completion(false) }
                return
            }

            print("========== RÉPONSE SERVEUR ==========")
            print(String(data: data, encoding: .utf8) ?? "Réponse illisible")
            print("=====================================")

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let clientSecret = json["clientSecret"] as? String
            else {
                print("❌ Marketplace Stripe clientSecret absent")
                DispatchQueue.main.async { completion(false) }
                return
            }

            print("✅ clientSecret reçu Stripe:", clientSecret)

            STPAPIClient.shared.publishableKey =
            "pk_test_51SvGmGPeql1aQTZ7DPBJJUOW3cb6X5oNVfD0Zx4xvUEwrCVcAjUCHKuZUTk8bVxpvVHAorcZsSabltgJoigFXu1600Eey5pria"

            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "Cutly Market"
            config.allowsDelayedPaymentMethods = true

            DispatchQueue.main.async {
                self.paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: clientSecret,
                    configuration: config
                )
                completion(true)
            }
        }.resume()
    }
}
