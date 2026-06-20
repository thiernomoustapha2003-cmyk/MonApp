import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import StripePayments
import StripePaymentSheet

// =======================================================
// BARBER DASHBOARD VIEW - VERSION CORRIGÉE (ZÉRO LIGNE ROUGE)
// =======================================================

struct BarberDashboardView: View {
    
    @State private var showQRScanner = false
    
    // ===== BOOKINGS & REVIEWS =====
    @State private var pendingBookings: [Booking] = []
    @State private var confirmedBookings: [Booking] = []
    @State private var reviews: [Review] = []
    
    // ===== PROFIL COIFFEUR =====
    @State private var barberName: String = ""
    @State private var barberCity: String = ""
    @State private var barberPhone: String = ""
    @State private var barberImageUrl: String = ""
    @State private var isPro: Bool = false
    @State private var acceptsOnlinePayment: Bool = false
    
    // ===== PAIEMENTS =====
    @State private var totalHeldAmount: Double = 0
    @State private var totalReleasedAmount: Double = 0
    @State private var totalCommission: Double = 0
    
    // ===== CALENDRIER =====
    @State private var monthToShow: Date = Date()
    @State private var dayStatuses: [String: SlotStatus] = [:]
    @State private var daySlots: [String: [AvailabilitySlot]] = [:]
    
    // ===== INTERACTIONS =====
    @State private var selectedDayKey: String? = nil
    
    @State private var showDayDetailsSheet = false
    @State private var showModifyDaySheet = false
    @State private var showBulkActionsSheet = false
    @State private var showCopyPasteSheet = false
    @State private var showSlotManagerSheet = false
    @State private var goToFinance = false
    
    
    // 🔥 NOUVELLES FONCTIONS (6 GRANDES OPTIONS)
    @State private var showPlanningSheet = false
    @State private var showBusinessSheet = false
    @State private var showSecuritySheet = false
    @State private var showFinanceSheet = false
    @State private var showAutomationSheet = false
    
    private let db = Firestore.firestore()
    private let barberId = Auth.auth().currentUser?.uid ?? ""
    
    // ===========================
    // BODY
    // ===========================
    var body: some View {
        NavigationStack {
            content
        }
    }
    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {

                // ===== BOUTON PRINCIPAL (SCAN) =====
                ScanClientButton {
                    showQRScanner = true
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // ===== HEADER PROFIL =====
                headerProfile

                NavigationLink(destination: BarberProfileView()) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text("Modifier mon profil")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Divider()

                // ===== PAIEMENTS =====
                paymentsSection
                
                Divider()
                
                // ===== MINI CALENDRIER =====
                sectionHeader(title: "📅 Mon calendrier (Interactif)")
                
                monthHeader
                monthGridInteractive
                
                Text("👉 Tap : voir heures • Appui long : changer couleur")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                NavigationLink(destination: AvailabilityView()) {
                    Text("📅 Ouvrir la gestion des créneaux (Availability)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Divider()
                
                // ===== NOUVELLES GRANDES OPTIONS =====
                sectionHeader(title: "⚙️ Fonctions avancées")
                
                
                
              
                
                VStack(spacing: 10) {
                    Button("📆 Gestion du planning") { showPlanningSheet = true }
                        .buttonStyle(DashboardButtonStyle(color: .blue))
                    
                    Button("🏪 Paramètres Business") { showBusinessSheet = true }
                        .buttonStyle(DashboardButtonStyle(color: .purple))
                    
                    NavigationLink {
                        ClientManagementView()
                    } label: {
                        Text("👥 Gestion des clients")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DashboardButtonStyle(color: .cyan))


                    NavigationLink {
                        BarberBookingsView()
                    } label: {
                        Text("📅 Rendez-vous clients")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DashboardButtonStyle(color: .green))
                    
                    NavigationLink {
                        ChatListView()
                    } label: {
                        HStack {
                            Image(systemName: "message.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("Messages")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(14)
                    }
                    Button("🔐 Sécurité & accès") { showSecuritySheet = true }
                        .buttonStyle(DashboardButtonStyle(color: .orange))
                    
                    Button("💶 Finance & paiements") { showFinanceSheet = true }
                        .buttonStyle(DashboardButtonStyle(color: Color(red: 0.40, green: 0.00, blue: 0.22)))
                    
                    Button("🤖 Automatisations") { showAutomationSheet = true }
                        .buttonStyle(DashboardButtonStyle(color: .red))
                    
                    NavigationLink(destination: BarberPayoutsView()) {
                        HStack {
                            Text("💸 Mes virements")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .background(Color.green)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // ===== ACTIONS GLOBALES =====
                    globalActionsSection
                    
                    Divider()
                    
                    // ===== DEMANDES =====
                    pendingSection
                    
                    Divider()
                    
                    // ===== CONFIRMÉS =====
                    confirmedSection
                    
                    Divider()
                    
                    // ===== AVIS =====
                    reviewsSection
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Mon tableau de bord")
            .onAppear {
                fetchBarberProfile()
                fetchPendingBookings()
                fetchConfirmedBookings()
                fetchReviews()
                fetchPaymentsSummary()
                fetchMonthStatusesAndSlots()
            }
        }
        NavigationLink("Mes Favoris") {
            FavoritesView()
        }
        // ===== SHEETS EXISTANTES =====
        .sheet(isPresented: $showDayDetailsSheet) {
            if let key = selectedDayKey {
                DayDetailsSheet(dayKey: key, slots: daySlots[key] ?? [])
            }
        }
        
        .sheet(isPresented: $showModifyDaySheet) {
            if let key = selectedDayKey {
                ModifyDaySheet(
                    dayKey: key,
                    onChangeStatus: changeStatusForDay,
                    onDeleteDay: deleteAllSlotsForDay,
                    onReplaceDay: replaceAllSlotsForDay
                )
            }
        }
        
        .sheet(isPresented: $showBulkActionsSheet) {
            BulkActionsSheet(
                onBlockAll: { changeStatusForAllDays(to: "booked") },
                onUnblockAll: { changeStatusForAllDays(to: "available") },
                onDeleteAll: deleteAllSlots,
                onRefresh: fetchMonthStatusesAndSlots
            )
        }
        
        .sheet(isPresented: $showCopyPasteSheet) {
            CopyPasteSheet(
                onCopyWeek: copyCurrentWeek,
                onPasteNextWeek: pasteToNextWeek
            )
        }
        
        
        .sheet(isPresented: $showSlotManagerSheet) {
            if let key = selectedDayKey {
                SlotManagerSheet(dayKey: key, onSave: fetchMonthStatusesAndSlots)
            }
        }
        
        // ===== NOUVELLES SHEETS (6 GRANDES OPTIONS) =====
        .sheet(isPresented: $showPlanningSheet) {
            PlanningSheet(barberId: barberId)
            
        }
        
        .sheet(isPresented: $showBusinessSheet) {
            BusinessSheet()
        }
        
        
        .sheet(isPresented: $showSecuritySheet) {
            NavigationStack {
                SecurityAccessView()
            }
        }
        
        .sheet(isPresented: $showFinanceSheet) {
            FinanceSheet()
        }
        
        .sheet(isPresented: $showAutomationSheet) {
            AutomationSheet()
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerView()
        }
    }

    // ===========================
    // UI HELPERS
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
            Text(value).bold()
        }
        .padding(.horizontal)
    }
    
    // ===========================
    // UI SECTIONS
    // ===========================
    
    var headerProfile: some View {
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
        }
        .padding()
    }
    
    var paymentsSection: some View {
        VStack(spacing: 10) {
            sectionHeader(title: "💰 Paiements & Revenus")
            
            infoLine(title: "Argent bloqué", value: String(format: "%.2f €", totalHeldAmount))
            infoLine(title: "Argent libéré", value: String(format: "%.2f €", totalReleasedAmount))
            infoLine(title: "Commission", value: String(format: "%.2f €", totalCommission))
            
            NavigationLink(
                destination: StripePayoutConfigView()
            ) {
                Text("⚙️ Configurer Stripe / IBAN")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    var globalActionsSection: some View {
        VStack(spacing: 10) {
            
            sectionHeader(title: "⚙️ Actions globales")
            
            Button("🟡 Bloquer / Débloquer tout le mois") {
                showBulkActionsSheet = true
            }
            .buttonStyle(DashboardButtonStyle(color: .orange))
            
            Button("📋 Copier / Coller semaine") {
                showCopyPasteSheet = true
            }
            .buttonStyle(DashboardButtonStyle(color: .blue))
            
            NavigationLink {
                ExpertStudioView()
            } label: {
                Text("🧠 Mode expert")
            }
            .buttonStyle(DashboardButtonStyle(color: .black))
            .buttonStyle(DashboardButtonStyle(color: .black))
            
            Button("🕒 Gestion détaillée des créneaux") {
                showSlotManagerSheet = true
            }
            .buttonStyle(DashboardButtonStyle(color: .green))
        }
        .padding(.horizontal)
    }
    
    var pendingSection: some View {
        VStack {
            sectionHeader(title: "📥 Demandes en attente")
            
            if pendingBookings.isEmpty {
                Text("Aucune demande en attente")
                    .foregroundColor(.gray)
            } else {
                ForEach(pendingBookings) { booking in
                    bookingCard(booking: booking, isPending: true)
                }
            }
        }
    }
    
    var confirmedSection: some View {
        VStack {
            sectionHeader(title: "📅 Rendez-vous confirmés")
            
            if confirmedBookings.isEmpty {
                Text("Aucun rendez-vous confirmé")
                    .foregroundColor(.gray)
            } else {
                ForEach(confirmedBookings) { booking in
                    bookingCard(booking: booking, isPending: false)
                }
            }
        }
    }
    
    var reviewsSection: some View {
        VStack {
            sectionHeader(title: "⭐ Avis des clients")
            
            if reviews.isEmpty {
                Text("Aucun avis pour le moment")
                    .foregroundColor(.gray)
            } else {
                ForEach(reviews) { review in
                    reviewCard(review: review)
                }
            }
        }
    }

    // ===========================
    // MINI CALENDRIER
    // ===========================
    
    var monthHeader: some View {
        HStack {
            Button {
                monthToShow = Calendar.current.date(byAdding: .month, value: -1, to: monthToShow) ?? monthToShow
                fetchMonthStatusesAndSlots()
            } label: {
                Image(systemName: "chevron.left")
            }
            
            Spacer()
            
            Text(formattedMonth(monthToShow))
                .font(.headline)
            
            Spacer()
            
            Button {
                monthToShow = Calendar.current.date(byAdding: .month, value: 1, to: monthToShow) ?? monthToShow
                fetchMonthStatusesAndSlots()
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
    }
    
    var monthGridInteractive: some View {
        let days = generateMonthDays(for: monthToShow)
        
        return VStack(spacing: 8) {
            HStack {
                ForEach(["Lun","Mar","Mer","Jeu","Ven","Sam","Dim"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    let key = formatDate(date)
                    let status = dayStatuses[key] ?? .notWorking
                    
                    VStack {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.caption)
                        
                        Circle()
                            .fill(colorForStatus(status))
                            .frame(width: 14, height: 14)
                    }
                    .frame(maxWidth: .infinity, minHeight: 55)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )
                    .onTapGesture {
                        selectedDayKey = key
                        showDayDetailsSheet = true
                    }
                    .onLongPressGesture {
                        cycleStatusForDay(key)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // ===========================
    // FIRESTORE LOGIC
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
                        clientId: data["clientId"] as? String ?? "",
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
                        clientId: data["clientId"] as? String ?? "",
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

    func fetchMonthStatusesAndSlots() {
        db.collection("slots")
            .whereField("barberId", isEqualTo: barberId)
            .getDocuments { snapshot, _ in

                var statusTemp: [String: SlotStatus] = [:]
                var slotsTemp: [String: [AvailabilitySlot]] = [:]

                snapshot?.documents.forEach { doc in
                    let data = doc.data()

                    if
                        let ts = data["date"] as? Timestamp,
                        let statusRaw = data["status"] as? String,
                        let status = SlotStatus(rawValue: statusRaw)
                    {
                        let key = formatDate(ts.dateValue())
                        statusTemp[key] = status

                        let slot = AvailabilitySlot(
                            id: doc.documentID,
                            barberId: barberId,
                            date: ts.dateValue(),
                            startTime: (data["startTime"] as? Timestamp)?.dateValue() ?? Date(),
                            endTime: (data["endTime"] as? Timestamp)?.dateValue() ?? Date(),
                            status: status
                        )

                        slotsTemp[key, default: []].append(slot)
                    }
                }

                DispatchQueue.main.async {
                    self.dayStatuses = statusTemp
                    self.daySlots = slotsTemp
                }
            }
    }

    // ===========================
    // ACTIONS SUR LES JOURS
    // ===========================

    func cycleStatusForDay(_ key: String) {
        let newStatus: String

        switch dayStatuses[key] {
        case .available:
            newStatus = "pending"
        case .pending:
            newStatus = "booked"
        case .booked:
            newStatus = "available"
        default:
            newStatus = "available"
        }

        changeStatusForDay(dayKey: key, to: newStatus)
    }

    func changeStatusForDay(dayKey: String, to status: String) {
        db.collection("slots")
            .whereField("barberId", isEqualTo: barberId)
            .getDocuments { snapshot, _ in

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    if let ts = data["date"] as? Timestamp,
                       formatDate(ts.dateValue()) == dayKey {
                        doc.reference.updateData(["status": status])
                    }
                }

                fetchMonthStatusesAndSlots()
            }
    }

    func changeStatusForAllDays(to status: String) {
        db.collection("slots")
            .whereField("barberId", isEqualTo: barberId)
            .getDocuments { snapshot, _ in

                snapshot?.documents.forEach { doc in
                    doc.reference.updateData(["status": status])
                }

                fetchMonthStatusesAndSlots()
            }
    }

    func deleteAllSlotsForDay(dayKey: String) {
        db.collection("slots")
            .whereField("barberId", isEqualTo: barberId)
            .getDocuments { snapshot, _ in

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    if let ts = data["date"] as? Timestamp,
                       formatDate(ts.dateValue()) == dayKey {
                        doc.reference.delete()
                    }
                }

                fetchMonthStatusesAndSlots()
            }
    }

    func deleteAllSlots() {
        db.collection("slots")
            .whereField("barberId", isEqualTo: barberId)
            .getDocuments { snapshot, _ in

                snapshot?.documents.forEach { doc in
                    doc.reference.delete()
                }

                fetchMonthStatusesAndSlots()
            }
    }

    func replaceAllSlotsForDay(dayKey: String) {
        deleteAllSlotsForDay(dayKey: dayKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            fetchMonthStatusesAndSlots()
        }
    }

    func copyCurrentWeek() { }
    func pasteToNextWeek() { }

    func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    func generateMonthDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.map { calendar.date(byAdding: .day, value: $0 - 1, to: start)! }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func colorForStatus(_ status: SlotStatus) -> Color {
        switch status {
        case .available: return .green
        case .booked: return .red
        case .pending: return .orange
        case .notWorking: return .yellow
        }
    }

    // ===========================
    // UI CARDS
    // ===========================

    func bookingCard(booking: Booking, isPending: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Client : \(booking.clientName)")
                .font(.headline)

            Text("📅 \(booking.date) • ⏰ \(booking.time)")
                .font(.subheadline)

            HStack {
                if isPending {
                    Button("Accepter") {
                        db.collection("bookings").document(booking.id)
                            .updateData(["status": "confirmed"]) { _ in
                                fetchPendingBookings()
                                fetchConfirmedBookings()
                            }
                    }
                    .foregroundColor(.green)

                    Spacer()

                    Button("Refuser") {
                        db.collection("bookings").document(booking.id)
                            .updateData(["status": "cancelled"]) { _ in
                                fetchPendingBookings()
                            }
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
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// =========================
// STYLES
// =========================

struct DashboardButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// =========================
// SHEETS (FENÊTRES)
// =========================

struct DayDetailsSheet: View {
    let dayKey: String
    let slots: [AvailabilitySlot]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Text("📅 Détails du \(dayKey)")
                    .font(.headline)

                if slots.isEmpty {
                    Text("Aucun créneau")
                        .foregroundColor(.gray)
                } else {
                    ForEach(slots) { slot in
                        Text("⏰ \(slot.startTime, style: .time) - \(slot.endTime, style: .time)")
                    }
                }

                Button("💾 Enregistrer") { dismiss() }
                Button("Fermer") { dismiss() }
            }
            .padding()
        }
    }
}

struct ModifyDaySheet: View {
    let dayKey: String
    var onChangeStatus: (String, String) -> Void
    var onDeleteDay: (String) -> Void
    var onReplaceDay: (String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Modifier le jour : \(dayKey)")
                    .font(.headline)

                Button("🟢 Rendre disponible") { onChangeStatus(dayKey, "available") }
                Button("🟡 Mettre en attente") { onChangeStatus(dayKey, "pending") }
                Button("🔴 Bloquer le jour") { onChangeStatus(dayKey, "booked") }
                Button("🗑 Supprimer tous les créneaux") { onDeleteDay(dayKey) }
                Button("🔄 Remplacer tous les créneaux") { onReplaceDay(dayKey) }
                Button("💾 Enregistrer") { dismiss() }
            }
            .padding()
        }
    }
}

struct BulkActionsSheet: View {
    var onBlockAll: () -> Void
    var onUnblockAll: () -> Void
    var onDeleteAll: () -> Void
    var onRefresh: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Actions globales sur le mois")
                    .font(.headline)

                Button("🔴 Bloquer tout le mois") { onBlockAll() }
                Button("🟢 Débloquer tout le mois") { onUnblockAll() }
                Button("🗑 Supprimer tous les créneaux") { onDeleteAll() }
                Button("🔄 Rafraîchir") { onRefresh() }
                Button("💾 Enregistrer") { dismiss() }
            }
            .padding()
        }
    }
}

struct CopyPasteSheet: View {
    var onCopyWeek: () -> Void
    var onPasteNextWeek: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Copier / Coller semaine")
                    .font(.headline)

                Button("📋 Copier semaine actuelle") { onCopyWeek() }
                Button("📎 Coller semaine suivante") { onPasteNextWeek() }
                Button("💾 Enregistrer") { dismiss() }
            }
            .padding()
        }
    }
}


struct SlotManagerSheet: View {
    let dayKey: String
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Gestion des créneaux — \(dayKey)")
                    .font(.headline)

                Button("✂️ Fractionner créneaux") { }
                Button("🔗 Fusionner créneaux") { }
                Button("➕ Ajouter créneau manuel") { }

                Button("💾 Enregistrer") {
                    onSave()
                    dismiss()
                }
            }
            .padding()
        }
    }
}

// =========================
// 6 GRANDES FENÊTRES
// =========================

// =======================================================
// ✅ NOUVELLE PLANNINGSHEET (REMPLACE L’ANCIENNE)
// =======================================================

struct PlanningSheet: View {
    
    
    let barberId: String
    
    @State private var blockedDays: Set<String> = []
    @State private var showHours = false
    @State private var showBreaks = false
    @State private var showOpeningHours = false
    @State private var showBlockDays = false
    @State private var showWeekend = false
    @State private var showCopy = false
    @State private var showTemplate = false
    
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Text("📆 Gestion du Planning")
                    .font(.headline)
                
                Button("🕒 Définir horaires d’ouverture") {
                    showOpeningHours = true
                }
                
                Button("☕ Gérer pauses automatiques") {
                    showBreaks = true
                }
                
                Button("🚫 Bloquer jours spécifiques") {
                    showBlockDays = true
                }
                
                Button("📅 Activer / désactiver week-end") {
                    showWeekend = true
                }
                
                Button("📋 Appliquer modèle prédéfini") {
                    showTemplate = true
                }
                
                Button("💾 Fermer") { dismiss() }
            }
            .padding()
        }
        // === LES SOUS-FENÊTRES (SHEETS) ===
        .sheet(isPresented: $showOpeningHours) {
            OpeningHoursSheet()
        }
        .sheet(isPresented: $showBreaks) {
            BreaksSheet(barberId: barberId)
        }
        .sheet(isPresented: $showBlockDays) {
            OpeningHoursSheet()
        }
        .sheet(isPresented: $showWeekend) {
            WeekendSheetPro(barberId: barberId)
        }
        
        .sheet(isPresented: $showCopy) {
            CopyPlanningSheet(barberId: barberId)
        }
        
        .sheet(isPresented: $showTemplate) {
            PlanningTemplateSheetPro(barberId: barberId)
        }
    }
}

// =======================================================
// ✅ WEEK-END (VRAIE VERSION PRO)
// =======================================================

struct WeekendSheetPro: View {
    let barberId: String
    @Environment(\.dismiss) var dismiss
    private let db = Firestore.firestore()

    @State private var weekendEnabled = false

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Activer le week-end", isOn: $weekendEnabled)

                Button("💾 Enregistrer") {
                    saveWeekend()
                    dismiss()
                }
            }
            .navigationTitle("Gestion du week-end")
        }
        .onAppear {
            fetchWeekend()
        }
    }

    func fetchWeekend() {
        db.collection("users")
            .document(barberId)
            .collection("planning")
            .document("weekend")
            .getDocument { snapshot, _ in
                let data = snapshot?.data() ?? [:]
                weekendEnabled = data["enabled"] as? Bool ?? false
            }
    }

    func saveWeekend() {
        db.collection("users")
            .document(barberId)
            .collection("planning")
            .document("weekend")
            .setData([
                "enabled": weekendEnabled
            ])
    }
}


// =======================================================
// ✅ COPIER / COLLER PLANNING (VRAIE VERSION)
// =======================================================

struct CopyPlanningSheet: View {
    let barberId: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("📋 Copier le planning")
                    .font(.headline)

                Button("Copier cette semaine") {
                    // (on connectera plus tard)
                }

                Button("Coller sur la semaine suivante") {
                    // (on connectera plus tard)
                }

                Button("💾 Fermer") { dismiss() }
            }
            .padding()
            .navigationTitle("Copier planning")
        }
    }
}

// =======================================================
// ✅ MODÈLES DE PLANNING (VRAIE VERSION)
// =======================================================

struct PlanningTemplateSheetPro: View {
    let barberId: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button("Modèle Classique") {
                    // (à brancher plus tard)
                    dismiss()
                }

                Button("Modèle Temps partiel") {
                    dismiss()
                }

                Button("Modèle Week-end OFF") {
                    dismiss()
                }
            }
            .navigationTitle("Modèles de planning")
        }
    }
}


// =======================================================
// ✅ NOUVEL ÉCRAN : GESTION DES PAUSES (PRO + FIRESTORE)
// =======================================================

struct BreaksSheet: View {
    let barberId: String

    @Environment(\.dismiss) var dismiss
    private let db = Firestore.firestore()

    @State private var breaks: [(start: Date, end: Date)] = []
    @State private var newStart = Date()
    @State private var newEnd = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Text("☕ Pauses automatiques")
                    .font(.headline)

                Divider()

                // ===== AJOUTER UNE PAUSE =====
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ajouter une pause")
                        .bold()

                    DatePicker("Début", selection: $newStart, displayedComponents: .hourAndMinute)
                    DatePicker("Fin", selection: $newEnd, displayedComponents: .hourAndMinute)

                    Button("➕ Ajouter cette pause") {
                        addBreak()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                Divider()

                // ===== LISTE DES PAUSES =====
                Text("Tes pauses")
                    .bold()

                if breaks.isEmpty {
                    Text("Aucune pause enregistrée")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(Array(breaks.enumerated()), id: \.offset) { index, pause in
                            HStack {
                                Text("\(pause.start, style: .time) → \(pause.end, style: .time)")
                                Spacer()
                                Button("🗑") {
                                    deleteBreak(at: index)
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                    .frame(height: 200)
                }

                Spacer()

                Button("💾 Enregistrer et fermer") {
                    saveBreaks()
                    dismiss()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
            .onAppear {
                fetchBreaks()
            }
        }
    }

    // ===========================
    // FIRESTORE LOGIC
    // ===========================

    func fetchBreaks() {
        db.collection("users")
            .document(barberId)
            .collection("planning")
            .document("breaks")
            .getDocument { snapshot, _ in

                let data = snapshot?.data() ?? [:]
                var loadedBreaks: [(Date, Date)] = []

                if let array = data["list"] as? [[String: Timestamp]] {
                    for item in array {
                        if let start = item["start"]?.dateValue(),
                           let end = item["end"]?.dateValue() {
                            loadedBreaks.append((start, end))
                        }
                    }
                }

                self.breaks = loadedBreaks
            }
    }

    func addBreak() {
        breaks.append((newStart, newEnd))
    }

    func deleteBreak(at index: Int) {
        breaks.remove(at: index)
    }

    func saveBreaks() {
        let mapped = breaks.map { pause in
            return [
                "start": Timestamp(date: pause.start),
                "end": Timestamp(date: pause.end)
            ]
        }

        db.collection("users")
            .document(barberId)
            .collection("planning")
            .document("breaks")
            .setData([
                "list": mapped
            ])
    }
}

struct WeekendSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Text("📅 Week-end")
                    .font(.headline)

                Text("Ici tu pourras activer/désactiver le week-end plus tard.")

                Button("Fermer") { dismiss() }
            }
            .padding()
        }
    }
}

struct PlanningTemplateSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Text("📋 Modèles de planning")
                    .font(.headline)

                Text("Ici tu pourras choisir un modèle plus tard.")

                Button("Fermer") { dismiss() }
            }
            .padding()
        }
    }
}


struct ClientSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Text("👥 Gestion des Clients").font(.headline)

                Button("Voir liste clients") { }
                Button("Blacklister un client") { }
                Button("Envoyer message") { }
                Button("Voir historique RDV") { }
                Button("Ajouter note client") { }
                Button("Exporter données clients") { }

                Button("💾 Enregistrer") { dismiss() }
            }
            .padding()
        }
    }
}

struct SecuritySheet: View {
    @State private var showPassword = false
    @State private var show2FA = false
    @State private var showDevices = false
    @State private var showRevoke = false
    @State private var showLogs = false
    @State private var showBackup = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Text("🔐 Sécurité & Accès").font(.headline)

                Button("Changer mot de passe") { showPassword = true }
                Button("Activer double authentification") { show2FA = true }
                Button("Gérer appareils connectés") { showDevices = true }
                Button("Révoquer accès employé") { showRevoke = true }
                Button("Voir journal de connexion") { showLogs = true }
                Button("Sauvegarde des données") { showBackup = true }

                Button("💾 Enregistrer") { dismiss() }
            }
            .padding()
        }
        .sheet(isPresented: $showPassword) { SimpleActionSheet(title: "Changer mot de passe") }
        .sheet(isPresented: $show2FA) { SimpleActionSheet(title: "Double authentification") }
        .sheet(isPresented: $showDevices) { SimpleActionSheet(title: "Appareils connectés") }
        .sheet(isPresented: $showRevoke) { SimpleActionSheet(title: "Révoquer accès") }
        .sheet(isPresented: $showLogs) { SimpleActionSheet(title: "Journal") }
        .sheet(isPresented: $showBackup) { SimpleActionSheet(title: "Sauvegarde") }
    }
}
struct FinanceSheet: View {
    @State private var showRevenue = false
    @State private var showCommission = false
    @State private var showStripe = false
    @State private var showInvoices = false
    @State private var showHistory = false
    @State private var showPlan = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Text("💶 Finance & Paiements").font(.headline)

                Button("Voir revenus du mois") { showRevenue = true }
                Button("Gérer commissions") { showCommission = true }
                Button("Télécharger factures") { showInvoices = true }
                Button("Historique des paiements") { showHistory = true }
                Button("Plan de paiement") { showPlan = true }

                Button("💾 Enregistrer") { dismiss() }
            }
            .padding()
        }
        .sheet(isPresented: $showRevenue) { FinanceMonthlyView() }
        .sheet(isPresented: $showCommission) { CommissionSettingsView() }
        .sheet(isPresented: $showInvoices) { InvoicesView() }
        .sheet(isPresented: $showHistory) { PaymentsHistoryView() }
        .sheet(isPresented: $showHistory) { BarberPayoutsView() }
        .sheet(isPresented: $showPlan) { PayoutScheduleView() }
    }
}


struct AutomationSheet: View {
    @State private var settings = AutomationSettings()
    private let service = AutomationService()
    
    @State private var showReminder = false
    @State private var showConfirm = false
    @State private var showMessage = false
    @State private var showBlock = false
    @State private var showSync = false
    @State private var showAI = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {

                Text("🤖 Automatisations")
                    .font(.headline)

                Button("⏰ Rappels automatiques") {
                    showReminder = true
                }

                Button("✅ Confirmation automatique") {
                    showConfirm = true
                }

                Button("💬 Message après RDV") {
                    showMessage = true
                }

                Button("🚫 Protection anti no-show") {
                    showBlock = true
                }

                Button("📅 Rebooking intelligent") {
                    showAI = true
                }

                Button("Fermer") {
                    dismiss()
                }
            }
            .padding()
        }
        .sheet(isPresented: $showReminder) { AutoReminderView() }
        .sheet(isPresented: $showConfirm) { AutoConfirmBookingView() }
        .sheet(isPresented: $showMessage) { AfterAppointmentMessageView() }
        .sheet(isPresented: $showBlock) { NoShowProtectionView() }
        .sheet(isPresented: $showAI) { SmartRebookingView() }
    }
    
    
    
    // =======================================================
    // ✅ VERSION CORRIGÉE (COMPATIBLE AVEC TON DASHBOARD)
    // =======================================================
    
    struct BlockDaysSheetPro: View {
        
        let barberId: String
        
        @Environment(\.dismiss) var dismiss
        let db = Firestore.firestore()
        
        @State private var blockedDays: Set<String> = []
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 15) {
                    
                    Text("⛔️ Bloquer des jours")
                        .font(.headline)
                    
                    Text("Tap sur un jour pour le bloquer / débloquer")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    Divider()
                    
                    // === MINI CALENDRIER ===
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                            
                            ForEach(generateNext30Days(), id: \.self) { date in
                                let key = formatDate(date)
                                let isBlocked = blockedDays.contains(key)
                                
                                VStack {
                                    Text("\(Calendar.current.component(.day, from: date))")
                                        .font(.caption)
                                    
                                    Circle()
                                        .fill(isBlocked ? Color.red : Color.green)
                                        .frame(width: 14, height: 14)
                                }
                                .frame(minHeight: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3))
                                )
                                .onTapGesture {
                                    toggleDay(key)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Divider()
                    
                    Button("💾 Enregistrer et fermer") {
                        saveBlockedDays()
                        dismiss()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
                .onAppear {
                    fetchBlockedDays()
                }
            }
        }
        
        // ===========================
        // FIRESTORE LOGIC
        // ===========================
        
        func fetchBlockedDays() {
            db.collection("users")
                .document(barberId)
                .collection("planning")
                .document("blockedDays")
                .getDocument { snapshot, _ in
                    
                    let data = snapshot?.data() ?? [:]
                    let list = data["days"] as? [String] ?? []
                    self.blockedDays = Set(list)
                }
        }
        
        func toggleDay(_ day: String) {
            if blockedDays.contains(day) {
                blockedDays.remove(day)
            } else {
                blockedDays.insert(day)
            }
        }
        
        func saveBlockedDays() {
            db.collection("users")
                .document(barberId)
                .collection("planning")
                .document("blockedDays")
                .setData([
                    "days": Array(blockedDays)
                ])
        }
        
        // ===========================
        // UTILS
        // ===========================
        
        func generateNext30Days() -> [Date] {
            let calendar = Calendar.current
            return (0..<30).compactMap {
                calendar.date(byAdding: .day, value: $0, to: Date())
            }
        }
        
        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
    }
    
    
    struct OpeningHoursSheet: View {
        
        let barberId: String
        @Environment(\.dismiss) var dismiss
        
        @State private var hours: [String: (isOpen: Bool, start: Date, end: Date)] = [
            "monday": (true, Date(), Date()),
            "tuesday": (true, Date(), Date()),
            "wednesday": (true, Date(), Date()),
            "thursday": (true, Date(), Date()),
            "friday": (true, Date(), Date()),
            "saturday": (true, Date(), Date()),
            "sunday": (false, Date(), Date())
        ]
        
        private let db = Firestore.firestore()
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        Text("🕒 Horaires d’ouverture")
                            .font(.headline)
                        
                        ForEach(days, id: \.self) { day in
                            dayRow(day: day)
                        }
                        
                        Button("💾 Enregistrer") {
                            saveOpeningHours()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        
                        Button("Fermer") {
                            dismiss()
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                fetchOpeningHours()
            }
        }
        
        let days = [
            "monday","tuesday","wednesday",
            "thursday","friday","saturday","sunday"
        ]
        
        func dayLabel(_ day: String) -> String {
            switch day {
            case "monday": return "Lundi"
            case "tuesday": return "Mardi"
            case "wednesday": return "Mercredi"
            case "thursday": return "Jeudi"
            case "friday": return "Vendredi"
            case "saturday": return "Samedi"
            default: return "Dimanche"
            }
        }
        
        func dayRow(day: String) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                
                Toggle(dayLabel(day), isOn: Binding(
                    get: { hours[day]?.isOpen ?? false },
                    set: { hours[day]?.isOpen = $0 }
                ))
                
                if hours[day]?.isOpen == true {
                    HStack {
                        Text("Ouverture")
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { hours[day]?.start ?? Date() },
                                set: { hours[day]?.start = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                    
                    HStack {
                        Text("Fermeture")
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { hours[day]?.end ?? Date() },
                                set: { hours[day]?.end = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                
                Divider()
            }
        }
        
        func saveOpeningHours() {
            var data: [String: Any] = [:]
            
            for day in days {
                if let h = hours[day] {
                    data[day] = [
                        "isOpen": h.isOpen,
                        "start": Timestamp(date: h.start),
                        "end": Timestamp(date: h.end)
                    ]
                }
            }
            
            db.collection("users")
                .document(barberId)
                .collection("planning")
                .document("openingHours")
                .setData(data, merge: true) { error in
                    if error == nil {
                        dismiss()
                    }
                }
        }
        
        func fetchOpeningHours() {
            db.collection("users")
                .document(barberId)
                .collection("planning")
                .document("openingHours")
                .getDocument { snapshot, _ in
                    
                    guard let data = snapshot?.data() else { return }
                    
                    for day in days {
                        if let d = data[day] as? [String: Any] {
                            let isOpen = d["isOpen"] as? Bool ?? false
                            let start = (d["start"] as? Timestamp)?.dateValue() ?? Date()
                            let end = (d["end"] as? Timestamp)?.dateValue() ?? Date()
                            
                            hours[day] = (isOpen, start, end)
                        }
                    }
                }
        }
    }
    // =============================================
    // ✅ SIMPLE ACTION SHEET (OBLIGATOIRE)
    // =============================================
    
    struct SimpleActionSheet: View {
        
        let title: String
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 20) {
                    
                    Text(title)
                        .font(.headline)
                    
                    Button("Option 1") { }
                    Button("Option 2") { }
                    Button("Option 3") { }
                    
                    Button("💾 Fermer") {
                        dismiss()
                    }
                }
                .padding()
            }
        }
    }
}
