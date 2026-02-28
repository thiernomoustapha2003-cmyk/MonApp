import Foundation
import FirebaseAuth
import FirebaseFirestore

final class PaymentFlowManager {

    static let shared = PaymentFlowManager()
    private let db = Firestore.firestore()

    // =========================================
    // PUBLIC ENTRY
    // =========================================
    func startPayment(
        barber: Barber,
        slot: AvailabilitySlot,
        completion: @escaping (String?, String?) -> Void
    ) {

        print("🚀 START PAYMENT FLOW")

        guard let user = Auth.auth().currentUser else {
            print("❌ utilisateur non connecté")
            completion(nil, nil)
            return
        }

        let barberId = barber.authId
        if barberId.isEmpty {
            print("❌ barber.authId vide")
            completion(nil, nil)
            return
        }

        guard let slotId = slot.id, !slotId.isEmpty else {
            print("❌ slot.id invalide")
            completion(nil, nil)
            return
        }

        let bookingRef = db.collection("bookings").document()

        let bookingData: [String: Any] = [
            "bookingId": bookingRef.documentID,
            "barberId": barberId,
            "barberName": barber.name,
            "clientId": user.uid,
            "clientName": user.displayName ?? "Client",
            "clientEmail": user.email ?? "",
            "slotId": slotId,
            "startTime": slot.startTime,
            "endTime": slot.endTime,
            "price": barber.price,
            "status": "pending_payment",
            "createdAt": Timestamp()
        ]

        print("📦 création booking:", bookingData)

        bookingRef.setData(bookingData) { error in

            if let error = error {
                print("❌ erreur création booking:", error)
                completion(nil, nil)
                return
            }

            print("✅ booking enregistré:", bookingRef.documentID)

            self.createConversationIfNeeded(barber: barber, client: user)

            self.callPaymentIntent(
                amount: barber.price,
                bookingId: bookingRef.documentID,
                barberId: barberId,
                slotId: slotId,
                clientId: user.uid,
                clientEmail: user.email ?? ""
            ) { secret in

                guard let secret = secret else {
                    print("❌ pas de clientSecret")
                    completion(nil, nil)
                    return
                }

                completion(secret, bookingRef.documentID)
            }
        }
    }

    // =========================================
    // CALL CLOUD FUNCTION
    // =========================================
    private func callPaymentIntent(
        amount: Double,
        bookingId: String,
        barberId: String,
        slotId: String,
        clientId: String,
        clientEmail: String,
        completion: @escaping (String?) -> Void
    ) {

        guard let url = URL(string: "https://createpaymentintent-jzvik52b6a-uc.a.run.app") else {
            completion(nil)
            return
        }

        let payload: [String: Any] = [
            "amount": Int(amount * 100),
            "bookingId": bookingId,
            "barberId": barberId,
            "slotId": slotId,
            "clientId": clientId,
            "clientEmail": clientEmail
        ]

        print("📤 ENVOI BACKEND:", payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ réseau:", error)
                completion(nil)
                return
            }

            guard let data = data else {
                print("❌ aucune data backend")
                completion(nil)
                return
            }

            let raw = String(data: data, encoding: .utf8) ?? "nil"
            print("📩 réponse backend:", raw)

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let secret = json["clientSecret"] as? String
            else {
                print("❌ clientSecret absent")
                completion(nil)
                return
            }

            print("🔐 clientSecret reçu")
            completion(secret)

        }.resume()
    }

    // =========================================
    // CONVERSATION
    // =========================================
    private func createConversationIfNeeded(barber: Barber, client: User) {

        let barberId = barber.authId
        if barberId.isEmpty { return }

        let conversationId = [client.uid, barberId].sorted().joined(separator: "_")
        let ref = db.collection("conversations").document(conversationId)

        ref.getDocument { snap, _ in
            if snap?.exists == true {
                print("💬 conversation existante")
                return
            }

            ref.setData([
                "participants": [client.uid, barberId],
                "clientId": client.uid,
                "barberId": barberId,
                "barberName": barber.name,
                "lastMessage": "",
                "lastSenderId": "",
                "createdAt": Timestamp(),
                "updatedAt": Timestamp()
            ])

            print("💬 conversation créée")
        }
    }
}
