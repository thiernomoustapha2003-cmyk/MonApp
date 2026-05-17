//
//  StripeService.swift
//  MonApp
//

import Foundation
import Stripe
import UIKit
import StripePaymentSheet

class StripeService {
    
    static let shared = StripeService()
    
    //////////////////////////////////////////////////////
    // 💳 STRIPE PAYMENT
    //////////////////////////////////////////////////////
    
    func startPayment(
        amount: Double,
        description: String,
        completion: @escaping (Bool) -> Void
    ) {
        
        //////////////////////////////////////////////////////
        // 🔥 CLOUD FUNCTION
        //////////////////////////////////////////////////////
        
        guard let url = URL(
            string: "https://us-central1-afroconnect-7588d.cloudfunctions.net/createCoinsPaymentIntent"
        ) else {
            completion(false)
            return
        }
        
        //////////////////////////////////////////////////////
        // 🌍 REQUEST
        //////////////////////////////////////////////////////
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        //////////////////////////////////////////////////////
        // 📦 BODY
        //////////////////////////////////////////////////////
        
        let body: [String: Any] = [
            "amount": Int(amount * 100),
            "description": description
        ]
        
        request.httpBody = try? JSONSerialization.data(
            withJSONObject: body
        )
        
        print("🔥 Envoi requête Stripe:", body)
        
        //////////////////////////////////////////////////////
        // 🚀 API CALL
        //////////////////////////////////////////////////////
        
        URLSession.shared.dataTask(with: request) {
            data,
            response,
            error in
            
            //////////////////////////////////////////////////////
            // ❌ NETWORK ERROR
            //////////////////////////////////////////////////////
            
            if let error = error {
                print("❌ Network error:", error.localizedDescription)
                
                DispatchQueue.main.async {
                    completion(false)
                }
                
                return
            }
            
            //////////////////////////////////////////////////////
            // ❌ NO DATA
            //////////////////////////////////////////////////////
            
            guard let data = data else {
                print("❌ Pas de data")
                
                DispatchQueue.main.async {
                    completion(false)
                }
                
                return
            }
            
            //////////////////////////////////////////////////////
            // 📦 DEBUG RESPONSE
            //////////////////////////////////////////////////////
            
            print(
                "📦 Réponse Stripe:",
                String(data: data, encoding: .utf8) ?? ""
            )
            
            //////////////////////////////////////////////////////
            // 🔐 CLIENT SECRET
            //////////////////////////////////////////////////////
            
            guard let json =
                    try? JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                  
                  let clientSecret =
                    json["clientSecret"] as? String else {
                
                print("❌ clientSecret introuvable")
                
                DispatchQueue.main.async {
                    completion(false)
                }
                
                return
            }
            
            //////////////////////////////////////////////////////
            // 🎨 MAIN THREAD
            //////////////////////////////////////////////////////
            
            DispatchQueue.main.async {
                
                //////////////////////////////////////////////////////
                // ⚙️ CONFIG
                //////////////////////////////////////////////////////
                
                var config = PaymentSheet.Configuration()
                
                config.merchantDisplayName = "Cutly"
                
                //////////////////////////////////////////////////////
                // 🍎 APPLE PAY
                //////////////////////////////////////////////////////
                
                config.applePay = .init(
                    merchantId: "merchant.com.cutly",
                    merchantCountryCode: "FR"
                )
                
                //////////////////////////////////////////////////////
                // 💳 PAYMENT SHEET
                //////////////////////////////////////////////////////
                
                let sheet = PaymentSheet(
                    paymentIntentClientSecret: clientSecret,
                    configuration: config
                )
                
                //////////////////////////////////////////////////////
                // 🪟 ROOT VIEW CONTROLLER
                //////////////////////////////////////////////////////
                
                guard let scene =
                        UIApplication.shared.connectedScenes.first
                        as? UIWindowScene,
                      
                      let root =
                        scene.windows.first?.rootViewController else {
                    
                    completion(false)
                    return
                }
                
                //////////////////////////////////////////////////////
                // 🔥 WAIT CLEAN PRESENTATION
                //////////////////////////////////////////////////////
                
                StripeService.waitForCleanPresenter(
                    from: root
                ) { presenter in
                    
                    //////////////////////////////////////////////////////
                    // 🚀 PRESENT STRIPE
                    //////////////////////////////////////////////////////
                    
                    sheet.present(
                        from: presenter
                    ) { result in
                        
                        switch result {
                            
                        case .completed:
                            
                            print("✅ Paiement réussi")
                            completion(true)
                            
                        case .canceled:
                            
                            print("⚠️ Paiement annulé")
                            completion(false)
                            
                        case .failed(let error):
                            
                            print(
                                "❌ Paiement échoué:",
                                error.localizedDescription
                            )
                            
                            completion(false)
                        }
                    }
                }
            }
            
        }.resume()
    }
}

//////////////////////////////////////////////////////////
// 🪟 TOP VIEW CONTROLLER
//////////////////////////////////////////////////////////

extension StripeService {
    
    static func topViewController(
        from root: UIViewController
    ) -> UIViewController {
        
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        
        if let nav = root as? UINavigationController {
            return topViewController(
                from: nav.visibleViewController ?? nav
            )
        }
        
        if let tab = root as? UITabBarController {
            return topViewController(
                from: tab.selectedViewController ?? tab
            )
        }
        
        return root
    }
    
    //////////////////////////////////////////////////////
    // ⏳ WAIT FOR CLEAN PRESENTATION
    //////////////////////////////////////////////////////
    
    static func waitForCleanPresenter(
        from root: UIViewController,
        attempt: Int = 0,
        completion: @escaping (UIViewController) -> Void
    ) {
        
        let presenter = topViewController(from: root)
        
        //////////////////////////////////////////////////////
        // ✅ READY
        //////////////////////////////////////////////////////
        
        if presenter.presentedViewController == nil {
            completion(presenter)
            return
        }
        
        //////////////////////////////////////////////////////
        // 🛑 MAX ATTEMPTS
        //////////////////////////////////////////////////////
        
        if attempt >= 10 {
            completion(presenter)
            return
        }
        
        //////////////////////////////////////////////////////
        // 🔁 RETRY
        //////////////////////////////////////////////////////
        
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.25
        ) {
            waitForCleanPresenter(
                from: root,
                attempt: attempt + 1,
                completion: completion
            )
        }
    }
}
