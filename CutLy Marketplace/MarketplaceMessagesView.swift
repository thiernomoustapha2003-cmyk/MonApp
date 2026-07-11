//
//  MarketplaceMessagesView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore








struct MarketplaceMessagesView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var searchText = ""
    @State private var selectedFilter: MarketplaceMessageFilter = .all
    @State private var animateHeader = false
    
    @State private var showConversationPreview = false
    
    @State private var conversations: [MarketplaceConversationItem] = []
    @State private var listener: ListenerRegistration?
    @State private var isLoadingConversations = false
    
    @State private var matchedConversationIds: Set<String> = []
    @State private var searchListener: ListenerRegistration?
    
    
    
    
    
    private let filters: [MarketplaceMessageFilter] = [.all, .buyerSeller, .orders, .disputes, .support, .unread]
    
    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        messagesHeroSection
                        searchSection
                        filtersSection
                        conversationToolsSection
                        conversationsSection
                        messagesReadySection
                        Spacer(minLength: 120)
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                listenConversations()

                if !searchText.isEmpty {
                    searchInMessages()
                }
            }
            .onChange(of: searchText) { newValue in

                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

                    matchedConversationIds.removeAll()
                    searchListener?.remove()

                } else {

                    searchInMessages()

                }

            }
            .onDisappear {
                listener?.remove()
                searchListener?.remove()
            }
            
        }
    }
    
    private var messagesHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Messages Marketplace")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Acheteurs, vendeurs, commandes, litiges, support et traduction automatique.")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(3)
                }
                
                Spacer()
                
                MarketplaceIconBadge(icon: "bubble.left.and.bubble.right.fill", size: 62)
            }
            
            HStack(spacing: 10) {
                MarketplaceMessagesChip(title: "Traduction", icon: "globe")
                MarketplaceMessagesChip(title: "Pièces jointes", icon: "paperclip")
                MarketplaceMessagesChip(title: "Litiges", icon: "shield.fill")
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
    
    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.secondary)
            
            TextField("Rechercher une conversation...", text: $searchText)
                .font(.system(.body, design: .rounded).weight(.semibold))
            
            if !searchText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(MarketplaceUITheme.glassBackground(colorScheme: colorScheme, cornerRadius: 24))
        .padding(.horizontal, 16)
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
    
    private var conversationToolsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Outils conversation",
                subtitle: "Traduction, pièces jointes, preuves et sécurité",
                actionTitle: "Aperçu",
                action: {
                    showConversationPreview = true
                }
            )
            .padding(.horizontal, 0)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                MarketplaceMessageToolCard(title: "Traduction auto", icon: "globe")
                MarketplaceMessageToolCard(title: "Photos / vidéos", icon: "photo.on.rectangle.angled")
                MarketplaceMessageToolCard(title: "Commande liée", icon: "cart.fill")
                MarketplaceMessageToolCard(title: "Litige sécurisé", icon: "exclamationmark.shield.fill")
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
        .sheet(isPresented: $showConversationPreview) {
            MarketplaceConversationPreviewSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var messagesReadySection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.green)
            
            Text("Messages prêts pour Firestore, conversations acheteur-vendeur, commandes, litiges, pièces jointes, traduction automatique et modération IA.")
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
    
    
    
    
    
    
    private var conversationsSection: some View {
        VStack(spacing: 12) {
            if isLoadingConversations {
                ProgressView()
                    .padding()
            } else if filteredConversations.isEmpty {
                MarketplaceMessagesEmptyView(
                    filter: selectedFilter
                )
            } else {
                ForEach(filteredConversations) { item in
                    NavigationLink {
                        MarketplaceConversationThreadView(
                            conversationId: item.id,
                            productId: item.productId,
                            sellerId: item.sellerId,
                            productTitle: item.productTitle
                        )
                    } label: {
                        MarketplaceConversationPremiumCard(item: item)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var filteredConversations: [MarketplaceConversationItem] {
        let uid = Auth.auth().currentUser?.uid ?? ""
        var result = conversations

        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

            let query = searchText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            result = result.filter { conversation in

                let localMatch =

                    conversation.title.lowercased().contains(query)

                    || conversation.lastMessage.lowercased().contains(query)

                    || conversation.productTitle.lowercased().contains(query)

                    || conversation.orderId.lowercased().contains(query)

                    || conversation.type.lowercased().contains(query)

                    || conversation.buyerId.lowercased().contains(query)

                    || conversation.sellerId.lowercased().contains(query)

                    || conversation.avatarIcon.lowercased().contains(query)

                    || conversation.typeTitle.lowercased().contains(query)

                    || conversation.displayAvatarURL.lowercased().contains(query)

                return localMatch
                    || matchedConversationIds.contains(conversation.id)

            }

        }

        let filtered: [MarketplaceConversationItem]

        switch selectedFilter {

        case .all:
            filtered = result

        case .buyerSeller:
            filtered = result.filter { $0.type == "buyerSeller" }

        case .orders:
            filtered = result.filter { !$0.orderId.isEmpty }

        case .disputes:
            filtered = result.filter { $0.type == "dispute" }

        case .support:
            filtered = result.filter { $0.type == "support" }

        case .unread:
            filtered = result.filter { $0.unreadFor.contains(uid) }

        }

        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return filtered.sorted { first, second in

            if query.isEmpty {

                return (first.lastMessageAt?.dateValue() ?? .distantPast)
                >
                (second.lastMessageAt?.dateValue() ?? .distantPast)

            }

            func score(_ item: MarketplaceConversationItem) -> Int {

                var value = 0

                if item.title.lowercased().hasPrefix(query) {
                    value += 120
                }

                if item.title.lowercased().contains(query) {
                    value += 90
                }

                if item.productTitle.lowercased().contains(query) {
                    value += 70
                }

                if item.lastMessage.lowercased().contains(query) {
                    value += 50
                }

                if matchedConversationIds.contains(item.id) {
                    value += 30
                }

                if item.unreadCount > 0 {
                    value += 10
                }

                return value
            }

            let firstScore = score(first)
            let secondScore = score(second)

            if firstScore == secondScore {

                return (first.lastMessageAt?.dateValue() ?? .distantPast)
                >
                (second.lastMessageAt?.dateValue() ?? .distantPast)

            }

            return firstScore > secondScore

        }
    }
    private func searchInMessages() {

        searchListener?.remove()

        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !query.isEmpty else {
            matchedConversationIds.removeAll()
            return
        }

        searchListener = Firestore.firestore()
            .collection("marketplace_messages")
            .order(by: "createdAt", descending: true)
            .limit(to: 500)
            .addSnapshotListener { snapshot, error in

                if let error {
                    print("❌ searchInMessages:", error.localizedDescription)
                    return
                }

                var ids = Set<String>()

                snapshot?.documents.forEach { document in

                    let data = document.data()

                    let text = (data["text"] as? String ?? "").lowercased()

                    if text.contains(query),
                       let conversationId = data["conversationId"] as? String {

                        ids.insert(conversationId)

                    }
                }

                matchedConversationIds = ids
            }
    }
    
    
    
    
    
    private func listenConversations() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isLoadingConversations = true
        listener?.remove()

        listener = Firestore.firestore()
            .collection("marketplace_conversations")
            .whereField("participantIds", arrayContains: uid)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { snapshot, error in
                isLoadingConversations = false

                if let error {
                    print("❌ listenConversations:", error.localizedDescription)
                    return
                }

                Task {
                    var loadedConversations: [MarketplaceConversationItem] = []

                    for doc in snapshot?.documents ?? [] {
                        let data = doc.data()

                        let buyerId = data["buyerId"] as? String ?? ""
                        let sellerId = data["sellerId"] as? String ?? ""
                        let type = data["type"] as? String ?? "buyerSeller"

                        var sellerName =
                            data["sellerDisplayName"] as? String ??
                            data["sellerFullName"] as? String ??
                            data["sellerName"] as? String ??
                            ""

                        var sellerPhotoURL =
                            data["sellerPhotoURL"] as? String ??
                            data["avatarURL"] as? String ??
                            ""

                        var sellerVerified =
                            data["sellerVerified"] as? Bool ??
                            data["isVerified"] as? Bool ??
                            false

                        if !sellerId.isEmpty {
                            let profileSnap = try? await Firestore.firestore()
                                .collection("marketplaceUsers")
                                .document(sellerId)
                                .getDocument()

                            let profile = profileSnap?.data() ?? [:]

                            if sellerName.isEmpty {
                                sellerName =
                                    profile["displayName"] as? String ??
                                    profile["fullName"] as? String ??
                                    profile["name"] as? String ??
                                    ""
                            }

                            if sellerPhotoURL.isEmpty {
                                sellerPhotoURL =
                                    profile["photoURL"] as? String ??
                                    profile["profileImageURL"] as? String ??
                                    ""
                            }

                            sellerVerified =
                                (profile["marketplaceVerified"] as? Bool == true) &&
                                (profile["badgeVisible"] as? Bool == true) &&
                                (profile["certificationStatus"] as? String == "active")
                        }

                        let buyerName =
                            data["buyerDisplayName"] as? String ??
                            data["buyerFullName"] as? String ??
                            data["buyerName"] as? String ??
                            "Acheteur Cutly"

                        let finalTitle: String

                        if type == "support" {
                            finalTitle = "Support Cutly"
                        } else if uid == sellerId {
                            finalTitle = buyerName
                        } else {
                            finalTitle = sellerName.isEmpty ? "Utilisateur Cutly" : sellerName
                        }

                        loadedConversations.append(
                            MarketplaceConversationItem(
                                id: doc.documentID,
                                title: finalTitle,
                                lastMessage: data["lastMessageText"] as? String ?? "Nouvelle conversation",
                                productId: data["productId"] as? String ?? "",
                                productTitle: data["productTitle"] as? String ?? "",
                                productImageURL: data["productImageURL"] as? String ?? "",
                                buyerId: buyerId,
                                sellerId: sellerId,
                                type: type,
                                orderId: data["orderId"] as? String ?? "",
                                unreadFor: data["unreadFor"] as? [String] ?? [],
                                unreadCount: data["unreadCount_\(uid)"] as? Int ?? 0,
                                avatarURL: sellerPhotoURL,
                                isVerified: type == "support" ? true : sellerVerified,
                                lastMessageAt: data["lastMessageAt"] as? Timestamp
                            )
                        )
                    }

                    await MainActor.run {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            conversations = loadedConversations.sorted {
                                ($0.lastMessageAt?.dateValue() ?? .distantPast) >
                                ($1.lastMessageAt?.dateValue() ?? .distantPast)
                            }
                        }
                    }
                }
            }
    }

    
    
    
    
    
    
    
    
}

// MARK: - Filter

enum MarketplaceMessageFilter: String, CaseIterable, Identifiable {
    case all
    case buyerSeller
    case orders
    case disputes
    case support
    case unread

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Tous"
        case .buyerSeller: return "Acheteur/Vendeur"
        case .orders: return "Commandes"
        case .disputes: return "Litiges"
        case .support: return "Support"
        case .unread: return "Non lus"
        }
    }

    var icon: String {
        switch self {
        case .all: return "bubble.left.and.bubble.right.fill"
        case .buyerSeller: return "person.2.fill"
        case .orders: return "cart.fill"
        case .disputes: return "exclamationmark.shield.fill"
        case .support: return "headset"
        case .unread: return "bell.badge.fill"
        }
    }
}

// MARK: - Components

private struct MarketplaceMessagesChip: View {
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

private struct MarketplaceConversationPremiumCard: View {
    let item: MarketplaceConversationItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack(alignment: .topTrailing) {
                conversationAvatar

                if item.unreadCount > 0 {
                    Text("\(min(item.unreadCount, 99))")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(
                            width: item.unreadCount > 9 ? 28 : 22,
                            height: 22
                        )
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.cyan,
                                    Color.blue,
                                    Color.purple
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.85), lineWidth: 2)
                        )
                        .shadow(color: .blue.opacity(0.35), radius: 8, x: 0, y: 4)
                        .offset(x: 8, y: -7)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 16, weight: item.unreadCount > 0 ? .black : .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if item.isVerified {
                        CutlyVerifiedBadge(size: 16)
                    }

                    if item.type == "support" {
                        Text("SUPPORT")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {

                    if item.unreadCount > 0 {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 8, height: 8)
                    }

                    Text(item.lastMessage)
                        .font(.system(size: 13, weight: item.unreadCount > 0 ? .bold : .medium))
                        .foregroundStyle(item.unreadCount > 0 ? .primary : .secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    MarketplaceMessageMiniBadge(title: item.typeTitle, icon: item.typeIcon)
                    MarketplaceMessageMiniBadge(title: "Traduction prête", icon: "globe")
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(item.timeText)
                    .font(.caption2.weight(item.unreadCount > 0 ? .black : .bold))
                    .foregroundStyle(item.unreadCount > 0 ? .primary : .secondary)

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    item.unreadCount > 0 ? Color.cyan.opacity(0.55) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: item.unreadCount > 0 ? Color.cyan.opacity(0.16) : Color.clear,
            radius: 12,
            x: 0,
            y: 6
        )
    }

    private var conversationAvatar: some View {
        ZStack(alignment: .bottomTrailing) {

            Group {

                if let url = URL(string: item.displayAvatarURL),
                   !item.displayAvatarURL.isEmpty {

                    AsyncImage(url: url) { phase in

                        switch phase {

                        case .empty:
                            avatarPlaceholder

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()

                        case .failure:
                            avatarPlaceholder

                        @unknown default:
                            avatarPlaceholder
                        }

                    }

                } else {

                    avatarPlaceholder

                }

            }
            .frame(width: 58, height: 58)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.cyan,
                                Color.blue,
                                Color.purple
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: item.unreadCount > 0 ? 3 : 1.5
                    )
            )
            .shadow(
                color: Color.blue.opacity(0.20),
                radius: 8,
                x: 0,
                y: 4
            )

            if item.isVerified {

                CutlyVerifiedBadge(size: 16)
                    .background(Circle().fill(.white))
                    .offset(x: 2, y: 2)

            }

        }
    }
    private var avatarPlaceholder: some View {

        MarketplaceIconBadge(
            icon: item.avatarIcon,
            size: 58
        )

    }
    
    
}

private struct MarketplaceMessageMiniBadge: View {
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


private struct MarketplaceMessageToolCard: View {
    let title: String
    let icon: String

    var body: some View {
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
}

private struct MarketplaceConversationPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var messageText = ""
    @State private var showTranslated = false

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    VStack(spacing: 8) {
                        MarketplaceIconBadge(icon: "bubble.left.and.bubble.right.fill", size: 60)

                        Text("Conversation marketplace")
                            .font(.system(.title2, design: .rounded).weight(.black))

                        Text("Aperçu prêt pour messages, traduction, pièces jointes et litiges.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 10) {
                        MarketplacePreviewBubble(
                            text: showTranslated ? "Hello, can the order be delivered to a pickup point?" : "Bonjour, est-ce que la commande peut être livrée en point relais ?",
                            isMe: false
                        )

                        MarketplacePreviewBubble(
                            text: showTranslated ? "Yes, we can deliver to a pickup point or local agency." : "Oui, on peut livrer en point relais ou agence locale.",
                            isMe: true
                        )
                    }
                    .padding(.horizontal, 16)

                    HStack(spacing: 10) {
                        Button {
                            showTranslated.toggle()
                        } label: {
                            Label(showTranslated ? "Original" : "Traduire", systemImage: "globe")
                        }
                        .buttonStyle(MarketplacePremiumButtonStyle(isFullWidth: false))

                        Button {
                        } label: {
                            Image(systemName: "paperclip")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                                .frame(width: 50, height: 50)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }

                    HStack(spacing: 10) {
                        TextField("Écrire un message...", text: $messageText)
                            .padding(14)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        Button {
                            messageText = ""
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(MarketplaceUITheme.primaryGradient)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.top, 28)
            }
            .navigationTitle("Aperçu")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct MarketplacePreviewBubble: View {
    let text: String
    let isMe: Bool

    var body: some View {
        HStack {
            if isMe { Spacer() }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(isMe ? .white : .primary)
                .padding(12)
                .background {
                    if isMe {
                        MarketplaceUITheme.primaryGradient
                    } else {
                        Color.primary.opacity(0.06)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .frame(maxWidth: 260, alignment: isMe ? .trailing : .leading)

            if !isMe { Spacer() }
        }
    }
}
struct MarketplaceConversationItem: Identifiable, Hashable {
    let id: String
    let title: String
    let lastMessage: String
    let productId: String
    let productTitle: String
    let productImageURL: String
    let buyerId: String
    let sellerId: String
    let type: String
    let orderId: String
    let unreadFor: [String]
    let unreadCount: Int
    let avatarURL: String
    let isVerified: Bool
    let lastMessageAt: Timestamp?

    var displayAvatarURL: String {
        if !avatarURL.isEmpty {
            return avatarURL
        }

        if !productImageURL.isEmpty {
            return productImageURL
        }

        return ""
    }

    var isUnread: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return unreadFor.contains(uid)
    }

    var avatarIcon: String {
        switch type {
        case "support":
            return "headset"
        case "store", "seller", "buyerSeller":
            return sellerId.isEmpty ? "person.fill" : "storefront.fill"
        case "dispute":
            return "exclamationmark.shield.fill"
        default:
            return "person.fill"
        }
    }

    var typeTitle: String {
        switch type {
        case "support": return "Support"
        case "dispute": return "Litige"
        case "order": return "Commande"
        case "store", "seller": return "Vendeur"
        default: return "Commande"
        }
    }

    var typeIcon: String {
        switch type {
        case "support": return "shield.fill"
        case "dispute": return "exclamationmark.shield.fill"
        case "order": return "cart.fill"
        case "store", "seller": return "bag.fill"
        default: return "cart.fill"
        }
    }

    var timeText: String {
        guard let date = lastMessageAt?.dateValue() else { return "" }

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

private struct MarketplaceMessagesEmptyView: View {

    let filter: MarketplaceMessageFilter

    private var title: String {
        switch filter {
        case .all:
            return "Aucune conversation"

        case .buyerSeller:
            return "Aucune conversation acheteur / vendeur"

        case .orders:
            return "Aucune conversation de commande"

        case .disputes:
            return "Aucun litige"

        case .support:
            return "Aucune conversation avec le support"

        case .unread:
            return "Aucun message non lu"
        }
    }

    private var subtitle: String {

        switch filter {

        case .all:
            return "Les messages avec les vendeurs, acheteurs, commandes, litiges et support apparaîtront ici automatiquement."

        case .buyerSeller:
            return "Les conversations entre acheteurs et vendeurs apparaîtront ici."

        case .orders:
            return "Les conversations liées aux commandes apparaîtront ici."

        case .disputes:
            return "Les conversations concernant les litiges apparaîtront ici."

        case .support:
            return "Les échanges avec le support Cutly apparaîtront ici."

        case .unread:
            return "Tous les messages non lus apparaîtront ici."
        }
    }

    var body: some View {

        VStack(spacing: 14) {

            MarketplaceIconBadge(
                icon: "bubble.left.and.bubble.right.fill",
                size: 64
            )

            Text(title)
                .font(.title3.bold())

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
        )
    }
}

#Preview {
    MarketplaceMessagesView()
}
