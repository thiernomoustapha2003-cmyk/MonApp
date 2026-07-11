//
//  MarketplaceTrackingView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth






struct MarketplaceTrackingView: View {
    let orderId: String
    
    
    
    @Environment(\.colorScheme) private var colorScheme
    
    
    
    
    @State private var animateHeader = false
    @State private var selectedStatus: MarketplaceTrackingStatus = .inTransit
    @State private var showCarrierActions = false
    
    @State private var orderData: [String: Any] = [:]
    @State private var trackingEvents: [[String: Any]] = []
    @State private var isLoadingTracking = false

    private let db = Firestore.firestore()
    
    
    
    
    
    
    private var orderNumber: String {
        orderData["orderNumber"] as? String ?? "#CMD-\(orderId.prefix(8).uppercased())"
    }

    private var carrierName: String {
        orderData["carrierName"] as? String ?? "Transporteur à confirmer"
    }

    private var trackingNumber: String {
        orderData["trackingNumber"] as? String ?? "Suivi pas encore disponible"
    }

    private var pickupCode: String {
        orderData["pickupCode"] as? String ?? "Code retrait généré après expédition"
    }

    private var barcodeValue: String {
        orderData["barcodeValue"] as? String ?? orderNumber
    }

    private var statusRaw: String {
        orderData["status"] as? String ?? "pendingPayment"
    }

    private var orderStatus: MarketplaceOrderStatus {
        MarketplaceOrderStatus(rawValue: statusRaw) ?? .pendingPayment
    }
    
    

    
    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        trackingHeroSection
                        carrierSection
                        trackingMapSection
                        trackingTimelineSection
                        deliveryProofSection
                        localPickupSection
                        trackingActionsSection
                        trackingReadySection
                        Spacer(minLength: 120)
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Suivi colis")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadTracking()
            }
            
            
            
        }
    }
    
    private var trackingHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(orderStatus.title)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("\(orderNumber) • \(carrierName)")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(3)
                }
                
                Spacer()
                
                MarketplaceIconBadge(icon: "location.fill", size: 62)
            }
            
            HStack(spacing: 10) {
                MarketplaceTrackingChip(title: carrierName, icon: "shippingbox.fill")
                MarketplaceTrackingChip(title: trackingNumber, icon: "number")
                MarketplaceTrackingChip(title: orderStatus.title, icon: "truck.box.fill")
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
    
    private var carrierSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Transporteur",
                subtitle: "Informations de suivi et numéro colis",
                actionTitle: "Copier",
                action: {}
            )
            .padding(.horizontal, 0)
            
            MarketplaceTrackingInfoRow(
                icon: "shippingbox.fill",
                title: carrierName,
                subtitle: "Transporteur"
            )

            MarketplaceTrackingInfoRow(
                icon: "number",
                title: trackingNumber,
                subtitle: "Numéro de suivi"
            )

            MarketplaceTrackingInfoRow(
                icon: "calendar",
                title: orderData["estimatedDeliveryText"] as? String ?? "Livraison estimée à confirmer",
                subtitle: orderData["deliveryWindow"] as? String ?? "Délai selon transporteur"
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var trackingMapSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Carte de suivi",
                subtitle: "Position GPS et points de passage",
                actionTitle: "Plein écran",
                action: {}
            )
            .padding(.horizontal, 0)
            
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(MarketplaceUITheme.darkLuxuryGradient)
                    .frame(height: 230)
                
                VStack(spacing: 14) {
                    MarketplaceIconBadge(icon: "map.fill", size: 62)
                    
                    Text("Carte GPS prête")
                        .font(.system(.title3, design: .rounded).weight(.black))
                        .foregroundStyle(.white)
                    
                    Text("MapKit sera branché ensuite avec position colis, agences, relais, hubs et destination.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var trackingTimelineSection: some View {

        VStack(alignment: .leading, spacing: 14) {

            MarketplaceSectionHeader(
                title: "Timeline livraison",
                subtitle: "Historique réel du colis",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)

            if trackingEvents.isEmpty {

                MarketplaceTrackingTimelineRow(
                    icon: "clock.fill",
                    title: "Aucun événement disponible",
                    subtitle: "Le transporteur n'a pas encore transmis d'informations.",
                    isDone: false
                )

            } else {

                ForEach(Array(trackingEvents.enumerated()), id: \.offset) { _, event in

                    MarketplaceTrackingTimelineRow(
                        icon: event["icon"] as? String ?? "shippingbox.fill",
                        title: event["title"] as? String ?? "Événement",
                        subtitle: event["subtitle"] as? String ?? "",
                        isDone: event["isDone"] as? Bool ?? false
                    )

                }

            }

        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
        )
        .padding(.horizontal,16)

    }
    private var deliveryProofSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Preuve de livraison",
                subtitle: "QR Code, signature, photo et validation finale",
                actionTitle: "Scanner",
                action: {}
            )
            .padding(.horizontal, 0)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white)
                        .frame(width: 110, height: 110)

                    Image(systemName: "qrcode")
                        .font(.system(size: 58, weight: .black))
                        .foregroundStyle(.black)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Code retrait sécurisé")
                        .font(.system(.headline, design: .rounded).weight(.black))

                    Text("Code lié à la commande \(orderNumber). Il servira au retrait, à la validation ou à la preuve de livraison.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)

                    Text(pickupCode)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            MarketplaceTrackingInfoRow(
                icon: "signature",
                title: "Signature numérique",
                subtitle: "Prévue pour livraison domicile, agence ou relais partenaire."
            )

            MarketplaceTrackingInfoRow(
                icon: "camera.fill",
                title: "Photo de preuve",
                subtitle: "Le livreur pourra ajouter une photo de dépôt ou de remise."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var localPickupSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Retrait local & Afrique",
                subtitle: "Adapté aux villes sans adresse postale complète",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)

            MarketplaceTrackingInfoRow(
                icon: "building.2.fill",
                title: "Agence locale",
                subtitle: "Retrait possible dans une agence de bus, poste, commerce partenaire ou dépôt local."
            )

            MarketplaceTrackingInfoRow(
                icon: "mappin.and.ellipse",
                title: "Point de repère",
                subtitle: "Ex : près de la mairie, marché central, carrefour principal, mosquée ou station."
            )

            MarketplaceTrackingInfoRow(
                icon: "phone.fill",
                title: "Téléphone obligatoire",
                subtitle: "Le numéro facilite la livraison quand l’adresse n’est pas standardisée."
            )

            MarketplaceTrackingInfoRow(
                icon: "hand.raised.fill",
                title: "Remise en main propre",
                subtitle: "Validation sécurisée dans l’application avec QR Code ou code de confirmation."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    private var trackingActionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showCarrierActions = true
            } label: {
                Label("Actions de suivi", systemImage: "ellipsis.circle.fill")
            }
            .buttonStyle(MarketplacePremiumButtonStyle())

            Button {
            } label: {
                Label("Recevoir les notifications", systemImage: "bell.badge.fill")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.primary)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button {
            } label: {
                Label("Partager le suivi", systemImage: "square.and.arrow.up")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.primary)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .confirmationDialog("Actions de suivi", isPresented: $showCarrierActions) {
            Button("Copier le numéro de suivi") {
                UIPasteboard.general.string = trackingNumber
            }

            Button("Ouvrir le site transporteur") {
                if let urlString = orderData["carrierTrackingURL"] as? String,
                   let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            }

            Button("Signaler un problème de livraison") {
                createTrackingIssue()
            }

            Button("Contacter le vendeur") {
                openSellerConversation()
            }

            Button("Contacter le transporteur") {
                if let phone = orderData["carrierPhone"] as? String,
                   let url = URL(string: "tel://\(phone)") {
                    UIApplication.shared.open(url)
                }
            }

            Button("Annuler", role: .cancel) {}
        }
    }

    private var trackingReadySection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.green)

            Text("Suivi colis prêt pour Firestore, transporteurs, GPS, QR Code, preuve de livraison, signature et notifications.")
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
    private func loadTracking() {
        guard !orderId.isEmpty else { return }

        isLoadingTracking = true

        db.collection("marketplace_orders")
            .document(orderId)
            .getDocument { snapshot, error in
                isLoadingTracking = false

                if let error {
                    print("❌ loadTracking order:", error.localizedDescription)
                    return
                }

                orderData = snapshot?.data() ?? [:]
            }

        db.collection("marketplace_tracking_events")
            .whereField("orderId", isEqualTo: orderId)
            .order(by: "createdAt", descending: false)
            .getDocuments { snapshot, error in
                if let error {
                    print("❌ loadTracking events:", error.localizedDescription)
                    return
                }

                trackingEvents = snapshot?.documents.map { $0.data() } ?? []
            }
    }
    private func createTrackingIssue() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("marketplace_delivery_issues")
            .document()
            .setData([
                "userId": uid,
                "orderId": orderId,
                "orderNumber": orderNumber,
                "trackingNumber": trackingNumber,
                "carrierName": carrierName,
                "status": "open",
                "priority": "normal",
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)
    }
    private func openSellerConversation() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let sellerId = orderData["sellerId"] as? String ?? ""
        guard !sellerId.isEmpty else { return }

        let conversationId = [uid, sellerId]
            .sorted()
            .joined(separator: "_")

        db.collection("marketplace_conversations")
            .document(conversationId)
            .setData([
                "id": conversationId,
                "participantIds": [uid, sellerId],
                "buyerId": orderData["buyerId"] as? String ?? uid,
                "sellerId": sellerId,
                "orderId": orderId,
                "orderNumber": orderNumber,
                "type": "buyerSeller",
                "source": "tracking",
                "lastMessageText": "Conversation ouverte depuis le suivi colis.",
                "lastMessageAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)
    }
    
    
    
    
    
    
    
    
    
    
    
}

// MARK: - Components

private struct MarketplaceTrackingChip: View {
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

private struct MarketplaceTrackingInfoRow: View {
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

private struct MarketplaceTrackingTimelineRow: View {
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





#Preview {
    MarketplaceTrackingView(orderId: "preview_order")
}
