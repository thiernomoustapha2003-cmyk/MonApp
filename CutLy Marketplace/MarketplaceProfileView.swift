//
//  MarketplaceProfileView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth







struct MarketplaceProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTab: MarketplaceProfileTab = .overview
    @State private var isCertified = false
    @State private var hasProfessionalStore = false
    @State private var animateHeader = false
    @State private var openCertification = false
    @State private var openIdentityVerification = false
    @State private var openAddressPayment = false
    @State private var openOrders = false
    @State private var openSelling = false
    @State private var openWallet = false
    @State private var openAddresses = false
    @State private var openSettings = false
    
    @State private var profile: MarketplaceUserProfile?
    @State private var isLoadingProfile = false
    @State private var stats = MarketplaceProfileStats()
    private let db = Firestore.firestore()
    @State private var purchasesListener: ListenerRegistration?
    @State private var salesListener: ListenerRegistration?
    @State private var favoritesListener: ListenerRegistration?
    @State private var reviewsListener: ListenerRegistration?
    @State private var recentOrders: [MarketplaceProfileOrderItem] = []
    @State private var ordersListener: ListenerRegistration?
    @State private var recentSales: [MarketplaceProfileOrderItem] = []
    @State private var salesOrdersListener: ListenerRegistration?
    @State private var walletBalanceText = "0 €"
    @State private var walletPendingText = "0 €"
    @State private var walletListener: ListenerRegistration?
    @State private var addressSummaryText = "Aucune adresse"
    @State private var addressListener: ListenerRegistration?
    @State private var settingsSummaryText = "Langue, devise, pays"
    @State private var settingsListener: ListenerRegistration?
    
    
    
    
    
    
    
    
    var body: some View {
        ZStack {
            MarketplaceUITheme.softBackgroundGradient
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    profileHeroSection
                    roleFreedomSection
                    certificationSection
                    identityTrustSection
                    addressPaymentSection
                    profileTabsSection
                    profileContentSection
                    profileReadySection
                    Spacer(minLength: 120)
                }
                .padding(.vertical, 18)
            }
            
            hiddenNavigationLinks
        }
        .navigationTitle("Profil Marketplace")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    MarketplaceProfileSetupView()
                } label: {
                    Image(systemName: "pencil.circle.fill")
                }
            }
        }
        .onDisappear {
            purchasesListener?.remove()
            salesListener?.remove()
            favoritesListener?.remove()
            reviewsListener?.remove()
            ordersListener?.remove()
            salesOrdersListener?.remove()
            walletListener?.remove()
            addressListener?.remove()
            settingsListener?.remove()
        }
        
        
        
        
    }
    
    private var hiddenNavigationLinks: some View {
        Group {
            NavigationLink("", destination: MarketplaceCertificationView(), isActive: $openCertification)
                .hidden()

            NavigationLink("", destination: MarketplaceCertificationView(), isActive: $openIdentityVerification)
                .hidden()
            
            NavigationLink("", destination: MarketplaceAddressPaymentHubView(), isActive: $openAddressPayment)
                .hidden()
            
            NavigationLink("", destination: MarketplaceOrdersView(), isActive: $openOrders)
                .hidden()
            
            NavigationLink("", destination: MarketplaceSellView(), isActive: $openSelling)
                .hidden()
            
            NavigationLink("", destination: MarketplaceWalletView(), isActive: $openWallet)
                .hidden()
            
            NavigationLink("", destination: MarketplaceAddressPaymentHubView(), isActive: $openAddresses)
                .hidden()
            
            NavigationLink("", destination: MarketplaceSettingsView(), isActive: $openSettings)
                .hidden()
        }
    }
    
    private var profileHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                if let urlString = profile?.photoURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                } else {
                    MarketplaceIconBadge(icon: "person.crop.circle.fill", size: 72)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(profile?.displayName ?? "Profil Marketplace")
                            .font(.system(.title2, design: .rounded).weight(.black))
                            .foregroundStyle(.white)
                        
                        if profile?.marketplaceVerified == true &&
                            profile?.badgeVisible == true &&
                            profile?.certificationStatus == "active" {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    Text(profileSubtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }
                
                Spacer()
            }
            
            HStack(spacing: 10) {
                MarketplaceProfileHeroChip(title: "Acheter", icon: "cart.fill")
                
                if profile?.sellerEnabled == true {
                    MarketplaceProfileHeroChip(title: "Vendre", icon: "bag.fill")
                }
                
                if profile?.marketplaceVerified == true &&
                    profile?.badgeVisible == true &&
                    profile?.certificationStatus == "active" {
                    MarketplaceProfileHeroChip(title: "Vérifié", icon: "checkmark.seal.fill")
                }
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
            loadProfile()
        }
    }
    
    private var roleFreedomSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Profil libre",
                subtitle: "Comme Vinted : un profil peut acheter et vendre",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)
            
            MarketplaceProfileInfoRow(
                icon: "cart.fill",
                title: "Acheter",
                subtitle: "Commander, suivre, payer, contacter un vendeur, laisser un avis."
            )
            
            MarketplaceProfileInfoRow(
                icon: "bag.fill",
                title: "Vendre",
                subtitle: "Publier des produits, recevoir des commandes, gérer retraits et livraisons."
            )
            
            MarketplaceProfileInfoRow(
                icon: "storefront.fill",
                title: "Boutique optionnelle",
                subtitle: "Une boutique professionnelle peut être créée en plus du profil personnel."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var certificationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Certification Cutly",
                subtitle: "Disponible pour personne, vendeur ou boutique",
                actionTitle: "Demander",
                action: {
                    openCertification = true
                }
            )
            .padding(.horizontal, 0)
            
            Toggle("Profil certifié", isOn: $isCertified)
                .padding(16)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            Toggle("Boutique professionnelle", isOn: $hasProfessionalStore)
                .padding(16)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            MarketplaceProfileInfoRow(
                icon: "checkmark.seal.fill",
                title: "Badge payant",
                subtitle: "Vérification identité, confiance acheteur, visibilité renforcée et protection IA."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var identityTrustSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Identité & confiance",
                subtitle: "Certification disponible pour tout profil Marketplace",
                actionTitle: "Vérifier",
                action: {
                    openIdentityVerification = true
                }
            )
            .padding(.horizontal, 0)
            
            MarketplaceProfileInfoRow(
                icon: "person.text.rectangle.fill",
                title: "Identité personnelle",
                subtitle: "Nom, pays, téléphone, photo de profil et vérification documentaire si nécessaire."
            )
            
            MarketplaceProfileInfoRow(
                icon: "checkmark.shield.fill",
                title: "Certification Cutly pour tous",
                subtitle: "Particulier, acheteur-vendeur, vendeur régulier, boutique professionnelle ou marque."
            )
            
            MarketplaceProfileInfoRow(
                icon: "brain.head.profile",
                title: "Score confiance IA",
                subtitle: "Analyse des ventes, achats, avis, litiges, remboursements et comportements suspects."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var addressPaymentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Adresses & paiements",
                subtitle: "Pensé pour Europe, Afrique et international",
                actionTitle: "Gérer",
                action: {
                    openAddressPayment = true
                }
            )
            .padding(.horizontal, 0)
            
            MarketplaceProfileInfoRow(
                icon: "mappin.and.ellipse",
                title: "Adresses flexibles",
                subtitle: "Adresse complète, point de repère, GPS, relais, poste, agence locale ou main propre."
            )
            
            MarketplaceProfileInfoRow(
                icon: "iphone.gen1.radiowaves.left.and.right",
                title: "Paiements & retraits",
                subtitle: "Stripe, cartes, Apple Pay, PayPal, Mobile Money, virement bancaire et Wallet Cutly."
            )
            
            MarketplaceProfileInfoRow(
                icon: "wallet.pass.fill",
                title: "Profil acheteur-vendeur",
                subtitle: "Le même compte peut acheter, vendre, recevoir des revenus et faire des achats."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var profileReadySection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.green)
            
            Text("Profil Marketplace prêt pour Firestore : achat, vente, boutique optionnelle, certification payante, adresses, paiements, wallet, sécurité et IA.")
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
    
    
    
    private var profileTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MarketplaceProfileTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                            Text(tab.title)
                        }
                        .font(.caption.bold())
                        .foregroundStyle(selectedTab == tab ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab
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
    
    private var profileContentSection: some View {
        VStack(spacing: 12) {
            switch selectedTab {
            case .overview:
                MarketplaceProfileOverview(stats: stats)
                
            case .orders:
                MarketplaceProfileOrdersSection(
                    orders: recentOrders,
                    openOrders: {
                        openOrders = true
                    }
                )
                
            case .selling:
                MarketplaceProfileOrdersSection(
                    orders: recentSales,
                    openOrders: {
                        openSelling = true
                    }
                )
                
            case .wallet:
                Button {
                    openWallet = true
                } label: {
                    MarketplaceProfilePlaceholder(
                        title: "Wallet : \(walletBalanceText)",
                        subtitle: "En attente : \(walletPendingText) • Retraits, Stripe, Mobile Money et paiements sécurisés.",
                        icon: "wallet.pass.fill"
                    )
                }
                
            case .addresses:
                Button {
                    openAddresses = true
                } label: {
                    MarketplaceProfilePlaceholder(
                        title: "Adresses",
                        subtitle: "\(addressSummaryText) • Adresse complète, GPS, point de repère, relais, poste et agence locale.",
                        icon: "mappin.and.ellipse"
                    )
                }
                
            case .settings:
                Button {
                    openSettings = true
                } label: {
                    MarketplaceProfilePlaceholder(
                        title: "Réglages",
                        subtitle: "\(settingsSummaryText) • Confidentialité, sécurité et notifications.",
                        icon: "gearshape.fill"
                    )
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
    private var profileSubtitle: String {
        let type = profile?.profileType ?? "personal"

        switch type {
        case "buyerSeller":
            return "Profil acheteur-vendeur • Peut acheter et vendre"
        case "business":
            return "Boutique professionnelle • Profil vendeur"
        default:
            return "Profil particulier • Acheteur Marketplace"
        }
    }

    private func loadProfile() {
        guard !isLoadingProfile else { return }
        isLoadingProfile = true

        Task {
            do {
                let loadedProfile = try await MarketplaceProfileService.shared.reloadProfile()

                await MainActor.run {
                    self.profile = loadedProfile
                    if let uid = loadedProfile?.id {
                        loadMarketplaceStats(for: uid)
                        if let uid = loadedProfile?.id {
                            loadRecentOrders(for: uid)
                            loadRecentSales(for: uid)
                            loadWalletSummary(for: uid)
                            loadAddressSummary(for: uid)
                            loadSettingsSummary(for: uid)
                            
                            
                            
                        }
                    }
                    

                    self.isCertified =
                        loadedProfile?.marketplaceVerified == true &&
                        loadedProfile?.badgeVisible == true &&
                        loadedProfile?.certificationStatus == "active"

                    self.hasProfessionalStore = loadedProfile?.profileType == "business"
                    self.isLoadingProfile = false
                }

            } catch {
                await MainActor.run {
                    self.isLoadingProfile = false
                }

                print("❌ loadProfile Marketplace:", error.localizedDescription)
            }
        }
    }
    
    
    private func loadMarketplaceStats(for uid: String) {

        

        let ordersRef = db.collection("marketplace_orders")
        let favoritesRef = db.collection("marketplace_favorites")
        let reviewsRef = db.collection("marketplace_seller_reviews")

        purchasesListener = ordersRef
            .whereField("buyerId", isEqualTo: uid)
            .addSnapshotListener { snapshot, _ in

                DispatchQueue.main.async {
                    stats.purchases = snapshot?.documents.count ?? 0
                }
            }

        salesListener = ordersRef
            .whereField("sellerId", isEqualTo: uid)
            .whereField("status", isEqualTo: "completed")
            .addSnapshotListener { snapshot, _ in

                DispatchQueue.main.async {
                    stats.sales = snapshot?.documents.count ?? 0
                }
            }

        favoritesListener = favoritesRef
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { snapshot, _ in

                DispatchQueue.main.async {
                    stats.favorites = snapshot?.documents.count ?? 0
                }
            }

        reviewsListener = reviewsRef
            .whereField("sellerId", isEqualTo: uid)
            .addSnapshotListener { snapshot, _ in

                let docs = snapshot?.documents ?? []
                var reviews: Double = 0

                if docs.isEmpty {
                    reviews = 0
                } else {
                    let total = docs.reduce(0.0) { partial, document in
                        partial + (document.data()["rating"] as? Double ?? 0)
                    }

                    reviews = total / Double(docs.count)
                }

                DispatchQueue.main.async {
                    stats.reviews = reviews
                }
            }
    }
    private func loadRecentOrders(for uid: String) {
        ordersListener?.remove()

        ordersListener = db.collection("marketplace_orders")
            .whereField("buyerId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 5)
            .addSnapshotListener { snapshot, error in

                if let error {
                    print("❌ loadRecentOrders:", error.localizedDescription)
                    return
                }

                let items: [MarketplaceProfileOrderItem] = snapshot?.documents.map { doc in
                    let data = doc.data()

                    return MarketplaceProfileOrderItem(
                        id: doc.documentID,
                        title: data["productTitle"] as? String ?? "Commande Marketplace",
                        status: data["status"] as? String ?? "pending",
                        totalText: data["totalText"] as? String ?? "\(data["total"] ?? "") €",
                        createdAt: data["createdAt"] as? Timestamp
                    )
                } ?? []

                DispatchQueue.main.async {
                    recentOrders = items
                }
            }
    }
    private func loadRecentSales(for uid: String) {

        salesOrdersListener?.remove()

        salesOrdersListener = db.collection("marketplace_orders")
            .whereField("sellerId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 5)
            .addSnapshotListener { snapshot, error in

                guard error == nil else { return }

                let items: [MarketplaceProfileOrderItem] =
                snapshot?.documents.map { doc in

                    let data = doc.data()

                    return MarketplaceProfileOrderItem(
                        id: doc.documentID,
                        title: data["productTitle"] as? String ?? "Produit vendu",
                        status: data["status"] as? String ?? "pending",
                        totalText: data["totalText"] as? String ?? "\(data["total"] ?? "") €",
                        createdAt: data["createdAt"] as? Timestamp
                    )

                } ?? []

                DispatchQueue.main.async {
                    recentSales = items
                }
            }
    }
    private func loadWalletSummary(for uid: String) {
        walletListener?.remove()

        walletListener = db.collection("marketplace_wallets")
            .whereField("userId", isEqualTo: uid)
            .limit(to: 1)
            .addSnapshotListener { snapshot, error in

                if let error {
                    print("❌ loadWalletSummary:", error.localizedDescription)
                    return
                }

                let data = snapshot?.documents.first?.data() ?? [:]

                let balance = data["availableBalance"] as? Double ?? 0
                let pending = data["pendingBalance"] as? Double ?? 0
                let currency = data["currency"] as? String ?? "EUR"

                DispatchQueue.main.async {
                    walletBalanceText = "\(String(format: "%.2f", balance)) \(currency)"
                    walletPendingText = "\(String(format: "%.2f", pending)) \(currency)"
                }
            }
    }
    private func loadAddressSummary(for uid: String) {
        addressListener?.remove()

        addressListener = db.collection("marketplace_addresses")
            .whereField("userId", isEqualTo: uid)
            .limit(to: 1)
            .addSnapshotListener { snapshot, error in

                if let error {
                    print("❌ loadAddressSummary:", error.localizedDescription)
                    return
                }

                let data = snapshot?.documents.first?.data() ?? [:]

                let city = data["city"] as? String ?? ""
                let country = data["country"] as? String ?? ""
                let relayName = data["relayName"] as? String ?? ""

                DispatchQueue.main.async {
                    if !relayName.isEmpty {
                        addressSummaryText = "Relais : \(relayName)"
                    } else if !city.isEmpty || !country.isEmpty {
                        addressSummaryText = "\(city) \(country)"
                    } else {
                        addressSummaryText = "Aucune adresse enregistrée"
                    }
                }
            }
    }
    private func loadSettingsSummary(for uid: String) {
        settingsListener?.remove()

        settingsListener = db.collection("marketplace_notification_settings")
            .whereField("userId", isEqualTo: uid)
            .limit(to: 1)
            .addSnapshotListener { snapshot, error in

                if let error {
                    print("❌ loadSettingsSummary:", error.localizedDescription)
                    return
                }

                let data = snapshot?.documents.first?.data() ?? [:]

                let language = data["language"] as? String ?? "Français"
                let currency = data["currency"] as? String ?? "EUR"
                let country = data["country"] as? String ?? "France"

                DispatchQueue.main.async {
                    settingsSummaryText = "\(language) • \(currency) • \(country)"
                }
            }
    }
    
    
    
    
    
}

// MARK: - Tabs

enum MarketplaceProfileTab: String, CaseIterable, Identifiable {
    case overview
    case orders
    case selling
    case wallet
    case addresses
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Vue"
        case .orders: return "Commandes"
        case .selling: return "Ventes"
        case .wallet: return "Wallet"
        case .addresses: return "Adresses"
        case .settings: return "Réglages"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "person.fill"
        case .orders: return "cart.fill"
        case .selling: return "bag.fill"
        case .wallet: return "wallet.pass.fill"
        case .addresses: return "mappin.and.ellipse"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Components

private struct MarketplaceProfileHeroChip: View {
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

private struct MarketplaceProfileInfoRow: View {
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

private struct MarketplaceProfileOverview: View {

    let stats: MarketplaceProfileStats

    var body: some View {

        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {

            MarketplaceProfileStatCard(
                title: "Achats",
                value: "\(stats.purchases)",
                icon: "cart.fill"
            )

            MarketplaceProfileStatCard(
                title: "Ventes",
                value: "\(stats.sales)",
                icon: "bag.fill"
            )

            MarketplaceProfileStatCard(
                title: "Avis",
                value: String(format: "%.1f", stats.reviews),
                icon: "star.fill"
            )

            MarketplaceProfileStatCard(
                title: "Favoris",
                value: "\(stats.favorites)",
                icon: "heart.fill"
            )
        }
    }
}

private struct MarketplaceProfileStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            MarketplaceIconBadge(icon: icon, size: 42)

            Text(value)
                .font(.system(.headline, design: .rounded).weight(.black))

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 122)
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct MarketplaceProfilePlaceholder: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 14) {
            MarketplaceIconBadge(icon: icon, size: 58)

            Text(title)
                .font(.system(.title3, design: .rounded).weight(.black))

            Text(subtitle)
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


private struct MarketplaceAddressPaymentHubView: View {
    var body: some View {
        VStack(spacing: 14) {
            NavigationLink {
                MarketplaceWalletView()
            } label: {
                MarketplaceProfilePlaceholder(
                    title: "Paiements & Wallet",
                    subtitle: "Solde, retraits, Stripe, PayPal, Mobile Money et paiements sécurisés.",
                    icon: "wallet.pass.fill"
                )
            }

            NavigationLink {
                MarketplaceSettingsView()
            } label: {
                MarketplaceProfilePlaceholder(
                    title: "Adresses & pays",
                    subtitle: "Adresse complète, GPS, point relais, poste, agence locale.",
                    icon: "mappin.and.ellipse"
                )
            }

            NavigationLink {
                MarketplaceHelpCenterView()
            } label: {
                MarketplaceProfilePlaceholder(
                    title: "Besoin d’aide ?",
                    subtitle: "Centre d’aide, support, litiges, paiements, livraison et sécurité.",
                    icon: "headset"
                )
            }
        }
        .buttonStyle(.plain)
        .padding()
        .navigationTitle("Adresses & paiements")
    }
}
struct MarketplaceProfileStats {
    var purchases: Int = 0
    var sales: Int = 0
    var reviews: Double = 0
    var favorites: Int = 0
}
struct MarketplaceProfileOrderItem: Identifiable, Hashable {
    let id: String
    let title: String
    let status: String
    let totalText: String
    let createdAt: Timestamp?

    var timeText: String {
        guard let date = createdAt?.dateValue() else { return "" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct MarketplaceProfileOrdersSection: View {
    let orders: [MarketplaceProfileOrderItem]
    let openOrders: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: openOrders) {
                MarketplaceProfilePlaceholder(
                    title: "Commandes",
                    subtitle: "Achats, ventes, retours et litiges.",
                    icon: "cart.fill"
                )
            }

            if orders.isEmpty {
                Text("Aucune commande récente pour le moment.")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            } else {
                ForEach(orders) { order in
                    HStack(spacing: 12) {
                        MarketplaceIconBadge(icon: "shippingbox.fill", size: 42)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(order.title)
                                .font(.subheadline.bold())
                                .lineLimit(1)

                            Text("\(order.status) • \(order.timeText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(order.totalText)
                            .font(.caption.bold())
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
            }
        }
    }
}



#Preview {
    MarketplaceProfileView()
}
