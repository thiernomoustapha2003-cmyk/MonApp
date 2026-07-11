//
//  MarketplaceOrderDetailView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI






struct MarketplaceOrderDetailView: View {
    let orderId: String
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var animateHeader = false
    @State private var showActionSheet = false
    @State private var orderData: [String: Any] = [:]
    @State private var orderItems: [[String: Any]] = []
    @State private var isLoadingOrder = false
    
    private let db = Firestore.firestore()
    
    @State private var showContactSheet = false
    @State private var showRefundSheet = false
    @State private var showDisputeSheet = false
    @State private var showProofPicker = false
    @State private var isExportingReceipt = false

    @State private var isUpdatingOrder = false
    
    @State private var showReviewSheet = false
    @State private var hasAlreadyReviewed = false
    
    
    
    
    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    private var buyerId: String {
        orderData["buyerId"] as? String ?? ""
    }

    private var sellerId: String {
        orderData["sellerId"] as? String ?? ""
    }

    private var canLeaveReview: Bool {
        currentUserId == buyerId && (status == .delivered || status == .completed) && !hasAlreadyReviewed
    }

    private var mainProductId: String {
        orderItems.first?["productId"] as? String
        ?? orderData["productId"] as? String
        ?? ""
    }

    private var mainProductTitle: String {
        orderItems.first?["title"] as? String
        ?? orderData["productTitle"] as? String
        ?? "Produit Marketplace"
    }
    
    private var orderNumber: String {
        orderData["orderNumber"] as? String ?? "#CMD-\(orderId.prefix(8).uppercased())"
    }

    private var statusRaw: String {
        orderData["status"] as? String ?? "pendingPayment"
    }

    private var status: MarketplaceOrderStatus {
        MarketplaceOrderStatus(rawValue: statusRaw) ?? .pendingPayment
    }

    private var buyerName: String {
        orderData["buyerName"] as? String ?? "Acheteur Marketplace"
    }

    private var itemsCount: Int {
        orderData["itemsCount"] as? Int ?? orderItems.count
    }

    private var totalText: String {
        cutlyOrderPriceText(orderData["totalText"] as? String ?? "\(orderData["total"] ?? "") €")
    }

    private var shippingText: String {
        orderData["shippingMethod"] as? String ?? "Livraison à confirmer"
    }

    private var paymentText: String {
        orderData["paymentMethod"] as? String ?? "Paiement sécurisé"
    }

    private var pickupCode: String {
        orderData["pickupCode"] as? String ?? "Code retrait généré après expédition"
    }

    private var trackingNumber: String {
        orderData["trackingNumber"] as? String ?? "Suivi pas encore disponible"
    }
    
    
    
    
    
    
    
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        orderHeroSection
                        buyerSection
                        orderedItemsSection
                        orderTimelineSection
                        deliveryTrackingSection
                        returnsDisputesSection
                        proofSupportSection
                        paymentSummarySection
                        orderReadySection
                        finalActionsSection
                        Spacer(minLength: 120)
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Détail commande")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadOrderDetail()
            }
            .sheet(isPresented: $showContactSheet) {
                MarketplaceOrderContactBuyerSheet(
                    orderId: orderId,
                    buyerId: orderData["buyerId"] as? String ?? "",
                    sellerId: orderData["sellerId"] as? String ?? "",
                    orderNumber: orderNumber
                )
            }

            .sheet(isPresented: $showDisputeSheet) {
                MarketplaceOrderDisputeSheet(
                    orderId: orderId,
                    orderNumber: orderNumber
                )
            }

            .sheet(isPresented: $showRefundSheet) {
                MarketplaceOrderRefundSheet(
                    orderId: orderId,
                    orderNumber: orderNumber,
                    totalText: totalText
                )
            }

            .sheet(isPresented: $isExportingReceipt) {
                MarketplaceOrderReceiptSheet(
                    orderId: orderId,
                    orderNumber: orderNumber,
                    buyerName: buyerName,
                    totalText: totalText,
                    paymentText: paymentText,
                    trackingNumber: trackingNumber,
                    pickupCode: pickupCode
                )
            }
            .sheet(isPresented: $showProofPicker) {
                MarketplaceOrderProofSheet(
                    orderId: orderId,
                    orderNumber: orderNumber
                )
            }
            .sheet(isPresented: $showReviewSheet) {
                MarketplaceLeaveReviewSheet(
                    orderId: orderId,
                    productId: mainProductId,
                    productTitle: mainProductTitle,
                    sellerId: sellerId
                ) {
                    hasAlreadyReviewed = true
                }
            }
            
            
            
        }
    }
    
    private var orderHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(orderNumber)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("\(status.title) • \(itemsCount) article\(itemsCount > 1 ? "s" : "")")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                }
                
                Spacer()
                
                MarketplaceIconBadge(icon: "shippingbox.fill", size: 62)
            }
            
            HStack(spacing: 10) {
                MarketplaceOrderDetailChip(title: status.title, icon: "creditcard.fill")
                MarketplaceOrderDetailChip(title: shippingText, icon: "shippingbox.fill")
                MarketplaceOrderDetailChip(title: "Protégée", icon: "shield.fill")
            }
        }
        .padding(22)
        .background(MarketplaceUITheme.darkLuxuryGradient)
        .clipShape(RoundedRectangle(cornerRadius: MarketplaceUITheme.cornerXL, style: .continuous))
        .overlay(MarketplaceUITheme.premiumStroke(colorScheme: colorScheme, cornerRadius: MarketplaceUITheme.cornerXL))
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 16)
        .padding(.horizontal, 16)
        .scaleEffect(animateHeader ? 1 : 0.97)
        .opacity(animateHeader ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                animateHeader = true
            }
        }
    }
    
    private var buyerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Acheteur",
                subtitle: "Informations nécessaires pour livraison et support",
                actionTitle: "Message",
                action: {}
            )
            .padding(.horizontal, 0)
            
            MarketplaceOrderDetailInfoRow(
                icon: "person.fill",
                title: buyerName,
                subtitle: orderData["buyerCountry"] as? String ?? "Acheteur CutLy Marketplace"
            )
            
            MarketplaceOrderDetailInfoRow(
                icon: "phone.fill",
                title: orderData["buyerPhoneMasked"] as? String ?? "Téléphone masqué",
                subtitle: "Confidentialité protégée"
            )
            
            MarketplaceOrderDetailInfoRow(
                icon: "mappin.and.ellipse",
                title: orderData["deliveryAddressTitle"] as? String ?? "Adresse flexible",
                subtitle: orderData["deliveryAddressSubtitle"] as? String ?? "Adresse complète, point relais, GPS ou point de repère selon le pays"
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var orderedItemsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Articles commandés",
                subtitle: "Produits, variantes, prix et quantités",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)
            
            ForEach(orderItems.indices, id: \.self) { index in

                let item = orderItems[index]

                MarketplaceOrderDetailProductRow(
                    title: item["title"] as? String ?? "Produit Marketplace",
                    subtitle: "\(item["variant"] as? String ?? "") • Quantité \(item["quantity"] as? Int ?? 1)",
                    price: cutlyOrderPriceText(
                        item["priceText"] as? String
                        ?? "\(item["price"] as? Double ?? 0) €"
                    ),
                    icon: "bag.fill"
                )
            }

            if orderItems.isEmpty {

                MarketplaceOrderDetailInfoRow(
                    icon: "shippingbox.fill",
                    title: "Articles",
                    subtitle: "Les produits de cette commande apparaîtront automatiquement."
                )

            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var orderTimelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Timeline commande",
                subtitle: "Chaque étape importante de la commande",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)
            
            MarketplaceOrderDetailTimelineRow(icon: "cart.fill", title: "Commande créée", subtitle: orderData["createdAtText"] as? String ?? "Date à confirmer", isDone: true)

            MarketplaceOrderDetailTimelineRow(icon: "creditcard.fill", title: "Paiement confirmé", subtitle: paymentText, isDone: status != .pendingPayment)

            MarketplaceOrderDetailTimelineRow(icon: "shippingbox.fill", title: "Préparation vendeur", subtitle: "Le vendeur prépare les articles", isDone: [.preparing, .shipped, .delivered, .completed].contains(status))

            MarketplaceOrderDetailTimelineRow(icon: "truck.box.fill", title: "Expédition", subtitle: trackingNumber, isDone: [.shipped, .delivered, .completed].contains(status))

            MarketplaceOrderDetailTimelineRow(icon: "checkmark.seal.fill", title: "Livraison", subtitle: status == .completed ? "Commande terminée" : "En attente", isDone: [.delivered, .completed].contains(status))
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var deliveryTrackingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Livraison & suivi",
                subtitle: "Transporteurs internationaux et solutions locales",
                actionTitle: "Ouvrir suivi",
                action: {}
            )
            .padding(.horizontal, 0)
            
            MarketplaceOrderDetailInfoRow(
                icon: "truck.box.fill",
                title: orderData["carrierName"] as? String ?? "Transporteur à confirmer",
                subtitle: trackingNumber
            )

            MarketplaceOrderDetailInfoRow(
                icon: "mappin.and.ellipse",
                title: orderData["deliveryType"] as? String ?? "Mode de livraison",
                subtitle: shippingText
            )

            MarketplaceOrderDetailInfoRow(
                icon: "qrcode.viewfinder",
                title: "Code retrait / QR",
                subtitle: pickupCode
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    private var returnsDisputesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Retours, remboursements & litiges",
                subtitle: "Gestion complète après achat",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)
            
            MarketplaceOrderDetailInfoRow(
                icon: "arrow.uturn.backward.circle.fill",
                title: "Retour produit",
                subtitle: "Demande de retour, validation vendeur, retour expédié, réception et inspection."
            )
            
            MarketplaceOrderDetailInfoRow(
                icon: "creditcard.trianglebadge.exclamationmark",
                title: "Remboursement",
                subtitle: "Remboursement total ou partiel selon paiement, preuve et décision."
            )
            
            MarketplaceOrderDetailInfoRow(
                icon: "exclamationmark.shield.fill",
                title: "Litige sécurisé",
                subtitle: "Messages, preuves, support Cutly, décision admin et historique complet."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var proofSupportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Preuves & support",
                subtitle: "Photos, vidéos, documents et contact acheteur",
                actionTitle: "Support",
                action: {}
            )
            .padding(.horizontal, 0)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                MarketplaceOrderDetailActionCard(title: "Ajouter preuve", icon: "photo.badge.plus") {
                    showProofPicker = true
                }

                MarketplaceOrderDetailActionCard(title: "Contacter acheteur", icon: "bubble.left.and.bubble.right.fill") {
                    showContactSheet = true
                }

                MarketplaceOrderDetailActionCard(title: "Créer litige", icon: "exclamationmark.triangle.fill") {
                    showDisputeSheet = true
                }

                MarketplaceOrderDetailActionCard(title: "Rembourser", icon: "creditcard.fill") {
                    showRefundSheet = true
                }
            }
            
            MarketplaceOrderDetailInfoRow(
                icon: "brain.head.profile",
                title: "Analyse IA",
                subtitle: "Détection commandes suspectes, remboursements abusifs, faux acheteurs et litiges anormaux."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var paymentSummarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Paiement",
                subtitle: "Montants, frais et commission Cutly",
                actionTitle: "Reçu",
                action: {}
            )
            .padding(.horizontal, 0)
            
            MarketplaceOrderDetailAmountRow(
                title: "Sous-total",
                amount: cutlyOrderPriceText(orderData["subtotalText"] as? String ?? "\(orderData["subtotal"] ?? "") €")
            )

            MarketplaceOrderDetailAmountRow(
                title: "Livraison",
                amount: cutlyOrderPriceText(orderData["shippingFeeText"] as? String ?? "\(orderData["shippingFee"] ?? "") €")
            )

            MarketplaceOrderDetailAmountRow(
                title: "Frais / taxes",
                amount: cutlyOrderPriceText(orderData["taxesText"] as? String ?? "\(orderData["taxes"] ?? "") €")
            )

            MarketplaceOrderDetailAmountRow(
                title: "Total payé",
                amount: totalText,
                isTotal: true
            )
            
            MarketplaceOrderDetailInfoRow(
                icon: "creditcard.fill",
                title: "Paiement sécurisé",
                subtitle: paymentText
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    
    private var orderReadySection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.green)
            
            Text("Commande prête avec paiement sécurisé, suivi colis, preuves, litiges, remboursements et support.")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .lineLimit(4)
            
            Spacer()
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
    }
    private var finalActionsSection: some View {
        VStack(spacing: 12) {

            if canLeaveReview {
                Button {
                    showReviewSheet = true
                } label: {
                    Label("Laisser un avis", systemImage: "star.fill")
                }
                .buttonStyle(MarketplacePremiumButtonStyle())
            }

            Button {
                showActionSheet = true
            } label: {
                Label("Actions de commande", systemImage: "ellipsis.circle.fill")
            }
            .buttonStyle(MarketplacePremiumButtonStyle())

            NavigationLink {
                MarketplaceTrackingView(orderId: orderId)
            } label: {
                Label("Ouvrir le suivi colis", systemImage: "location.fill")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.primary)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .confirmationDialog("Actions de commande", isPresented: $showActionSheet) {
            Button("Contacter l’acheteur") {
                showContactSheet = true
            }

            Button("Ajouter une preuve") {
                showProofPicker = true
            }

            Button("Créer un litige") {
                showDisputeSheet = true
            }

            Button("Rembourser") {
                showRefundSheet = true
            }

            Button("Exporter le reçu") {
                isExportingReceipt = true
            }

            Button("Annuler", role: .cancel) { }
        }
    }
    private func loadOrderDetail() {
        guard !orderId.isEmpty else { return }

        isLoadingOrder = true

        db.collection("marketplace_orders")
            .document(orderId)
            .getDocument { snapshot, error in
                isLoadingOrder = false

                if let error {
                    print("❌ loadOrderDetail:", error.localizedDescription)
                    return
                }

                orderData = snapshot?.data() ?? [:]
                checkReviewStatus()
                
            }

        db.collection("marketplace_order_items")
            .whereField("orderId", isEqualTo: orderId)
            .getDocuments { snapshot, error in
                if let error {
                    print("❌ loadOrderItems:", error.localizedDescription)
                    return
                }

                orderItems = snapshot?.documents.map { $0.data() } ?? []
            }
    }
    private func checkReviewStatus() {
        guard !currentUserId.isEmpty else { return }
        guard !mainProductId.isEmpty else { return }

        let reviewId = "\(orderId)_\(mainProductId)_\(currentUserId)"

        db.collection("marketplace_reviews")
            .document(reviewId)
            .getDocument { snapshot, _ in
                hasAlreadyReviewed = snapshot?.exists == true
            }
    }
    
    
    
  
    
    
    
    
    
}


// MARK: - Components

private struct MarketplaceOrderDetailChip: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.14))
        .clipShape(Capsule())
    }
}

private struct MarketplaceOrderDetailInfoRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct MarketplaceOrderDetailProductRow: View {
    let title: String
    let subtitle: String
    let price: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MarketplaceUITheme.primaryGradient)
                .frame(width: 58, height: 58)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(price)
                .font(.headline.weight(.black))
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct MarketplaceOrderDetailAmountRow: View {
    let title: String
    let amount: String
    var isTotal: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? .headline.weight(.black) : .subheadline.weight(.semibold))
                .foregroundStyle(isTotal ? .primary : .secondary)

            Spacer()

            Text(amount)
                .font(isTotal ? .headline.weight(.black) : .subheadline.weight(.bold))
        }
        .padding(.vertical, 6)
    }
}
private struct MarketplaceOrderDetailTimelineRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isDone: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isDone ? .white : .secondary)
                .frame(width: 32, height: 32)
                .background(isDone ? AnyView(MarketplaceUITheme.primaryGradient) : AnyView(Color.primary.opacity(0.08)))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.caption.bold())
                .foregroundStyle(isDone ? .green : .secondary)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
private struct MarketplaceOrderDetailActionCard: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                MarketplaceIconBadge(icon: icon, size: 42)

                Text(title)
                    .font(.caption.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 112)
            .padding(12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}


private struct MarketplaceOrderContactBuyerSheet: View {
    let orderId: String
    let buyerId: String
    let sellerId: String
    let orderNumber: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                MarketplaceIconBadge(icon: "bubble.left.and.bubble.right.fill", size: 70)

                Text("Contacter l’acheteur")
                    .font(.title2.bold())

                Text("Une conversation CutLy Marketplace sera ouverte pour la commande \(orderNumber).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                NavigationLink {
                    MarketplaceConversationThreadView(
                        conversationId: [buyerId, sellerId].sorted().joined(separator: "_"),
                        productId: "",
                        sellerId: sellerId,
                        productTitle: "Commande \(orderNumber)"
                    )
                } label: {
                    Label("Ouvrir la conversation", systemImage: "message.fill")
                }
                .buttonStyle(MarketplacePremiumButtonStyle())

                Spacer()
            }
            .padding()
            .navigationTitle("Message")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
private struct MarketplaceOrderDisputeSheet: View {
    let orderId: String
    let orderNumber: String

    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var isSending = false

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                MarketplaceIconBadge(icon: "exclamationmark.shield.fill", size: 70)

                Text("Créer un litige")
                    .font(.title2.bold())

                TextField("Explique le problème...", text: $reason, axis: .vertical)
                    .lineLimit(5)
                    .padding(14)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Button {
                    createDispute()
                } label: {
                    Label(isSending ? "Envoi..." : "Créer le litige", systemImage: "paperplane.fill")
                }
                .buttonStyle(MarketplacePremiumButtonStyle())
                .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)

                Spacer()
            }
            .padding()
            .navigationTitle("Litige")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func createDispute() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSending = true

        db.collection("marketplace_disputes").document().setData([
            "orderId": orderId,
            "orderNumber": orderNumber,
            "createdBy": uid,
            "reason": reason,
            "status": "open",
            "priority": "high",
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true) { _ in
            isSending = false
            dismiss()
        }
    }
}
private struct MarketplaceOrderRefundSheet: View {

    let orderId: String
    let orderNumber: String
    let totalText: String

    @Environment(\.dismiss) private var dismiss

    @State private var reason = ""
    @State private var isSending = false

    private let db = Firestore.firestore()

    var body: some View {

        NavigationStack {

            VStack(spacing:20){

                MarketplaceIconBadge(
                    icon: "creditcard.arrow.counterclockwise",
                    size:70
                )

                Text("Demande de remboursement")
                    .font(.title2.bold())

                Text("Montant : \(totalText)")
                    .font(.headline)

                TextField(
                    "Motif du remboursement",
                    text:$reason,
                    axis:.vertical
                )
                .lineLimit(5)
                .padding(14)
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:18,
                        style:.continuous
                    )
                )

                Button {

                    requestRefund()

                } label: {

                    Label(
                        isSending
                        ? "Envoi..."
                        : "Envoyer la demande",
                        systemImage:"arrow.uturn.backward.circle.fill"
                    )

                }
                .buttonStyle(MarketplacePremiumButtonStyle())
                .disabled(
                    reason
                        .trimmingCharacters(in:.whitespacesAndNewlines)
                        .isEmpty
                    || isSending
                )

                Spacer()

            }
            .padding()
            .navigationTitle("Remboursement")
            .navigationBarTitleDisplayMode(.inline)

        }

    }

    private func requestRefund() {

        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        isSending = true

        db.collection("marketplace_refunds")
            .document()
            .setData([

                "orderId":orderId,
                "orderNumber":orderNumber,
                "userId":uid,
                "reason":reason,
                "amountText":totalText,

                "status":"pending",

                "createdAt":FieldValue.serverTimestamp()

            ]) { error in

                isSending = false

                if error == nil {
                    dismiss()
                }

            }

    }

}
private struct MarketplaceOrderReceiptSheet: View {
    let orderId: String
    let orderNumber: String
    let buyerName: String
    let totalText: String
    let paymentText: String
    let trackingNumber: String
    let pickupCode: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    MarketplaceIconBadge(icon: "doc.richtext.fill", size: 70)

                    Text("Reçu Cutly Market")
                        .font(.title2.bold())

                    Text("Le PDF officiel de commande est généré automatiquement côté serveur et envoyé par e-mail à l’acheteur après validation de la commande.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 12) {
                        MarketplaceOrderDetailAmountRow(title: "Commande", amount: orderNumber)
                        MarketplaceOrderDetailAmountRow(title: "Acheteur", amount: buyerName)
                        MarketplaceOrderDetailAmountRow(title: "Paiement", amount: paymentText)
                        MarketplaceOrderDetailAmountRow(title: "Suivi", amount: trackingNumber)
                        MarketplaceOrderDetailAmountRow(title: "Code retrait", amount: pickupCode)
                        MarketplaceOrderDetailAmountRow(title: "Total payé", amount: totalText, isTotal: true)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    MarketplaceOrderDetailInfoRow(
                        icon: "envelope.fill",
                        title: "E-mail automatique",
                        subtitle: "L’acheteur reçoit le reçu PDF sur l’adresse enregistrée dans l’application."
                    )

                    MarketplaceOrderDetailInfoRow(
                        icon: "qrcode.viewfinder",
                        title: "QR / code-barres",
                        subtitle: "Les codes sont générés côté backend pour le retrait, le suivi et la preuve de commande."
                    )

                    MarketplaceOrderDetailInfoRow(
                        icon: "shippingbox.fill",
                        title: "Bon vendeur",
                        subtitle: "Le vendeur recevra aussi les informations nécessaires pour préparer le colis."
                    )

                    Button {
                        dismiss()
                    } label: {
                        Label("Fermer", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(MarketplacePremiumButtonStyle())
                }
                .padding()
            }
            .navigationTitle("Reçu")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
private struct MarketplaceOrderProofSheet: View {
    let orderId: String
    let orderNumber: String

    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var note = ""

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                MarketplaceIconBadge(icon: "photo.badge.plus", size: 70)

                Text("Ajouter une preuve")
                    .font(.title2.bold())

                TextField("Note ou description de la preuve", text: $note, axis: .vertical)
                    .lineLimit(4)
                    .padding(14)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                    Label("Choisir photo ou vidéo", systemImage: "photo.on.rectangle.angled")
                }
                .buttonStyle(MarketplacePremiumButtonStyle())

                if isUploading {
                    ProgressView("Envoi de la preuve...")
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Preuve")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItem) { newItem in
                uploadProof(item: newItem)
            }
        }
    }

    private func uploadProof(item: PhotosPickerItem?) {
        guard let item else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isUploading = true

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    await MainActor.run { isUploading = false }
                    return
                }

                let proofId = UUID().uuidString
                let ref = storage.reference()
                    .child("marketplaceOrders")
                    .child(uid)
                    .child(orderId)
                    .child("proofs")
                    .child("\(proofId).bin")

                _ = try await ref.putDataAsync(data)
                let url = try await ref.downloadURL()

                try await db.collection("marketplace_evidence")
                    .document(proofId)
                    .setData([
                        "id": proofId,
                        "orderId": orderId,
                        "orderNumber": orderNumber,
                        "userId": uid,
                        "fileURL": url.absoluteString,
                        "note": note,
                        "type": "proof",
                        "status": "active",
                        "createdAt": FieldValue.serverTimestamp()
                    ])

                await MainActor.run {
                    isUploading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                }
                print("❌ uploadProof:", error.localizedDescription)
            }
        }
    }
}
private struct MarketplaceLeaveReviewSheet: View {
    let orderId: String
    let productId: String
    let productTitle: String
    let sellerId: String
    let onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var rating: Int = 5
    @State private var comment = ""
    @State private var isSending = false
    @State private var errorMessage = ""

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                MarketplaceIconBadge(icon: "star.fill", size: 70)

                Text("Laisser un avis")
                    .font(.title2.bold())

                Text(productTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            rating = star
                        } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                    }
                }

                TextField("Ton avis sur le produit...", text: $comment, axis: .vertical)
                    .lineLimit(4...7)
                    .padding(14)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }

                Button {
                    submitReview()
                } label: {
                    Label(isSending ? "Envoi..." : "Publier l’avis", systemImage: "paperplane.fill")
                }
                .disabled(isSending || comment.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
                .buttonStyle(MarketplacePremiumButtonStyle())

                Spacer()
            }
            .padding()
            .navigationTitle("Avis")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func submitReview() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard !productId.isEmpty, !sellerId.isEmpty else {
            errorMessage = "Produit ou vendeur introuvable."
            return
        }

        isSending = true

        let cleanComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        let reviewId = "\(orderId)_\(productId)_\(uid)"

        let reviewData: [String: Any] = [
            "id": reviewId,
            "orderId": orderId,
            "productId": productId,
            "productTitle": productTitle,
            "sellerId": sellerId,
            "buyerId": uid,
            "buyerName": Auth.auth().currentUser?.displayName ?? "Acheteur Cutly",
            "rating": rating,
            "comment": cleanComment,
            "status": "active",
            "sellerReply": "",
            "sellerReplyAt": NSNull(),
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("marketplace_reviews")
            .document(reviewId)
            .setData(reviewData, merge: true) { error in
                if let error {
                    isSending = false
                    errorMessage = error.localizedDescription
                    return
                }

                db.collection("marketplace_notifications")
                    .document()
                    .setData([
                        "userId": sellerId,
                        "senderId": uid,
                        "type": "new_review",
                        "title": "Nouvel avis reçu",
                        "body": "Un acheteur a laissé \(rating) étoile(s) sur \(productTitle).",
                        "productId": productId,
                        "orderId": orderId,
                        "isRead": false,
                        "createdAt": FieldValue.serverTimestamp()
                    ], merge: true)

                isSending = false
                onSuccess()
                dismiss()
            }
    }
}
private func cutlyOrderPriceText(_ text: String) -> String {
    let cleaned = text
        .replacingOccurrences(of: "EUR", with: "")
        .replacingOccurrences(of: "Euro", with: "")
        .replacingOccurrences(of: "€", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: ",", with: ".")

    guard let value = Double(cleaned) else {
        return text.replacingOccurrences(of: "EUR", with: "€")
    }

    if value.truncatingRemainder(dividingBy: 1) == 0 {
        return "\(Int(value)) €"
    }

    return String(format: "%.2f €", value).replacingOccurrences(of: ".", with: ",")
}




#Preview {
    MarketplaceOrderDetailView(orderId: "preview_order")
}
