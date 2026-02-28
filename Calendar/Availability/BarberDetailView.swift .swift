import SwiftUI
import MapKit
import CoreLocation
import FirebaseFirestore
import FirebaseAuth
import PassKit
import Stripe
import StripePaymentsUI
import StripePaymentSheet



// =====================================================
// MARK: - BARBER DETAIL VIEW
// =====================================================

struct BarberDetailView: View {

    let barber: Barber
    let db = Firestore.firestore()

    // MARK: - MAP & NAVIGATION
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @State private var barberCoordinate: CLLocationCoordinate2D?
    @State private var distanceText = ""
    @State private var durationText = ""

    @StateObject private var locationManager = LocationManager()

    // MARK: - UI STATES
    @State private var isFavorite = false
    @State private var userRating: Int = 0

    @State private var showBookingSheet = false
    @State private var selectedSlot: Calendar.AvailabilitySlott?

    @State private var slots: [Calendar.AvailabilitySlot] = []
    @State private var isLoadingSlots = true

    @State private var currentWeekStart: Date = Calendar.current.startOfDay(for: Date())

    // ✅ CONNEXION
    @State private var showLoginSheet = false
    @State private var showLoginAlert = false
    @State private var pendingAction: PendingAction? = nil

    // ✅ STRIPE PAIEMENT
    @State private var paymentLocked = false
    @State private var showConfirmServiceAlert = false
    @State private var paymentIntentClientSecret: String?
    @State private var paymentSheet: PaymentSheet?
    @State private var isPreparingPayment = false

    enum PendingAction {
        case call
        case whatsapp
        case book
        case payment
    }

    // MARK: - BODY
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                profileView
                ratingView
                favoriteButton
                infoView

                mapView
                distanceView

                navigationButton
                bookingButton
                paymentButton
                callButton
                whatsappButton

                Divider().padding(.horizontal)

                calendarHeader
                weekCalendarGrid   // ← CALENDRIER COMME TON IMAGE

                Divider().padding(.horizontal)

                slotsSection

                Divider().padding(.horizontal)

                magicButtonsSection
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            geocodeBarberAddress()
            checkFavorite()
            loadBarberSlots()
        }
        .sheet(isPresented: $showBookingSheet) {
            bookingView
        }
        .sheet(isPresented: $showLoginSheet, onDismiss: {
            if Auth.auth().currentUser != nil {
                performPendingAction()
            }
        }) {
            LoginView()
        }

        .alert("Connexion requise", isPresented: $showLoginAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Se connecter") {
                showLoginSheet = true
            }
        } message: {
            Text("Vous devez vous connecter pour effectuer cette action.")
        }

        .alert("Confirmer la prestation", isPresented: $showConfirmServiceAlert) {
            Button("Problème / Réclamation", role: .destructive) {
                print("⚠️ Réclamation envoyée")
            }
            Button("Prestation OK") {
                releasePaymentToBarber()
            }
        } message: {
            Text("Confirmez-vous que la prestation a bien été réalisée ?")
        }
    }
}

// =====================================================
// MARK: - UI COMPONENTS
// =====================================================

extension BarberDetailView {

    var profileView: some View {
        AsyncImage(url: URL(string: barber.imageUrl ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.gray)
        }
        .frame(width: 150, height: 150)
        .clipShape(Circle())
        .shadow(radius: 6)
        .padding(.top, 20)
    }

    var ratingView: some View {
        HStack {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= userRating ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        userRating = star
                        print("⭐ Note donnée : \(star)")
                    }
            }
        }
    }

    var favoriteButton: some View {
        Button(action: toggleFavorite) {
            HStack {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : .gray)
                Text(isFavorite ? "Retirer des favoris" : "Ajouter aux favoris")
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }

    var infoView: some View {
        VStack(spacing: 10) {
            Text(barber.name)
                .font(.title)
                .bold()

            Text("📍 \(barber.city)")
                .foregroundColor(.gray)

            Text("💰 \(barber.price, specifier: "%.2f") €")
                .font(.headline)
                .foregroundColor(.green)

            if !barber.description.isEmpty {
                Text(barber.description)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }

    var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: barberCoordinate != nil ? [barber] : []) { _ in
            MapMarker(coordinate: region.center, tint: .red)
        }
        .frame(height: 200)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    var distanceView: some View {
        HStack {
            Image(systemName: "car.fill")
            Text("Distance : \(distanceText)")
            Spacer()
            Image(systemName: "clock")
            Text("Durée : \(durationText)")
        }
        .padding(.horizontal)
    }

    var navigationButton: some View {
        mainButton("🚀 Commencer la navigation", color: .blue, action: startNavigation)
    }

    var bookingButton: some View {
        mainButton("📅 Réserver maintenant", color: .black) {
            handleAction(.book)
        }
    }

    var paymentButton: some View {
        mainButton("💳 Payer (CB ou Apple Pay)", color: .purple) {
            handleAction(.payment)
        }
    }

    var callButton: some View {
        Group {
            if !barber.phone.isEmpty {
                mainButton("📞 Appeler", color: .orange) {
                    handleAction(.call)
                }
            }
        }
    }

    var whatsappButton: some View {
        Group {
            if !barber.phone.isEmpty {
                mainButton("💬 WhatsApp", color: .green) {
                    handleAction(.whatsapp)
                }
            }
        }
    }

    func mainButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    var calendarHeader: some View {
        HStack {
            Button(action: previousWeek) {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text("Semaine du \(formattedWeekRange())")
                .font(.headline)

            Spacer()

            Button(action: nextWeek) {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
    }

    // ===============================
    // ✅ CALENDRIER EXACTEMENT COMME TON IMAGE
    // ===============================
    var weekCalendarGrid: some View {
        VStack(spacing: 10) {

            HStack(spacing: 6) {
                ForEach(0..<7) { index in
                    VStack {
                        Text(dayShortName(for: index))
                            .font(.caption)

                        Text(dayFullLabel(for: index))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            Divider()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {

                ForEach(0..<7) { dayIndex in

                    VStack(spacing: 8) {

                        let daySlots = slotsForDay(dayIndex)

                        if let daySlots = daySlots, !daySlots.isEmpty {

                            ForEach(daySlots) { slot in

                                Text(slot.startTime, style: .time)
                                    .font(.caption2)
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                                    .background(colorForStatus(slot.status).opacity(0.15))
                                    .foregroundColor(colorForStatus(slot.status))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(colorForStatus(slot.status), lineWidth: 0.5)
                                    )
                                    .onTapGesture {
                                        if slot.status == .available {
                                            selectedSlot = slot
                                            showBookingSheet = true
                                        }
                                    }
                            }

                        } else {

                            Text("—")
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    var slotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📅 Créneaux disponibles")
                .font(.title2)
                .bold()
                .padding(.horizontal)

            if isLoadingSlots {
                ProgressView("Chargement des créneaux...")
                    .padding()
            }
            else if slots.isEmpty {
                Text("Aucun créneau disponible")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            else {
                ForEach(slots) { slot in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(slot.date, style: .date)
                                .font(.headline)
                            Text("\(slot.startTime, style: .time) → \(slot.endTime, style: .time)")
                                .font(.subheadline)
                        }

                        Spacer()

                        Text(labelForStatus(slot.status))
                            .font(.caption)
                            .padding(6)
                            .background(colorForStatus(slot.status).opacity(0.2))
                            .foregroundColor(colorForStatus(slot.status))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .onTapGesture {
                        if slot.status == .available {
                            selectedSlot = slot
                            showBookingSheet = true
                        }
                    }
                }
            }
        }
    }

    var magicButtonsSection: some View {
        VStack(spacing: 12) {

            mainButton("✨ Partager ce coiffeur", color: .blue) {
                let text = "Découvre ce coiffeur : \(barber.name)"
                let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true)
            }

            mainButton("🌟 Ajouter à mes coups de cœur", color: .pink) {
                toggleFavorite()
            }

            mainButton("📍 Voir sur Maps", color: .teal) {
                startNavigation()
            }
        }
        .padding(.horizontal)
    }
}

// =====================================================
// MARK: - LOGIC
// =====================================================

extension BarberDetailView {

    func handleAction(_ action: PendingAction) {
        pendingAction = action

        if Auth.auth().currentUser == nil {
            showLoginAlert = true
        } else {
            performPendingAction()
        }
    }

    func performPendingAction() {
        guard let action = pendingAction else { return }

        switch action {
        case .call:
            callPhone(barber.phone)

        case .whatsapp:
            openWhatsApp(barber.phone)

        case .book:
            showBookingSheet = true

        case .payment:
            prepareStripePayment()
        }
    }

    // ==========================
    // 🔹 STRIPE PAIEMENT
    // ==========================

    func prepareStripePayment() {
        isPreparingPayment = true

        let url = URL(string: "https://TON_BACKEND.com/create-payment-intent")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "amount": Int(barber.price * 100),
            "currency": "eur",
            "barberId": barber.id,
            "escrow": true
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in

            DispatchQueue.main.async {
                isPreparingPayment = false
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let clientSecret = json["clientSecret"] as? String
            else {
                print("❌ Erreur création PaymentIntent")
                return
            }

            DispatchQueue.main.async {
                paymentIntentClientSecret = clientSecret

                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "Cutly"
                config.applePay = .init(merchantId: "merchant.com.cutly", merchantCountryCode: "FR")

                paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: clientSecret,
                    configuration: config
                )

                presentPaymentSheet()
            }

        }.resume()
    }

    func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else { return }

        paymentSheet.present(from: UIApplication.shared.windows.first!.rootViewController!) { result in
            switch result {
            case .completed:
                print("✅ Paiement réussi → Argent bloqué")
                lockPayment()

            case .failed(let error):
                print("❌ Paiement échoué:", error.localizedDescription)

            case .canceled:
                print("⚠️ Paiement annulé")
            }
        }
    }

    func lockPayment() {
        paymentLocked = true
        print("🔒 Paiement bloqué (escrow)")
        showConfirmServiceAlert = true
    }

    func releasePaymentToBarber() {
        if paymentLocked {
            print("💸 Paiement libéré au coiffeur")
            paymentLocked = false
        }
    }

    // ==========================
    // FONCTIONS UTILES (COMPLÈTES)
    // ==========================

    func previousWeek() {
        currentWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart) ?? currentWeekStart
    }

    func nextWeek() {
        currentWeekStart = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
    }

    func formattedWeekRange() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM"

        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart

        return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: endDate))"
    }

    func dayShortName(for index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: index, to: currentWeekStart) ?? Date()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    func dayFullLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: index, to: currentWeekStart) ?? Date()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    func colorForStatus(_ status: SlotStatus) -> Color {
        switch status {
        case .available:
            return .green
        case .booked:
            return .red
        case .pending:
            return .orange
        }
    }

    func labelForStatus(_ status: SlotStatus) -> String {
        switch status {
        case .available: return "Disponible"
        case .booked: return "Réservé"
        case .pending: return "En attente"
        }
    }

    func slotsForDay(_ index: Int) -> [AvailabilitySlot]? {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: index, to: currentWeekStart) ?? Date()

        return slots.filter {
            calendar.isDate($0.date, inSameDayAs: targetDate)
        }
    }

    func loadBarberSlots() {
        isLoadingSlots = true

        db.collection("slots")
            .whereField("barberId", isEqualTo: barber.id)
            .order(by: "date", descending: false)
            .getDocuments { snapshot, _ in

                isLoadingSlots = false

                guard let documents = snapshot?.documents else { return }

                self.slots = documents.compactMap { doc -> AvailabilitySlot? in
                    let data = doc.data()

                    guard
                        let date = data["date"] as? Timestamp,
                        let start = data["startTime"] as? Timestamp,
                        let end = data["endTime"] as? Timestamp
                    else {
                        return nil
                    }

                    let isBooked = data["isBooked"] as? Bool ?? false

                    return AvailabilitySlot(
                        id: doc.documentID,
                        barberId: barber.id,
                        date: date.dateValue(),
                        startTime: start.dateValue(),
                        endTime: end.dateValue(),
                        isBooked: isBooked,
                        status: isBooked ? .booked : .available
                    )
                }
            }
    }

    func geocodeBarberAddress() {
        let address = "\(barber.street) \(barber.houseNumber), \(barber.postalCode) \(barber.city)"

        CLGeocoder().geocodeAddressString(address) { placemarks, _ in
            guard let location = placemarks?.first?.location else { return }

            barberCoordinate = location.coordinate
            region.center = location.coordinate
            calculateRoute()
        }
    }

    func calculateRoute() {
        guard let barberCoord = barberCoordinate,
              let userCoord = locationManager.location else { return }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: barberCoord))
        request.transportType = .automobile

        MKDirections(request: request).calculate { response, _ in
            guard let route = response?.routes.first else { return }

            let distance = route.distance / 1000
            let duration = route.expectedTravelTime / 60

            self.distanceText = String(format: "%.1f km", distance)
            self.durationText = String(format: "%.0f min", duration)
        }
    }

    func startNavigation() {
        guard
            let barberCoord = barberCoordinate,
            let userCoord = locationManager.location
        else { return }

        let source = MKMapItem(placemark: MKPlacemark(coordinate: userCoord))
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: barberCoord))

        MKMapItem.openMaps(
            with: [source, destination],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }

    func toggleFavorite() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let ref = db.collection("favorites")
            .whereField("userId", isEqualTo: userId)
            .whereField("barberId", isEqualTo: barber.id)

        ref.getDocuments { snapshot, _ in
            if let doc = snapshot?.documents.first {
                doc.reference.delete()
                isFavorite = false
            } else {
                db.collection("favorites").addDocument(data: [
                    "userId": userId,
                    "barberId": barber.id
                ])
                isFavorite = true
            }
        }
    }

    func checkFavorite() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("favorites")
            .whereField("userId", isEqualTo: userId)
            .whereField("barberId", isEqualTo: barber.id)
            .getDocuments { snapshot, _ in
                isFavorite = !(snapshot?.documents.isEmpty ?? true)
            }
    }

    func callPhone(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    func openWhatsApp(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "https://wa.me/\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    var bookingView: some View {
        VStack(spacing: 16) {
            Text("Confirmer votre réservation")
                .font(.headline)

            if let slot = selectedSlot {
                Text(slot.date, style: .date)
                Text("\(slot.startTime, style: .time) → \(slot.endTime, style: .time)")
            }

            Button("Confirmer") {
                showBookingSheet = false
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
