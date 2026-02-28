import Foundation
import FirebaseFirestore
import StripePayments

class BookingService {
    
    private let db = Firestore.firestore()
    
    // =====================================================
    // ✅ AJOUTER UNE RÉSERVATION (TU AVAIS DÉJÀ — GARDÉ)
    // =====================================================
    func addBooking(
        barber: Barber,
        date: Date,
        clientName: String,
        completion: ((Bool) -> Void)? = nil
    ) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: date)
        
        // ===========================
        // ✅ TES CHAMPS (TOUS GARDÉS)
        // ===========================
        let data: [String: Any] = [
            "barberId": barber.id,
            "barberName": barber.name,
            "clientName": clientName,
            "date": dateString,
            "time": timeString,
            "status": "pending",                 // ⏳ En attente
            "paymentStatus": "not_paid",         // 💳 Pas encore payé
            "escrowStatus": "not_started",       // 🔒 Pas encore bloqué
            "platformCommissionRate": barber.platformCommissionRate,
            "barberIsPro": barber.isPro,
            "barberIsCertified": barber.isCertified,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("bookings").addDocument(data: data) { error in
            if let error = error {
                print("❌ Erreur Firestore booking:", error)
                completion?(false)
            } else {
                print("✅ Réservation enregistrée dans Firestore")
                completion?(true)
            }
        }
    }
    
    // =====================================================
    // ✅ RÉCUPÉRER LES RÉSERVATIONS (TU L’AVAIS — GARDÉ)
    // =====================================================
    func fetchBookings(completion: @escaping ([Booking]) -> Void) {
        
        db.collection("bookings")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
            
            if let error = error {
                print("❌ Erreur fetch bookings:", error)
                completion([])
                return
            }
            
            var bookings: [Booking] = []
            
            snapshot?.documents.forEach { doc in
                let data = doc.data()
                
                let booking = Booking(
                    id: doc.documentID,
                    barberId: data["barberId"] as? String ?? "",
                    barberName: data["barberName"] as? String ?? "",
                    clientName: data["clientName"] as? String ?? "",
                    date: data["date"] as? String ?? "",
                    time: data["time"] as? String ?? "",
                    status: data["status"] as? String ?? "pending"
                )
                
                bookings.append(booking)
            }
            
            completion(bookings)
        }
    }
    
    // =====================================================
    // 🔒 NOUVEAU : CRÉER UN PAIEMENT STRIPE (INTENTION)
    // =====================================================
    func createPaymentIntent(
        bookingId: String,
        amount: Double,
        completion: @escaping (String?) -> Void
    ) {
        // ⚠️ À TERME : tu appelleras ton backend ici (Node.js / Firebase Functions)
        // Pour l’instant, on simule une "PaymentIntent"
        
        let fakeClientSecret = "pi_test_\(UUID().uuidString)"
        
        db.collection("bookings").document(bookingId).updateData([
            "stripePaymentIntent": fakeClientSecret,
            "paymentStatus": "intent_created",
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Erreur création PaymentIntent:", error)
                completion(nil)
            } else {
                print("🧾 PaymentIntent créé (simulé)")
                completion(fakeClientSecret)
            }
        }
    }
    
    // =====================================================
    // 🔒 NOUVEAU : BLOQUER L’ARGENT (ESCROW)
    // =====================================================
    func startEscrowPayment(
        bookingId: String,
        amount: Double,
        completion: @escaping (Bool) -> Void
    ) {
        db.collection("bookings").document(bookingId).updateData([
            "paymentStatus": "paid",
            "escrowStatus": "held",          // 💰 Argent bloqué
            "heldAmount": amount,
            "paidAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Erreur startEscrow:", error)
                completion(false)
            } else {
                print("🔒 Paiement bloqué (escrow) avec succès")
                completion(true)
            }
        }
    }
    
    // =====================================================
    // ✅ NOUVEAU : CONFIRMATION DU CLIENT
    // =====================================================
    func confirmServiceCompleted(
        bookingId: String,
        completion: @escaping (Bool) -> Void
    ) {
        db.collection("bookings").document(bookingId).updateData([
            "status": "completed",
            "clientConfirmedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Erreur confirmation client:", error)
                completion(false)
            } else {
                print("✅ Prestation confirmée par le client")
                completion(true)
            }
        }
    }
    
    // =====================================================
    // 💸 NOUVEAU : DÉBLOQUER L’ARGENT → PAIEMENT COIFFEUR
    // =====================================================
    func releasePaymentToBarber(
        bookingId: String,
        barberId: String,
        totalAmount: Double,
        commissionRate: Double,
        completion: @escaping (Bool) -> Void
    ) {
        let commission = totalAmount * commissionRate
        let barberAmount = totalAmount - commission
        
        db.collection("bookings").document(bookingId).updateData([
            "escrowStatus": "released",
            "barberPaidAmount": barberAmount,
            "platformCommission": commission,
            "paidToBarberAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Erreur paiement coiffeur:", error)
                completion(false)
            } else {
                print("💸 Paiement libéré au coiffeur. Ta commission :", commission)
                completion(true)
            }
        }
    }
    
    // =====================================================
    // ⚠️ NOUVEAU : ANNULATION (REMBOURSEMENT CLIENT)
    // =====================================================
    func cancelBookingAndRefund(
        bookingId: String,
        completion: @escaping (Bool) -> Void
    ) {
        db.collection("bookings").document(bookingId).updateData([
            "status": "cancelled",
            "escrowStatus": "refunded",
            "refundedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Erreur remboursement:", error)
                completion(false)
            } else {
                print("🔄 Réservation annulée et client remboursé")
                completion(true)
            }
        }
    }
}
