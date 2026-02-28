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
// MARK: - BARBER DETAIL VIEW  (CLIENT PRO VERSION — CORRIGÉE)
// =====================================================

struct BarberDetailView: View {

    let barber: Barber
    let db = Firestore.firestore()
    
    @State private var services: [Service] = []

    // MARK: - MAP & NAVIGATION
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @State private var barberCoordinate: CLLocationCoordinate2D?
    @State private var distanceText = ""
    @State private var durationText = ""

    @StateObject private var locationManager = LocationManager()
    private let bookingService = BookingService.shared

    // MARK: - UI STATES
    @State private var isFavorite = false
    @State private var userRating: Int = 0

    @State private var showBookingSheet = false
    @State private var selectedSlot: AvailabilitySlot?

    @State private var slots: [AvailabilitySlot] = []
    @State private var isLoadingSlots = true

    @State private var currentWeekStart: Date = Calendar.current.startOfDay(for: Date())

    // sélection par JOUR
    @State private var showDaySlotsSheet = false
    @State private var selectedDaySlots: [AvailabilitySlot] = []
    @State private var selectedDay: Date = Date()

    // CONNEXION
    @State private var showLoginSheet = false
    @State private var showLoginAlert = false
    @State private var pendingAction: PendingAction? = nil

    // STRIPE PAIEMENT
    @State private var paymentLocked = false
    @State private var showConfirmServiceAlert = false
    @State private var paymentIntentClientSecret: String?
    @State private var paymentSheet: PaymentSheet?
    @State private var isPreparingPayment = false
    // 🔐 SHEET D'EXPLICATION AVANT PAIEMENT (ESCROW)
    @State private var showEscrowInfoSheet = false
    @State private var hasAcceptedEscrow = false
    @State private var showEscrowInfo = false
    

    // STOCKER L’ID DE LA RÉSERVATION
    @State private var currentBookingId: String?

    enum PendingAction {
        case call
        case whatsapp
        case book
        case payment
    }

    // MARK: - BODY
    var body: some View {

        ScrollViewReader { proxy in
            ScrollView {

                VStack(spacing: 18) {

                    profileView
                    ratingView
                    favoriteButton
                    infoView

                    // 🔥 SECTION SERVICES

                    if !services.isEmpty {
                        
                        VStack(alignment: .leading, spacing: 16) {
                            
                            Text("Prestations")
                                .font(.title3)
                                .bold()
                                .padding(.horizontal)
                            
                            ForEach(services) { service in
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    
                                    Text(service.name)
                                        .font(.headline)
                                    
                                    Text("\(Int(service.price)) € • \(service.duration) min")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                    
                                    Text(service.description)
                                        .font(.subheadline)
                                    
                                    if !service.imageURLs.isEmpty {
                                        
                                        TabView {
                                            ForEach(service.imageURLs.indices, id: \.self) { index in
                                                
                                                if let url = URL(string: service.imageURLs[index]) {
                                                    AsyncImage(url: url) { image in
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                    } placeholder: {
                                                        ZStack {
                                                            Color.gray.opacity(0.2)
                                                            ProgressView()
                                                        }
                                                    }
                                                    .frame(height: 260)
                                                    .clipped()
                                                    .cornerRadius(16)
                                                }
                                            }
                                        }
                                        .frame(height: 260)
                                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                                    }
                                    
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                        
                                        Text("\(service.likesCount) likes")
                                            .font(.subheadline)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    mapView
                    distanceView

                    navigationButton

                    // ==============================
                    // 🔹 ACTIONS PRINCIPALES
                    // ==============================

                    paymentButton
                    callButton
                    whatsappButton

                    // 🔹 Bouton qui SCROLL vers le calendrier
                    mainButton("📅 Réserver maintenant", color: .black) {
                        withAnimation {
                            proxy.scrollTo("CALENDAR_SECTION", anchor: .top)
                        }
                    }

                    Divider().padding(.horizontal)

                    // =========================
                    // 🔥 CALENDRIER
                    // =========================
                    VStack {
                        calendarHeader
                        weekCalendarGrid
                    }
                    .id("CALENDAR_SECTION")

                    Divider().padding(.horizontal)

                    legendSection

                    Divider().padding(.horizontal)

                    magicButtonsSection
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            geocodeBarberAddress()
            checkFavorite()
            loadBarberSlots()
            loadServices()   // 🔥 AJOUTE CETTE LIGNE
        }
        .sheet(isPresented: $showBookingSheet) {
            bookingView
        }
        .sheet(isPresented: $showEscrowInfoSheet) {
            escrowInfoView
        }
        .sheet(isPresented: $showDaySlotsSheet) {
            daySlotsSelectionView
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

            Text("💰 \(Int(barber.price)) €")
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

    var paymentButton: some View {
        mainButton("💳 Payer (CB ou Apple Pay)", color: .purple) {
            showEscrowInfo = true   // 🔥 OUVRE D'ABORD LA FENÊTRE ESCROW
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

    // ==========================
    // 🔥 CALENDRIER HEADER
    // ==========================
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
        .padding(.horizontal, 20)
    }

    var weekCalendarGrid: some View {
        VStack(spacing: 12) {

            HStack(spacing: 12) {
                ForEach(0..<7) { index in
                    VStack {
                        Text(dayShortName(for: index))
                            .font(.caption.bold())

                        Text(dayFullLabel(for: index))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)

            Divider()

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7),
                spacing: 12
            ) {

                ForEach(0..<7) { dayIndex in

                    let dayDate = Calendar.current.date(
                        byAdding: .day,
                        value: dayIndex,
                        to: currentWeekStart
                    ) ?? Date()

                    let daySlots = slotsForSpecificDate(dayDate)

                    Button {
                        selectedDay = dayDate
                        selectedDaySlots = daySlots
                        showDaySlotsSheet = true
                    } label: {

                        VStack(spacing: 6) {

                            let color: Color = {
                                if daySlots.isEmpty {
                                    return .gray
                                }
                                if daySlots.contains(where: { $0.status == .available }) {
                                    return .green
                                }
                                if daySlots.contains(where: { $0.status == .pending || $0.status == .notWorking }) {
                                    return .orange
                                }
                                return .red
                            }()

                            Circle()
                                .fill(color)
                                .frame(width: 14, height: 14)

                            Text(daySlots.isEmpty ? "—" : "Voir")
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    var daySlotsSelectionView: some View {
        NavigationView {
            VStack(spacing: 12) {

                Text("Créneaux du \(selectedDay, style: .date)")
                    .font(.headline)
                    .padding()

                if selectedDaySlots.isEmpty {
                    Text("Aucun créneau pour ce jour")
                        .foregroundColor(.gray)
                        .padding()
                } else {

                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(selectedDaySlots) { slot in

                                Button {
                                    if slot.status == .available {
                                        selectedSlot = slot
                                        showDaySlotsSheet = false
                                        showBookingSheet = true
                                    }
                                } label: {
                                    HStack {
                                        Text("\(slot.startTime, style: .time) → \(slot.endTime, style: .time)")
                                            .font(.headline)

                                        Spacer()

                                        Text(labelForStatus(slot.status))
                                            .font(.caption)
                                            .padding(6)
                                            .background(colorForStatus(slot.status).opacity(0.2))
                                            .foregroundColor(colorForStatus(slot.status))
                                            .cornerRadius(8)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(10)
                                }
                                .disabled(slot.status != .available)
                            }
                        }
                        .padding()
                    }
                }

                Button("Fermer") {
                    showDaySlotsSheet = false
                }
                .padding()
            }
        }
    }
    
    var escrowInfoView: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {

                        Text("🔒 Sécurité de votre paiement (Escrow)")
                            .font(.title3)
                            .bold()

                        Text("""
    Lorsque vous payez :
    • L’argent ne va PAS directement au coiffeur.
    • Il est temporairement bloqué par la plateforme.
    • Le coiffeur ne reçoit l’argent que SI vous confirmez
      que la prestation a bien été réalisée.
    • Après votre coupe, une demande de confirmation
      vous sera envoyée dans l’application.
    • Si vous avez un problème, vous pourrez signaler
      une réclamation avant la libération des fonds.
    """)

                        Divider()

                        Toggle("J’ai compris et j’accepte", isOn: $hasAcceptedEscrow)
                            .padding(.vertical)

                    }
                    .padding()
                }

                Button(action: {
                    if hasAcceptedEscrow {
                        showEscrowInfoSheet = false
                        // 👉 MAINTENANT on lance vraiment le paiement
                        startBookingThenPayment()
                    }
                }) {
                    Text("Continuer vers le paiement")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasAcceptedEscrow ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!hasAcceptedEscrow)
                .padding()

            }
            .navigationTitle("Avant de payer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        showEscrowInfoSheet = false
                    }
                }
            }
        }
    }
    

    var legendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📌 Légende des couleurs")
                .font(.headline)
                .padding(.horizontal)

            HStack {
                colorBadge(label: "Disponible", color: .green)
                colorBadge(label: "Pris", color: .red)
                colorBadge(label: "En attente", color: .orange)
                colorBadge(label: "Pause", color: .yellow)
            }
            .padding(.horizontal)
        }
    }

    func colorBadge(label: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
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
// MARK: - LOGIC (CORRIGÉE)
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
            startBookingThenPayment()
        }
    }
    
    func startBookingThenPayment() {
        
        guard let slot = selectedSlot else {
            print("⚠️ Aucun créneau sélectionné")
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            showLoginAlert = true
            return
        }
        
        isPreparingPayment = true
        
        bookingService.addBooking(
            barber: barber,
            date: slot.startTime,
            clientName: user.displayName ?? "Client"
        ) { success in
            
            if !success {
                DispatchQueue.main.async {
                    self.isPreparingPayment = false
                }
                return
            }
            
            // 1️⃣ Récupérer la réservation qu’on vient de créer
            self.db.collection("bookings")
                .whereField("barberId", isEqualTo: barber.id ?? "")
                .whereField("clientName", isEqualTo: user.displayName ?? "Client")
                .order(by: "createdAt", descending: true)
                .limit(to: 1)
                .getDocuments { snapshot, _ in
                    
                    guard let doc = snapshot?.documents.first else {
                        DispatchQueue.main.async {
                            self.isPreparingPayment = false
                        }
                        print("❌ Impossible de récupérer la réservation")
                        return
                    }
                    
                    let bookingId = doc.documentID
                    self.currentBookingId = bookingId
                    
                    print("🔥 barber.id RAW =", barber.id ?? "nil")
                    print("🔥 barber.id =", barber.id)
                    print("🔥 barber.authId =", barber.authId)
                    print("🆔 barber.id envoyé:", barber.id ?? "nil")
                    
                    // 2️⃣ Demander à Stripe le clientSecret
                    guard let slot = selectedSlot, 
                          let slotId = slot.id else {
                        print("❌ Slot introuvable")
                        return
                    }

                    self.bookingService.createPaymentIntent(
                        bookingId: bookingId,
                        amount: barber.price,
                        barberId: barber.id ?? "",
                        slotId: slotId
                    ) { clientSecret in
                        DispatchQueue.main.async {
                            self.isPreparingPayment = false
                        }
                        
                        guard let clientSecret = clientSecret else {
                            print("❌ Impossible d’obtenir clientSecret")
                            return
                        }
                        
                        // 3️⃣ Préparer PaymentSheet Stripe
                        DispatchQueue.main.async {
                            self.paymentIntentClientSecret = clientSecret
                            
                            var config = PaymentSheet.Configuration()
                            config.merchantDisplayName = "Cutly"
                            config.applePay = .init(
                                merchantId: "merchant.com.cutly",
                                merchantCountryCode: "FR"
                            )
                            
                            self.paymentSheet = PaymentSheet(
                                paymentIntentClientSecret: clientSecret,
                                configuration: config
                            )
                            
                            // 4️⃣ Ouvrir l’écran de paiement Stripe
                            self.presentPaymentSheet()
                        }
                    }
                }
        }
    }
    func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else { return }
        
        paymentSheet.present(from: UIApplication.shared.windows.first!.rootViewController!) { result in
            switch result {
            case .completed:
                self.lockPayment()
                self.markSlotAsBooked()
                
            case .failed(let error):
                print("❌ Paiement échoué:", error.localizedDescription)
                
            case .canceled:
                print("⚠️ Paiement annulé")
            }
        }
    }
    
    func lockPayment() {
        paymentLocked = true
        showConfirmServiceAlert = true
        
        if let bookingId = currentBookingId {
            bookingService.startEscrowPayment(
                bookingId: bookingId,
                amount: barber.price
            ) { _ in }
        }
    }
    
    func releasePaymentToBarber() {
        if paymentLocked, let bookingId = currentBookingId {
            guard let barberId = barber.id else {
                print("❌ ERREUR : barber.id est nil")
                return
            }
            
            bookingService.releasePaymentToBarber(
                bookingId: bookingId,
                barberId: barberId,
                totalAmount: barber.price,
                commissionRate: barber.platformCommissionRate
            ) { _ in }
            
            paymentLocked = false
        }
    }
    
    // 🔥🔥🔥 VERSION FINALE — À COPIER / COLLER 🔥🔥🔥
    // 🔥🔥🔥 VERSION PROPRE ET FONCTIONNELLE 🔥🔥🔥
    func loadBarberSlots() {

        guard let barberId = barber.id else {
            print("❌ barber.id est nil")
            return
        }

        db.collection("slots")
            .whereField("barberId", isEqualTo: barberId)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoadingSlots = false
                }
                
                if let error = error {
                    print("❌ Erreur Firestore slots:", error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("⚠️ Aucun slot trouvé pour :", barberId)
                    DispatchQueue.main.async {
                        self.slots = []
                    }
                    return
                }
                
                print("✅ Slots trouvés :", documents.count)
                
                let loadedSlots = documents.compactMap { doc -> AvailabilitySlot? in
                    let data = doc.data()
                    
                    guard
                        let barberId = data["barberId"] as? String,
                        let date = data["date"] as? Timestamp,
                        let start = data["startTime"] as? Timestamp,
                        let end = data["endTime"] as? Timestamp,
                        let statusRaw = data["status"] as? String
                    else {
                        print("⚠️ Slot invalide :", data)
                        return nil
                    }
                    
                    return AvailabilitySlot(
                        id: doc.documentID,
                        barberId: barberId,
                        date: date.dateValue(),
                        startTime: start.dateValue(),
                        endTime: end.dateValue(),
                        status: SlotStatus(rawValue: statusRaw) ?? .available
                    )
                }
                
                DispatchQueue.main.async {
                    self.slots = loadedSlots
                    print("🟢 Slots transformés :", loadedSlots.count)
                    
                    let uniqueDays = Set(loadedSlots.map {
                        Calendar.current.startOfDay(for: $0.date)
                    })
                    
                    print("📅 Jours uniques chargés :")
                    for day in uniqueDays {
                        print("   →", day)
                    }
                }
            }
    }
    
    func slotsForSpecificDate(_ date: Date) -> [AvailabilitySlot] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return slots.filter { slot in
            let slotDay = calendar.startOfDay(for: slot.date)
            return calendar.isDate(slotDay, inSameDayAs: targetDay)
        }
    }
    
    func previousWeek() {
        currentWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart) ?? currentWeekStart
        loadBarberSlots()
    }
    
    func nextWeek() {
        currentWeekStart = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
        loadBarberSlots()
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
        case .notWorking:
            return .yellow
        }
    }
    
    func labelForStatus(_ status: SlotStatus) -> String {
        switch status {
        case .available: return "Libre"
        case .booked: return "Pris"
        case .pending: return "En attente"
        case .notWorking: return "Pause"
        }
    }
    
    func toggleFavorite() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard let barberId = barber.id else { return }
        
        let ref = db.collection("favorites")
            .whereField("userId", isEqualTo: userId)
            .whereField("barberId", isEqualTo: barberId)
        
        ref.getDocuments { snapshot, _ in
            if let doc = snapshot?.documents.first {
                doc.reference.delete()
                isFavorite = false
            } else {
                db.collection("favorites").addDocument(data: [
                    "userId": userId,
                    "barberId": barberId
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
            
            Button("Confirmer et payer") {
                showBookingSheet = false
                showEscrowInfoSheet = true   // 🔥 Ouvre le pop-up escrow
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    func markSlotAsBooked() {
        guard let slot = selectedSlot else {
            print("❌ Aucun slot sélectionné")
            return
        }
        
        guard let slotId = slot.id else {
            print("❌ Impossible de mettre à jour : slot.id est nil")
            return
        }
        
        db.collection("slots").document(slotId).updateData([
            "status": "booked"
        ]) { error in
            if let error = error {
                print("❌ Erreur mise à jour slot :", error.localizedDescription)
            } else {
                print("✅ Slot marqué comme booked :", slotId)
                DispatchQueue.main.async {
                    self.loadBarberSlots()
                }
            }
        }
    }
    
    private func loadServices() {
        
        guard let barberId = barber.id, !barberId.isEmpty else {
            print("❌ barberId nil ou vide")
            return
        }
        
        print("🔥 barberId utilisé:", barberId)
        
        Firestore.firestore()
            .collection("barbers")
            .document(barberId)
            .collection("services")
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Erreur chargement services:", error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ Aucun service trouvé")
                    return
                }
                
                print("📦 Nombre services trouvés:", documents.count)
                
                var loadedServices: [Service] = []
                
                for doc in documents {
                    
                    let data = doc.data()
                    
                    // 🔥 Correction prix SAFE (Int ou Double)
                    let rawPrice = data["price"]
                    
                    var priceValue: Double = 0
                    
                    if let doublePrice = rawPrice as? Double {
                        priceValue = doublePrice
                    } else if let intPrice = rawPrice as? Int {
                        priceValue = Double(intPrice)
                    }
                    
                    let service = Service(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        price: priceValue,
                        duration: data["duration"] as? Int ?? 0,
                        description: data["description"] as? String ?? "",
                        imageURLs: data["imageURLs"] as? [String] ?? [],
                        isPremium: data["isPremium"] as? Bool ?? false,
                        isActive: data["isActive"] as? Bool ?? true,
                        likesCount: data["likesCount"] as? Int ?? 0,
                        likedBy: data["likedBy"] as? [String] ?? []
                    )
                    
                    loadedServices.append(service)
                }
                
                DispatchQueue.main.async {
                    self.services = loadedServices
                }
            }
    }
}
