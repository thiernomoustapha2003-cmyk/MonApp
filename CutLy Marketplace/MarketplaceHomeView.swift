
//  MarketplacePremiumHomeView.swift
//  MonApp
//
//  Redesign 1:1 conforme à l'image fournie.
//  ⚠️ Aucune logique Firebase / Firestore / Storage / ViewModel n'a été modifiée.
//  Toutes les propriétés du ViewModel et du LocationManager utilisées ici sont
//  identiques au fichier d'origine.
//
//  Les zones marquées \"// TODO:\" indiquent des éléments visuels de l'image
//  (ex: badges, avatars) que tu pourras brancher plus tard à tes vraies données.
//  Le fichier compile tel quel.
//

import SwiftUI
import FirebaseAuth
import Combine



// MARK: - Palette locale conforme à l'image
// (locale au fichier, ne remplace pas ton MarketplaceUITheme existant)
private enum CutlyPalette {
    static let background       = Color(red: 0.04, green: 0.04, blue: 0.07)   // fond quasi noir
    static let card             = Color(red: 0.09, green: 0.09, blue: 0.13)   // cartes sombres
    static let cardStroke       = Color.white.opacity(0.06)
    static let heroTop          = Color(red: 0.11, green: 0.09, blue: 0.19)
    static let heroBottom       = Color(red: 0.06, green: 0.05, blue: 0.11)
    static let purple           = Color(red: 0.60, green: 0.35, blue: 1.00)
    static let pink             = Color(red: 1.00, green: 0.30, blue: 0.65)
    static let orange           = Color(red: 1.00, green: 0.55, blue: 0.30)
    static let verifiedBlue     = Color(red: 0.20, green: 0.55, blue: 1.00)
    static let liveRed          = Color(red: 1.00, green: 0.24, blue: 0.36)
    static let star             = Color(red: 1.00, green: 0.78, blue: 0.20)

    static let ctaGradient = LinearGradient(
        colors: [orange, pink, purple],
        startPoint: .leading, endPoint: .trailing
    )
    static let logoGradient = LinearGradient(
        colors: [purple, pink],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let bottomPlusGradient = LinearGradient(
        colors: [purple, pink],
        startPoint: .top, endPoint: .bottom
    )
    static let discoverWordGradient = LinearGradient(
        colors: [orange, pink],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - View principale
struct MarketplacePremiumHomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    
    @State private var animateHeader = false
    @State private var heroPageIndex = 0
    @State private var selectedBottomTab: BottomTab = .home
    @StateObject private var viewModel = MarketplaceHomeViewModel()
    @StateObject private var locationManager = MarketplaceLocationManager.shared
    @State private var showLogoutConfirmation = false
    @State private var showFiltersSheet = false
    @State private var showAroundMeSheet = false
    @State private var showDealsSheet = false
    @State private var showAISuggestionsSheet = false
    @State private var showCategoriesSheet = false
    
    @State private var showExploreFromBottom = false
    
    @State private var showCategoriesFromBottom = false
    
    @State private var showProfileFromBottom = false
    
    @State private var showSellFromBottom = false
    
    
    
    @State private var showLiveSheet = false
    @State private var showFavoritesSheet = false
    @State private var showOrdersSheet = false
    @State private var showNotificationsSheet = false
    @State private var showMessagesSheet = false
    @State private var showWalletSheet = false
    
    
    
    
    
    
    @State private var isDarkMode = true
    
    private enum Destination {
        case explore, categories, favorites, messages, orders, tracking
        case sell, wallet, profile, notifications, settings, support, legal, live
    }
    
    private enum BottomTab { case home, explore, categories, profile }
    
    // Accès rapides (icônes rondes de l'image)
    private struct QuickTab: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let destination: Destination
        var badgeDot: Bool = false
        var liveBadge: Bool = false
    }
    
    private let quickTabs: [QuickTab] = [
        .init(title: "Autour de moi", icon: "mappin.and.ellipse", destination: .tracking),
        .init(title: "Offres du jour", icon: "tag.fill", destination: .explore, badgeDot: true),
        .init(title: "Suggestions IA", icon: "sparkles", destination: .explore),
        .init(title: "Live Shopping", icon: "video.fill", destination: .live, liveBadge: true),
        .init(title: "Catégories", icon: "square.grid.2x2.fill", destination: .categories),
        .init(title: "Favoris", icon: "heart.fill", destination: .favorites)
    ]
    
    // Petites actions (Suivi / Vendre / Commandes / Revenus / Messages)
    private struct MiniAction: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let tint: Color
        let destination: Destination
    }
    
    private let miniActions: [MiniAction] = [
        .init(title: "Suivi", subtitle: "Abonne-toi", icon: "paperplane.fill", tint: CutlyPalette.purple, destination: .tracking),
        .init(title: "Vendre", subtitle: "Publie vite", icon: "plus.square.fill", tint: CutlyPalette.pink, destination: .sell),
        .init(title: "Commandes", subtitle: "Achat & vente", icon: "doc.text.fill", tint: CutlyPalette.orange, destination: .orders),
        .init(title: "Revenus", subtitle: "Gains & paiements", icon: "lock.fill", tint: Color.green, destination: .wallet),
        .init(title: "Messages", subtitle: "Discute", icon: "bubble.left.fill", tint: Color.blue, destination: .messages)
    ]
    
    // Catégories colorées (bas de l'image)
    private struct ColorCategory: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let tint: Color
    }
    
    private let colorCategories: [ColorCategory] = [
        .init(title: "Mode", icon: "tshirt.fill", tint: CutlyPalette.purple),
        .init(title: "Électronique", icon: "iphone", tint: CutlyPalette.pink),
        .init(title: "Maison", icon: "house.fill", tint: CutlyPalette.orange),
        .init(
            title: "Beauté",
            icon: "sparkle",
            tint: Color(red: 1.0, green: 0.35, blue: 0.55)
        ),
        .init(
            title: "Services",
            icon: "wrench.and.screwdriver.fill",
            tint: Color(red: 0.30, green: 0.75, blue: 0.90)
        ),
        .init(
            title: "Auto",
            icon: "car.fill",
            tint: Color(red: 1.0, green: 0.55, blue: 0.25)
        ),
        .init(title: "Plus", icon: "ellipsis", tint: .gray)
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CutlyPalette.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    topBar
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                    
                    searchBar
                        .padding(.horizontal, 18)
                    
                    heroSection
                        .padding(.horizontal, 16)
                    
                    quickTabsRow
                        .padding(.horizontal, 16)
                    
                   
                    if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        searchResultsSection
                    } else {
                        twoColumnOfferAndAISection
                            .padding(.horizontal, 16)
                        
                        popularProductsSection
                            .padding(.horizontal, 16)
                        
                        
                        miniActionsRow
                            .padding(.horizontal, 16)
                    }
                    
                    Color.clear.frame(height: 110) // espace pour la bottom bar
                }
                .padding(.top, 4)
                .frame(maxWidth: UIScreen.main.bounds.width)
                .clipped()
            }
            
            bottomTabBar
        }
        .foregroundStyle(.white)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .navigationBarHidden(true)
        .onAppear {
            locationManager.requestLocation()
            locationManager.startLiveTracking()
            viewModel.loadHome()
            animateHeader = true
        }
        .refreshable {
            viewModel.loadHome()
        }
        .onDisappear {
            locationManager.stopLiveTracking()
        }
        .confirmationDialog(
            "Déconnexion",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {

            Button("Se déconnecter", role: .destructive) {
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("Erreur : \(error.localizedDescription)")
                }
            }

            Button("Annuler", role: .cancel) { }

        } message: {
            Text("Êtes-vous sûr de vouloir vous déconnecter de votre compte Cutly ? Vous devrez vous reconnecter pour accéder de nouveau à votre espace.")
        }
        .sheet(isPresented: $showFiltersSheet) {
            MarketplaceFilterSheet(
                selectedRadiusKm: $viewModel.selectedRadiusKm,
                radiusOptionsKm: viewModel.radiusOptionsKm
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAroundMeSheet) {
            AroundMeRadiusSheet(
                selectedRadiusKm: $viewModel.selectedRadiusKm,
                city: locationManager.city,
                country: locationManager.country
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
     

        .sheet(isPresented: $showDealsSheet) {
            MarketplaceExploreView()
        }

        .sheet(isPresented: $showAISuggestionsSheet) {
            MarketplaceExploreView()
        }

        .sheet(isPresented: $showCategoriesSheet) {
            MarketplaceCategoriesView()
        }
        .sheet(isPresented: $showExploreFromBottom) {
            NavigationStack {
                MarketplaceExploreView()
            }
        }

        .sheet(isPresented: $showCategoriesFromBottom) {
            NavigationStack {
                MarketplaceCategoriesView()
            }
        }

        .sheet(isPresented: $showProfileFromBottom) {
            NavigationStack {
                MarketplaceProfileView()
            }
        }

        .sheet(isPresented: $showSellFromBottom) {
            MarketplaceSellView()
        }
        .sheet(isPresented: $showLiveSheet) {
            LiveDiscoveryView()
        }

        .sheet(isPresented: $showFavoritesSheet) {
            MarketplaceFavoritesView()
        }

        .sheet(isPresented: $showOrdersSheet) {
            MarketplaceOrdersView()
        }

        .sheet(isPresented: $showNotificationsSheet) {
            MarketplaceNotificationsView()
        }

        .sheet(isPresented: $showMessagesSheet) {
            MarketplaceMessagesView()
        }

        .sheet(isPresented: $showWalletSheet) {
            MarketplaceWalletView()
        }
        
        
        
        
    }
    
    
    
    
    // MARK: - Top bar (logo + notifications + panier + avatar)
    
    private var topBar: some View {
        HStack(spacing: 10) {

            Button {
                dismiss()
            } label: {
                Label("Retour", systemImage: "chevron.left")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(CutlyPalette.card)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(CutlyPalette.cardStroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button {
                showLogoutConfirmation = true
            } label: {
                Label("Déconnexion", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(Color.red.opacity(0.22))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.red.opacity(0.35), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                showNotificationsSheet = true
            } label: {
                topBarIcon(
                    system: "bell.fill",
                    badge: viewModel.unreadNotificationsCount,
                    badgeColor: CutlyPalette.liveRed
                )
            }
            .buttonStyle(.plain)

            Button {
                showOrdersSheet = true
            } label: {
                topBarIcon(
                    system: "cart.fill",
                    badge: viewModel.activeOrdersCount,
                    badgeColor: CutlyPalette.purple
                )
            }
            .buttonStyle(.plain)
           

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isDarkMode.toggle()
                }
            } label: {
                topBarIcon(
                    system: isDarkMode ? "moon.fill" : "sun.max.fill",
                    badge: 0,
                    badgeColor: CutlyPalette.pink
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private func topBarIcon(system: String, badge: Int, badgeColor: Color) -> some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Circle()
                    .fill(CutlyPalette.card)
                    .frame(width: 42, height: 42)
                
                Image(systemName: system)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(
                Circle()
                    .stroke(CutlyPalette.cardStroke, lineWidth: 1)
            )
            
            if badge > 0 {
                Text(badge > 99 ? "99+" : "\(badge)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeColor)
                    .clipShape(Capsule())
                    .offset(x: 4, y: -4)
            }
        }
    }
    
    // MARK: - Barre de recherche
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            
            HStack(spacing: 10) {
                
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.55))
                
                TextField(
                    "",
                    text: $viewModel.searchText,
                    prompt: Text("Rechercher un produit, une marque, un vendeur…")
                        .foregroundColor(.white.opacity(0.5))
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .onSubmit {
                    viewModel.searchProducts()
                    viewModel.saveSearchHistory()
                }
                .onChange(of: viewModel.searchText) { _ in
                    viewModel.searchProducts()
                    viewModel.loadSearchSuggestions()
                }
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                        viewModel.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(CutlyPalette.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(CutlyPalette.cardStroke, lineWidth: 1)
            )
            
            Button {
                showFiltersSheet = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(CutlyPalette.card)
                        .frame(width: 46, height: 50)
                    
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(CutlyPalette.cardStroke, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Hero section (grande carte violette avec titre + sac 3D)
    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CutlyPalette.heroTop,
                    CutlyPalette.heroBottom,
                    CutlyPalette.purple.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(CutlyPalette.purple.opacity(0.28))
                .frame(width: 220, height: 220)
                .blur(radius: 55)
                .offset(x: animateHeader ? 80 : 45, y: animateHeader ? -45 : -20)

            Circle()
                .fill(CutlyPalette.pink.opacity(0.18))
                .frame(width: 170, height: 170)
                .blur(radius: 45)
                .offset(x: -80, y: 90)

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Achète,\nvends et\ndécouvre\nle meilleur")
                            .font(.system(size: 29, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineSpacing(3)
                            .minimumScaleFactor(0.72)
                            .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 5)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(.ultraThinMaterial.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                        Text("Afrique • Europe • International\nPartout dans le monde")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.82))
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ZStack {
                        Image("marketplaceBag3D")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 155, height: 155)
                            .shadow(color: CutlyPalette.purple.opacity(0.75), radius: 24, x: 0, y: 12)
                            .scaleEffect(animateHeader ? 1.045 : 0.965)
                            .rotation3DEffect(
                                .degrees(animateHeader ? 4.5 : -4.5),
                                axis: (x: 0.12, y: 1.0, z: 0.0)
                            )
                            .animation(
                                .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                                value: animateHeader
                            )
                    }
                    .frame(width: 150, height: 160)
                }

                HStack(spacing: 7) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(i == heroPageIndex ? .white : .white.opacity(0.25))
                            .frame(width: i == heroPageIndex ? 20 : 7, height: 7)
                    }

                    Spacer()
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 330)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.38), radius: 20, x: 0, y: 14)
        .onAppear {
            animateHeader = true
        }
    }
    
    // MARK: - Quick tabs row (icônes rondes)
    
    private var quickTabsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 18) {

                quickCircleButton(
                    title: "Autour de moi",
                    icon: "mappin.and.ellipse",
                    badgeText: nil
                ) {
                    showAroundMeSheet = true
                }

                quickCircleButton(
                    title: "Offres du jour",
                    icon: "tag.fill",
                    badgeText: nil,
                    showDot: true
                ) {
                    showDealsSheet = true
                }

                quickCircleButton(
                    title: "Suggestions",
                    icon: "sparkles",
                    badgeText: nil
                ) {
                    showAISuggestionsSheet = true
                }

                quickCircleButton(
                    title: "Live Shop",
                    icon: "video.fill",
                    badgeText: "LIVE"
                ) {
                    showLiveSheet = true
                }
                .buttonStyle(.plain)

                quickCircleButton(
                    title: "Catégories",
                    icon: "square.grid.2x2.fill",
                    badgeText: nil
                ) {
                    showCategoriesSheet = true
                }

                quickCircleButton(
                    title: "Favoris",
                    icon: "heart.fill",
                    badgeText: nil
                ) {
                    showFavoritesSheet = true
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
    private func quickCircleButton(
        title: String,
        icon: String,
        badgeText: String? = nil,
        showDot: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            quickCircleContent(
                title: title,
                icon: icon,
                badgeText: badgeText,
                showDot: showDot
            )
        }
        .buttonStyle(.plain)
    }

    private func quickCircleContent(
        title: String,
        icon: String,
        badgeText: String?,
        showDot: Bool
    ) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(CutlyPalette.card)
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(CutlyPalette.purple)
                }
                .overlay(
                    Circle()
                        .stroke(CutlyPalette.cardStroke, lineWidth: 1)
                )

                if showDot {
                    Circle()
                        .fill(CutlyPalette.liveRed)
                        .frame(width: 10, height: 10)
                        .offset(x: 2, y: -2)
                }

                if let badgeText = badgeText {
                    Text(badgeText)
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(CutlyPalette.liveRed)
                        .clipShape(Capsule())
                        .offset(x: 4, y: -8)
                }
            }

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 76)
    }
    
    
    
    private func quickTabContent(_ tab: QuickTab) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(CutlyPalette.card)
                        .frame(width: 56, height: 56)

                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(CutlyPalette.purple)
                }
                .overlay(
                    Circle()
                        .stroke(CutlyPalette.cardStroke, lineWidth: 1)
                )

                if tab.badgeDot {
                    Circle()
                        .fill(CutlyPalette.liveRed)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(CutlyPalette.background, lineWidth: 2))
                        .offset(x: 2, y: -2)
                }

                if tab.liveBadge {
                    Text("LIVE")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(CutlyPalette.liveRed)
                        .clipShape(Capsule())
                        .offset(x: 6, y: -6)
                }
            }

            Text(tab.title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
        .frame(width: 68)
    }
    
    
    
    
    
    // MARK: - Autour de moi (radius)
    private var aroundMeSection: some View {
        HStack(spacing: 12) {
            
            ZStack {
                Circle()
                    .fill(CutlyPalette.purple.opacity(0.18))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(CutlyPalette.purple)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                
                Text("Autour de moi")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(
                    "\(locationManager.city.isEmpty ? "Localisation…" : locationManager.city)\(locationManager.country.isEmpty ? "" : ", \(locationManager.country)")"
                )
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
            }
            
            Spacer(minLength: 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    
                    ForEach(viewModel.radiusOptionsKm, id: \.self) { radius in
                        
                        Button {
                            viewModel.selectedRadiusKm = radius
                        } label: {
                            
                            let isSelected = viewModel.selectedRadiusKm == radius
                            
                            Text(radius == 0 ? "Partout" : "\(Int(radius)) km")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    isSelected
                                    ? AnyShapeStyle(.white)
                                    : AnyShapeStyle(.white.opacity(0.75))
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background {
                                    if isSelected {
                                        Capsule()
                                            .fill(CutlyPalette.logoGradient)
                                    } else {
                                        Capsule()
                                            .fill(Color.white.opacity(0.06))
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Button {
                
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(CutlyPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CutlyPalette.cardStroke, lineWidth: 1)
        )
    }
    
    // MARK: - Section \"Offre du jour\" + \"Suggestions IA\" (2 colonnes)
    
    private var twoColumnOfferAndAISection: some View {
        HStack(alignment: .top, spacing: 12) {

            offerOfTheDayCard
                .frame(maxWidth: .infinity)

            aiSuggestionsCard
                .frame(maxWidth: .infinity)
        }
    }
    
    private var offerOfTheDayCard: some View {
        let products = viewModel.applyLocalRadiusFilter(
            products: viewModel.popularProducts,
            locationManager: locationManager
        )

        let offerProduct = products.first { ($0.discountPercent ?? 0) > 0 }

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                icon: "bolt.fill",
                title: "Offre du jour",
                tint: CutlyPalette.orange
            )

            if let product = offerProduct {
                NavigationLink {
                    MarketplaceProductDetailView(product: product)
                } label: {
                    MarketplaceProductCard(
                        product: product,
                        onFavoriteTap: {
                            viewModel.toggleFavorite(product: product)
                        }
                    )
                    .frame(height: 208)
                    .clipped()
                }
                .buttonStyle(.plain)
            } else {
                emptyHomeMiniCard("Aucune offre active")
            }
        }
    }
    
    private var aiSuggestionsCard: some View {
        let products = viewModel.applyLocalRadiusFilter(
            products: viewModel.popularProducts,
            locationManager: locationManager
        )

        let suggestionProduct = products.first

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                icon: "sparkles",
                title: "Suggestions IA",
                tint: CutlyPalette.pink
            )

            if let product = suggestionProduct {
                NavigationLink {
                    MarketplaceProductDetailView(product: product)
                } label: {
                    MarketplaceProductCard(
                        product: product,
                        onFavoriteTap: {
                            viewModel.toggleFavorite(product: product)
                        }
                    )
                    .frame(height: 208)
                    .clipped()
                }
                .buttonStyle(.plain)
            } else {
                emptyHomeMiniCard("Aucune suggestion pour le moment")
            }
        }
    }
    private func sectionHeader(icon: String, title: String, tint: Color) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            NavigationLink {
                MarketplaceExploreView()
            } label: {
                HStack(spacing: 2) {
                    Text("Voir plus")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(CutlyPalette.pink)
            }
            .buttonStyle(.plain)
        }
    }
    private func emptyHomeMiniCard(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: 208)
            .background(CutlyPalette.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    
    private func aiRecommendationMiniCard(_ recommendation: MarketplaceHomeRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 60)

                Image(systemName: recommendation.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(CutlyPalette.pink)
            }

            Text(recommendation.title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(recommendation.subtitle)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    
    private func aiMiniProduct(title: String, price: String, rating: String, icon: String, isNew: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 60)
                    .overlay(
                        // TODO: AsyncImage à brancher
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                    )
                if isNew {
                    Text("Nouveau")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(CutlyPalette.pink)
                        .clipShape(Capsule())
                        .padding(4)
                }
            }
            
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            Text(price)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(CutlyPalette.pink)
            
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .foregroundStyle(CutlyPalette.star)
                Text(rating)
                    .foregroundStyle(.white)
            }
            .font(.system(size: 9, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Produits populaires
    
    private var popularProductsSection: some View {
        let products = viewModel.applyLocalRadiusFilter(
            products: viewModel.popularProducts,
            locationManager: locationManager
        )
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(CutlyPalette.orange)
                    Text("Produits populaires")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button {} label: {
                    HStack(spacing: 2) {
                        Text("Voir plus")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(CutlyPalette.pink)
                }.buttonStyle(.plain)
            }
            
            if products.isEmpty {
                
                // TODO: brancher tes produits Firestore
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    HStack(spacing: 12) {
                        
                        popularPlaceholderCard(
                            title: "Sac de livraison Cutly",
                            price: "9,99 €",
                            oldPrice: nil,
                            city: "Vitré, France",
                            rating: "5.0",
                            shop: "Cutly Shop",
                            verified: true,
                            iconTint: CutlyPalette.purple,
                            icon: "bag.fill"
                        )
                        
                        popularPlaceholderCard(
                            title: "Nike Air Force 1 '07",
                            price: "89,99 €",
                            oldPrice: "119,99 €",
                            city: "Paris, France",
                            rating: "4.8",
                            shop: "Sneakers Elite",
                            verified: true,
                            iconTint: .white,
                            icon: "shoe.fill"
                        )
                        
                        popularPlaceholderCard(
                            title: "iPhone 14 Pro",
                            price: "899,00 €",
                            oldPrice: nil,
                            city: "Lyon, France",
                            rating: "4.7",
                            shop: "TechStore",
                            verified: true,
                            iconTint: .white.opacity(0.9),
                            icon: "iphone"
                        )
                    }
                }
                
            } else {
                
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    HStack(spacing: 12) {
                        
                        ForEach(products) { product in
                            
                            NavigationLink {
                                MarketplaceProductDetailView(product: product)
                            } label: {
                                MarketplaceProductCard(
                                    product: product,
                                    onFavoriteTap: {
                                        viewModel.toggleFavorite(product: product)
                                    }
                                )
                                .frame(width: 185, height: 208)
                                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                                .clipped()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
   
    
    private func popularPlaceholderCard(
        title: String, price: String, oldPrice: String?,
        city: String, rating: String, shop: String,
        verified: Bool, iconTint: Color, icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 165, height: 115)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(iconTint)
                    )
                Image(systemName: "heart")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(Color.black.opacity(0.35)))
                    .padding(6)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                Text(price)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(CutlyPalette.pink)
                if let old = oldPrice {
                    Text(old)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .strikethrough()
                }
            }
            
            Text(city)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill").foregroundStyle(CutlyPalette.star)
                Text(rating).foregroundStyle(.white)
                Text("• \(shop)").foregroundStyle(.white.opacity(0.55))
                if verified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(CutlyPalette.verifiedBlue)
                }
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .padding(10)
        .frame(width: 185)
        .background(CutlyPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CutlyPalette.cardStroke, lineWidth: 1)
        )
    }
    
    // MARK: - Mini actions (Suivi / Vendre / Commandes / Revenus / Messages)
    
    private var miniActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(miniActions) { action in
                    Button {
                        openMiniAction(action.destination)
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle().fill(action.tint.opacity(0.20))
                                    .frame(width: 32, height: 32)
                                Image(systemName: action.icon)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(action.tint)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text(action.title)
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)

                                Text(action.subtitle)
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(CutlyPalette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(CutlyPalette.cardStroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    private func openMiniAction(_ destination: Destination) {
        switch destination {
        case .tracking, .orders:
            showOrdersSheet = true
        case .sell:
            showSellFromBottom = true
        case .wallet:
            showWalletSheet = true
        case .messages:
            showMessagesSheet = true
        default:
            break
        }
    }
    
    
    
    
    
    // MARK: - Résultats de recherche (préserve les résultats du ViewModel)
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            HStack {
                Text("Résultats de recherche")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text(
                    viewModel.isSearching
                    ? "Recherche en cours…"
                    : "\(viewModel.searchResults.count) résultat(s)"
                )
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, 16)
            
            if viewModel.isSearching {
                
                VStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 18)
                            .fill(CutlyPalette.card)
                            .frame(height: 88)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(CutlyPalette.cardStroke, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)
                
            } else if viewModel.searchResults.isEmpty {
                
                emptyRow(
                    title: "Aucun résultat",
                    subtitle: "Essayez avec un autre mot-clé ou une autre catégorie.",
                    icon: "magnifyingglass"
                )
                .padding(.horizontal, 16)
                
            } else {
                
                LazyVStack(spacing: 10) {
                    
                    ForEach(viewModel.searchResults) { product in
                        
                        NavigationLink {
                            MarketplaceExploreView()
                        } label: {
                            searchResultRow(product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    private func searchResultRow(_ product: MarketplaceHomeProduct) -> some View {
        HStack(spacing: 12) {
            
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .frame(width: 60, height: 60)
                .overlay(
                    Group {
                        if let urlStr = product.imageURL,
                           let url = URL(string: urlStr) {
                            
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "bag.fill")
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            
                        } else {
                            
                            Image(systemName: "bag.fill")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            
            VStack(alignment: .leading, spacing: 3) {
                
                HStack(spacing: 4) {
                    
                    Text(product.title)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                    
                    if product.sellerVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(CutlyPalette.verifiedBlue)
                    }
                }
                .foregroundStyle(.white)
                
                Text(cutlyHomePriceText(product.priceText))
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(CutlyPalette.pink)
                
                if !product.country.isEmpty {
                    Text(product.country)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(12)
        .background(CutlyPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(CutlyPalette.cardStroke, lineWidth: 1)
        )
    }
    
    private func emptyRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.white.opacity(0.06)).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundStyle(.white.opacity(0.7))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                Text(subtitle).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
        }
        .padding(14)
        .background(CutlyPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(CutlyPalette.cardStroke, lineWidth: 1))
    }
    
    // MARK: - Bottom Tab Bar
    
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            bottomTabItem(.home,       title: "Accueil",    icon: "house.fill")
            bottomTabItem(.explore,    title: "Explorer",   icon: "magnifyingglass")
            
            // Bouton + central
            Button {
                showSellFromBottom = true
            } label: {
                ZStack {
                    Circle()
                        .fill(CutlyPalette.bottomPlusGradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: CutlyPalette.pink.opacity(0.55), radius: 12, x: 0, y: 6)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)
                }
                .offset(y: -14)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            
            bottomTabItem(.categories, title: "Catégories", icon: "square.grid.2x2.fill")
            bottomTabItem(.profile,    title: "Profil",     icon: "person.fill")
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(
            CutlyPalette.card
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color.white.opacity(0.06)),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func bottomTabItem(_ tab: BottomTab, title: String, icon: String) -> some View {
        Button {
            selectedBottomTab = tab

            if tab == .explore {
                showExploreFromBottom = true
            }

            if tab == .categories {
                showCategoriesFromBottom = true
            }

            if tab == .profile {
                showProfileFromBottom = true
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(selectedBottomTab == tab ? CutlyPalette.pink : .white.opacity(0.6))

                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(selectedBottomTab == tab ? CutlyPalette.pink : .white.opacity(0.6))

                Capsule()
                    .fill(selectedBottomTab == tab ? CutlyPalette.pink : Color.clear)
                    .frame(width: 18, height: 3)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Navigation helpers
    
    @ViewBuilder
    private func destinationView(_ destination: Destination) -> some View {
        switch destination {
        case .explore:       MarketplaceExploreView()
        case .categories:    MarketplaceCategoriesView()
        case .favorites:     MarketplaceFavoritesView()
        case .messages:      MarketplaceMessagesView()
        case .orders:        MarketplaceOrdersView()
        case .tracking:      MarketplaceOrdersView()
        case .sell:          MarketplaceSellView()
        case .wallet:        MarketplaceWalletView()
        case .profile:       MarketplaceProfileView()
        case .notifications: MarketplaceNotificationsView()
        case .settings:      MarketplaceSettingsView()
        case .support:       MarketplaceHelpCenterView()
        case .legal:         MarketplaceLegalPrivacyView()
        case .live:          LiveDiscoveryView()
        }
    }
    
    // MARK: - Formatage prix (identique au fichier d'origine, préservé)

            private func cutlyHomePriceText(_ text: String) -> String {

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

                return String(format: "%.2f €", value)
                    .replacingOccurrences(of: ".", with: ",")
            }
    
    
    
    
    
}
private struct MarketplaceFilterSheet: View {
    @Binding var selectedRadiusKm: Double
    let radiusOptionsKm: [Double]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Filtres marketplace")
                        .font(.system(.title2, design: .rounded).weight(.black))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Distance")
                            .font(.headline.bold())

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(radiusOptionsKm, id: \.self) { radius in
                                    Button {
                                        selectedRadiusKm = radius
                                    } label: {
                                        Text(radius == 0 ? "Partout" : "\(Int(radius)) km")
                                            .font(.caption.bold())
                                            .foregroundStyle(selectedRadiusKm == radius ? .white : .primary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedRadiusKm == radius
                                                ? AnyView(CutlyPalette.logoGradient)
                                                : AnyView(Color.primary.opacity(0.08))
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    FilterRow(icon: "tag.fill", title: "Prix & promotions", subtitle: "Offres, réductions, flash sales")
                    FilterRow(icon: "square.grid.2x2.fill", title: "Catégories", subtitle: "Mode, beauté, électronique, maison")
                    FilterRow(icon: "checkmark.seal.fill", title: "Vendeurs vérifiés", subtitle: "Afficher les boutiques certifiées")
                    FilterRow(icon: "star.fill", title: "Notes", subtitle: "Produits les mieux notés")
                    FilterRow(icon: "shippingbox.fill", title: "Livraison", subtitle: "Retrait, point relais, domicile")
                }
                .padding(20)
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct FilterRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(CutlyPalette.logoGradient)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.bold())

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
private struct AroundMeRadiusSheet: View {
    @Binding var selectedRadiusKm: Double

    let city: String
    let country: String

    @State private var customRadius: Double = 50

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Autour de moi")
                        .font(.system(.title2, design: .rounded).weight(.black))

                    Text("\(city.isEmpty ? "Position actuelle" : city)\(country.isEmpty ? "" : ", \(country)")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Button {
                        selectedRadiusKm = 0
                    } label: {
                        Text("Partout")
                            .font(.headline.bold())
                            .foregroundStyle(selectedRadiusKm == 0 ? .white : .primary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(selectedRadiusKm == 0 ? AnyView(CutlyPalette.logoGradient) : AnyView(Color.primary.opacity(0.08)))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectedRadiusKm = customRadius
                    } label: {
                        Text("\(Int(customRadius)) km")
                            .font(.headline.bold())
                            .foregroundStyle(selectedRadiusKm != 0 ? .white : .primary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(selectedRadiusKm != 0 ? AnyView(CutlyPalette.logoGradient) : AnyView(Color.primary.opacity(0.08)))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Distance personnalisée")
                            .font(.headline.bold())

                        Spacer()

                        Text("\(Int(customRadius)) km")
                            .font(.headline.bold())
                            .foregroundStyle(CutlyPalette.pink)
                    }

                    Slider(value: $customRadius, in: 1...1000, step: 1) {
                        Text("Distance")
                    } minimumValueLabel: {
                        Text("1")
                    } maximumValueLabel: {
                        Text("1000")
                    }
                    .onChange(of: customRadius) { newValue in
                        selectedRadiusKm = newValue
                    }
                }

                Text("Les produits affichés seront filtrés selon la distance choisie.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(22)
            .navigationTitle("Localisation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}



        // MARK: - Preview

        #Preview {
            NavigationStack {
                MarketplacePremiumHomeView()
            }
            .preferredColorScheme(.dark)
        }
