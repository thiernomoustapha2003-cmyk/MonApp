import FirebaseFirestore
import FirebaseAuth

class BookingService {
    
    static let shared = BookingService()
    private init() {}
    
    private let db = Firestore.firestore()
    // =====================================================
    // ✅ AJOUTER UNE RÉSERVATION (SÉCURISÉE)
    // =====================================================
    func addBooking(
        barber: Barber,
        date: Date,
        clientName: String,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ Aucun utilisateur connecté")
            completion?(false)
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: date)
        
        let data: [String: Any] = [
            "barberId": barber.id,
            "barberName": barber.name,
            "clientName": clientName,
            "clientId": uid,
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
                
                DispatchQueue.main.async {
                    completion?(false)
                }
                
            } else {
                print("✅ Réservation enregistrée dans Firestore")
                
                // 👇 création conversation automatique
                if let clientId = Auth.auth().currentUser?.uid {
                    self.createConversationIfNeeded(
                        barberId: barber.id ?? "",
                        clientId: clientId
                    )
                }
                
                DispatchQueue.main.async {
                    completion?(true)
                }
            }
        }
    }
    
    // =====================================================
    // ✅ RÉCUPÉRER LES RÉSERVATIONS (GARDÉ)
    // =====================================================
    func fetchBookings(completion: @escaping ([Booking]) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        db.collection("bookings")
            .whereField("clientId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Erreur fetch bookings:", error)
                    DispatchQueue.main.async {
                        completion([])
                    }
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
                        clientId: data["clientId"] as? String ?? "",
                        date: data["date"] as? String ?? "",
                        time: data["time"] as? String ?? "",
                        status: data["status"] as? String ?? "pending",
                        
                        paymentStatus: data["paymentStatus"] as? String ?? "not_paid",
                        escrowStatus: data["escrowStatus"] as? String ?? "not_started",
                        heldAmount: data["heldAmount"] as? Double,
                        barberPaidAmount: data["barberPaidAmount"] as? Double,
                        platformCommission: data["platformCommission"] as? Double,
                        barberIsPro: data["barberIsPro"] as? Bool ?? false,
                        barberIsCertified: data["barberIsCertified"] as? Bool ?? false,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                        clientConfirmedAt: (data["clientConfirmedAt"] as? Timestamp)?.dateValue(),
                        paidToBarberAt: (data["paidToBarberAt"] as? Timestamp)?.dateValue(),
                        refundedAt: (data["refundedAt"] as? Timestamp)?.dateValue()
                    )
                    
                    bookings.append(booking)
                }
                
                DispatchQueue.main.async {
                    completion(bookings)
                }
            }
    }
    // ======================================================
    // 💬 CREATION CONVERSATION AUTOMATIQUE APRES BOOKING
    // ======================================================
    func createConversationIfNeeded(barberId: String, clientId: String) {
        
        let conversationId = [barberId, clientId].sorted().joined(separator: "_")
        let conversationRef = db.collection("conversations").document(conversationId)
        
        conversationRef.getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                print("💬 Conversation déjà existante")
                return
            }
            
            print("🆕 Création nouvelle conversation")
            
            conversationRef.setData([
                "participants": [barberId, clientId],
                "createdAt": Timestamp(date: Date()),
                "lastMessage": "",
                "lastMessageDate": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("❌ Erreur création conversation:", error)
                } else {
                    print("✅ Conversation créée automatiquement")
                }
            }
        }
    }
    
    
    
    // =====================================================
    // 🔒 CRÉER UN PAIEMENT STRIPE (INTENTION) — VERSION UNIQUE & PROPRE
    // =====================================================
    func createPaymentIntent(
        bookingId: String,
        amount: Double,
        barberId: String,
        slotId: String,
        completion: @escaping (String?) -> Void
    ) {
        
        let url = URL(string: "https://createpaymentintent-jzvik52b6a-uc.a.run.app")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let user = Auth.auth().currentUser else {
            completion(nil)
            return
        }
        
        // ⭐️ CE QUE LE BACKEND ATTEND
        let body: [String: Any] = [
            "amount": Int(amount * 100),
            "bookingId": bookingId,
            "barberId": barberId,
            "clientId": user.uid,
            "slotId": slotId,
            "clientEmail": user.email ?? "no@email.com"
        ]
        
        print("📤 BODY ENVOYÉ AU SERVEUR :", body)
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("❌ Erreur réseau:", error.localizedDescription)
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard let data = data else {
                print("❌ Aucune donnée reçue")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("📦 Réponse serveur :", raw)
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let clientSecret = json["clientSecret"] as? String {
                
                print("🟢 clientSecret reçu :", clientSecret)
                DispatchQueue.main.async { completion(clientSecret) }
                
            } else {
                print("❌ clientSecret absent")
                DispatchQueue.main.async { completion(nil) }
            }
            
        }.resume()
    }
    // =====================================================
    // 🔒 BLOQUER L’ARGENT (ESCROW)
    // =====================================================
    func startEscrowPayment(
        bookingId: String,
        amount: Double,
        completion: @escaping (Bool) -> Void
    ) {
        db.collection("bookings").document(bookingId).updateData([
            "paymentStatus": "paid",
            "escrowStatus": "held",
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
    // ✅ CONFIRMATION DU CLIENT — OK
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
    // 💸 DÉBLOQUER L’ARGENT → PAIEMENT COIFFEUR
    // =====================================================
    func releasePaymentToBarber(
        bookingId: String,
        barberId: String,
        totalAmount: Double,
        commissionRate: Double,
        completion: @escaping (Bool) -> Void
    ) {
        
        let commission = totalAmount * commissionRate
        let barberPaid = totalAmount - commission
        
        db.collection("bookings").document(bookingId).updateData([
            "escrowStatus": "released",
            "barberPaidAmount": barberPaid,
            "platformCommission": commission,
            "releasedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Erreur release payment:", error)
                completion(false)
            } else {
                print("💸 Paiement libéré au coiffeur :", barberPaid)
                completion(true)
            }
        }
    }
    
    // =====================================================
    // ⚠️ ANNULATION (REMBOURSEMENT CLIENT)
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
    
    // =====================================================
    // 👂 ECOUTE TEMPS RÉEL BOOKING
    // =====================================================
    func listenToBooking(bookingId: String, completion: @escaping (Booking?) -> Void) {
        
        db.collection("bookings").document(bookingId)
            .addSnapshotListener { snapshot, error in
                
                guard let data = snapshot?.data() else {
                    completion(nil)
                    return
                }
                
                let booking = Booking(
                    id: bookingId,
                    barberId: data["barberId"] as? String ?? "",
                    barberName: data["barberName"] as? String ?? "",
                    clientName: data["clientName"] as? String ?? "",
                    clientId: data["clientId"] as? String ?? "",
                    date: data["date"] as? String ?? "",
                    time: data["time"] as? String ?? "",
                    status: data["status"] as? String ?? "pending",
                    paymentStatus: data["paymentStatus"] as? String ?? "not_paid",
                    escrowStatus: data["escrowStatus"] as? String ?? "not_started",
                    heldAmount: data["heldAmount"] as? Double,
                    barberPaidAmount: data["barberPaidAmount"] as? Double,
                    platformCommission: data["platformCommission"] as? Double,
                    barberIsPro: data["barberIsPro"] as? Bool ?? false,
                    barberIsCertified: data["barberIsCertified"] as? Bool ?? false,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                    clientConfirmedAt: (data["clientConfirmedAt"] as? Timestamp)?.dateValue(),
                    paidToBarberAt: (data["paidToBarberAt"] as? Timestamp)?.dateValue(),
                    refundedAt: (data["refundedAt"] as? Timestamp)?.dateValue()
                )
                
                completion(booking)
            }
    }
}
    // ======================================================
    // 💬 CREATE CONVERSATION AFTER BOOKING
    // ======================================================
func createConversationIfNeeded(barberId: String, clientId: String) {
    let db = Firestore.firestore()
    
    // ID unique pour éviter les doublons
    let conversationId = [barberId, clientId].sorted().joined(separator: "_")
    
    let conversationRef = db.collection("conversations").document(conversationId)
    
    conversationRef.getDocument { snapshot, error in
        if let snapshot = snapshot, snapshot.exists {
            print("💬 Conversation existe déjà")
            return
        }
        
        let data: [String: Any] = [
            "participants": [barberId, clientId],
            "createdAt": Timestamp(),
            "lastMessage": "",
            "lastMessageDate": Timestamp()
        ]
        
        conversationRef.setData(data) { error in
            if let error = error {
                print("❌ Erreur création conversation:", error.localizedDescription)
            } else {
                print("✅ Conversation créée :", conversationId)
            }
        }
    }
    func createBooking(
        barber: Barber,
        slot: AvailabilitySlot,
        completion: @escaping (Bool) -> Void
    ) {
        
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let data: [String: Any] = [
            "barberId": barber.id ?? "",
            "clientId": user.uid,
            "date": slot.startTime,
            "createdAt": Timestamp(),
            "status": "pending"
        ]
        
        db.collection("bookings").addDocument(data: data) { error in
            completion(error == nil)
        }
    }
    func confirmBookingAfterPayment(barberId: String, slotId: String, completion: @escaping (Bool) -> Void) {
        
        let db = Firestore.firestore()
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let slotRef = db.collection("slots").document(slotId)
        
        // Lire le slot pour récupérer la date du RDV
        slotRef.getDocument { snapshot, _ in
            guard
                let data = snapshot?.data(),
                let timestamp = data["startTime"] as? Timestamp,
                let uid = Auth.auth().currentUser?.uid
            else {
                completion(false)
                return
            }
            
            let appointmentDate = timestamp.dateValue()
            
            // Marquer le slot comme réservé
            slotRef.updateData([
                "status": "booked",
                "bookedBy": uid
            ]) { error in
                
                if let error = error {
                    print("❌ Slot booking error:", error)
                    completion(false)
                    return
                }
                
                // 🔔 Programmer les rappels automatiques
                ReminderScheduler.shared.scheduleReminders(
                    bookingId: slotId,
                    barberId: barberId,
                    appointmentDate: appointmentDate
                )
                
                // 💬 Créer conversation automatiquement
                let conversationId = [uid, barberId].sorted().joined(separator: "_")
                
                Firestore.firestore()
                    .collection("conversations")
                    .document(conversationId)
                    .setData([
                        "participants": [uid, barberId],
                        "clientId": uid,
                        "barberId": barberId,
                        "lastMessage": "",
                        "lastSenderId": "",
                        "createdAt": Timestamp(),
                        "updatedAt": Timestamp()
                    ], merge: true)
                
                completion(true)
            }
        }
        // ==========================================
        // 🔥 BOOKINGS CLIENT (AFFICHAGE COMPLET)
        // ==========================================
        
        func fetchBookingsForClient(completion: @escaping ([ClientBookingDisplay]) -> Void) {
            
            guard let uid = Auth.auth().currentUser?.uid else {
                completion([])
                return
            }
            
            db.collection("bookings")
                .whereField("clientId", isEqualTo: uid)
                .getDocuments { snapshot, error in
                    
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    
                    var results: [ClientBookingDisplay] = []
                    let group = DispatchGroup()
                    
                    for doc in documents {
                        
                        let data = doc.data()
                        
                        let barberId = data["barberId"] as? String ?? ""
                        let timestamp = data["date"] as? Timestamp ?? Timestamp()
                        let serviceName = data["serviceName"] as? String ?? ""
                        let price = data["price"] as? Double ?? 0
                        let status = data["status"] as? String ?? "pending"
                        
                        group.enter()
                        
                        db.collection("users").document(barberId).getDocument { barberDoc, _ in
                            
                            let barberData = barberDoc?.data()
                            
                            let barberName = barberData?["fullName"] as? String ?? "Barber"
                            let barberPhoto = barberData?["profileImageUrl"] as? String
                            
                            let display = ClientBookingDisplay(
                                id: doc.documentID,
                                barberName: barberName,
                                barberPhoto: barberPhoto,
                                date: timestamp.dateValue(),
                                serviceName: serviceName,
                                price: price,
                                status: status
                            )
                            
                            results.append(display)
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        completion(results)
                    }
                }
        }
    }
    // =====================================================
    // 👂 ECOUTER UNE RESERVATION EN TEMPS REEL
    // =====================================================
    func listenToBooking(bookingId: String,
                         update: @escaping (Booking?) -> Void) -> ListenerRegistration {

        return db.collection("bookings")
            .document(bookingId)
            .addSnapshotListener { snapshot, error in
                
                guard let data = snapshot?.data() else {
                    update(nil)
                    return
                }
                
                let booking = Booking(
                    id: snapshot!.documentID,
                    barberId: data["barberId"] as? String ?? "",
                    barberName: data["barberName"] as? String ?? "",
                    clientName: data["clientName"] as? String ?? "",
                    clientId: data["clientId"] as? String ?? "",
                    date: data["date"] as? String ?? "",
                    time: data["time"] as? String ?? "",
                    status: data["status"] as? String ?? "pending",
                    paymentStatus: data["paymentStatus"] as? String ?? "not_paid",
                    escrowStatus: data["escrowStatus"] as? String ?? "not_started",
                    heldAmount: data["heldAmount"] as? Double,
                    barberPaidAmount: data["barberPaidAmount"] as? Double,
                    platformCommission: data["platformCommission"] as? Double,
                    barberIsPro: data["barberIsPro"] as? Bool ?? false,
                    barberIsCertified: data["barberIsCertified"] as? Bool ?? false,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                    clientConfirmedAt: (data["clientConfirmedAt"] as? Timestamp)?.dateValue(),
                    paidToBarberAt: (data["paidToBarberAt"] as? Timestamp)?.dateValue(),
                    refundedAt: (data["refundedAt"] as? Timestamp)?.dateValue()
                )
                
                print("🔥 BOOKING UPDATE:", booking.status, booking.escrowStatus)
                update(booking)
            }
    }
}
