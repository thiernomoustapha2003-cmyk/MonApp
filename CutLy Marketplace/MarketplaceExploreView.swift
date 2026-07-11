//
//  MarketplaceExploreView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY on 30/06/2026.
//  Refonte visuelle — structure Firestore / Storage inchangée.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore








private enum MarketplaceExploreTab {
    case home
    case explore
    case publish
    case messages
    case profile
}




struct MarketplaceExploreView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("marketplaceExploreTheme") private var marketplaceExploreTheme = "system"

    private var forcedColorScheme: ColorScheme? {
        switch marketplaceExploreTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    
    
    @State private var selectedTab: MarketplaceExploreTab = .explore
    
    @State private var navigateToHome = false
    
    @StateObject private var viewModel = MarketplaceExploreViewModel()
    @StateObject private var locationManager = MarketplaceLocationManager.shared

    @State private var isGridLayout = true

    @State private var showCategoryFilter = false
    @State private var showCountryFilter = false
    @State private var showBudgetFilter = false
    @State private var showAllFilters = false
    
    @State private var navigateToPublish = false
    
    @State private var navigateToMessages = false
    @State private var unreadMessagesCount = 0
    
    @State private var navigateToProfile = false
    
    @State private var navigateToNotifications = false
    
    

    @State private var selectedCategory: String = "Toutes"

    private let categories = [
        "Toutes", "Mode", "Électronique", "Véhicules",
        "Immobilier", "Bien-être", "Maison"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    topBar

                    searchBar

                    filterChipsRow

                    ScrollView(showsIndicators: false) {

                        VStack(spacing: 16) {

                            resultsHeader

                            productsContent

                        }
                        .padding(.top, 14)
                        .padding(.bottom, 120)

                    }
                    .refreshable {

                        viewModel.loadProducts()

                    }

                }
                .safeAreaInset(edge: .bottom) {

                    marketplaceBottomBar

                }
            }
            .navigationBarHidden(true)
            .onAppear {
                locationManager.requestLocation()
                locationManager.startLiveTracking()

                viewModel.updateUserLocation(from: locationManager)
                viewModel.startFavoritesListener()
                viewModel.loadProducts()
                loadUnreadMarketplaceMessages()
            }
            .onDisappear {
                locationManager.stopLiveTracking()
            }
            .sheet(isPresented: $showCountryFilter) {
                MarketplaceExploreCountryFilterSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showBudgetFilter) {
                MarketplaceExploreBudgetFilterSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showAllFilters) {
                MarketplaceExploreAllFiltersSheet(
                    viewModel: viewModel,
                    locationManager: locationManager
                )
            }
            .sheet(isPresented: $showCategoryFilter) {
                MarketplaceExploreCategorySheet(
                    categories: categories,
                    selected: $selectedCategory
                )
            }
            .navigationDestination(isPresented: $navigateToPublish) {
                MarketplaceSellView()
            }
            .navigationDestination(isPresented: $navigateToMessages) {
                MarketplaceMessagesView()
            }
            .navigationDestination(isPresented: $navigateToProfile) {
                MarketplaceProfileView()
            }
            .navigationDestination(isPresented: $navigateToHome) {
                MarketplacePremiumHomeView()
            }
            .navigationDestination(isPresented: $navigateToNotifications) {
                MarketplaceNotificationsView()
            }
            
            
            
            
            .preferredColorScheme(forcedColorScheme)
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: 42, height: 42)
                    .background(.regularMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Explorer")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 12) {
                Menu {
                    Button {
                        showAllFilters = true
                    } label: {
                        Label("Filtres", systemImage: "slider.horizontal.3")
                    }

                    Divider()

                    Button {
                        marketplaceExploreTheme = "light"
                    } label: {
                        Label("Mode clair", systemImage: "sun.max.fill")
                    }

                    Button {
                        marketplaceExploreTheme = "dark"
                    } label: {
                        Label("Mode sombre", systemImage: "moon.fill")
                    }

                    Button {
                        marketplaceExploreTheme = "system"
                    } label: {
                        Label("Automatique", systemImage: "iphone")
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 42, height: 42)
                        .background(.regularMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    navigateToNotifications = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 42, height: 42)
                            .background(.regularMaterial)
                            .clipShape(Circle())

                        if notificationBadgeCount > 0 {
                            Text(notificationBadgeCount > 99 ? "99+" : "\(notificationBadgeCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(minWidth: 19, minHeight: 19)
                                .background(.purple)
                                .clipShape(Capsule())
                                .offset(x: 5, y: -4)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.secondary)

            TextField("Rechercher un produit, une marque...", text: $viewModel.searchText)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { viewModel.searchProducts() }
                .onChange(of: viewModel.searchText) { _ in
                    viewModel.searchProducts()
                }

            if !viewModel.searchText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        viewModel.clearSearch()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Filter chips

    private var filterChipsRow: some View {

        HStack(spacing: 8) {

            MarketplaceExploreChip(
                title: selectedCategory == "Toutes" ? "Catégories" : selectedCategory,
                showsChevron: true
            ) {
                showCategoryFilter = true
            }

            MarketplaceExploreChip(
                title: viewModel.selectedCountry.isEmpty ? "Tous les pays" : viewModel.selectedCountry,
                showsChevron: true
            ) {
                showCountryFilter = true
            }

            MarketplaceExploreChip(
                title: "Prix",
                showsChevron: true
            ) {
                showBudgetFilter = true
            }

            MarketplaceExploreChip(
                title: "Filtres",
                icon: "slider.horizontal.3",
                showsChevron: false
            ) {
                showAllFilters = true
            }

        }
        .padding(.horizontal,16)
        .padding(.bottom,14)

    }

    private var priceChipTitle: String {
        guard viewModel.minimumPrice != nil || viewModel.maximumPrice != nil else {
            return "Prix"
        }

        let minText = viewModel.minimumPrice.map { "\(Int($0)) €" } ?? "Min"
        let maxText = viewModel.maximumPrice.map { "\(Int($0)) €" } ?? "Max"

        return "\(minText) - \(maxText)"
    }

    // MARK: - Results header

    private var resultsHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Produits disponibles")
                    .font(.system(.title3, design: .rounded).weight(.black))
                    .foregroundStyle(.primary)

                Text("\(viewModel.products.count) produit(s) trouvé(s)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isGridLayout = true }
                } label: {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isGridLayout ? .white : .secondary)
                        .frame(width: 34, height: 34)
                        .background(isGridLayout ? AnyView(MarketplaceUITheme.primaryGradient) : AnyView(Color.primary.opacity(0.06)))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isGridLayout = false }
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(!isGridLayout ? .white : .secondary)
                        .frame(width: 34, height: 34)
                        .background(!isGridLayout ? AnyView(MarketplaceUITheme.primaryGradient) : AnyView(Color.primary.opacity(0.06)))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Products content
    @ViewBuilder
    private var productsContent: some View {
        if viewModel.isLoading && viewModel.products.isEmpty {
            LazyVGrid(columns: gridColumns, spacing: 7) {
                ForEach(0..<6, id: \.self) { _ in
                    MarketplaceSkeletonView(cornerRadius: 26)
                        .frame(height: 208)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .clipped()
                }
            }
            .padding(.horizontal, 16)

        } else if viewModel.products.isEmpty {
            MarketplaceExploreEmptyState()
                .padding(.horizontal, 16)
                .padding(.top, 30)

        } else if isGridLayout {
            LazyVGrid(columns: gridColumns, spacing: 7) {
                ForEach(viewModel.products) { product in
                    NavigationLink {
                        MarketplaceProductDetailView(product: product)
                    } label: {
                        MarketplaceProductCard(
                            product: product,
                            onFavoriteTap: {
                                viewModel.toggleFavorite(product: product)
                            }
                        )
                        .onAppear {
                            viewModel.loadMoreIfNeeded(current: product)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

        } else {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.products) { product in
                    NavigationLink {
                        MarketplaceProductDetailView(product: product)
                    } label: {
                        MarketplaceProductListCard(product: product)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .onAppear {
                                viewModel.loadMoreIfNeeded(current: product)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 0), spacing: 7),
            GridItem(.flexible(minimum: 0), spacing: 7)
        ]
    }

    

    // Lit un éventuel compteur de notifications sur le ViewModel sans exiger
    // que la propriété existe (évite toute erreur de compilation si ton
    // MarketplaceExploreViewModel ne l'a pas encore). Ajoute une propriété
    // `notificationCount: Int` à ton ViewModel pour l'activer automatiquement.
    private var notificationBadgeCount: Int {
        for child in Mirror(reflecting: viewModel).children {
            if child.label == "notificationCount", let value = child.value as? Int {
                return value
            }
        }
        return 0
    }
}

// MARK: - Filter chip

private struct MarketplaceExploreChip: View {

    let title: String
    var icon: String? = nil
    var showsChevron = false
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            HStack(spacing: 5) {

                if let icon {

                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))

                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                if showsChevron {

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))

                }

            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(.regularMaterial)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )

        }
        .buttonStyle(.plain)

    }

}

// MARK: - Empty state

private struct MarketplaceExploreEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.secondary)

            Text("Aucun produit trouvé")
                .font(.system(.headline, design: .rounded).weight(.bold))

            Text("Essaie un autre mot-clé, une autre catégorie ou réinitialise les filtres.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}


private struct MarketplaceExploreCategorySheet: View {
    let categories: [String]
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selected = category
                        dismiss()
                    } label: {
                        HStack {
                            Text(category)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selected == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Catégories")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Country filter sheet

private struct MarketplaceExploreCountryFilterSheet: View {
    @ObservedObject var viewModel: MarketplaceExploreViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private var allCountries: [String] {
        Locale.Region.isoRegions
            .compactMap { region in
                Locale.current.localizedString(forRegionCode: region.identifier)
            }
            .sorted()
    }

    private var filteredCountries: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return allCountries
        }

        return allCountries.filter {
            $0.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    viewModel.selectedCountry = ""
                    viewModel.applyFilters()
                    dismiss()
                } label: {
                    HStack {
                        Text("Tous les pays")
                        Spacer()

                        if viewModel.selectedCountry.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.purple)
                        }
                    }
                }

                ForEach(filteredCountries, id: \.self) { country in
                    Button {
                        viewModel.selectedCountry = country
                        viewModel.applyFilters()
                        dismiss()
                    } label: {
                        HStack {
                            Text(country)
                            Spacer()

                            if viewModel.selectedCountry == country {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.purple)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Rechercher un pays")
            .navigationTitle("Pays")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Budget filter sheet

private struct MarketplaceExploreBudgetFilterSheet: View {
    @ObservedObject var viewModel: MarketplaceExploreViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var minText = ""
    @State private var maxText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Filtrer par prix")
                    .font(.title2.bold())

                TextField("Prix minimum", text: $minText)
                    .keyboardType(.decimalPad)
                    .marketplaceExploreSheetField()

                TextField("Prix maximum", text: $maxText)
                    .keyboardType(.decimalPad)
                    .marketplaceExploreSheetField()

                Button {
                    viewModel.minimumPrice = Double(minText.replacingOccurrences(of: ",", with: ".")) ?? 0
                    viewModel.maximumPrice = Double(maxText.replacingOccurrences(of: ",", with: ".")) ?? 1_000_000
                    viewModel.applyFilters()
                    dismiss()
                } label: {
                    Label("Appliquer", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(MarketplacePremiumButtonStyle())

                Button("Réinitialiser le prix") {
                    viewModel.minimumPrice = nil
                    viewModel.maximumPrice = nil
                    viewModel.applyFilters()
                    dismiss()
                }
                .font(.subheadline.bold())

                Spacer()
            }
            .padding()
            .navigationTitle("Prix")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Combined filters sheet (livraison, état, distance)

private struct MarketplaceExploreAllFiltersSheet: View {
    @ObservedObject var viewModel: MarketplaceExploreViewModel
    @ObservedObject var locationManager: MarketplaceLocationManager
    @Environment(\.dismiss) private var dismiss

    private let distances: [Double] = [0, 5, 10, 25, 50, 100, 250]

    var body: some View {
        NavigationStack {
            List {
                Section("Livraison") {
                    Toggle("Livraison disponible", isOn: $viewModel.onlyDelivery)
                    Toggle("Retrait en main propre", isOn: $viewModel.onlyPickup)
                }

                Section("État du produit") {
                    Button("Tous les états") {
                        viewModel.selectedCondition = ""
                    }
                    ForEach(MarketplaceProductCondition.allCases) { condition in
                        Button {
                            viewModel.selectedCondition = condition.title
                        } label: {
                            HStack {
                                Text(condition.title).foregroundStyle(.primary)
                                Spacer()
                                if viewModel.selectedCondition == condition.title {
                                    Image(systemName: "checkmark").foregroundStyle(.purple)
                                }
                            }
                        }
                    }
                }

                Section("Distance") {
                    ForEach(distances, id: \.self) { distance in
                        Button {
                            viewModel.radiusKm = distance
                        } label: {
                            HStack {
                                Text(distance == 0 ? "Partout" : "\(Int(distance)) km")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if viewModel.radiusKm == distance {
                                    Image(systemName: "checkmark").foregroundStyle(.purple)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Réinitialiser") {
                        viewModel.resetFilters()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    viewModel.updateUserLocation(from: locationManager)
                    viewModel.applyFilters()
                    viewModel.loadProducts()
                    dismiss()
                } label: {
                    Label("Appliquer les filtres", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(MarketplacePremiumButtonStyle())
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Shared sheet field style

private extension View {
    func marketplaceExploreSheetField() -> some View {
        self
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Price formatting helper

private func formatMarketplacePrice(_ text: String) -> String {
    let cleaned = text
        .replacingOccurrences(of: "EUR", with: "")
        .replacingOccurrences(of: "Euro", with: "")
        .replacingOccurrences(of: "€", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    let normalized = cleaned.replacingOccurrences(of: ",", with: ".")

    guard let value = Double(normalized) else {
        return text.replacingOccurrences(of: "EUR", with: "€")
    }

    if value.truncatingRemainder(dividingBy: 1) == 0 {
        return "\(Int(value)) €"
    } else {
        return String(format: "%.2f €", value).replacingOccurrences(of: ".", with: ",")
    }
}
// MARK: - Marketplace Bottom Bar
private extension MarketplaceExploreView {

    var marketplaceBottomBar: some View {

        HStack(spacing: 0) {

            bottomBarItem(
                icon: "house.fill",
                title: "Accueil",
                isSelected: selectedTab == MarketplaceExploreTab.home
            ) {
                selectedTab = MarketplaceExploreTab.home
                navigateToHome = true
            }

            Spacer()

            bottomBarItem(
                icon: "magnifyingglass",
                title: "Explorer",
                isSelected: selectedTab == MarketplaceExploreTab.explore
            ) {
                selectedTab = MarketplaceExploreTab.explore
            }

            Spacer()

            Button {
                selectedTab = MarketplaceExploreTab.publish
                navigateToPublish = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(MarketplaceUITheme.primaryGradient)
                    .clipShape(Circle())
                    .shadow(color: .purple.opacity(0.45), radius: 18, y: 10)
            }
            .buttonStyle(.plain)
            .offset(y: -18)

            Spacer()

            ZStack(alignment: .topTrailing) {
                bottomBarItem(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Messages",
                    isSelected: selectedTab == MarketplaceExploreTab.messages
                ) {
                    selectedTab = MarketplaceExploreTab.messages
                    navigateToMessages = true
                }

                if unreadMessagesCount > 0 {
                    Text(unreadMessagesCount > 99 ? "99+" : "\(unreadMessagesCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(.red)
                        .clipShape(Capsule())
                        .offset(x: 12, y: -4)
                }
            }

            Spacer()

            bottomBarItem(
                icon: "person.fill",
                title: "Profil",
                isSelected: selectedTab == MarketplaceExploreTab.profile
            ) {
                selectedTab = MarketplaceExploreTab.profile
                navigateToProfile = true
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    func bottomBarItem(
        icon: String,
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))

                Text(title)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(
                isSelected
                ? AnyShapeStyle(MarketplaceUITheme.primaryGradient)
                : AnyShapeStyle(Color.secondary)
            )
        }
        .buttonStyle(.plain)
    }
}

private extension MarketplaceExploreView {

    func loadUnreadMarketplaceMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            unreadMessagesCount = 0
            return
        }

        Firestore.firestore()
            .collection("marketplace_conversations")
            .whereField("participantIds", arrayContains: uid)
            .addSnapshotListener { snapshot, error in

                if let error {
                    print("❌ unread messages:", error.localizedDescription)
                    return
                }

                let count = snapshot?.documents.filter { document in
                    let unreadFor = document.data()["unreadFor"] as? [String] ?? []
                    return unreadFor.contains(uid)
                }.count ?? 0

                unreadMessagesCount = count
            }
    }
}








#Preview {
    MarketplaceExploreView()
}
