//
//  AdminDashboardBookings.swift
//  Cutly
//
//  Dashboard Premium - Bookings
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AdminBookingStatistics {

    var totalBookings: Int = 0
    var completed: Int = 0
    var cancelled: Int = 0
    var pending: Int = 0
    var refunded: Int = 0

    var totalRevenue: Double = 0
    var platformCommission: Double = 0

    var averageBookingValue: Double = 0
}

enum BookingFilter: String, CaseIterable, Identifiable {

    case today = "Aujourd'hui"
    case week = "Cette semaine"
    case month = "Ce mois"
    case year = "Cette année"
    case custom = "Personnalisé"

    var id: String { rawValue }
}

enum BookingStatusFilter: String, CaseIterable, Identifiable {

    case all = "Toutes"
    case pending = "En attente"
    case confirmed = "Confirmées"
    case completed = "Terminées"
    case cancelled = "Annulées"
    case refunded = "Remboursées"
    case dispute = "Litiges"

    var id: String { rawValue }
}

struct AdminDashboardBookings: View {

    @State private var selectedPeriod: BookingFilter = .today
    @State private var selectedStatus: BookingStatusFilter = .all

    @State private var searchText = ""

    @State private var startDate = Date()

    @State private var endDate = Date()

    @State private var statistics = AdminBookingStatistics()

    @State private var bookings: [AdminBookingItem] = []

    @State private var loading = true

    @State private var showingCalendar = false

    private let db = Firestore.firestore()

    var filteredBookings: [AdminBookingItem] {

        bookings.filter {

            if selectedStatus == .all {
                return true
            }

            return $0.status.lowercased() ==
                selectedStatus.rawValue.lowercased()
        }
    }

    var body: some View {

        ScrollView {

            VStack(spacing:24){

                premiumHeader

                filterBar

                statisticsCards

                bookingList

            }
            .padding()

        }
        .background(Color(
            red:0.96,
            green:0.97,
            blue:1.0
        ))
        .navigationTitle("Réservations")
        .navigationBarTitleDisplayMode(.inline)
        .task {

            await loadBookings()

        }

    }

}
extension AdminDashboardBookings {

    // MARK: - HEADER PREMIUM

    var premiumHeader: some View {

        VStack(alignment: .leading, spacing: 20) {

            HStack {

                VStack(alignment: .leading, spacing: 6) {

                    Text("Centre des réservations")
                        .font(.system(size: 30, weight: .bold))

                    Text("Toutes les réservations de la plateforme Cutly")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))

                }

                Spacer()

                Button {

                    showingCalendar.toggle()

                } label: {

                    Label("Calendrier", systemImage: "calendar")

                }
                .buttonStyle(.borderedProminent)

            }

            HStack(spacing:16){
                TextField("Rechercher un client, coiffeur ou réservation...", text: $searchText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(14)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
                    .cornerRadius(16)

                Button{

                    Task {

                        await loadBookings()

                    }

                }label:{

                    Image(systemName:"arrow.clockwise")
                        .font(.title3)

                }

            }

        }

    }

    // MARK: - FILTRES

    var filterBar: some View {

        VStack(spacing:16){

            ScrollView(.horizontal, showsIndicators: false){

                HStack{

                    ForEach(BookingFilter.allCases){ filter in

                        Button{

                            selectedPeriod = filter

                            Task{

                                await loadBookings()

                            }

                        }label:{

                            Text(filter.rawValue)
                                .font(.subheadline.bold())
                                .padding(.horizontal,18)
                                .padding(.vertical,10)
                                .background(
                                    selectedPeriod == filter
                                    ? Color.purple
                                    : Color.white
                                )
                                .foregroundStyle(
                                    selectedPeriod == filter
                                    ? .white
                                    : .primary
                                )
                                .clipShape(Capsule())

                        }

                    }

                }

            }

            Picker("Etat", selection: $selectedStatus){

                ForEach(BookingStatusFilter.allCases){

                    Text($0.rawValue)
                        .tag($0)

                }

            }
            .pickerStyle(.segmented)

        }

    }

}
extension AdminDashboardBookings {

    // MARK: - STATISTIQUES

    var statisticsCards: some View {

        VStack(spacing:20){

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing:18
            ){

                bookingCard(
                    title: "Réservations",
                    value: "\(statistics.totalBookings)",
                    subtitle: "Toutes périodes",
                    icon: "calendar.badge.clock",
                    color: .blue
                )

                bookingCard(
                    title: "Terminées",
                    value: "\(statistics.completed)",
                    subtitle: "Services effectués",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                bookingCard(
                    title: "Annulées",
                    value: "\(statistics.cancelled)",
                    subtitle: "Clients / Coiffeurs",
                    icon: "xmark.circle.fill",
                    color: .red
                )

                bookingCard(
                    title: "En attente",
                    value: "\(statistics.pending)",
                    subtitle: "Confirmation",
                    icon: "clock.fill",
                    color: .orange
                )

                bookingCard(
                    title: "Remboursements",
                    value: "\(statistics.refunded)",
                    subtitle: "Stripe / Mobile Money",
                    icon: "arrow.uturn.backward.circle.fill",
                    color: .purple
                )

                bookingCard(
                    title: "Commission",
                    value: String(format: "%.2f €", statistics.platformCommission),
                    subtitle: "Revenus Cutly",
                    icon: "eurosign.circle.fill",
                    color: .mint
                )

            }

            VStack(spacing:16){

                HStack{

                    Text("Chiffre d'affaires")
                        .font(.headline)

                    Spacer()

                    Text(
                        String(
                            format:"%.2f €",
                            statistics.totalRevenue
                        )
                    )
                    .font(.title2.bold())
                    .foregroundStyle(.green)

                }

                ProgressView(
                    value: statistics.platformCommission,
                    total: max(statistics.totalRevenue,1)
                )
                .tint(.green)

                HStack{
                    
                    Text("Commission plateforme")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black.opacity(0.82))
                    
                    Spacer()
                    
                    Text("\(Int((statistics.platformCommission / max(statistics.totalRevenue,1))*100)) %")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                }

            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius:22))
            .shadow(color:.black.opacity(0.06),radius:12)

        }

    }

    // MARK: - CARTE PREMIUM

    func bookingCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {

                Image(systemName: icon)
                    .font(.title2.bold())
                    .foregroundStyle(color)

                Spacer()

                Circle()
                    .fill(color.opacity(0.22))
                    .frame(width: 16, height: 16)
            }

            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.black)

            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)

            Text(subtitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 12)
    }

}
extension AdminDashboardBookings {

    // MARK: - LISTE DES RÉSERVATIONS

    var bookingList: some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                Text("Réservations")
                    .font(.title2.bold())

                Spacer()

                Text("\(filteredBookings.count)")
                    .font(.headline)
                    .padding(.horizontal,12)
                    .padding(.vertical,6)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(Capsule())

            }

            if loading {

                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical,80)

            } else if filteredBookings.isEmpty {

                VStack(spacing:20){

                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundStyle(.gray)

                    Text("Aucune réservation trouvée")
                        .font(.headline)

                    Text("Les nouvelles réservations apparaîtront ici automatiquement.")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth:.infinity)
                .padding(.vertical,80)

            } else {

                LazyVStack(spacing:18){

                    ForEach(filteredBookings){ booking in

                        bookingRow(booking)

                    }

                }

            }

        }

    }

    // MARK: - CELLULE PREMIUM

    @ViewBuilder
    func bookingRow(_ booking: AdminBookingItem) -> some View {

        VStack(alignment:.leading,spacing:18){

            HStack{

                VStack(alignment:.leading,spacing:5){

                    Text("Réservation")
                        .font(.headline)

                    Text(booking.id)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black.opacity(0.78))

                }

                Spacer()

                bookingStatusBadge(booking.status)

            }

            Divider()

            HStack{

                bookingInfo(
                    title: "Paiement",
                    value: booking.paymentStatus,
                    icon: "creditcard.fill"
                )

                Spacer()

                bookingInfo(
                    title: "Commission",
                    value: String(format:"%.2f €", booking.commission),
                    icon: "eurosign.circle.fill"
                )

                Spacer()

                bookingInfo(
                    title: "Montant",
                    value: String(format:"%.2f €", booking.amount),
                    icon: "banknote.fill"
                )

            }

            Divider()

            HStack(spacing:12){

                Button{

                    openBookingDetails(booking)

                }label:{

                    Label("Voir", systemImage: "eye.fill")

                }
                .buttonStyle(.borderedProminent)

                Button{

                    contactClient(booking)

                }label:{

                    Label("Client", systemImage: "person.fill")

                }
                .buttonStyle(.bordered)

                Button{

                    contactBarber(booking)

                }label:{

                    Label("Coiffeur", systemImage: "scissors")

                }
                .buttonStyle(.bordered)

            }

            HStack(spacing:12){

                Button{

                    refundBooking(booking)

                }label:{

                    Label("Rembourser", systemImage: "arrow.uturn.backward.circle.fill")

                }
                .buttonStyle(.bordered)

                Button{

                    openDispute(booking)

                }label:{

                    Label("Litige", systemImage: "exclamationmark.bubble.fill")

                }
                .buttonStyle(.bordered)

                Spacer()

            }

        }
        .padding(22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius:24))
        .shadow(color:.black.opacity(0.05),radius:10)

    }

    // MARK: - BADGE

    @ViewBuilder
    func bookingStatusBadge(_ status:String)->some View{

        Text(status)

            .font(.caption.bold())

            .padding(.horizontal,12)

            .padding(.vertical,6)

            .background(statusColor(status).opacity(0.18))

            .foregroundStyle(statusColor(status))

            .clipShape(Capsule())

    }

    func bookingInfo(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.78))

            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
        }
    }

}
extension AdminDashboardBookings {

    // MARK: - FIRESTORE

    @MainActor
    func loadBookings() async {

        loading = true

        do {

            let snapshot = try await db
                .collection("bookings")
                .order(by: "createdAt", descending: true)
                .getDocuments()

            var loaded: [AdminBookingItem] = []

            var stats = AdminBookingStatistics()

            for document in snapshot.documents {

                let data = document.data()

                let booking = AdminBookingItem(

                    id: document.documentID,

                    status: data["status"] as? String ?? "pending",

                    paymentStatus: data["paymentStatus"] as? String ?? "pending",

                    amount: data["amount"] as? Double ?? 0,

                    commission: data["platformCommission"] as? Double ?? 0,

                    createdAt: (data["createdAt"] as? Timestamp)?
                        .dateValue() ?? Date()

                )

                loaded.append(booking)

                stats.totalBookings += 1

                stats.totalRevenue += booking.amount

                stats.platformCommission += booking.commission

                switch booking.status.lowercased() {

                case "completed":
                    stats.completed += 1

                case "cancelled":
                    stats.cancelled += 1

                case "pending":
                    stats.pending += 1

                case "refunded":
                    stats.refunded += 1

                default:
                    break

                }

            }

            if stats.totalBookings > 0 {

                stats.averageBookingValue =
                stats.totalRevenue /
                Double(stats.totalBookings)

            }

            bookings = loaded

            statistics = stats

            loading = false

        }

        catch {

            print("❌ Booking Dashboard :", error.localizedDescription)

            loading = false

        }

    }

    // MARK: - COULEUR DES BADGES

    func statusColor(_ status:String)->Color{

        switch status.lowercased(){

        case "completed":
            return .green

        case "confirmed":
            return .blue

        case "pending":
            return .orange

        case "cancelled":
            return .red

        case "refunded":
            return .purple

        case "dispute":
            return .pink

        default:
            return .gray

        }

    }

    // MARK: - ACTIONS

    func openBookingDetails(_ booking:AdminBookingItem){

        print("📄 Ouvrir réservation :",booking.id)

        // TODO
        // Navigation vers BookingDetailsView

    }

    func contactClient(_ booking:AdminBookingItem){

        print("👤 Contacter client :",booking.id)

        // TODO
        // Ouvrir la conversation Chat

    }

    func contactBarber(_ booking:AdminBookingItem){

        print("💈 Contacter coiffeur :",booking.id)

        // TODO
        // Ouvrir la conversation Chat

    }

    func refundBooking(_ booking:AdminBookingItem){

        print("💳 Demande remboursement :",booking.id)

        // TODO
        // Stripe Refund
        // Orange Money
        // Wave
        // Mobile Money

    }

    func openDispute(_ booking:AdminBookingItem){

        print("⚖️ Ouvrir litige :",booking.id)

        // TODO
        // IA Cutly
        // Analyse automatique
        // Historique
        // Décision
        // Documents
        // Photos

    }

}
extension AdminDashboardBookings {

    // MARK: - CALENDRIER PREMIUM

    @ViewBuilder
    var bookingCalendarSection: some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundStyle(.purple)

                Text("Calendrier professionnel")
                    .font(.title2.bold())

                Spacer()

            }

            VStack(spacing: 18) {

                DatePicker(
                    "Date de début",
                    selection: $startDate,
                    displayedComponents: .date
                )

                DatePicker(
                    "Date de fin",
                    selection: $endDate,
                    displayedComponents: .date
                )

                HStack {

                    Button {

                        Task {

                            await loadBookings()

                        }

                    } label: {

                        Label(
                            "Appliquer",
                            systemImage: "line.3.horizontal.decrease.circle.fill"
                        )

                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    Button {

                        startDate = Calendar.current.date(
                            byAdding: .day,
                            value: -30,
                            to: Date()
                        ) ?? Date()

                        endDate = Date()

                        Task {

                            await loadBookings()

                        }

                    } label: {

                        Label(
                            "Réinitialiser",
                            systemImage: "arrow.counterclockwise.circle.fill"
                        )

                    }
                    .buttonStyle(.bordered)

                }

            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.05), radius: 10)

        }

    }

    // MARK: - IA CUTLY (Préparation)

    func analyzeBookingWithAI(
        booking: AdminBookingItem
    ) {

        print("🤖 Analyse IA réservation :", booking.id)

        /*
         
         TODO OpenAI

         - Détection fraude

         - Réservation suspecte

         - Faux paiement

         - Multi-comptes

         - Score de confiance

         - Résumé automatique

         - Proposition remboursement

         - Proposition bannissement

         */

    }

    // MARK: - EXPORT

    func exportBookingsCSV() {

        print("📄 Export CSV")

        // TODO

    }

    func exportBookingsPDF() {

        print("📑 Export PDF")

        // TODO

    }

    // MARK: - NOTIFICATIONS

    func notifyCustomer(
        booking: AdminBookingItem
    ) {

        print("📩 Notification client")

        // TODO

    }

    func notifyBarber(
        booking: AdminBookingItem
    ) {

        print("💈 Notification coiffeur")

        // TODO

    }

}
