//
//  AdminDashboardMarketplace.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

//
//  AdminDashboardMarketplace.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct AdminMarketplaceSeller: Identifiable {

    let id: String

    let shopName: String

    let ownerName: String

    let email: String

    let phone: String

    let country: String

    let city: String

    let verified: Bool

    let suspended: Bool

    let productsCount: Int

    let ordersCount: Int

    let totalRevenue: Double

    let commissionPaid: Double

    let createdAt: Date

}

struct AdminMarketplaceProduct: Identifiable {

    let id: String

    let sellerId: String

    let sellerName: String

    let title: String

    let category: String

    let price: Double

    let stock: Int

    let images: [String]

    let status: String

    let reported: Bool

    let views: Int

    let favorites: Int

    let sales: Int

    let createdAt: Date

}

struct AdminMarketplaceOrder: Identifiable {

    let id: String

    let buyerName: String

    let sellerName: String

    let total: Double

    let commission: Double

    let status: String

    let paymentStatus: String

    let deliveryStatus: String

    let createdAt: Date

}
struct AdminMarketplaceNotification: Identifiable {
    let id: String
    let title: String
    let body: String
    let type: String
    let priority: String
    let targetId: String
    let isRead: Bool
    let createdAt: Date
}



struct AdminDashboardMarketplace: View {
    
    @State private var sellers: [AdminMarketplaceSeller] = []
    
    @State private var products: [AdminMarketplaceProduct] = []
    
    @State private var orders: [AdminMarketplaceOrder] = []
    
    @State private var selectedMenu = 0
    
    @State private var search = ""
    
    @State private var loading = true
    
    @State private var totalRevenue: Double = 0
    
    @State private var totalCommission: Double = 0
    
    @State private var totalOrders = 0
    
    @State private var totalProducts = 0
    
    @State private var totalSellers = 0
    
    @State private var selectedSeller: AdminMarketplaceSeller?
    
    @State private var selectedProduct: AdminMarketplaceProduct?
    
    @State private var selectedOrder: AdminMarketplaceOrder?
    
    @State private var showSellerSheet = false
    
    @State private var showProductSheet = false
    
    @State private var showOrderSheet = false
    
    @State private var totalReports = 0
    @State private var totalDisputes = 0
    @State private var totalPayments = 0
    @State private var totalWithdrawals = 0
    @State private var totalAIAlerts = 0
    @State private var totalSupportTickets = 0
    
    @State private var adminAlerts: [String] = []
    @State private var recentActivity: [String] = []
    
    @State private var adminNotifications: [AdminMarketplaceNotification] = []
    @State private var unreadAdminNotifications = 0
    
    
    
    
    
    private let db = Firestore.firestore()
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 24) {
                
                premiumMarketplaceHeader

                marketplaceStatistics

                adminAlertsSection

                recentActivitySection
                
                adminNotificationsSection
                
                marketplaceSystemStatusSection

                marketplaceMenu

                marketplaceBody
                
            }
            .padding()
            
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.99))
        .navigationTitle("Marketplace")
        .task {
            
            await loadMarketplace()
            
        }
        
    }
    // MARK: - HEADER PREMIUM

    private var premiumMarketplaceHeader: some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                VStack(alignment: .leading, spacing: 6) {

                    Text("Marketplace Cutly")
                        .font(.system(size: 34, weight: .bold))

                    Text("Administration complète de la marketplace")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))

                }

                Spacer()

                Button {

                    Task {
                        await loadMarketplace()
                    }

                } label: {

                    Label("Actualiser", systemImage: "arrow.clockwise")
                        .padding(.horizontal,18)
                        .padding(.vertical,10)
                        .background(Color.purple)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())

                }

            }

            HStack(spacing: 14) {

                Image(systemName: "magnifyingglass")
                    .font(.headline.bold())
                    .foregroundColor(.black)

                TextField("Rechercher un vendeur, un produit, une commande...", text: $search)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)

            }
            .padding(16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

        }

    }

    // MARK: - CARTES PREMIUM

    private var marketplaceStatistics: some View {

        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing:18
        ) {

            AdminDashboardCard(
                title:"Vendeurs",
                value:"\(totalSellers)",
                subtitle:"Comptes actifs",
                icon:"storefront.fill"
            )

            AdminDashboardCard(
                title:"Produits",
                value:"\(totalProducts)",
                subtitle:"Catalogue",
                icon:"shippingbox.fill"
            )

            AdminDashboardCard(
                title:"Commandes",
                value:"\(totalOrders)",
                subtitle:"Marketplace",
                icon:"cart.fill"
            )

            AdminDashboardCard(
                title:"Revenus",
                value:formatEUR(totalRevenue),
                subtitle:"Volume vendu",
                icon:"eurosign.circle.fill"
            )

            AdminDashboardCard(
                title:"Commission",
                value:formatEUR(totalCommission),
                subtitle:"Plateforme",
                icon:"banknote.fill"
            )
            AdminDashboardCard(
                title:"Signalements",
                value:"\(totalReports)",
                subtitle:"À vérifier",
                icon:"flag.fill"
            )

            AdminDashboardCard(
                title:"Litiges",
                value:"\(totalDisputes)",
                subtitle:"Commandes sensibles",
                icon:"exclamationmark.shield.fill"
            )

            AdminDashboardCard(
                title:"Paiements",
                value:"\(totalPayments)",
                subtitle:"Transactions",
                icon:"creditcard.fill"
            )

            AdminDashboardCard(
                title:"Retraits",
                value:"\(totalWithdrawals)",
                subtitle:"Demandes vendeurs",
                icon:"arrow.down.circle.fill"
            )

            AdminDashboardCard(
                title:"Alertes IA",
                value:"\(totalAIAlerts)",
                subtitle:"Risques détectés",
                icon:"brain.head.profile"
            )

            AdminDashboardCard(
                title:"Support",
                value:"\(totalSupportTickets)",
                subtitle:"Tickets ouverts",
                icon:"headset"
            )
            
        }

    }
    private var adminAlertsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Alertes administrateur", systemImage: "bell.badge.fill")
                .font(.title3.bold())
                .foregroundColor(.black)

            if adminAlerts.isEmpty {
                AdminEmptyState(text: "Aucune alerte critique pour le moment.")
            } else {
                ForEach(adminAlerts, id: \.self) { alert in
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)

                        Text(alert)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)

                        Spacer()
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
        }
        .padding(22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Activité récente Marketplace", systemImage: "clock.arrow.circlepath")
                .font(.title3.bold())
                .foregroundColor(.black)

            if recentActivity.isEmpty {
                AdminEmptyState(text: "Aucune activité récente.")
            } else {
                ForEach(recentActivity, id: \.self) { activity in
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)

                        Text(activity)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)

                        Spacer()
                    }
                    .padding(14)
                    .background(Color.purple.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
        }
        .padding(22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }
    private var adminNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Tout ce qui se passe", systemImage: "bell.badge.fill")
                    .font(.title3.bold())
                    .foregroundColor(.black)

                Spacer()

                Text("\(unreadAdminNotifications) non lu(s)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(unreadAdminNotifications > 0 ? Color.red : Color.gray)
                    .clipShape(Capsule())
            }

            if adminNotifications.isEmpty {
                AdminEmptyState(text: "Aucune notification admin.")
            } else {
                ForEach(adminNotifications) { notification in
                    Button {
                        Task {
                            await markAdminNotificationAsRead(notification.id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: notification.isRead ? "bell.fill" : "bell.badge.fill")
                                .foregroundStyle(notification.isRead ? .gray : .red)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)

                                Text(notification.body)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.black.opacity(0.65))
                                    .lineLimit(2)

                                Text(notification.type)
                                    .font(.caption2.bold())
                                    .foregroundColor(.purple)
                            }

                            Spacer()

                            if !notification.isRead {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding(14)
                        .background(notification.isRead ? Color.white : Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }
    
    
    // MARK: - MENU PREMIUM

    private var marketplaceMenu: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                marketplaceMenuButton(index: 0, title: "Vendeurs", icon: "storefront.fill")
                marketplaceMenuButton(index: 1, title: "Produits", icon: "shippingbox.fill")
                marketplaceMenuButton(index: 2, title: "Commandes", icon: "cart.fill")
                marketplaceMenuButton(index: 3, title: "Paiements", icon: "creditcard.fill")
                marketplaceMenuButton(index: 4, title: "Livraison", icon: "truck.box.fill")
                marketplaceMenuButton(index: 5, title: "Litiges", icon: "exclamationmark.shield.fill")
                marketplaceMenuButton(index: 6, title: "Signalements", icon: "flag.fill")
                marketplaceMenuButton(index: 7, title: "Support", icon: "headset")
                marketplaceMenuButton(index: 8, title: "Certification", icon: "checkmark.seal.fill")
                marketplaceMenuButton(index: 9, title: "Analytics", icon: "chart.line.uptrend.xyaxis")
                marketplaceMenuButton(index: 10, title: "IA", icon: "brain.head.profile")
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func marketplaceMenuButton(
        index: Int,
        title: String,
        icon: String
    ) -> some View {

        Button {
            withAnimation(.spring()) {
                selectedMenu = index
            }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2.bold())

                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(selectedMenu == index ? Color.purple : Color.white)
            .foregroundColor(selectedMenu == index ? .white : .black)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(selectedMenu == index ? 0 : 0.10), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: - CONTENU

    @ViewBuilder
    private var marketplaceBody: some View {
        switch selectedMenu {
        case 0:
            sellersView
        case 1:
            productsView
        case 2:
            ordersView
        case 3:
            paymentsAdminView
        case 4:
            shippingAdminView
        case 5:
            disputesAdminView
        case 6:
            reportsAdminView
        case 7:
            supportAdminView
        case 8:
            certificationAdminView
        case 9:
            analyticsAdminView
        default:
            aiMarketplaceView
        }
    }
    // MARK: - VENDEURS

    private var sellersView: some View {

        VStack(spacing:18){

            if sellers.isEmpty{

                AdminEmptyState(
                    text: "Aucun vendeur enregistré."
                )

            }else{

                ForEach(sellers){ seller in

                    sellerCard(seller)

                }

            }

        }

    }

    @ViewBuilder
    private func sellerCard(
        _ seller: AdminMarketplaceSeller
    ) -> some View{

        VStack(alignment:.leading,spacing:18){

            HStack{

                VStack(alignment:.leading,spacing:4){

                    Text(seller.shopName)
                        .font(.title3.bold())

                    Text(seller.ownerName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))
                }

                Spacer()

                if seller.verified{

                    Label(
                        "Vérifié",
                        systemImage:"checkmark.seal.fill"
                    )
                    .foregroundStyle(.green)

                }else{

                    Label(
                        "En attente",
                        systemImage:"clock.fill"
                    )
                    .foregroundStyle(.orange)

                }

            }

            Divider()

            LazyVGrid(
                columns:[
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing:14
            ){

                marketplaceInfo(
                    icon:"shippingbox.fill",
                    title:"Produits",
                    value:"\(seller.productsCount)"
                )

                marketplaceInfo(
                    icon:"cart.fill",
                    title:"Commandes",
                    value:"\(seller.ordersCount)"
                )

                marketplaceInfo(
                    icon:"eurosign.circle.fill",
                    title:"Ventes",
                    value:formatEUR(
                        seller.totalRevenue
                    )
                )

                marketplaceInfo(
                    icon:"banknote.fill",
                    title:"Commission",
                    value:formatEUR(
                        seller.commissionPaid
                    )
                )

            }

            HStack{

                Button{

                    selectedSeller = seller

                    showSellerSheet = true

                }label:{

                    Label(
                        "Voir",
                        systemImage:"eye.fill"
                    )

                }
                .buttonStyle(.borderedProminent)

                Button {
                    Task {
                        if seller.suspended {
                            await unsuspendSeller(seller.id)
                        } else {
                            await suspendSeller(seller.id)
                        }
                    }
                } label: {
                    Label(
                        seller.suspended ? "Réactiver" : "Suspendre",
                        systemImage: seller.suspended
                            ? "play.circle.fill"
                            : "pause.circle.fill"
                    )
                }
                .buttonStyle(.bordered)

                Button{

                    print("Supprimer vendeur")

                }label:{

                    Label(
                        "Supprimer",
                        systemImage:"trash.fill"
                    )

                }
                .tint(.red)
                .buttonStyle(.bordered)

            }

        }
        .padding(22)
        .background(.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius:26
            )
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:8
        )

    }

    private func marketplaceInfo(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        VStack(spacing: 10) {

            Image(systemName: icon)
                .font(.title2.bold())
                .foregroundStyle(.purple)

            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)

            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.82))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    // MARK: - PRODUITS

    private var productsView: some View {

        VStack(spacing:18){

            if products.isEmpty{

                AdminEmptyState(
                    text: "Aucun produit disponible."
                )

            }else{

                ForEach(products){ product in

                    productCard(product)

                }

            }

        }

    }

    @ViewBuilder
    private func productCard(
        _ product: AdminMarketplaceProduct
    ) -> some View {

        VStack(alignment:.leading,spacing:18){

            HStack{

                VStack(alignment:.leading,spacing:5){

                    Text(product.title)
                        .font(.title3.bold())

                    Text(product.sellerName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))

                }

                Spacer()

                Text(product.status.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(product.status == "active" ? .green : .orange)
                    .padding(.horizontal,10)
                    .padding(.vertical,6)
                    .background(product.status == "active"
                        ? Color.green.opacity(0.18)
                        : Color.orange.opacity(0.18))
                    .clipShape(Capsule())

            }

            Divider()

            LazyVGrid(
                columns:[
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing:14
            ){

                marketplaceInfo(
                    icon:"eurosign.circle.fill",
                    title:"Prix",
                    value:formatEUR(product.price)
                )

                marketplaceInfo(
                    icon:"shippingbox.fill",
                    title:"Stock",
                    value:"\(product.stock)"
                )

                marketplaceInfo(
                    icon:"eye.fill",
                    title:"Vues",
                    value:"\(product.views)"
                )

                marketplaceInfo(
                    icon:"heart.fill",
                    title:"Favoris",
                    value:"\(product.favorites)"
                )

                marketplaceInfo(
                    icon:"cart.fill",
                    title:"Ventes",
                    value:"\(product.sales)"
                )

                marketplaceInfo(
                    icon:"flag.fill",
                    title:"Signalé",
                    value:product.reported ? "Oui" : "Non"
                )

            }

            HStack{

                Button{

                    selectedProduct = product

                    showProductSheet = true

                }label:{

                    Label(
                        "Voir",
                        systemImage:"eye.fill"
                    )

                }
                .buttonStyle(.borderedProminent)

                Button {
                    Task {
                        if product.status == "removed_by_admin" {
                            await restoreProduct(product.id)
                        } else {
                            await removeProduct(product.id)
                        }
                    }
                } label: {
                    Label(
                        product.status == "removed_by_admin"
                            ? "Restaurer"
                            : "Retirer",
                        systemImage: product.status == "removed_by_admin"
                            ? "arrow.uturn.backward.circle.fill"
                            : "xmark.circle.fill"
                    )
                }
                .buttonStyle(.bordered)

                Button{

                    print("Supprimer produit")

                }label:{

                    Label(
                        "Supprimer",
                        systemImage:"trash.fill"
                    )

                }
                .tint(.red)
                .buttonStyle(.bordered)

            }

        }
        .padding(22)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:8
        )

    }
    // MARK: - COMMANDES

    private var ordersView: some View {

        VStack(spacing:18){

            if orders.isEmpty {

                AdminEmptyState(
                    text: "Aucune commande."
                )

            } else {

                ForEach(orders){ order in

                    orderCard(order)

                }

            }

        }

    }

    @ViewBuilder
    private func orderCard(
        _ order: AdminMarketplaceOrder
    ) -> some View {

        VStack(alignment:.leading,spacing:18){

            HStack{

                VStack(alignment:.leading){

                    Text(order.buyerName)
                        .font(.headline)

                    Text(order.sellerName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))

                }

                Spacer()

                Text(order.status.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal,10)
                    .padding(.vertical,6)
                    .background(Color.green.opacity(0.18))
                    .clipShape(Capsule())

            }

            Divider()

            LazyVGrid(
                columns:[
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing:14
            ){

                marketplaceInfo(
                    icon:"eurosign.circle.fill",
                    title:"Montant",
                    value:formatEUR(order.total)
                )

                marketplaceInfo(
                    icon:"banknote.fill",
                    title:"Commission",
                    value:formatEUR(order.commission)
                )

                marketplaceInfo(
                    icon:"creditcard.fill",
                    title:"Paiement",
                    value:order.paymentStatus
                )

                marketplaceInfo(
                    icon:"truck.box.fill",
                    title:"Livraison",
                    value:order.deliveryStatus
                )

            }

            HStack{

                Button{

                    selectedOrder = order

                    showOrderSheet = true

                }label:{

                    Label(
                        "Voir",
                        systemImage:"eye.fill"
                    )

                }
                .buttonStyle(.borderedProminent)

                Button {
                    Task {
                        await refundOrder(order.id)
                    }
                } label: {
                    Label(
                        "Rembourser",
                        systemImage: "arrow.uturn.backward.circle.fill"
                    )
                }
                .buttonStyle(.bordered)

            }

        }
        .padding(22)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:8
        )

    }
    private var paymentsAdminView: some View {
        adminModuleCard(
            title: "Paiements & retraits",
            subtitle: "Transactions, commissions, escrow, remboursements, Stripe, PayPal, Mobile Money et Wallet Cutly.",
            icon: "creditcard.fill",
            stats: [
                ("Paiements", "\(totalPayments)"),
                ("Retraits", "\(totalWithdrawals)"),
                ("Commission", formatEUR(totalCommission)),
                ("Volume", formatEUR(totalRevenue))
            ]
        )
    }

    private var shippingAdminView: some View {
        adminModuleCard(
            title: "Livraison & suivi",
            subtitle: "Suivi colis, transporteurs, agences locales, bus, coursiers, GPS, QR Code, signature et preuves.",
            icon: "truck.box.fill",
            stats: [
                ("Commandes", "\(totalOrders)"),
                ("Litiges", "\(totalDisputes)"),
                ("International", "Actif"),
                ("Afrique", "Prêt")
            ]
        )
    }

    private var disputesAdminView: some View {
        adminModuleCard(
            title: "Litiges",
            subtitle: "Retours, remboursements, preuves photo/vidéo, décisions admin et médiation Cutly.",
            icon: "exclamationmark.shield.fill",
            stats: [
                ("Litiges", "\(totalDisputes)"),
                ("Signalements", "\(totalReports)"),
                ("IA", "\(totalAIAlerts)"),
                ("Support", "\(totalSupportTickets)")
            ]
        )
    }

    private var reportsAdminView: some View {
        adminModuleCard(
            title: "Signalements",
            subtitle: "Produits, vendeurs, boutiques, messages, avis, fraudes, contrefaçons et sanctions.",
            icon: "flag.fill",
            stats: [
                ("Signalements", "\(totalReports)"),
                ("Alertes IA", "\(totalAIAlerts)"),
                ("Produits", "\(totalProducts)"),
                ("Vendeurs", "\(totalSellers)")
            ]
        )
    }

    private var supportAdminView: some View {
        adminModuleCard(
            title: "Support",
            subtitle: "Tickets utilisateurs, urgences, escalades, litiges, preuves et réponses support.",
            icon: "headset",
            stats: [
                ("Tickets", "\(totalSupportTickets)"),
                ("Litiges", "\(totalDisputes)"),
                ("Signalements", "\(totalReports)"),
                ("Urgences", "\(totalAIAlerts)")
            ]
        )
    }

    private var certificationAdminView: some View {
        adminModuleCard(
            title: "Certification",
            subtitle: "Demandes de badge payant pour particuliers, acheteurs-vendeurs, boutiques, marques et partenaires.",
            icon: "checkmark.seal.fill",
            stats: [
                ("Vendeurs", "\(totalSellers)"),
                ("Boutiques", "\(totalSellers)"),
                ("Paiements", "\(totalPayments)"),
                ("IA", "\(totalAIAlerts)")
            ]
        )
    }

    private var analyticsAdminView: some View {
        adminModuleCard(
            title: "Analytics Marketplace",
            subtitle: "Ventes, pays, produits, boutiques, paiements, livraisons, litiges, IA et croissance.",
            icon: "chart.line.uptrend.xyaxis",
            stats: [
                ("Revenus", formatEUR(totalRevenue)),
                ("Commandes", "\(totalOrders)"),
                ("Produits", "\(totalProducts)"),
                ("Commission", formatEUR(totalCommission))
            ]
        )
    }

    private func adminModuleCard(
        title: String,
        subtitle: String,
        icon: String,
        stats: [(String, String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.purple)
                    .frame(width: 60, height: 60)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.black)

                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.black.opacity(0.72))
                        .lineLimit(3)
                }

                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 14) {
                ForEach(stats, id: \.0) { item in
                    marketplaceInfo(
                        icon: "circle.grid.2x2.fill",
                        title: item.0,
                        value: item.1
                    )
                }
            }

            HStack {
                Button {
                    Task {
                        await loadMarketplace()
                    }
                } label: {
                    Label("Actualiser", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    print("Ouvrir module admin : \(title)")
                } label: {
                    Label("Ouvrir", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
    
    
    
    
    
    
    // MARK: - IA MARKETPLACE

    private var aiMarketplaceView: some View {

        VStack(alignment:.leading,spacing:20){

            Label(
                "Cutly AI Marketplace",
                systemImage: "brain.head.profile"
            )
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.black)

            aiRow("Détection automatique des faux vendeurs")
            aiRow("Détection des produits interdits")
            aiRow("Détection des fraudes")
            aiRow("Analyse automatique des litiges")
            aiRow("Analyse des remboursements")
            aiRow("Détection des faux avis")
            aiRow("Détection des ventes suspectes")
            aiRow("Classement automatique des vendeurs")
            aiRow("Suggestions administrateur")
            aiRow("Connexion OpenAI (à brancher)")

        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:28)
        )

    }

    private func aiRow(
        _ text: String
    ) -> some View {

        HStack(spacing: 10) {

            Image(systemName: "sparkles")
                .font(.headline.bold())
                .foregroundStyle(.purple)

            Text(text)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)

            Spacer()
        }
    }
    private func adminPlaceholderView(
        title: String,
        subtitle: String,
        icon: String
    ) -> some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(.purple)

            Text(title)
                .font(.title2.bold())
                .foregroundColor(.black)

            Text(subtitle)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.black.opacity(0.72))
                .multilineTextAlignment(.center)

            Text("Ce module sera branché avec les collections Firestore Marketplace déjà créées.")
                .font(.caption.bold())
                .foregroundColor(.black.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
    // MARK: - ACTIONS ADMIN MARKETPLACE

    private func suspendSeller(_ sellerId: String) async {
        do {
            try await db.collection(MarketplaceFirestoreService.Collection.stores)
                .document(sellerId)
                .setData([
                    "isSuspended": true,
                    "suspendedAt": Timestamp(),
                    "updatedAt": Timestamp()
                ], merge: true)
            await createAdminNotification(
                title: "Vendeur suspendu",
                body: "Un vendeur a été suspendu depuis le dashboard admin.",
                type: "seller_suspended",
                priority: "high",
                targetId: sellerId
            )
            
            await loadMarketplace()
        } catch {
            print("Erreur suspension vendeur: \(error.localizedDescription)")
        }
    }

    private func unsuspendSeller(_ sellerId: String) async {
        do {
            try await db.collection(MarketplaceFirestoreService.Collection.stores)
                .document(sellerId)
                .setData([
                    "isSuspended": false,
                    "unsuspendedAt": Timestamp(),
                    "updatedAt": Timestamp()
                ], merge: true)

            await loadMarketplace()
        } catch {
            print("Erreur réactivation vendeur: \(error.localizedDescription)")
        }
    }

    private func removeProduct(_ productId: String) async {
        do {
            try await db.collection(MarketplaceFirestoreService.Collection.products)
                .document(productId)
                .setData([
                    "status": "removed_by_admin",
                    "removedAt": Timestamp(),
                    "updatedAt": Timestamp()
                ], merge: true)
            await createAdminNotification(
                title: "Produit retiré",
                body: "Un produit a été retiré par l’administration.",
                type: "product_removed",
                priority: "high",
                targetId: productId
            )
            
            await loadMarketplace()
        } catch {
            print("Erreur retrait produit: \(error.localizedDescription)")
        }
    }

    private func restoreProduct(_ productId: String) async {
        do {
            try await db.collection(MarketplaceFirestoreService.Collection.products)
                .document(productId)
                .setData([
                    "status": "active",
                    "restoredAt": Timestamp(),
                    "updatedAt": Timestamp()
                ], merge: true)

            await loadMarketplace()
        } catch {
            print("Erreur restauration produit: \(error.localizedDescription)")
        }
    }

    private func refundOrder(_ orderId: String) async {
        do {
            try await db.collection(MarketplaceFirestoreService.Collection.orders)
                .document(orderId)
                .setData([
                    "status": "refund_requested_by_admin",
                    "refundRequestedAt": Timestamp(),
                    "updatedAt": Timestamp()
                ], merge: true)
            
            await createAdminNotification(
                title: "Remboursement demandé",
                body: "Une demande de remboursement a été créée par l’administration.",
                type: "refund_requested",
                priority: "high",
                targetId: orderId
            )
            await loadMarketplace()
        } catch {
            print("Erreur remboursement commande: \(error.localizedDescription)")
        }
    }

    private func closeReport(_ reportId: String) async {
        do {
            try await MarketplaceReportService.shared.updateReportStatus(
                reportId: reportId,
                status: .closed,
                adminId: Auth.auth().currentUser?.uid,
                note: "Fermé depuis le dashboard admin."
            )

            await loadMarketplace()
        } catch {
            print("Erreur fermeture signalement: \(error.localizedDescription)")
        }
    }

    private func approveCertification(_ requestId: String) async {
        do {
            try await db.collection(MarketplaceFirestoreService.Collection.certificationRequests)
                .document(requestId)
                .setData([
                    "status": "approved",
                    "approvedAt": Timestamp(),
                    "approvedBy": Auth.auth().currentUser?.uid ?? "",
                    "updatedAt": Timestamp()
                ], merge: true)

            await loadMarketplace()
        } catch {
            print("Erreur validation certification: \(error.localizedDescription)")
        }
    }

    private func rejectCertification(_ requestId: String) async {
        do {
            try await db.collection(MarketplaceFirestoreService.Collection.certificationRequests)
                .document(requestId)
                .setData([
                    "status": "rejected",
                    "rejectedAt": Timestamp(),
                    "rejectedBy": Auth.auth().currentUser?.uid ?? "",
                    "updatedAt": Timestamp()
                ], merge: true)

            await loadMarketplace()
        } catch {
            print("Erreur rejet certification: \(error.localizedDescription)")
        }
    }
    // MARK: - NOTIFICATIONS ADMIN

    private func createAdminNotification(
        title: String,
        body: String,
        type: String,
        priority: String = "normal",
        targetId: String? = nil
    ) async {
        do {
            let ref = db.collection(MarketplaceFirestoreService.Collection.adminNotifications).document()

            try await ref.setData([
                "id": ref.documentID,
                "title": title,
                "body": body,
                "type": type,
                "priority": priority,
                "targetId": targetId ?? "",
                "isRead": false,
                "createdAt": Timestamp(),
                "createdBy": Auth.auth().currentUser?.uid ?? "system"
            ], merge: true)
        } catch {
            print("Erreur notification admin: \(error.localizedDescription)")
        }
    }
    private func loadAdminNotifications() async {
        do {
            let snapshot = try await db
                .collection(MarketplaceFirestoreService.Collection.adminNotifications)
                .order(by: "createdAt", descending: true)
                .limit(to: 20)
                .getDocuments()

            let items = snapshot.documents
                .filter { $0.documentID != "_schema" }
                .map { document -> AdminMarketplaceNotification in
                    let data = document.data()

                    return AdminMarketplaceNotification(
                        id: document.documentID,
                        title: data["title"] as? String ?? "Notification admin",
                        body: data["body"] as? String ?? "",
                        type: data["type"] as? String ?? "marketplace",
                        priority: data["priority"] as? String ?? "normal",
                        targetId: data["targetId"] as? String ?? "",
                        isRead: data["isRead"] as? Bool ?? false,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }

            await MainActor.run {
                adminNotifications = items
                unreadAdminNotifications = items.filter { !$0.isRead }.count
            }
        } catch {
            print("Erreur chargement notifications admin: \(error.localizedDescription)")
        }
    }

    private func markAdminNotificationAsRead(_ notificationId: String) async {
        do {
            try await db
                .collection(MarketplaceFirestoreService.Collection.adminNotifications)
                .document(notificationId)
                .setData([
                    "isRead": true,
                    "readAt": Timestamp(),
                    "updatedAt": Timestamp()
                ], merge: true)

            await loadAdminNotifications()
        } catch {
            print("Erreur lecture notification admin: \(error.localizedDescription)")
        }
    }
    private var marketplaceSystemStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Système Marketplace", systemImage: "checkmark.seal.fill")
                .font(.title3.bold())
                .foregroundColor(.black)

            adminSystemRow("Firestore", "Collections centralisées et bootstrap automatique", true)
            adminSystemRow("Storage", "Produits, preuves, litiges, support et documents", true)
            adminSystemRow("Paiements", "Stripe, PayPal, Mobile Money, Wallet, escrow", true)
            adminSystemRow("Livraison", "Afrique, Europe, monde, GPS, relais, agences", true)
            adminSystemRow("IA & modération", "Fraude, contrefaçons, faux avis, risques", true)
            adminSystemRow("Admin", "Alertes, actions, notifications et surveillance", true)
            adminSystemRow("Cloud Functions", "À brancher après le dashboard", false)
        }
        .padding(22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    private func adminSystemRow(_ title: String, _ subtitle: String, _ ready: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: ready ? "checkmark.circle.fill" : "clock.fill")
                .foregroundStyle(ready ? .green : .orange)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.black.opacity(0.65))
            }

            Spacer()
        }
        .padding(12)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    
    // MARK: - FIRESTORE

    @MainActor
    private func loadMarketplace() async {
        loading = true
        
        do {
            async let productsSnapshot = db.collection(MarketplaceFirestoreService.Collection.products).getDocuments()
            async let ordersSnapshot = db.collection(MarketplaceFirestoreService.Collection.orders).getDocuments()
            async let storesSnapshot = db.collection(MarketplaceFirestoreService.Collection.stores).getDocuments()
            async let paymentsSnapshot = db.collection(MarketplaceFirestoreService.Collection.payments).getDocuments()
            async let withdrawalsSnapshot = db.collection(MarketplaceFirestoreService.Collection.withdrawals).getDocuments()
            async let reportsSnapshot = db.collection(MarketplaceFirestoreService.Collection.reports).getDocuments()
            async let disputesSnapshot = db.collection(MarketplaceFirestoreService.Collection.disputes).getDocuments()
            async let aiSnapshot = db.collection(MarketplaceFirestoreService.Collection.aiModerationResults).getDocuments()
            async let supportSnapshot = db.collection(MarketplaceFirestoreService.Collection.supportTickets).getDocuments()
            
            let (
                productsResult,
                ordersResult,
                storesResult,
                paymentsResult,
                withdrawalsResult,
                reportsResult,
                disputesResult,
                aiResult,
                supportResult
            ) = try await (
                productsSnapshot,
                ordersSnapshot,
                storesSnapshot,
                paymentsSnapshot,
                withdrawalsSnapshot,
                reportsSnapshot,
                disputesSnapshot,
                aiSnapshot,
                supportSnapshot
            )
            
            totalProducts = productsResult.documents.filter { $0.documentID != "_schema" }.count
            totalOrders = ordersResult.documents.filter { $0.documentID != "_schema" }.count
            totalSellers = storesResult.documents.filter { $0.documentID != "_schema" }.count
            totalPayments = paymentsResult.documents.filter { $0.documentID != "_schema" }.count
            totalWithdrawals = withdrawalsResult.documents.filter { $0.documentID != "_schema" }.count
            totalReports = reportsResult.documents.filter { $0.documentID != "_schema" }.count
            totalDisputes = disputesResult.documents.filter { $0.documentID != "_schema" }.count
            totalAIAlerts = aiResult.documents.filter { $0.documentID != "_schema" }.count
            totalSupportTickets = supportResult.documents.filter { $0.documentID != "_schema" }.count
            products = productsResult.documents
                .filter { $0.documentID != "_schema" }
                .prefix(20)
                .map { document in
                    let data = document.data()

                    return AdminMarketplaceProduct(
                        id: document.documentID,
                        sellerId: data["sellerId"] as? String ?? "",
                        sellerName: data["sellerName"] as? String ?? "Vendeur",
                        title: data["title"] as? String ?? "Produit sans titre",
                        category: data["categoryId"] as? String ?? "Catégorie",
                        price: data["price"] as? Double ?? 0,
                        stock: data["stock"] as? Int ?? 0,
                        images: data["imageURLs"] as? [String] ?? [],
                        status: data["status"] as? String ?? "unknown",
                        reported: data["reported"] as? Bool ?? false,
                        views: data["views"] as? Int ?? 0,
                        favorites: data["favorites"] as? Int ?? 0,
                        sales: data["sales"] as? Int ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }

            orders = ordersResult.documents
                .filter { $0.documentID != "_schema" }
                .prefix(20)
                .map { document in
                    let data = document.data()

                    return AdminMarketplaceOrder(
                        id: document.documentID,
                        buyerName: data["buyerName"] as? String ?? "Acheteur",
                        sellerName: data["sellerName"] as? String ?? "Vendeur",
                        total: data["total"] as? Double ?? data["amount"] as? Double ?? 0,
                        commission: data["commission"] as? Double ?? data["platformCommission"] as? Double ?? 0,
                        status: data["status"] as? String ?? "unknown",
                        paymentStatus: data["paymentStatus"] as? String ?? "unknown",
                        deliveryStatus: data["deliveryStatus"] as? String ?? "unknown",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }

            sellers = storesResult.documents
                .filter { $0.documentID != "_schema" }
                .prefix(20)
                .map { document in
                    let data = document.data()

                    return AdminMarketplaceSeller(
                        id: document.documentID,
                        shopName: data["name"] as? String ?? data["shopName"] as? String ?? "Boutique",
                        ownerName: data["ownerName"] as? String ?? data["sellerName"] as? String ?? "Propriétaire",
                        email: data["email"] as? String ?? "",
                        phone: data["phone"] as? String ?? "",
                        country: data["countryCode"] as? String ?? "",
                        city: data["city"] as? String ?? "",
                        verified: data["isVerified"] as? Bool ?? false,
                        suspended: data["isSuspended"] as? Bool ?? false,
                        productsCount: data["productsCount"] as? Int ?? 0,
                        ordersCount: data["ordersCount"] as? Int ?? 0,
                        totalRevenue: data["totalRevenue"] as? Double ?? 0,
                        commissionPaid: data["commissionPaid"] as? Double ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
            
            
            
            
            totalRevenue = ordersResult.documents.reduce(0) { partial, document in
                if document.documentID == "_schema" { return partial }
                return partial + (document.data()["total"] as? Double ?? 0)
            }
            
            totalCommission = ordersResult.documents.reduce(0) { partial, document in
                if document.documentID == "_schema" { return partial }
                return partial + (document.data()["commission"] as? Double ?? 0)
            }
            
            
            
            loading = false
        } catch {
            print("Admin marketplace load error: \(error.localizedDescription)")
            loading = false
        }
        adminAlerts = []

        if totalReports > 0 {
            adminAlerts.append("\(totalReports) signalement(s) à vérifier.")
        }

        if totalDisputes > 0 {
            adminAlerts.append("\(totalDisputes) litige(s) actif(s).")
        }

        if totalAIAlerts > 0 {
            adminAlerts.append("\(totalAIAlerts) alerte(s) IA détectée(s).")
        }

        if totalWithdrawals > 0 {
            adminAlerts.append("\(totalWithdrawals) demande(s) de retrait à surveiller.")
        }

        recentActivity = [
            "Produits actifs : \(totalProducts)",
            "Commandes marketplace : \(totalOrders)",
            "Paiements enregistrés : \(totalPayments)",
            "Tickets support : \(totalSupportTickets)"
        ]

        await loadAdminNotifications()

        loading = false
        
        
    }

    // MARK: - OUTILS

    private func formatEUR(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) €"
    }
    
    
    
}
