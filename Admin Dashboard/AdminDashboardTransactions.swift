//
//  AdminDashboardTransactions.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI
import FirebaseFirestore
import Charts

struct AdminTransactionStatistics {

    var totalRevenue: Double = 0

    var totalWithdrawals: Double = 0

    var totalRefunds: Double = 0

    var totalCommission: Double = 0

    var liveRevenue: Double = 0

    var bookingRevenue: Double = 0

    var marketplaceRevenue: Double = 0

    var adsRevenue: Double = 0

}
struct AdminRevenueSlice: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
    let color: Color
}

enum TransactionPeriod: String, CaseIterable, Identifiable {

    case today = "Aujourd'hui"

    case week = "7 jours"

    case month = "30 jours"

    case year = "Cette année"

    case custom = "Personnalisé"

    var id: String { rawValue }

}

enum TransactionCategory: String, CaseIterable, Identifiable {

    case all = "Toutes"

    case booking = "Réservations"

    case live = "Lives"

    case marketplace = "Marketplace"

    case ads = "Publicités"

    case withdraw = "Retraits"

    case refund = "Remboursements"

    var id: String { rawValue }

}

struct AdminDashboardTransactions: View {

    @State private var statistics = AdminTransactionStatistics()

    @State private var selectedPeriod: TransactionPeriod = .today

    @State private var selectedCategory: TransactionCategory = .all
    @State private var transactions: [AdminTransactionItem] = []

    @State private var search = ""

    @State private var startDate = Date()

    @State private var endDate = Date()

    @State private var loading = true

    var revenueSlices: [AdminRevenueSlice] {
        [
            AdminRevenueSlice(title: "Lives", value: statistics.liveRevenue, color: .red),
            AdminRevenueSlice(title: "Réservations", value: statistics.bookingRevenue, color: .green),
            AdminRevenueSlice(title: "Marketplace", value: statistics.marketplaceRevenue, color: .blue),
            AdminRevenueSlice(title: "Publicités", value: statistics.adsRevenue, color: .orange)
        ]
    }

    var hasRevenueData: Bool {
        revenueSlices.reduce(0) { $0 + $1.value } > 0
    }
    
    
    private let db = Firestore.firestore()

    var body: some View {

        ScrollView {

            VStack(spacing:24){

                premiumHeader

                filterBar

                statisticsCards

                transactionsList

            }

            .padding()

        }

        .background(Color(
            red:0.96,
            green:0.97,
            blue:1
        ))

        .navigationTitle("Transactions")

        .navigationBarTitleDisplayMode(.inline)

        .task {

            await loadTransactions()

        }

    }

}
extension AdminDashboardTransactions {

    // MARK: - HEADER PREMIUM

    var premiumHeader: some View {

        VStack(alignment: .leading, spacing: 20) {

            HStack {

                VStack(alignment: .leading, spacing: 6) {

                    Text("Centre financier Cutly")
                        .font(.system(size: 30, weight: .bold))

                    Text("Toutes les transactions de la plateforme")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))

                }

                Spacer()

                Button {

                    Task {

                        await loadTransactions()

                    }

                } label: {

                    Label("Actualiser", systemImage: "arrow.clockwise.circle.fill")

                }
                .buttonStyle(.borderedProminent)

            }

            HStack(spacing:16){

                TextField("Rechercher une transaction...", text: $search)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(14)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
                    .cornerRadius(16)

                Button {

                    exportTransactionsCSV()

                } label: {

                    Image(systemName: "square.and.arrow.up")

                }
                .buttonStyle(.bordered)

            }

        }

    }

    // MARK: - FILTRES

    var filterBar: some View {

        VStack(spacing:18){

            ScrollView(.horizontal, showsIndicators: false){

                HStack{

                    ForEach(TransactionPeriod.allCases){ period in

                        Button{

                            selectedPeriod = period

                            Task{

                                await loadTransactions()

                            }

                        }label:{

                            Text(period.rawValue)
                                .font(.subheadline.bold())
                                .padding(.horizontal,18)
                                .padding(.vertical,10)
                                .background(
                                    selectedPeriod == period
                                    ? Color.purple
                                    : Color.white
                                )
                                .foregroundStyle(
                                    selectedPeriod == period
                                    ? .white
                                    : .primary
                                )
                                .clipShape(Capsule())

                        }

                    }

                }

            }

            Picker(
                "Catégorie",
                selection: $selectedCategory
            ){

                ForEach(TransactionCategory.allCases){

                    Text($0.rawValue)
                        .tag($0)

                }

            }
            .pickerStyle(.segmented)

        }

    }

}
extension AdminDashboardTransactions {

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

                transactionCard(
                    title: "Revenus",
                    value: formatEUR(statistics.totalRevenue),
                    subtitle: "Plateforme",
                    icon: "eurosign.circle.fill",
                    color: .green
                )

                transactionCard(
                    title: "Commissions",
                    value: formatEUR(statistics.totalCommission),
                    subtitle: "Cutly",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )

                transactionCard(
                    title: "Retraits",
                    value: formatEUR(statistics.totalWithdrawals),
                    subtitle: "Toutes banques",
                    icon: "banknote.fill",
                    color: .blue
                )

                transactionCard(
                    title: "Remboursements",
                    value: formatEUR(statistics.totalRefunds),
                    subtitle: "Clients",
                    icon: "arrow.uturn.backward.circle.fill",
                    color: .orange
                )

                transactionCard(
                    title: "Lives",
                    value: formatEUR(statistics.liveRevenue),
                    subtitle: "Cadeaux",
                    icon: "video.fill",
                    color: .red
                )

                transactionCard(
                    title: "Réservations",
                    value: formatEUR(statistics.bookingRevenue),
                    subtitle: "Services",
                    icon: "calendar",
                    color: .mint
                )

                transactionCard(
                    title: "Marketplace",
                    value: formatEUR(statistics.marketplaceRevenue),
                    subtitle: "Boutique",
                    icon: "bag.fill",
                    color: .indigo
                )

                transactionCard(
                    title: "Publicités",
                    value: formatEUR(statistics.adsRevenue),
                    subtitle: "Ads",
                    icon: "megaphone.fill",
                    color: .pink
                )

            }

            AdminSectionBox(title: "Répartition des revenus", icon: "chart.pie.fill") {

                if hasRevenueData {

                    Chart(revenueSlices) { item in
                        SectorMark(
                            angle: .value(item.title, item.value),
                            innerRadius: .ratio(0.58),
                            angularInset: 2
                        )
                        .foregroundStyle(item.color)
                    }
                    .frame(height: 260)

                    VStack(spacing: 10) {
                        ForEach(revenueSlices) { item in
                            HStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 12, height: 12)

                                Text(item.title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)

                                Spacer()

                                Text(formatEUR(item.value))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black.opacity(0.82))
                            }
                        }
                    }

                } else {

                    VStack(spacing: 16) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.purple)

                        Text("Aucune donnée financière pour cette période")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)

                        Text("Les revenus Lives, Réservations, Marketplace et Publicités apparaîtront ici automatiquement dès que Firestore recevra des transactions.")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black.opacity(0.82))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 45)
                }
            }

        }

    }

    // MARK: - CARTE PREMIUM

    func transactionCard(
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
    func formatEUR(_ value:Double)->String{

        String(format:"%.2f €",value)

    }

}
extension AdminDashboardTransactions {

    // MARK: - LISTE DES TRANSACTIONS

    var transactionsList: some View {

        VStack(alignment: .leading, spacing: 20) {

            HStack {

                Text("Transactions")
                    .font(.title2.bold())

                Spacer()

                Text("Temps réel")
                    .font(.caption.bold())
                    .padding(.horizontal,10)
                    .padding(.vertical,5)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .clipShape(Capsule())

            }

            if loading {

                ProgressView()
                    .padding(.vertical,60)
                    .frame(maxWidth:.infinity)

            } else {

                LazyVStack(spacing:18){

                    ForEach(filteredTransactions){ transaction in

                        transactionRow(transaction)

                    }

                }

            }

        }

    }

    // MARK: - CELLULE PREMIUM

    @ViewBuilder
    func transactionRow(
        _ transaction: AdminTransactionItem
    ) -> some View {

        VStack(alignment:.leading,spacing:18){

            HStack{

                VStack(alignment:.leading,spacing:5){

                    Text(transaction.title)
                        .font(.headline)
                    Text(transaction.id)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black.opacity(0.78))

                }

                Spacer()

                transactionStatusBadge(transaction.status)

            }

            Divider()

            HStack{

                transactionInfo(
                    title:"Montant",
                    value:formatEUR(transaction.amount),
                    icon:"eurosign.circle.fill"
                )

                Spacer()

                transactionInfo(
                    title:"Commission",
                    value:formatEUR(transaction.commission),
                    icon:"chart.line.uptrend.xyaxis"
                )

                Spacer()

                transactionInfo(
                    title:"Type",
                    value:transaction.category,
                    icon:"square.stack.3d.up.fill"
                )

            }

            Divider()

            HStack(spacing:12){

                Button{

                    openTransaction(transaction)

                }label:{

                    Label("Voir",systemImage:"eye.fill")

                }
                .buttonStyle(.borderedProminent)

                Button{

                    refundTransaction(transaction)

                }label:{

                    Label("Rembourser",systemImage:"arrow.uturn.backward.circle")

                }
                .buttonStyle(.bordered)

                Button{

                    exportTransaction(transaction)

                }label:{

                    Label("Exporter",systemImage:"square.and.arrow.up")

                }
                .buttonStyle(.bordered)

            }

        }
        .padding(22)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:24)
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:10
        )

    }

    // MARK: - BADGE

    func transactionStatusBadge(
        _ status: String
    ) -> some View {

        Text(status.isEmpty ? "pending" : status)
            .font(.system(size: 14, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(transactionStatusColor(status).opacity(0.20))
            .foregroundColor(transactionStatusColor(status))
            .clipShape(Capsule())
    }

    // MARK: - INFO

    func transactionInfo(
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
extension AdminDashboardTransactions {

    // MARK: - DONNÉES

    

    var filteredTransactions: [AdminTransactionItem] {
        transactions.filter { item in

            let matchesSearch =
            search.isEmpty ||
            item.title.localizedCaseInsensitiveContains(search) ||
            item.id.localizedCaseInsensitiveContains(search) ||
            item.category.localizedCaseInsensitiveContains(search) ||
            item.senderName.localizedCaseInsensitiveContains(search)

            let matchesCategory =
            selectedCategory == .all ||
            item.category == selectedCategory.rawValue

            return matchesSearch && matchesCategory
        }
    }

    // MARK: - CHARGEMENT
    @MainActor
    func loadTransactions() async {
        loading = true

        defer {
            loading = false
        }

        do {
            var loaded: [AdminTransactionItem] = []

            var revenue: Double = 0
            var commission: Double = 0
            var withdrawals: Double = 0
            var refunds: Double = 0

            var live: Double = 0
            var bookingsTotal: Double = 0
            var marketplace: Double = 0
            var ads: Double = 0

            let now = Date()
            let calendar = Calendar.current

            let start: Date = {
                switch selectedPeriod {
                case .today:
                    return calendar.startOfDay(for: now)
                case .week:
                    return calendar.date(byAdding: .day, value: -7, to: now) ?? now
                case .month:
                    return calendar.date(byAdding: .day, value: -30, to: now) ?? now
                case .year:
                    return calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
                case .custom:
                    return calendar.startOfDay(for: startDate)
                }
            }()

            let end: Date = {
                if selectedPeriod == .custom {
                    return endDate
                }
                return now
            }()

            func isInPeriod(_ date: Date) -> Bool {
                date >= start && date <= end
            }

            // MARK: - Cadeaux Lives
            let giftsSnapshot = try await db.collection("giftTransactions").getDocuments()

            for doc in giftsSnapshot.documents {
                let data = doc.data()
                let date = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                guard isInPeriod(date) else { continue }

                let coins = data["platformCoins"] as? Int ?? 0
                let amount = Double(coins) * 0.10
                let itemCommission = data["platformCommissionEUR"] as? Double ?? 0

                let item = AdminTransactionItem(
                    id: doc.documentID,
                    title: data["giftName"] as? String ?? "Cadeau Live",
                    senderName: data["senderName"] as? String ?? "Utilisateur",
                    category: "Lives",
                    amount: amount,
                    commission: itemCommission,
                    status: data["status"] as? String ?? "completed",
                    date: date
                )

                loaded.append(item)
                revenue += amount
                live += amount
                commission += itemCommission
            }

            // MARK: - Réservations
            let bookingsSnapshot = try await db.collection("bookings").getDocuments()

            for doc in bookingsSnapshot.documents {
                let data = doc.data()
                let date = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                guard isInPeriod(date) else { continue }

                let amount = data["amount"] as? Double
                    ?? data["totalPrice"] as? Double
                    ?? data["price"] as? Double
                    ?? 0

                let itemCommission = data["platformCommission"] as? Double
                    ?? data["commission"] as? Double
                    ?? amount * 0.15

                let item = AdminTransactionItem(
                    id: doc.documentID,
                    title: "Réservation",
                    senderName: data["clientName"] as? String ?? "Client",
                    category: "Réservations",
                    amount: amount,
                    commission: itemCommission,
                    status: data["paymentStatus"] as? String ?? data["status"] as? String ?? "pending",
                    date: date
                )

                loaded.append(item)
                revenue += amount
                bookingsTotal += amount
                commission += itemCommission
            }

            // MARK: - Marketplace / Commandes
            let ordersSnapshot = try await db.collection("orders").getDocuments()

            for doc in ordersSnapshot.documents {
                let data = doc.data()
                let date = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                guard isInPeriod(date) else { continue }

                let amount = data["total"] as? Double
                    ?? data["amount"] as? Double
                    ?? 0

                let itemCommission = data["platformCommission"] as? Double ?? 0

                let item = AdminTransactionItem(
                    id: doc.documentID,
                    title: "Commande Marketplace",
                    senderName: data["buyerName"] as? String ?? "Acheteur",
                    category: "Marketplace",
                    amount: amount,
                    commission: itemCommission,
                    status: data["status"] as? String ?? "pending",
                    date: date
                )

                loaded.append(item)
                revenue += amount
                marketplace += amount
                commission += itemCommission
            }

            // MARK: - Publicités
            let adsSnapshot = try await db.collection("adRevenue").getDocuments()

            for doc in adsSnapshot.documents {
                let data = doc.data()
                let date = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                guard isInPeriod(date) else { continue }

                let amount = data["amountEUR"] as? Double ?? 0

                let item = AdminTransactionItem(
                    id: doc.documentID,
                    title: "Revenu publicitaire",
                    senderName: "Cutly Ads",
                    category: "Publicités",
                    amount: amount,
                    commission: amount,
                    status: data["status"] as? String ?? "completed",
                    date: date
                )

                loaded.append(item)
                revenue += amount
                ads += amount
                commission += amount
            }

            // MARK: - Retraits
            let withdrawalsSnapshot = try await db.collection("platformWithdrawRequests").getDocuments()

            for doc in withdrawalsSnapshot.documents {
                let data = doc.data()
                let date = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                guard isInPeriod(date) else { continue }

                let amount = data["amountEUR"] as? Double ?? 0

                let item = AdminTransactionItem(
                    id: doc.documentID,
                    title: "Retrait plateforme",
                    senderName: data["adminId"] as? String ?? "Admin",
                    category: "Retraits",
                    amount: amount,
                    commission: 0,
                    status: data["status"] as? String ?? "pending",
                    date: date
                )

                loaded.append(item)
                withdrawals += amount
            }

            // MARK: - Remboursements
            let refundsSnapshot = try await db.collection("refunds").getDocuments()

            for doc in refundsSnapshot.documents {
                let data = doc.data()
                let date = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                guard isInPeriod(date) else { continue }

                let amount = data["amountEUR"] as? Double
                    ?? data["amount"] as? Double
                    ?? 0

                let item = AdminTransactionItem(
                    id: doc.documentID,
                    title: "Remboursement",
                    senderName: data["userName"] as? String ?? "Utilisateur",
                    category: "Remboursements",
                    amount: amount,
                    commission: 0,
                    status: data["status"] as? String ?? "completed",
                    date: date
                )

                loaded.append(item)
                refunds += amount
            }

            loaded.sort { $0.date > $1.date }

            withAnimation(.easeInOut(duration: 0.25)) {
                transactions = loaded

                statistics.totalRevenue = revenue
                statistics.totalCommission = commission
                statistics.totalWithdrawals = withdrawals
                statistics.totalRefunds = refunds
                statistics.liveRevenue = live
                statistics.bookingRevenue = bookingsTotal
                statistics.marketplaceRevenue = marketplace
                statistics.adsRevenue = ads
            }

        } catch {
            print("❌ Erreur transactions globales :", error.localizedDescription)
        }
    }

    // MARK: - ACTIONS

    func openTransaction(
        _ transaction: AdminTransactionItem
    ) {

        print("👁️ Transaction :", transaction.id)

    }

    func refundTransaction(
        _ transaction: AdminTransactionItem
    ) {

        print("💸 Remboursement :", transaction.id)

        // TODO
        // Stripe Refund
        // CinetPay Refund
        // Wallet Refund

    }

    func exportTransaction(
        _ transaction: AdminTransactionItem
    ) {

        print("📤 Export :", transaction.id)

    }

    func exportTransactionsCSV() {

        print("📄 Export CSV")

    }

}


// MARK: - COULEURS DES STATUTS

extension AdminDashboardTransactions {

    func transactionStatusColor(_ status: String) -> Color {

        switch status.lowercased() {

        case "completed",
             "success",
             "paid",
             "released":
            return .green

        case "pending":
            return .orange

        case "processing":
            return .blue

        case "cancelled",
             "canceled":
            return .gray

        case "failed":
            return .red

        case "refunded":
            return .purple

        default:
            return .secondary

        }

    }

}

// MARK: - FORMAT DATE

extension AdminDashboardTransactions {

    func formatDate(_ date: Date) -> String {

        let formatter = DateFormatter()

        formatter.locale = Locale(identifier: "fr_FR")

        formatter.dateStyle = .medium

        formatter.timeStyle = .short

        return formatter.string(from: date)

    }

}

// MARK: - IA CUTLY (PRÉPARATION)

extension AdminDashboardTransactions {

    func analyseTransactionsIA() {

        /*
         =====================================================

         IA CUTLY

         Cette partie sera reliée plus tard à OpenAI.

         L'IA pourra automatiquement :

         • détecter les fraudes
         • détecter les faux paiements
         • détecter les remboursements suspects
         • détecter les créateurs suspects
         • détecter le blanchiment
         • proposer des actions
         • générer des rapports
         • répondre au support automatiquement
         • classer les litiges
         • générer les statistiques
         • assister les administrateurs

         =====================================================
         */

        print("🤖 Analyse IA des transactions")

    }

}

// MARK: - FIN DU MODULE
