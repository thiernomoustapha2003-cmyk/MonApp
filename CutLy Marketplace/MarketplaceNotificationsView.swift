//
//  MarketplaceNotificationsView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore




struct MarketplaceNotificationsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedFilter: MarketplaceNotificationFilter = .all
    @State private var animateHeader = false
    
    
    @State private var showSettingsSheet = false
    @State private var notifications: [MarketplaceNotificationItem] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var listener: ListenerRegistration?
    
    
    
    
    
    private let filters: [MarketplaceNotificationFilter] = [
        .all, .orders, .payments, .shipping, .messages, .disputes, .ai
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        notificationsHeroSection
                        notificationActionsSection
                        filtersSection
                        notificationsListSection
                        notificationsReadySection
                        Spacer(minLength: 120)
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                listenNotifications()
            }
            .onDisappear {
                listener?.remove()
            }
        }
    }
    
    private var notificationsHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notifications Marketplace")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Commandes, paiements, livraison, messages, litiges et alertes IA.")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(3)
                }
                
                Spacer()
                
                MarketplaceIconBadge(icon: "bell.badge.fill", size: 62)
            }
            
            HStack(spacing: 10) {
                MarketplaceNotificationChip(title: "Commandes", icon: "cart.fill")
                MarketplaceNotificationChip(title: "Paiements", icon: "creditcard.fill")
                MarketplaceNotificationChip(title: "IA", icon: "brain.head.profile")
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
    
    private var notificationActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Actions rapides",
                subtitle: "Gère les alertes importantes de la Marketplace",
                actionTitle: "Paramètres",
                action: {
                    showSettingsSheet = true
                }
            )
            .padding(.horizontal, 0)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                MarketplaceNotificationActionCard(title: "Tout marquer lu", icon: "checkmark.circle.fill")
                MarketplaceNotificationActionCard(title: "Alertes paiement", icon: "creditcard.fill")
                MarketplaceNotificationActionCard(title: "Alertes livraison", icon: "shippingbox.fill")
                MarketplaceNotificationActionCard(title: "Alertes sécurité IA", icon: "brain.head.profile")
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
        .sheet(isPresented: $showSettingsSheet) {
            MarketplaceNotificationSettingsSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    
    private var filtersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(filters) { filter in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            selectedFilter = filter
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: filter.icon)
                            Text(filter.title)
                        }
                        .font(.caption.bold())
                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            selectedFilter == filter
                            ? AnyView(MarketplaceUITheme.primaryGradient)
                            : AnyView(Color.primary.opacity(0.06))
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var notificationsListSection: some View {
        VStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .padding()
            } else if filteredNotifications.isEmpty {
                MarketplaceNotificationEmptyView()
            } else {
                ForEach(filteredNotifications) { item in
                    MarketplaceNotificationPremiumCard(item: item) {
                        markAsRead(item)
                    }
                }
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption.bold())
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var notificationsReadySection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.green)
            
            Text("Notifications prêtes pour Firestore, push, commandes, paiements, livraison, Mobile Money, litiges, messages et alertes IA.")
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
    private var filteredNotifications: [MarketplaceNotificationItem] {
        switch selectedFilter {
        case .all:
            return notifications
        case .orders:
            return notifications.filter { $0.type.contains("order") }
        case .payments:
            return notifications.filter { $0.type.contains("payment") || $0.type.contains("paid") }
        case .shipping:
            return notifications.filter { $0.type.contains("shipping") || $0.type.contains("shipment") }
        case .messages:
            return notifications.filter { $0.type.contains("message") }
        case .disputes:
            return notifications.filter { $0.type.contains("dispute") || $0.type.contains("refund") }
        case .ai:
            return notifications.filter { $0.type.contains("ai") || $0.type.contains("security") || $0.type.contains("favorite") }
        }
    }

    private func listenNotifications() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        listener?.remove()

        listener = Firestore.firestore()
            .collection("marketplace_notifications")
            .whereField("userId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 80)
            .addSnapshotListener { snapshot, error in
                isLoading = false

                if let error {
                    errorMessage = error.localizedDescription
                    print("❌ listenNotifications:", error.localizedDescription)
                    return
                }

                notifications = snapshot?.documents.map { doc in
                    let data = doc.data()

                    return MarketplaceNotificationItem(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "Notification Cutly",
                        body: data["body"] as? String ?? "",
                        type: data["type"] as? String ?? "general",
                        targetId: data["targetId"] as? String ?? data["productId"] as? String ?? data["conversationId"] as? String ?? "",
                        targetType: data["targetType"] as? String ?? "",
                        isRead: data["isRead"] as? Bool ?? false,
                        createdAt: data["createdAt"] as? Timestamp,
                        priority: data["priority"] as? String ?? "normal"
                    )
                } ?? []
            }
    }

    private func markAsRead(_ item: MarketplaceNotificationItem) {
        guard !item.isRead else { return }

        Firestore.firestore()
            .collection("marketplace_notifications")
            .document(item.id)
            .setData([
                "isRead": true,
                "readAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }
    
    
    
    
    
    
    
    
}

// MARK: - Filter

enum MarketplaceNotificationFilter: String, CaseIterable, Identifiable {
    case all
    case orders
    case payments
    case shipping
    case messages
    case disputes
    case ai

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Toutes"
        case .orders: return "Commandes"
        case .payments: return "Paiements"
        case .shipping: return "Livraison"
        case .messages: return "Messages"
        case .disputes: return "Litiges"
        case .ai: return "IA"
        }
    }

    var icon: String {
        switch self {
        case .all: return "bell.fill"
        case .orders: return "cart.fill"
        case .payments: return "creditcard.fill"
        case .shipping: return "shippingbox.fill"
        case .messages: return "bubble.left.and.bubble.right.fill"
        case .disputes: return "exclamationmark.shield.fill"
        case .ai: return "brain.head.profile"
        }
    }
}

// MARK: - Components

private struct MarketplaceNotificationChip: View {
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

private struct MarketplaceNotificationPremiumCard: View {
    let item: MarketplaceNotificationItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    MarketplaceIconBadge(icon: item.icon, size: 50)

                    if !item.isRead {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .offset(x: 4, y: -2)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.title)
                            .font(.subheadline.weight(item.isRead ? .bold : .black))
                            .lineLimit(1)

                        if item.isUrgent {
                            Text("Urgent")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                    }

                    Text(item.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)

                    MarketplaceNotificationMiniBadge(title: item.category, icon: item.categoryIcon)
                }

                Spacer()

                Text(item.timeText)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MarketplaceNotificationMiniBadge: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Preview Data

struct MarketplaceNotificationMockItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let body: String
    let time: String
    let icon: String
    let category: String
    let categoryIcon: String
    let isRead: Bool
    let isUrgent: Bool
}

enum MarketplaceNotificationPreviewData {
    static let items: [MarketplaceNotificationMockItem] = [
        .init(
            title: "Commande payée",
            body: "La commande #CMD-2026-000184 a été payée avec succès.",
            time: "Maintenant",
            icon: "cart.fill",
            category: "Commande",
            categoryIcon: "cart.fill",
            isRead: false,
            isUrgent: false
        ),
        .init(
            title: "Paiement Mobile Money",
            body: "Un paiement Orange Money / Wave / MTN pourra être suivi ici selon le pays.",
            time: "10:42",
            icon: "iphone.gen1.radiowaves.left.and.right",
            category: "Paiement",
            categoryIcon: "creditcard.fill",
            isRead: false,
            isUrgent: false
        ),
        .init(
            title: "Colis en transit",
            body: "Votre colis est en route vers le point relais ou l’agence locale.",
            time: "Hier",
            icon: "shippingbox.fill",
            category: "Livraison",
            categoryIcon: "shippingbox.fill",
            isRead: true,
            isUrgent: false
        ),
        .init(
            title: "Alerte IA anti-fraude",
            body: "Une activité inhabituelle a été détectée sur une commande ou un remboursement.",
            time: "Lun.",
            icon: "brain.head.profile",
            category: "Sécurité",
            categoryIcon: "shield.fill",
            isRead: false,
            isUrgent: true
        )
    ]
}
private struct MarketplaceNotificationActionCard: View {
    let title: String
    let icon: String

    var body: some View {
        Button {
        } label: {
            VStack(spacing: 10) {
                MarketplaceIconBadge(icon: icon, size: 42)

                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
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
private struct MarketplaceNotificationEmptyView: View {
    var body: some View {
        VStack(spacing: 14) {
            MarketplaceIconBadge(icon: "bell.slash.fill", size: 64)

            Text("Aucune notification")
                .font(.title3.bold())

            Text("Les notifications Cutly apparaîtront ici : favoris, messages, commandes, paiements, livraisons, litiges et alertes IA.")
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



private struct MarketplaceNotificationSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var orderUpdates = true
    @State private var paymentUpdates = true
    @State private var shipmentUpdates = true
    @State private var messageUpdates = true
    @State private var disputeUpdates = true
    @State private var aiSecurityAlerts = true
    @State private var promotions = true
    @State private var quietHours = false

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        MarketplaceIconBadge(icon: "bell.badge.fill", size: 66)

                        Text("Paramètres notifications")
                            .font(.system(.title2, design: .rounded).weight(.black))

                        Text("Choisis les alertes Marketplace importantes : commandes, paiements, livraison, messages, litiges, Mobile Money et IA anti-fraude.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 22)

                        VStack(spacing: 12) {
                            Toggle("Commandes", isOn: $orderUpdates)
                                .marketplaceNotificationToggle()

                            Toggle("Paiements & Mobile Money", isOn: $paymentUpdates)
                                .marketplaceNotificationToggle()

                            Toggle("Expédition & livraison", isOn: $shipmentUpdates)
                                .marketplaceNotificationToggle()

                            Toggle("Messages", isOn: $messageUpdates)
                                .marketplaceNotificationToggle()

                            Toggle("Litiges & remboursements", isOn: $disputeUpdates)
                                .marketplaceNotificationToggle()

                            Toggle("Alertes IA anti-fraude", isOn: $aiSecurityAlerts)
                                .marketplaceNotificationToggle()

                            Toggle("Promotions & baisses de prix", isOn: $promotions)
                                .marketplaceNotificationToggle()

                            Toggle("Mode silencieux", isOn: $quietHours)
                                .marketplaceNotificationToggle()
                        }
                        .padding(.horizontal, 16)

                        Button {
                            dismiss()
                        } label: {
                            Label("Enregistrer", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(MarketplacePremiumButtonStyle())
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 30)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension View {
    func marketplaceNotificationToggle() -> some View {
        self
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
struct MarketplaceNotificationItem: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let type: String
    let targetId: String
    let targetType: String
    let isRead: Bool
    let createdAt: Timestamp?
    let priority: String

    var isUrgent: Bool {
        priority == "urgent" || priority == "high"
    }

    var icon: String {
        switch type {
        case "product_favorite": return "heart.fill"
        case "newMessage", "marketplace_message": return "bubble.left.and.bubble.right.fill"
        case "orderPaid", "orderDelivered", "orderCancelled": return "cart.fill"
        case "shippingUpdated": return "shippingbox.fill"
        case "paymentReceived": return "creditcard.fill"
        case "disputeOpened", "disputeUpdated", "refundUpdated": return "exclamationmark.shield.fill"
        case "securityAlert", "aiAlert": return "brain.head.profile"
        default: return "bell.fill"
        }
    }

    var category: String {
        switch type {
        case "product_favorite": return "Favori"
        case "newMessage", "marketplace_message": return "Message"
        case "orderPaid", "orderDelivered", "orderCancelled": return "Commande"
        case "shippingUpdated": return "Livraison"
        case "paymentReceived": return "Paiement"
        case "disputeOpened", "disputeUpdated", "refundUpdated": return "Litige"
        case "securityAlert", "aiAlert": return "Sécurité"
        default: return "Cutly"
        }
    }

    var categoryIcon: String { icon }

    var timeText: String {
        guard let date = createdAt?.dateValue() else { return "" }

        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }

        if calendar.isDateInYesterday(date) {
            return "Hier"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized + "."
    }
}





#Preview {
    MarketplaceNotificationsView()
}
