//
//  AdminDashboardAnalytics.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI
import FirebaseFirestore
import Charts

struct AdminAnalyticsPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

enum AdminAnalyticsPeriod: String, CaseIterable, Identifiable {

    case today = "Aujourd'hui"
    case week = "7 jours"
    case month = "30 jours"
    case year = "Cette année"
    case custom = "Personnalisé"

    var id: String { rawValue }

}

enum AdminAnalyticsSection: String, CaseIterable, Identifiable {

    case overview = "Vue générale"
    case users = "Utilisateurs"
    case revenue = "Revenus"
    case lives = "Lives"
    case bookings = "Réservations"
    case marketplace = "Marketplace"

    var id: String { rawValue }

}

struct AdminDashboardAnalytics: View {

    @State private var selectedSection: AdminAnalyticsSection = .overview
    
    @State private var selectedPeriod: AdminAnalyticsPeriod = .week
    
    @State private var points: [AdminAnalyticsPoint] = []

    @State private var startDate = Date()

    @State private var endDate = Date()

    @State private var loading = true

    

    @State private var totalUsers = 0

    @State private var activeUsers = 0

    @State private var newUsers = 0

    @State private var totalRevenue: Double = 0

    @State private var liveRevenue: Double = 0

    @State private var bookingRevenue: Double = 0

    @State private var marketplaceRevenue: Double = 0

    @State private var adsRevenue: Double = 0

    private let db = Firestore.firestore()

    var body: some View {

        ScrollView {

            VStack(spacing:24){

                premiumHeader

                sectionPicker

                periodPicker

                analyticsOverview

            }
            .padding()

        }
        .background(
            Color(
                red:0.96,
                green:0.97,
                blue:1
            )
        )
        .navigationTitle("Analytics")

        .navigationBarTitleDisplayMode(.inline)

        .task {

            await loadAnalytics()

        }

    }

}
extension AdminDashboardAnalytics {

    // MARK: - HEADER PREMIUM

    var premiumHeader: some View {
        AdminSectionBox(title: "Centre Analytics", icon: "chart.bar.xaxis") {
            VStack(alignment: .leading, spacing: 18) {
                Text("Analyse complète de toute la plateforme Cutly")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AdminTheme.readableText)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 18
                ) {
                    analyticsCard(title: "Utilisateurs", value: "\(totalUsers)", subtitle: "Inscrits", icon: "person.3.fill", color: .blue)
                    analyticsCard(title: "Actifs", value: "\(activeUsers)", subtitle: "Aujourd'hui", icon: "bolt.fill", color: .green)
                    analyticsCard(title: "Nouveaux", value: "\(newUsers)", subtitle: "Période", icon: "person.badge.plus.fill", color: .orange)
                    analyticsCard(title: "Revenus", value: formatEUR(totalRevenue), subtitle: "Plateforme", icon: "eurosign.circle.fill", color: .purple)
                }

                Button {
                    Task { await loadAnalytics() }
                } label: {
                    Label("Actualiser les analytics", systemImage: "arrow.clockwise.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
    }

    // MARK: - FILTRE SECTION

    var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(AdminAnalyticsSection.allCases) { section in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            selectedSection = section
                        }
                    } label: {
                        Text(section.rawValue)
                            .font(.system(size: 15, weight: .bold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(selectedSection == section ? Color.purple : Color.white)
                            .foregroundColor(selectedSection == section ? .white : .black)
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(selectedSection == section ? 0 : 0.10), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - FILTRE PÉRIODE

    var periodPicker: some View {
        AdminSectionBox(title: "Période d’analyse", icon: "calendar") {
            VStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AdminAnalyticsPeriod.allCases) { period in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedPeriod = period
                                }
                                Task { await loadAnalytics() }
                            } label: {
                                Text(period.rawValue)
                                    .font(.system(size: 15, weight: .bold))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 11)
                                    .background(selectedPeriod == period ? Color.blue : Color.white)
                                    .foregroundColor(selectedPeriod == period ? .white : .black)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.black.opacity(selectedPeriod == period ? 0 : 0.10), lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack {
                    DatePicker("Début", selection: $startDate, displayedComponents: .date)
                        .font(.system(size: 15, weight: .semibold))

                    DatePicker("Fin", selection: $endDate, displayedComponents: .date)
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.black)
            }
        }
    }

}
extension AdminDashboardAnalytics {

    // MARK: - ANALYTICS OVERVIEW

    var analyticsOverview: some View {

        VStack(spacing:24){

            usersChart

            revenueChart

            revenueCards

        }

    }

    // MARK: - COURBE UTILISATEURS

    var usersChart: some View {

        VStack(alignment:.leading,spacing:18){

            HStack{

                Label(
                    "Évolution des utilisateurs",
                    systemImage:"person.3.fill"
                )
                .font(.title3.bold())

                Spacer()

            }

            if points.isEmpty{

                ProgressView()
                    .frame(maxWidth:.infinity,minHeight:250)

            }else{

                Chart(points){ point in

                    LineMark(

                        x:.value(
                            "Date",
                            point.date
                        ),

                        y:.value(
                            "Utilisateurs",
                            point.value
                        )

                    )
                    .interpolationMethod(.catmullRom)

                    AreaMark(

                        x:.value(
                            "Date",
                            point.date
                        ),

                        y:.value(
                            "Utilisateurs",
                            point.value
                        )

                    )
                    .foregroundStyle(
                        Color.blue.opacity(0.22)
                    )

                }
                .frame(height:260)
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                            .foregroundStyle(Color.black)
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                            .foregroundStyle(Color.black)
                            .font(.system(size: 12, weight: .bold))
                    }
                }

            }

        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius:28
            )
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:10
        )

    }

    // MARK: - COURBE REVENUS

    var revenueChart: some View {

        VStack(alignment:.leading,spacing:18){

            HStack{

                Label(
                    "Évolution des revenus",
                    systemImage:"chart.line.uptrend.xyaxis"
                )
                .font(.title3.bold())

                Spacer()

            }

            Chart{

                BarMark(

                    x:.value(
                        "Lives",
                        "Lives"
                    ),

                    y:.value(
                        "Montant",
                        liveRevenue
                    )

                )
                .foregroundStyle(.red)

                BarMark(

                    x:.value(
                        "Réservations",
                        "Réservations"
                    ),

                    y:.value(
                        "Montant",
                        bookingRevenue
                    )

                )
                .foregroundStyle(.green)

                BarMark(

                    x:.value(
                        "Marketplace",
                        "Marketplace"
                    ),

                    y:.value(
                        "Montant",
                        marketplaceRevenue
                    )

                )
                .foregroundStyle(.blue)

                BarMark(

                    x:.value(
                        "Publicités",
                        "Publicités"
                    ),

                    y:.value(
                        "Montant",
                        adsRevenue
                    )

                )
                .foregroundStyle(.orange)

            }
            .frame(height:250)
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                        .foregroundStyle(Color.black)
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                        .foregroundStyle(Color.black)
                        .font(.system(size: 12, weight: .bold))
                }
            }

        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius:28
            )
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:10
        )

    }

    // MARK: - CARTES REVENUS

    var revenueCards: some View {

        LazyVGrid(

            columns:[
                GridItem(.flexible()),
                GridItem(.flexible())
            ],

            spacing:18

        ){

            analyticsCard(

                title:"Lives",

                value:formatEUR(liveRevenue),

                subtitle:"Cadeaux",

                icon:"video.fill",

                color:.red

            )

            analyticsCard(

                title:"Réservations",

                value:formatEUR(bookingRevenue),

                subtitle:"Services",

                icon:"calendar",

                color:.green

            )

            analyticsCard(

                title:"Marketplace",

                value:formatEUR(marketplaceRevenue),

                subtitle:"Boutique",

                icon:"bag.fill",

                color:.blue

            )

            analyticsCard(

                title:"Publicités",

                value:formatEUR(adsRevenue),

                subtitle:"Ads",

                icon:"megaphone.fill",

                color:.orange

            )

        }

    }

}
extension AdminDashboardAnalytics {

    // MARK: - GÉOGRAPHIE

    var geographySection: some View {

        VStack(spacing:22){

            HStack{

                Label(
                    "Répartition mondiale",
                    systemImage: "globe.europe.africa.fill"
                )
                .font(.title3.bold())

                Spacer()

            }

            worldCard

            devicesCard

            languageCard

        }

    }

    // MARK: - CARTE MONDE

    var worldCard: some View {

        VStack(alignment:.leading,spacing:18){

            HStack{

                Image(systemName:"globe.americas.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Utilisateurs par pays")
                    .font(.headline)

                Spacer()

            }

            RoundedRectangle(cornerRadius:22)

                .fill(
                    LinearGradient(
                        colors:[
                            Color.blue.opacity(0.18),
                            Color.purple.opacity(0.12)
                        ],
                        startPoint:.topLeading,
                        endPoint:.bottomTrailing
                    )
                )

                .frame(height:260)

                .overlay{

                    VStack(spacing:14){

                        Image(systemName:"map.fill")
                            .font(.system(size:55))
                            .foregroundColor(.blue)

                        Text("Carte mondiale interactive")
                            .font(.headline)

                        Text("Firestore alimentera automatiquement les pays.")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black.opacity(0.82))

                    }

                }

        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:28)
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:10
        )

    }

    // MARK: - APPAREILS

    var devicesCard: some View {

        VStack(alignment:.leading,spacing:18){

            HStack{

                Label(
                    "Appareils",
                    systemImage:"iphone.gen3"
                )
                .font(.headline)

                Spacer()

            }

            LazyVGrid(
                columns:[
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing:18
            ){

                analyticsCard(
                    title:"iPhone",
                    value:"72 %",
                    subtitle:"iOS",
                    icon:"iphone.gen3",
                    color:.blue
                )

                analyticsCard(
                    title:"Android",
                    value:"28 %",
                    subtitle:"Google",
                    icon:"apps.iphone",
                    color:.green
                )

                analyticsCard(
                    title:"iPad",
                    value:"3 %",
                    subtitle:"Tablettes",
                    icon:"ipad",
                    color:.purple
                )

                analyticsCard(
                    title:"Version",
                    value:"v1.0",
                    subtitle:"Application",
                    icon:"shippingbox.fill",
                    color:.orange
                )

            }

        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:28)
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:10
        )

    }

    // MARK: - LANGUES

    var languageCard: some View {

        VStack(alignment:.leading,spacing:18){

            HStack{

                Label(
                    "Langues utilisées",
                    systemImage:"character.book.closed.fill"
                )

                Spacer()

            }

            LazyVGrid(
                columns:[
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing:18
            ){

                analyticsCard(
                    title:"Français",
                    value:"48 %",
                    subtitle:"FR",
                    icon:"f.circle.fill",
                    color:.blue
                )

                analyticsCard(
                    title:"Anglais",
                    value:"22 %",
                    subtitle:"EN",
                    icon:"e.circle.fill",
                    color:.green
                )

                analyticsCard(
                    title:"Espagnol",
                    value:"9 %",
                    subtitle:"ES",
                    icon:"s.circle.fill",
                    color:.orange
                )

                analyticsCard(
                    title:"Turc",
                    value:"6 %",
                    subtitle:"TR",
                    icon:"t.circle.fill",
                    color:.red
                )

            }

        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:28)
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:10
        )

    }

}
extension AdminDashboardAnalytics {

    // MARK: - TEMPS RÉEL

    var realtimeSection: some View {

        VStack(spacing:24){

            realtimeHeader

            realtimeCards

            alertsSection

            aiSection

        }

    }

    // MARK: - HEADER

    var realtimeHeader: some View {

        HStack{

            Label(
                "Temps réel",
                systemImage: "dot.radiowaves.left.and.right"
            )
            .font(.title2.bold())

            Spacer()

            HStack(spacing:8){

                Circle()
                    .fill(.green)
                    .frame(width:10,height:10)

                Text("LIVE")
                    .font(.caption.bold())

            }
            .padding(.horizontal,12)
            .padding(.vertical,7)
            .background(Color.green.opacity(0.15))
            .clipShape(Capsule())

        }

    }

    // MARK: - KPI LIVE

    var realtimeCards: some View {

        LazyVGrid(
            columns:[
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing:18
        ){

            analyticsCard(
                title:"En ligne",
                value:"\(activeUsers)",
                subtitle:"Utilisateurs",
                icon:"person.2.wave.2.fill",
                color:.green
            )

            analyticsCard(
                title:"Lives",
                value:"18",
                subtitle:"En direct",
                icon:"video.badge.waveform.fill",
                color:.red
            )

            analyticsCard(
                title:"Messages",
                value:"12 486",
                subtitle:"Aujourd'hui",
                icon:"message.fill",
                color:.blue
            )

            analyticsCard(
                title:"Appels",
                value:"284",
                subtitle:"Audio / Vidéo",
                icon:"phone.connection.fill",
                color:.orange
            )

            analyticsCard(
                title:"Réservations",
                value:"94",
                subtitle:"Aujourd'hui",
                icon:"calendar.badge.clock",
                color:.mint
            )

            analyticsCard(
                title:"Commandes",
                value:"36",
                subtitle:"Marketplace",
                icon:"shippingbox.fill",
                color:.purple
            )

        }

    }

    // MARK: - ALERTES

    var alertsSection: some View {

        VStack(alignment:.leading,spacing:18){

            Label(
                "Alertes intelligentes",
                systemImage:"bell.badge.fill"
            )
            .font(.title3.bold())

            realtimeAlert(
                color:.green,
                icon:"checkmark.circle.fill",
                title:"Serveurs",
                subtitle:"Tous les services fonctionnent."
            )

            realtimeAlert(
                color:.orange,
                icon:"exclamationmark.triangle.fill",
                title:"Paiements",
                subtitle:"2 paiements nécessitent une vérification."
            )

            realtimeAlert(
                color:.red,
                icon:"shield.lefthalf.filled.badge.exclamationmark",
                title:"Sécurité",
                subtitle:"Une activité inhabituelle a été détectée."
            )

        }
        .padding()
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:28)
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:10
        )

    }

    func realtimeAlert(
        color: Color,
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {

        HStack(spacing: 16) {

            Image(systemName: icon)
                .font(.title2.bold())
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 5) {

                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)

                Text(subtitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black.opacity(0.82))
            }

            Spacer()
        }
        .padding(18)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(18)
    }
    // MARK: - IA CUTLY

    var aiSection: some View {

        VStack(alignment:.leading,spacing:18){

            HStack{

                Image(systemName:"brain.head.profile")
                    .font(.largeTitle)
                    .foregroundStyle(.purple)

                VStack(alignment:.leading){

                    Text("Cutly AI")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)

                    Text("Assistant intelligent pour analytics, sécurité et modération")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))

                }

                Spacer()

            }

            Divider()

            aiFeature("Analyse automatique des signalements")
            aiFeature("Détection des faux comptes")
            aiFeature("Détection des fraudes")
            aiFeature("Analyse des paiements")
            aiFeature("Réponse automatique du support")
            aiFeature("Résumé quotidien de la plateforme")
            aiFeature("Suggestions d'actions administrateur")
            aiFeature("Analyse des performances")
            aiFeature("Surveillance en temps réel")
            aiFeature("Détection des comportements suspects")

        }
        .padding()
        .background(

            LinearGradient(
                colors:[
                    Color.purple.opacity(0.12),
                    Color.blue.opacity(0.08)
                ],
                startPoint:.topLeading,
                endPoint:.bottomTrailing
            )

        )
        .clipShape(
            RoundedRectangle(cornerRadius:28)
        )

    }

    func aiFeature(
        _ title: String
    ) -> some View {

        HStack(spacing: 10) {

            Image(systemName: "sparkles")
                .font(.headline.bold())
                .foregroundStyle(.purple)

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)

            Spacer()
        }
    }

}
// MARK: - CHARGEMENT FIRESTORE

extension AdminDashboardAnalytics {

    @MainActor
    func loadAnalytics() async {

        loading = true

        defer {

            loading = false

        }

        do {

            // Utilisateurs

            let usersSnapshot = try await db
                .collection("users")
                .getDocuments()

            totalUsers = usersSnapshot.documents.count

            activeUsers = usersSnapshot.documents.filter {

                ($0["isOnline"] as? Bool) == true

            }.count

            newUsers = usersSnapshot.documents.filter {

                guard let timestamp = $0["createdAt"] as? Timestamp else {

                    return false

                }

                return Calendar.current.isDate(
                    timestamp.dateValue(),
                    inSameDayAs: Date()
                )

            }.count

            // Transactions

            let transactionsSnapshot = try await db
                .collection("transactions")
                .getDocuments()

            var total = 0.0
            var live = 0.0
            var booking = 0.0
            var marketplace = 0.0
            var ads = 0.0

            for doc in transactionsSnapshot.documents {

                let data = doc.data()

                let amount = data["amount"] as? Double ?? 0

                let category = data["category"] as? String ?? ""

                total += amount

                switch category {

                case "Lives":

                    live += amount

                case "Réservations":

                    booking += amount

                case "Marketplace":

                    marketplace += amount

                case "Publicités":

                    ads += amount

                default:

                    break

                }

            }

            totalRevenue = total
            liveRevenue = live
            bookingRevenue = booking
            marketplaceRevenue = marketplace
            adsRevenue = ads

            // Graphe

            points.removeAll()

            for i in 0..<30 {

                let value = Double.random(in: 150...900)

                let date = Calendar.current.date(
                    byAdding: .day,
                    value: -i,
                    to: Date()
                )!

                points.append(
                    AdminAnalyticsPoint(
                        date: date,
                        value: value
                    )
                )

            }

            points.sort {

                $0.date < $1.date

            }

        }

        catch {

            print("❌ Analytics :", error)

        }

    }

}

// MARK: - EXPORTS

extension AdminDashboardAnalytics {

    func exportPDF() {

        print("📄 Export PDF Analytics")

    }

    func exportCSV() {

        print("📊 Export CSV Analytics")

    }

    func exportExcel() {

        print("📈 Export Excel Analytics")

    }

}

// MARK: - FORMAT

extension AdminDashboardAnalytics {

    func formatEUR(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) €"
    }

}

// MARK: - CARTE KPI

extension AdminDashboardAnalytics {

    func analyticsCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {
                Image(systemName: icon)
                    .font(.title2.bold())
                    .foregroundColor(color)

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
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: .black.opacity(0.06), radius: 10)
    }

}
