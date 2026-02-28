import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import StripePayments
import StripePaymentSheet
struct BarberDashboardView: View {

    @State private var pendingBookings: [Booking] = []
    @State private var confirmedBookings: [Booking] = []
    @State private var reviews: [Review] = []

    // NOUVEAUX ÉTATS (AJOUTÉS — SANS RIEN SUPPRIMER)
    @State private var barberName: String = ""
    @State private var barberCity: String = ""
    @State private var barberPhone: String = ""
    @State private var barberImageUrl: String = ""
    @State private var isPro: Bool = false
    @State private var acceptsOnlinePayment: Bool = false
    @State private var totalHeldAmount: Double = 0
    @State private var totalReleasedAmount: Double = 0
    @State private var totalCommission: Double = 0

    private let db = Firestore.firestore()
    private let barberId = Auth.auth().currentUser?.uid ?? ""

    var body: some View {
        NavigationStack {

            ScrollView {
                VStack(spacing: 20) {

                    // ===== HEADER PROFIL COIFFEUR (AMÉLIORÉ) =====
                    VStack(spacing: 10) {

                        if let url = URL(string: barberImageUrl), !barberImageUrl.isEmpty {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "scissors")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.black)
                            }
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "scissors")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.black)
                        }

                        Text(barberName.isEmpty ? "Espace Coiffeur" : barberName)
                            .font(.largeTitle)
                            .bold()

                        Text(barberCity.isEmpty ? "Votre ville" : barberCity)
                            .font(.footnote)
                            .foregroundColor(.gray)

                        HStack {
                            Text(isPro ? "💎 Coiffeur PRO" : "👤 Coiffeur Standard")
                                .font(.caption)
                                .padding(6)
                                .background(isPro ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                                .cornerRadius(8)

                            Text(acceptsOnlinePayment ? "💳 Paiement en ligne ACTIVÉ" : "❌ Paiement en ligne DÉSACTIVÉ")
                                .font(.caption)
                                .padding(6)
                                .background(acceptsOnlinePayment ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding()

                    Divider()

                    // ===== SECTION PAIEMENTS (NOUVEAU) =====
                    sectionHeader(title: "💰 Paiements & Revenus")

                    VStack(spacing: 10) {

                        infoLine(
                            title: "Argent bloqué (escrow)",
                            value: String(format: "%.2f €", totalHeldAmount)
                        )

                        infoLine(
                            title: "Argent libéré",
                            value: String(format: "%.2f €", totalReleasedAmount)
                        )

                        infoLine(
                            title: "Commission plateforme",
                            value: String(format: "%.2f €", totalCommission)
                        )

                        NavigationLink(destination: StripePayoutConfigView()) {
                            Text("⚙️ Configurer mon paiement (Stripe / IBAN)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                    }
                    .padding(.horizontal)

                    Divider()

                    // ===== SECTION 1 : DEMANDES DE RENDEZ-VOUS =====
                    sectionHeader(title: "📥 Demandes en attente")

                    if pendingBookings.isEmpty {
                        Text("Aucune demande en attente")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(pendingBookings) { booking in
                            bookingCard(booking: booking, isPending: true)
                        }
                    }

                    Divider()

                    // ===== SECTION 2 : RENDEZ-VOUS CONFIRMÉS =====
                    sectionHeader(title: "📅 Rendez-vous confirmés")

                    if confirmedBookings.isEmpty {
                        Text("Aucun rendez-vous confirmé")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(confirmedBookings) { booking in
                            bookingCard(booking: booking, isPending: false)
                        }
                    }

                    Divider()

                    // ===== SECTION 3 : AVIS & NOTES CLIENTS =====
                    sectionHeader(title: "⭐ Avis des clients")

                    if reviews.isEmpty {
                        Text("Aucun avis pour le moment")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(reviews) { review in
                            reviewCard(review: review)
                        }
                    }

                    Divider()

                    // ===== BOUTONS ACTIONS RAPIDES =====
                    VStack(spacing: 10) {

                        NavigationLink(destination: AvailabilityView()) {
                            Text("📅 Gérer mes créneaux")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        NavigationLink(destination: BarberProfileView()) {
                            Text("👤 Voir / Modifier mon profil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button("🚪 Se déconnecter") {
                            try? Auth.auth().signOut()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Mon Dashboard")
            .onAppear {
                fetchBarberProfile()
                fetchPendingBookings()
                fetchConfirmedBookings()
                fetchReviews()
                fetchPaymentsSummary()
            }
        }
    }

    // ===========================
    // UI COMPONENTS (GARDÉS + AMÉLIORÉS)
    // ===========================

    func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .bold()
            Spacer()
        }
        .padding(.horizontal)
    }

    func infoLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .bold()
        }
        .padding(.horizontal)
    }

    func bookingCard(booking: Booking, isPending: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Client : \(booking.clientName)")
                .font(.headline)

            Text("📅 \(booking.date) • ⏰ \(booking.time)")
                .font(.subheadline)

            HStack {
                if isPending {
                    Button("Accepter") {
                        updateBookingStatus(bookingId: booking.id, status: "confirmed")
                    }
                    .foregroundColor(.green)

                    Spacer()

                    Button("Refuser") {
                        updateBookingStatus(bookingId: booking.id, status: "cancelled")
                    }
                    .foregroundColor(.red)
                } else {
                    Text("✅ Confirmé")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    func reviewCard(review: Review) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.clientName)
                    .font(.headline)

                Spacer()

                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                }
            }

            Text(review.comment)
                .font(.subheadline)

            Button("Répondre") {
                print("Réponse au client : \(review.clientName)")
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // ===========================
    // FIRESTORE LOGIC (TOUT GARDÉ + AJOUTS)
    // ===========================

    func fetchBarberProfile() {
        db.collection("users").document(barberId).getDocument { snapshot, _ in
            let data = snapshot?.data() ?? [:]
            barberName = data["name"] as? String ?? "Coiffeur"
            barberCity = data["city"] as? String ?? ""
            barberPhone = data["phone"] as? String ?? ""
            barberImageUrl = data["imageUrl"] as? String ?? ""
            isPro = data["isPro"] as? Bool ?? false
            acceptsOnlinePayment = data["acceptsOnlinePayment"] as? Bool ?? false
        }
    }

    func fetchPaymentsSummary() {
        db.collection("bookings")
            .whereField("barberId", isEqualTo: barberId)
            .getDocuments { snapshot, _ in

                totalHeldAmount = 0
                totalReleasedAmount = 0
                totalCommission = 0

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    totalHeldAmount += data["heldAmount"] as? Double ?? 0
                    totalReleasedAmount += data["barberPaidAmount"] as? Double ?? 0
                    totalCommission += data["platformCommission"] as? Double ?? 0
                }
            }
    }

    func fetchPendingBookings() {
        db.collection("bookings")
            .whereField("barberId", isEqualTo: barberId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, _ in

                self.pendingBookings = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return Booking(
                        id: doc.documentID,
                        barberId: data["barberId"] as? String ?? "",
                        barberName: data["barberName"] as? String ?? "",
                        clientName: data["clientName"] as? String ?? "",
                        date: data["date"] as? String ?? "",
                        time: data["time"] as? String ?? "",
                        status: data["status"] as? String ?? "pending"
                    )
                } ?? []
            }
    }

    func fetchConfirmedBookings() {
        db.collection("bookings")
            .whereField("barberId", isEqualTo: barberId)
            .whereField("status", isEqualTo: "confirmed")
            .getDocuments { snapshot, _ in

                self.confirmedBookings = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return Booking(
                        id: doc.documentID,
                        barberId: data["barberId"] as? String ?? "",
                        barberName: data["barberName"] as? String ?? "",
                        clientName: data["clientName"] as? String ?? "",
                        date: data["date"] as? String ?? "",
                        time: data["time"] as? String ?? "",
                        status: data["status"] as? String ?? "confirmed"
                    )
                } ?? []
            }
    }

    func fetchReviews() {
        db.collection("reviews")
            .whereField("barberId", isEqualTo: barberId)
            .getDocuments { snapshot, _ in

                self.reviews = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return Review(
                        id: doc.documentID,
                        barberId: barberId,
                        clientName: data["clientName"] as? String ?? "Anonyme",
                        rating: data["rating"] as? Int ?? 0,
                        comment: data["comment"] as? String ?? ""
                    )
                } ?? []
            }
    }

    func updateBookingStatus(bookingId: String, status: String) {
        db.collection("bookings").document(bookingId).updateData([
            "status": status
        ]) { error in
            if error == nil {
                fetchPendingBookings()
                fetchConfirmedBookings()
            }
        }
    }
}
// ==========================
// 🔹 VUE TEMPORAIRE DE CONFIG STRIPE (IBAN)
// ==========================

struct StripePayoutConfigView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Configuration Stripe (IBAN)")
                .font(.title2)
                .bold()

            Text("Ici tu pourras plus tard connecter ton compte Stripe et ajouter ton IBAN.")
                .multilineTextAlignment(.center)
                .padding()

            Spacer()
        }
        .padding()
        .navigationTitle("Paiement coiffeur")
    }
}
