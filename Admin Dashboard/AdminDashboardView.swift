//
//  AdminDashboardView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AdminDashboardView: View {
    
    
    @StateObject private var realtime = AdminRealtimeService.shared
    @State var marketplaceListener: ListenerRegistration?
    @State var transactionsListener: ListenerRegistration?
    @State var bookingsListener: ListenerRegistration?
    @State var usersListener: ListenerRegistration?
    @State var reportsListener: ListenerRegistration?
    
    @State var isSidebarCollapsed = false
    
    @State var selectedTab: AdminDashboardTab = .home
    @State var selectedLanguage: AdminLanguage = .fr
    
    @State var users: [AdminUserItem] = []
    @State var reports: [AdminReportItem] = []
    @State var bookings: [AdminBookingItem] = []
    @State var transactions: [AdminTransactionItem] = []
    
    @State var liveRevenue: Double = 0
    @State var bookingRevenue: Double = 0
    @State var shopRevenue: Double = 0
    @State var adsRevenue: Double = 0
    
    let db = Firestore.firestore()
    
    var totalRevenue: Double {
        liveRevenue + bookingRevenue + shopRevenue + adsRevenue
    }
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                AdminDashboardSidebar(
                    selectedTab: $selectedTab,
                    isCollapsed: $isSidebarCollapsed
                )
                
                ScrollView {
                    VStack(spacing: 22) {
                        topHeader

                        switch selectedTab {

                        case .home:
                            homeContent

                        case .revenue:
                            revenueContent

                        case .users:
                            usersContent

                        case .reports:
                            reportsContent

                        case .bookings:
                            bookingsContent

                        case .transactions:
                            transactionsContent

                        case .analytics:
                            analyticsContent

                        case .marketplace:
                            marketplaceContent

                        case .lives:
                            liveContent

                        case .appeals:
                            appealsContent

                        case .messages:
                            placeholderContent("Messages")

                        case .calls:
                            placeholderContent("Appels")

                        case .gifts:
                            placeholderContent("Cadeaux")

                        case .shop:
                            placeholderContent("Boutique")

                        case .orders:
                            placeholderContent("Commandes")

                        case .withdrawals:
                            placeholderContent("Retraits")

                        case .settings:
                            placeholderContent("Paramètres")
                        }
                    }
                    .padding()
                    .foregroundStyle(.primary)
                    .tint(.purple)
                }
                .background(
                    Color(red: 0.93, green: 0.94, blue: 0.98)
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadAll()
                startReportsRealtimeListener()
                startUsersRealtimeListener()
                startBookingsRealtimeListener()
                startTransactionsRealtimeListener()
                startMarketplaceRealtimeListener()
                realtime.start()
            }
            .onDisappear {
                stopReportsRealtimeListener()
                stopUsersRealtimeListener()
                stopBookingsRealtimeListener()
                stopTransactionsRealtimeListener()
                stopMarketplaceRealtimeListener()
                realtime.stop()
            }
        }
    }
    
    
    var topHeader: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedTab.rawValue)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)

                Text("Gestion complète de la plateforme Cutly")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black.opacity(0.82))
            }

            Spacer()

            Picker("Langue", selection: $selectedLanguage) {
                ForEach(AdminLanguage.allCases) { lang in
                    Text(lang.rawValue).tag(lang)
                }
            }
            .pickerStyle(.menu)
            .tint(.blue)

            Button {
                loadAll()
                realtime.start()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title3.bold())
                    .foregroundColor(.blue)
                    .padding(14)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.vertical, 10)
    }
    
    var homeContent: some View {
        AdminDashboardHome(
            totalRevenue: totalRevenue,
            usersCount: users.count,
            reportsCount: reports.count,
            bookingsCount: bookings.count,
            transactionsCount: transactions.count,
            liveRevenue: liveRevenue,
            bookingRevenue: bookingRevenue,
            shopRevenue: shopRevenue,
            adsRevenue: adsRevenue,
            onOpenReports: { selectedTab = .reports },
            onOpenUsers: { selectedTab = .users },
            onOpenRevenue: { selectedTab = .revenue },
            onOpenBookings: { selectedTab = .bookings },
            onOpenAI: { selectedTab = .settings }
        )
    }
    
    var revenueContent: some View {
        VStack(spacing: 18) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                AdminDashboardCard(title: "Lives", value: formatEUR(liveRevenue), subtitle: "Cadeaux envoyés", icon: "gift.fill")
                AdminDashboardCard(title: "Réservations", value: formatEUR(bookingRevenue), subtitle: "Commissions services", icon: "scissors")
                AdminDashboardCard(title: "Boutique", value: formatEUR(shopRevenue), subtitle: "Commandes marketplace", icon: "cart.fill")
                AdminDashboardCard(title: "Publicités", value: formatEUR(adsRevenue), subtitle: "Pré-roll et sponsorisés", icon: "megaphone.fill")
            }
            
            AdminSectionBox(title: "Retraits plateforme", icon: "creditcard.fill") {
                Button("Créer une demande de retrait") {
                    createWithdrawRequest()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    var usersContent: some View {
        AdminDashboardUsers(
            users: users,
            onRefresh: {
                loadAll()
            }
        )
    }
    
    var reportsContent: some View {
        AdminDashboardReports(
            reports: reports,
            onRefresh: {
                loadAll()
            },
            onWarn: { report in
                warnUser(report)
            },
            onRestrict: { report in
                restrictUser(report)
            },
            onBan: { report in
                banUser(report)
            }
        )
    }
    
    var bookingsContent: some View {
        
        AdminDashboardBookings()
        
    }
    
    func placeholderContent(_ title: String) -> some View {
        AdminSectionBox(title: title, icon: "sparkles") {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(title) sera branché ici avec ses données Cutly.")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)

                Text("Ce module est prévu dans le tableau de bord administrateur et sera connecté aux données Firestore correspondantes.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black.opacity(0.82))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    var transactionsContent: some View {
        
        AdminDashboardTransactions()
        
    }
    var liveContent: some View {

        AdminDashboardLive()

    }

    var appealsContent: some View {

        AdminDashboardAppeals()

    }

    var marketplaceContent: some View {

        AdminDashboardMarketplace()

    }
    var analyticsContent: some View {

        AdminDashboardAnalytics()

    }
}

