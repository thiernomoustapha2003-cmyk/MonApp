//
//  MarketplaceOrdersView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore







struct MarketplaceOrdersView: View {

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedFilter: MarketplaceOrdersFilter = .all
    @State private var searchText = ""
    @State private var animateHeader = false
    
    @State private var showExportSheet = false
    
    
    @State private var orders: [MarketplaceOrderListItem] = []
    @State private var ordersListener: ListenerRegistration?
    @State private var isLoadingOrders = false

    private let db = Firestore.firestore()
    
    private func listenOrders() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isLoadingOrders = true
        ordersListener?.remove()

        ordersListener = db.collection("marketplace_orders")
            .whereFilter(
                Filter.orFilter([
                    Filter.whereField("buyerId", isEqualTo: uid),
                    Filter.whereField("sellerId", isEqualTo: uid)
                ])
            )
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in

                isLoadingOrders = false

                if let error {
                    print("❌ listenOrders:", error.localizedDescription)
                    return
                }

                orders = snapshot?.documents.map { doc in
                    let data = doc.data()

                    let buyerName =
                        data["buyerDisplayName"] as? String ??
                        data["buyerFullName"] as? String ??
                        data["buyerName"] as? String ??
                        data["clientName"] as? String ??
                        "Acheteur Cutly"

                    let sellerName =
                        data["sellerDisplayName"] as? String ??
                        data["sellerFullName"] as? String ??
                        data["sellerName"] as? String ??
                        data["storeName"] as? String ??
                        data["shopName"] as? String ??
                        "Vendeur Cutly"

                    return MarketplaceOrderListItem(
                        id: doc.documentID,
                        orderNumber: data["orderNumber"] as? String ?? "#CMD-\(doc.documentID.prefix(8).uppercased())",
                        buyerId: data["buyerId"] as? String ?? "",
                        sellerId: data["sellerId"] as? String ?? "",
                        buyerName: buyerName,
                        sellerName: sellerName,
                        statusRaw: data["status"] as? String ?? "pendingPayment",
                        itemsCount: data["itemsCount"] as? Int ?? 0,
                        totalText: data["totalText"] as? String ?? "\(data["total"] ?? "") €",
                        shippingMethod: data["shippingMethod"] as? String ?? "Livraison à confirmer",
                        paymentMethod: data["paymentMethod"] as? String ?? "Paiement sécurisé",
                        trackingNumber: data["trackingNumber"] as? String ?? "",
                        pickupCode: data["pickupCode"] as? String ?? "",
                        barcodeValue: data["barcodeValue"] as? String ?? "",
                        createdAt: data["createdAt"] as? Timestamp
                    )
                } ?? []
            }
    }
    private func updateOrderStatus(orderId: String, newStatus: String) {
        db.collection("marketplace_orders")
            .document(orderId)
            .setData([
                "status": newStatus,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if let error {
                    print("❌ updateOrderStatus:", error.localizedDescription)
                }
            }
    }
    
    
    
    
    
    
    

    var body: some View {

        NavigationStack {

            ZStack {

                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {

                    VStack(spacing: 22) {

                        ordersHeroSection
                        ordersStatisticsSection
                        ordersExportPanelSection
                        orderFilterSection
                        ordersPreviewSection
                        Spacer(minLength: 120)

                    }
                    .padding(.vertical,18)

                }

            }
            .navigationTitle("Commandes")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                listenOrders()
            }
            .onDisappear {
                ordersListener?.remove()
            }

        }

    }

}
private extension MarketplaceOrdersView {

    var ordersHeroSection: some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                VStack(alignment: .leading, spacing: 8) {

                    Text("Gestion des commandes")
                        .font(.system(size:30,
                                      weight:.black,
                                      design:.rounded))
                        .foregroundStyle(.white)

                    Text("Toutes tes ventes Marketplace réunies au même endroit.")
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                MarketplaceIconBadge(
                    icon: "shippingbox.fill",
                    size: 62
                )

            }

            HStack(spacing:10){

                MarketplaceOrdersChip(
                    title:"Paiement",
                    icon:"creditcard.fill"
                )

                MarketplaceOrdersChip(
                    title:"Expédition",
                    icon:"truck.box.fill"
                )

                MarketplaceOrdersChip(
                    title:"Protection",
                    icon:"shield.fill"
                )

            }

        }
        .padding(22)
        .background(
            MarketplaceUITheme.darkLuxuryGradient
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: MarketplaceUITheme.cornerXL,
                style:.continuous
            )
        )
        .overlay(
            MarketplaceUITheme.premiumStroke(
                colorScheme: colorScheme,
                cornerRadius: MarketplaceUITheme.cornerXL
            )
        )
        .padding(.horizontal,16)

    }

}
private extension MarketplaceOrdersView {

    var ordersStatisticsSection: some View {

        LazyVGrid(
            columns:[
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing:14
        ){

            MarketplaceOrdersStatCard(
                title:"Commandes",
                value:"\(orders.count)",
                icon:"cart.fill"
            )

            MarketplaceOrdersStatCard(
                title:"En attente",
                value:"\(orders.filter { $0.status == .pendingPayment || $0.status == .paid || $0.status == .preparing }.count)",
                icon:"clock.fill"
            )

            MarketplaceOrdersStatCard(
                title:"Expédiées",
                value:"\(orders.filter { $0.status == .shipped || $0.status == .delivered || $0.status == .completed }.count)",
                icon:"truck.box.fill"
            )

            MarketplaceOrdersStatCard(
                title:"Litiges",
                value:"\(orders.filter { $0.status == .disputed }.count)",
                icon:"exclamationmark.triangle.fill"
            )

        }
        .padding(.horizontal,16)

    }

}
private extension MarketplaceOrdersView {

    var orderFilterSection: some View {

        VStack(spacing:16){

            TextField(
                "Rechercher une commande",
                text:$searchText
            )
            .marketplaceOrdersField()

            ScrollView(.horizontal,showsIndicators:false){

                HStack(spacing:10){

                    ForEach(MarketplaceOrdersFilter.allCases) { filter in
                        Button {
                            withAnimation {
                                selectedFilter = filter
                            }
                        } label: {
                            Text(filter.title)
                                .font(.caption.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    selectedFilter == filter
                                    ? AnyView(MarketplaceUITheme.primaryGradient)
                                    : AnyView(Color.primary.opacity(0.08))
                                )
                                .foregroundStyle(
                                    selectedFilter == filter ? Color.white : Color.primary
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                }

            }

        }
        .padding(.horizontal,16)

    }

}

private extension MarketplaceOrdersView {

    var ordersExportPanelSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Actions vendeur",
                subtitle: "Export, suivi, litiges et préparation Firestore",
                actionTitle: "Exporter",
                action: {
                    showExportSheet = true
                }
            )
            .padding(.horizontal, 0)

            HStack(spacing: 12) {
                MarketplaceOrdersActionCard(title: "Export PDF", icon: "doc.richtext.fill")
                MarketplaceOrdersActionCard(title: "Export Excel", icon: "tablecells.fill")
                MarketplaceOrdersActionCard(title: "Étiquettes", icon: "printer.fill")
            }

            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)

                Text("Commandes prêtes pour Firestore, paiements, suivi colis, retours, litiges et remboursements.")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                Spacer()
            }
            .padding(12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
        .confirmationDialog("Exporter les commandes", isPresented: $showExportSheet) {
            Button("Exporter en PDF") {}
            Button("Exporter en Excel") {}
            Button("Annuler", role: .cancel) {}
        }
    }
}



private extension MarketplaceOrdersView {

    var filteredOrders: [MarketplaceOrderListItem] {
        var result = orders

        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()

            result = result.filter {
                $0.orderNumber.lowercased().contains(query)
                || $0.buyerName.lowercased().contains(query)
                || $0.sellerName.lowercased().contains(query)
                || $0.trackingNumber.lowercased().contains(query)
                || $0.pickupCode.lowercased().contains(query)
            }
        }

        if selectedFilter == .all {
            return result
        }

        return result.filter { $0.status == selectedFilter.orderStatus }
    }

    var ordersPreviewSection: some View {

        VStack(spacing:16){

            if isLoadingOrders {
                ProgressView()
                    .padding()
            } else if filteredOrders.isEmpty {
                MarketplaceOrdersEmptyView()
            } else {
                ForEach(filteredOrders) { order in
                    MarketplaceOrderPremiumCard(
                        order: order,
                        currentUserId: Auth.auth().currentUser?.uid ?? "",
                        onUpdateStatus: { newStatus in
                            updateOrderStatus(orderId: order.id, newStatus: newStatus)
                        }
                    )
                }
            }
        }
        .padding(.horizontal,16)

    }

}
enum MarketplaceOrdersFilter: String, CaseIterable, Identifiable {
    case all
    case pendingPayment
    case paid
    case preparing
    case shipped
    case delivered
    case completed
    case cancelled
    case returnRequested
    case disputed
    case refunded
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .all: return "Toutes"
        case .pendingPayment: return "Paiement"
        case .paid: return "Payées"
        case .preparing: return "Préparation"
        case .shipped: return "Expédiées"
        case .delivered: return "Livrées"
        case .completed: return "Terminées"
        case .cancelled: return "Annulées"
        case .returnRequested: return "Retours"
        case .disputed: return "Litiges"
        case .refunded: return "Remboursées"
        }
    }
    var orderStatus: MarketplaceOrderStatus {
        switch self {
        case .all: return .pendingPayment
        case .pendingPayment: return .pendingPayment
        case .paid: return .paid
        case .preparing: return .preparing
        case .shipped: return .shipped
        case .delivered: return .delivered
        case .completed: return .completed
        case .cancelled: return .cancelled
        case .returnRequested: return .returnRequested
        case .disputed: return .disputed
        case .refunded: return .refunded
        }
    }
    
    
}











private struct MarketplaceOrdersStatCard: View {

    let title:String
    let value:String
    let icon:String

    var body: some View{

        VStack(spacing:10){

            MarketplaceIconBadge(
                icon: icon,
                size:42
            )

            Text(value)
                .font(.system(size:24,
                              weight:.black,
                              design:.rounded))

            Text(title)
                .font(.caption)

        }
        .frame(maxWidth:.infinity,minHeight:120)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius:26,
                style:.continuous
            )
        )

    }

}





private struct MarketplaceOrderPremiumCard: View {
    let order: MarketplaceOrderListItem
    let currentUserId: String
    let onUpdateStatus: (String) -> Void
    
    private var status: MarketplaceOrderStatus {
        order.status
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            timeline
            deliveryPaymentBox
            riskSupportBox
            actionButtons
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
    
    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            MarketplaceIconBadge(icon: "shippingbox.fill", size: 44)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(order.orderNumber)
                    .font(.headline.weight(.black))
                
                Text(order.clientText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Text(status.title)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MarketplaceUITheme.primaryGradient)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Text(order.totalText)
                .font(.system(.headline, design: .rounded).weight(.black))
        }
    }
    
    private var timeline: some View {
        VStack(spacing: 10) {
            MarketplaceOrderTimelineRow(icon: "cart.fill", title: "Commande créée", isDone: true)
            MarketplaceOrderTimelineRow(icon: "creditcard.fill", title: "Paiement confirmé", isDone: status != .pendingPayment)
            MarketplaceOrderTimelineRow(icon: "shippingbox.fill", title: "Préparation", isDone: [.preparing, .shipped, .delivered, .completed].contains(status))
            MarketplaceOrderTimelineRow(icon: "truck.box.fill", title: "Expédition", isDone: [.shipped, .delivered, .completed].contains(status))
            MarketplaceOrderTimelineRow(icon: "checkmark.seal.fill", title: "Livraison", isDone: [.delivered, .completed].contains(status))
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    
    private var deliveryPaymentBox: some View {
        VStack(spacing: 10) {
            MarketplaceOrderInfoRow(
                icon: "globe.europe.africa.fill",
                title: "Livraison",
                value: order.shippingMethod
            )
            
            MarketplaceOrderInfoRow(
                icon: "creditcard.fill",
                title: "Paiement",
                value: order.paymentMethod
            )
            
            MarketplaceOrderInfoRow(
                icon: "qrcode.viewfinder",
                title: "Code retrait",
                value: order.pickupCode.isEmpty ? "Code retrait généré après expédition" : order.pickupCode
            )
        }
    }
    private var riskSupportBox: some View {
        VStack(spacing: 10) {
            MarketplaceOrderInfoRow(
                icon: "arrow.uturn.backward.circle.fill",
                title: "Retours",
                value: "Demande de retour, réception vendeur et inspection produit."
            )
            
            MarketplaceOrderInfoRow(
                icon: "creditcard.trianglebadge.exclamationmark",
                title: "Remboursements",
                value: "Remboursement total ou partiel avec historique de paiement."
            )
            
            MarketplaceOrderInfoRow(
                icon: "exclamationmark.shield.fill",
                title: "Litiges",
                value: "Preuves photo/vidéo, messages, support et décision admin."
            )
        }
    }
    
    
    
    private var actionButtons: some View {
        VStack(spacing: 10) {

            if currentUserId == order.sellerId {
                HStack(spacing: 10) {
                    if status == .paid {
                        Button {
                            onUpdateStatus("preparing")
                        } label: {
                            Label("Préparer", systemImage: "shippingbox.fill")
                        }
                        .buttonStyle(MarketplacePremiumButtonStyle(isFullWidth: false))
                    }

                    if status == .preparing {
                        Button {
                            onUpdateStatus("shipped")
                        } label: {
                            Label("Colis expédié", systemImage: "truck.box.fill")
                        }
                        .buttonStyle(MarketplacePremiumButtonStyle(isFullWidth: false))
                    }

                    if status == .shipped {
                        Button {
                            onUpdateStatus("delivered")
                        } label: {
                            Label("Livré", systemImage: "checkmark.seal.fill")
                        }
                        .buttonStyle(MarketplacePremiumButtonStyle(isFullWidth: false))
                    }
                }
            }

            HStack(spacing: 10) {
                NavigationLink {
                    MarketplaceOrderDetailView(orderId: order.id)
                } label: {
                    Label("Détails", systemImage: "doc.text.fill")
                }
                .buttonStyle(MarketplacePremiumButtonStyle(isFullWidth: false))

                NavigationLink {
                    MarketplaceTrackingView(orderId: order.id)
                } label: {
                    Label("Suivi", systemImage: "location.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }

                NavigationLink {
                    MarketplaceConversationThreadView(
                        conversationId: order.conversationId,
                        productId: "",
                        sellerId: order.sellerId,
                        productTitle: "Commande \(order.orderNumber)"
                    )
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                        .padding(12)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
            }
        }
    }
}

private struct MarketplaceOrderTimelineRow: View {
    let icon: String
    let title: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isDone ? .white : .secondary)
                .frame(width: 30, height: 30)
                .background(isDone ? AnyView(MarketplaceUITheme.primaryGradient) : AnyView(Color.primary.opacity(0.08)))
                .clipShape(Circle())

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(isDone ? .primary : .secondary)

            Spacer()

            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.caption.bold())
                .foregroundStyle(isDone ? .green : .secondary)
        }
    }
}

private struct MarketplaceOrderInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))

                Text(value)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
private extension View {
    func marketplaceOrdersField() -> some View {
        self
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
private struct MarketplaceOrdersActionCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        Button {
        } label: {
            VStack(spacing: 10) {
                MarketplaceIconBadge(icon: icon, size: 38)
                
                Text(title)
                    .font(.caption.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 92)
            .padding(10)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MarketplaceOrdersEmptyView: View {
    var body: some View {
        VStack(spacing: 14) {
            MarketplaceIconBadge(icon: "shippingbox.fill", size: 64)

            Text("Aucune commande")
                .font(.title3.bold())

            Text("Les commandes acheteur, vendeur, paiements, expéditions, retours et litiges apparaîtront ici automatiquement.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

private struct MarketplaceOrdersChip: View {

    let title:String
    let icon:String

    var body: some View{

        HStack(spacing:6){

            Image(systemName:icon)

            Text(title)

        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal,12)
        .padding(.vertical,8)
        .background(.white.opacity(0.12))
        .clipShape(Capsule())

    }

}


struct MarketplaceOrderListItem: Identifiable, Hashable {
    let id: String
    let orderNumber: String
    let buyerId: String
    let sellerId: String
    let buyerName: String
    let sellerName: String
    let statusRaw: String
    let itemsCount: Int
    let totalText: String
    let shippingMethod: String
    let paymentMethod: String
    let trackingNumber: String
    let pickupCode: String
    let barcodeValue: String
    let createdAt: Timestamp?
    
    var status: MarketplaceOrderStatus {
        MarketplaceOrderStatus(rawValue: statusRaw) ?? .pendingPayment
    }
    
    var clientText: String {
        "Client : \(buyerName) • \(itemsCount) article\(itemsCount > 1 ? "s" : "")"
    }
    var conversationId: String {
        [buyerId, sellerId]
            .sorted()
            .joined(separator: "_")
    }
    
}
private struct MarketplaceOrderTrackingView: View {
    let order: MarketplaceOrderListItem

    var body: some View {
        ZStack {
            MarketplaceUITheme.softBackgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    MarketplaceOrderTrackingCard(
                        title: "Suivi colis",
                        value: order.trackingNumber.isEmpty ? "Suivi pas encore disponible" : order.trackingNumber,
                        icon: "location.fill"
                    )

                    MarketplaceOrderTrackingCard(
                        title: "Code retrait",
                        value: order.pickupCode.isEmpty ? "Généré après expédition" : order.pickupCode,
                        icon: "qrcode.viewfinder"
                    )

                    MarketplaceOrderTrackingCard(
                        title: "Code-barres",
                        value: order.barcodeValue.isEmpty ? order.orderNumber : order.barcodeValue,
                        icon: "barcode.viewfinder"
                    )

                    MarketplaceOrderTimelineRow(icon: "cart.fill", title: "Commande créée", isDone: true)
                    MarketplaceOrderTimelineRow(icon: "creditcard.fill", title: "Paiement confirmé", isDone: order.status != .pendingPayment)
                    MarketplaceOrderTimelineRow(icon: "shippingbox.fill", title: "Préparation", isDone: [.preparing, .shipped, .delivered, .completed].contains(order.status))
                    MarketplaceOrderTimelineRow(icon: "truck.box.fill", title: "Expédition", isDone: [.shipped, .delivered, .completed].contains(order.status))
                    MarketplaceOrderTimelineRow(icon: "checkmark.seal.fill", title: "Livraison", isDone: [.delivered, .completed].contains(order.status))
                }
                .padding()
            }
        }
        .navigationTitle("Suivi colis")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MarketplaceOrderTrackingCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            MarketplaceIconBadge(icon: icon, size: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.bold())

                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}






#Preview {
    MarketplaceOrdersView()
}
