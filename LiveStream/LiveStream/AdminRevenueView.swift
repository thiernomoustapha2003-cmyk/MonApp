import SwiftUI
import FirebaseFirestore
import Charts

struct AdminRevenuePoint: Identifiable {
    let id = UUID()
    let date: Date
    let coins: Int
}

struct AdminRevenueTransaction: Identifiable {
    let id: String
    let giftName: String
    let senderName: String
    let creatorId: String
    let platformCoins: Int
    let totalCoins: Int
    let date: Date
}

enum AdminRevenueRange: String, CaseIterable, Identifiable {
    case today = "Aujourd’hui"
    case sevenDays = "7J"
    case thirtyDays = "30J"
    case threeMonths = "3M"
    case oneYear = "1A"
    case all = "Tout"
    var id: String { rawValue }
}

struct AdminRevenueView: View {

    @State private var selectedRange: AdminRevenueRange = .sevenDays
    @State private var points: [AdminRevenuePoint] = []
    @State private var transactions: [AdminRevenueTransaction] = []

    @State private var totalPlatformCoins = 0
    @State private var totalVolumeCoins = 0
    @State private var giftsCount = 0
    @State private var selectedWithdrawAmount = ""
    @State private var showWithdrawPanel = false
    @State private var isLoading = false
    
    @State private var liveRevenueEUR: Double = 0
    @State private var bookingRevenueEUR: Double = 0
    @State private var adsRevenueEUR: Double = 0
    @State private var marketplaceRevenueEUR: Double = 0

    var totalRevenueEUR: Double {
        liveRevenueEUR + bookingRevenueEUR + adsRevenueEUR + marketplaceRevenueEUR
    }

    private let db = Firestore.firestore()
    private let coinValueEUR: Double = 0.10

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                globalRevenueSummary
                rangePicker
                chartSection
                incomeGrid
                futureModulesSection
                lastTransactionsSection
                withdrawSection
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Revenus Cutly")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPlatformWallet()
            loadRevenue()
            loadBookingRevenue()
        }
        .onChange(of: selectedRange) { _ in
            loadRevenue()
            loadBookingRevenue()
        }
    }
}

extension AdminRevenueView {

    var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Solde plateforme")
                .foregroundColor(.white.opacity(0.65))

            Text(formatEUR(Double(totalPlatformCoins) * coinValueEUR))
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.green)

            HStack {
                Text("\(totalPlatformCoins) coins")
                Spacer()
                Text("Volume: \(totalVolumeCoins) coins")
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.65))

            Button {
                showWithdrawPanel.toggle()
            } label: {
                Text("Retirer mon argent")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(16)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.12), Color.green.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(26)
    }

    var globalRevenueSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Résumé global plateforme")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                dashboardCard("🎁 Lives", formatEUR(liveRevenueEUR), "cadeaux live")
                dashboardCard("💈 Réservations", formatEUR(bookingRevenueEUR), "commissions services")
                dashboardCard("📢 Publicités", formatEUR(adsRevenueEUR), "prévu")
                dashboardCard("🛍 Marketplace", formatEUR(marketplaceRevenueEUR), "Cutly Shop")
            }

            HStack {
                Text("Total plateforme")
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text(formatEUR(totalRevenueEUR))
                    .foregroundColor(.green)
                    .font(.title3.bold())
            }
            .padding()
            .background(Color.green.opacity(0.14))
            .cornerRadius(18)
        }
    }
    
    func loadBookingRevenue() {
        
        var query: Query = db.collection("bookings")
            .order(by: "createdAt", descending: false)
        
        if let startDate = startDateForRange() {
            query = query.whereField(
                "createdAt",
                isGreaterThanOrEqualTo: Timestamp(date: startDate)
            )
        }
        
        query.getDocuments { snapshot, error in
            
            if let error = error {
                print("❌ Booking revenue error:", error.localizedDescription)
                return
            }
            
            var totalCommissionEUR: Double = 0
            
            snapshot?.documents.forEach { doc in
                
                let data = doc.data()
                
                let status = data["status"] as? String ?? ""
                let paymentStatus = data["paymentStatus"] as? String ?? ""
                let escrowStatus = data["escrowStatus"] as? String ?? ""
                
                let isValidPaidBooking =
                    paymentStatus == "paid" ||
                    escrowStatus == "released" ||
                    status == "completed" ||
                    status == "confirmed"

                guard isValidPaidBooking else {
                    return
                }
                
                let commission = data["platformCommission"] as? Double ?? 0
                
                totalCommissionEUR += commission
            }
            
            DispatchQueue.main.async {
                self.bookingRevenueEUR = totalCommissionEUR
            }
        }
    }
    
    
    
    var rangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(AdminRevenueRange.allCases) { range in
                    Button {
                        selectedRange = range
                    } label: {
                        Text(range.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(selectedRange == range ? .black : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(selectedRange == range ? Color.yellow : Color.white.opacity(0.12))
                            .cornerRadius(20)
                    }
                }
            }
        }
    }

    var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Évolution des revenus")
                .font(.headline)
                .foregroundColor(.white)

            if points.isEmpty {
                Text("Aucune donnée pour cette période")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, minHeight: 230)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(22)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Coins", point.coins)
                    )

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Coins", point.coins)
                    )
                    .opacity(0.25)
                }
                .frame(height: 250)
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(22)
            }
        }
    }

    var incomeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            dashboardCard("🎁 Cadeaux live", "\(giftsCount)", "transactions")
            dashboardCard("👑 Commission", "\(totalPlatformCoins)", "coins")
            dashboardCard("💈 Réservations", "Actif", "commissions services")
            dashboardCard("📢 Publicités", "Bientôt", "ads live")
        }
    }

    var futureModulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Modules revenus futurs")
                .foregroundColor(.white)
                .font(.headline)

            futureRow("🛍 Cutly Shop", "Marketplace vendeurs / commandes / livraison")
            futureRow("🚚 Livraison", "Guinée, Sénégal, Mali, Côte d’Ivoire…")
            futureRow("⭐ Premium", "Abonnements créateurs et boosts")
            futureRow("📺 Ads Live", "Publicités avant et pendant les lives")
        }
    }

    var lastTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dernières transactions")
                .foregroundColor(.white)
                .font(.headline)

            if transactions.isEmpty {
                Text("Aucune transaction récente")
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(18)
            } else {
                ForEach(transactions.prefix(10)) { tx in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tx.giftName)
                                .foregroundColor(.white)
                                .bold()

                            Text(tx.senderName)
                                .foregroundColor(.white.opacity(0.55))
                                .font(.caption)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(formatEUR(Double(tx.platformCoins) * coinValueEUR))
                                .foregroundColor(.green)
                                .bold()

                            Text("\(tx.platformCoins) coins")
                                .foregroundColor(.white.opacity(0.55))
                                .font(.caption2)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                }
            }
        }
    }

    var withdrawSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Retrait plateforme")
                .foregroundColor(.white)
                .font(.headline)

            if showWithdrawPanel {
                TextField("Montant à retirer en €", text: $selectedWithdrawAmount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(14)
                    .foregroundColor(.white)

                Button {
                    print("🏦 Demande retrait plateforme:", selectedWithdrawAmount)
                } label: {
                    Text("Créer une demande de retrait")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                }

                Text("Le vrai retrait sera connecté plus tard à Stripe, banque, Orange Money, Wave ou CinetPay.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(22)
    }

    func dashboardCard(_ title: String, _ value: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.white.opacity(0.7))
                .font(.caption)

            Text(value)
                .foregroundColor(.white)
                .font(.title3.bold())

            Text(subtitle)
                .foregroundColor(.white.opacity(0.45))
                .font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.07))
        .cornerRadius(18)
    }

    func futureRow(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundColor(.white)
                .bold()

            Text(subtitle)
                .foregroundColor(.white.opacity(0.55))
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }
}

extension AdminRevenueView {

    func loadPlatformWallet() {
        db.collection("platformStats")
            .document("wallet")
            .getDocument { snapshot, _ in
                let data = snapshot?.data() ?? [:]

                DispatchQueue.main.async {
                    self.totalPlatformCoins = data["giftCommissionCoins"] as? Int ?? 0
                    self.totalVolumeCoins = data["totalGiftVolumeCoins"] as? Int ?? 0
                }
            }
    }

    func loadRevenue() {
        isLoading = true

        var query: Query = db.collection("giftTransactions")
            .order(by: "createdAt", descending: false)

        if let startDate = startDateForRange() {
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startDate))
        }

        query.getDocuments { snapshot, error in
            if let error = error {
                print("❌ AdminRevenue error:", error.localizedDescription)
                isLoading = false
                return
            }

            var grouped: [Date: Int] = [:]
            var txs: [AdminRevenueTransaction] = []
            var platformTotal = 0
            var volumeTotal = 0
            var count = 0

            snapshot?.documents.forEach { doc in
                let data = doc.data()

                let platformCoins = data["platformCoins"] as? Int ?? 0
                let totalCoins = data["totalCoins"] as? Int ?? 0
                let giftName = data["giftName"] as? String ?? "Cadeau"
                let senderName = data["senderName"] as? String ?? "Utilisateur"
                let creatorId = data["creatorId"] as? String ?? ""
                let timestamp = data["createdAt"] as? Timestamp
                let date = timestamp?.dateValue() ?? Date()

                let day = Calendar.current.startOfDay(for: date)
                grouped[day, default: 0] += platformCoins

                platformTotal += platformCoins
                volumeTotal += totalCoins
                count += 1

                txs.append(
                    AdminRevenueTransaction(
                        id: doc.documentID,
                        giftName: giftName,
                        senderName: senderName,
                        creatorId: creatorId,
                        platformCoins: platformCoins,
                        totalCoins: totalCoins,
                        date: date
                    )
                )
            }

            DispatchQueue.main.async {
                self.points = grouped
                    .map { AdminRevenuePoint(date: $0.key, coins: $0.value) }
                    .sorted { $0.date < $1.date }

                self.transactions = txs.sorted { $0.date > $1.date }
                self.totalPlatformCoins = platformTotal
                self.totalVolumeCoins = volumeTotal
                self.giftsCount = count
                self.isLoading = false
                self.liveRevenueEUR = Double(platformTotal) * coinValueEUR
            }
        }
    }

    func startDateForRange() -> Date? {
        let calendar = Calendar.current
        let now = Date()

        switch selectedRange {
        case .today:
            return calendar.startOfDay(for: now)
        case .sevenDays:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .thirtyDays:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now)
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .all:
            return nil
        }
    }

    func formatEUR(_ value: Double) -> String {
        String(format: "%.2f €", value)
    }
}
