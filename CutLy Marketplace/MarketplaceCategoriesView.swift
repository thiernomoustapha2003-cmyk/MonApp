//
//  MarketplaceCategoriesView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI

struct MarketplaceCategoriesView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategoryId: String = "beauty"
    @State private var searchText: String = ""

    private let categories: [MarketplaceCategory] = [
        .init(id: "beauty", name: "Beauté", icon: "sparkles", gradientStartHex: "#F97316", gradientEndHex: "#EC4899", isFeatured: true),
        .init(id: "hair", name: "Cheveux & Coiffure", icon: "scissors", gradientStartHex: "#8B5CF6", gradientEndHex: "#EC4899", isFeatured: true),
        .init(id: "wigs_extensions", name: "Perruques & Extensions", icon: "person.crop.circle", gradientStartHex: "#A855F7", gradientEndHex: "#EC4899", isFeatured: true),
        .init(id: "makeup", name: "Maquillage", icon: "paintbrush.fill", gradientStartHex: "#FB7185", gradientEndHex: "#F97316"),
        .init(id: "skincare", name: "Soins visage & corps", icon: "drop.fill", gradientStartHex: "#06B6D4", gradientEndHex: "#3B82F6"),
        .init(id: "perfume", name: "Parfums", icon: "sparkles", gradientStartHex: "#F59E0B", gradientEndHex: "#EC4899"),

        .init(id: "fashion_women", name: "Mode Femme", icon: "tshirt.fill", gradientStartHex: "#EC4899", gradientEndHex: "#7C3AED", isFeatured: true),
        .init(id: "fashion_men", name: "Mode Homme", icon: "figure.stand", gradientStartHex: "#111827", gradientEndHex: "#2563EB", isFeatured: true),
        .init(id: "shoes", name: "Chaussures", icon: "shoeprints.fill", gradientStartHex: "#0F172A", gradientEndHex: "#F97316"),
        .init(id: "bags", name: "Sacs & Bagagerie", icon: "bag.fill", gradientStartHex: "#7C2D12", gradientEndHex: "#F59E0B"),
        .init(id: "jewelry", name: "Bijoux", icon: "diamond.fill", gradientStartHex: "#FACC15", gradientEndHex: "#F97316"),
        .init(id: "watches", name: "Montres", icon: "applewatch", gradientStartHex: "#111827", gradientEndHex: "#64748B"),

        .init(id: "phones", name: "Téléphones", icon: "iphone", gradientStartHex: "#0EA5E9", gradientEndHex: "#2563EB", isFeatured: true),
        .init(id: "electronics", name: "Électronique", icon: "desktopcomputer", gradientStartHex: "#06B6D4", gradientEndHex: "#3B82F6", isFeatured: true),
        .init(id: "computers", name: "Informatique", icon: "laptopcomputer", gradientStartHex: "#1E293B", gradientEndHex: "#3B82F6"),
        .init(id: "gaming", name: "Gaming", icon: "gamecontroller.fill", gradientStartHex: "#7C3AED", gradientEndHex: "#2563EB"),
        .init(id: "photo_video", name: "Photo & Vidéo", icon: "camera.fill", gradientStartHex: "#0F172A", gradientEndHex: "#6366F1"),
        .init(id: "audio", name: "Audio & Casques", icon: "headphones", gradientStartHex: "#18181B", gradientEndHex: "#22C55E"),

        .init(id: "home", name: "Maison", icon: "house.fill", gradientStartHex: "#10B981", gradientEndHex: "#059669", isFeatured: true),
        .init(id: "furniture", name: "Meubles", icon: "bed.double.fill", gradientStartHex: "#92400E", gradientEndHex: "#F59E0B"),
        .init(id: "kitchen", name: "Cuisine", icon: "fork.knife", gradientStartHex: "#EF4444", gradientEndHex: "#F97316"),
        .init(id: "appliances", name: "Électroménager", icon: "washer.fill", gradientStartHex: "#64748B", gradientEndHex: "#0EA5E9"),
        .init(id: "garden", name: "Jardin & Extérieur", icon: "leaf.fill", gradientStartHex: "#16A34A", gradientEndHex: "#84CC16"),

        .init(id: "cars", name: "Voitures", icon: "car.fill", gradientStartHex: "#F59E0B", gradientEndHex: "#EF4444"),
        .init(id: "auto_parts", name: "Pièces Auto", icon: "wrench.and.screwdriver.fill", gradientStartHex: "#334155", gradientEndHex: "#F97316"),
        .init(id: "motorcycles", name: "Moto & Scooter", icon: "bicycle", gradientStartHex: "#111827", gradientEndHex: "#EF4444"),
        .init(id: "tools", name: "Bricolage & Outils", icon: "hammer.fill", gradientStartHex: "#78716C", gradientEndHex: "#F59E0B"),

        .init(id: "babies", name: "Bébés & Enfants", icon: "figure.and.child.holdinghands", gradientStartHex: "#FBBF24", gradientEndHex: "#FB7185"),
        .init(id: "toys", name: "Jouets", icon: "teddybear.fill", gradientStartHex: "#A78BFA", gradientEndHex: "#FB7185"),
        .init(id: "school", name: "École & Fournitures", icon: "book.fill", gradientStartHex: "#2563EB", gradientEndHex: "#06B6D4"),

        .init(id: "sports", name: "Sport", icon: "sportscourt.fill", gradientStartHex: "#22C55E", gradientEndHex: "#0EA5E9"),
        .init(id: "health", name: "Santé & Bien-être", icon: "heart.fill", gradientStartHex: "#EF4444", gradientEndHex: "#EC4899"),
        .init(id: "books", name: "Livres", icon: "books.vertical.fill", gradientStartHex: "#92400E", gradientEndHex: "#F97316"),
        .init(id: "music", name: "Musique", icon: "music.note", gradientStartHex: "#7C3AED", gradientEndHex: "#EC4899"),
        .init(id: "art", name: "Art & Collection", icon: "paintpalette.fill", gradientStartHex: "#F97316", gradientEndHex: "#8B5CF6"),

        .init(id: "food", name: "Alimentation", icon: "cart.fill", gradientStartHex: "#16A34A", gradientEndHex: "#F59E0B"),
        .init(id: "local_products", name: "Produits locaux", icon: "leaf.fill", gradientStartHex: "#15803D", gradientEndHex: "#CA8A04", isFeatured: true),
        .init(id: "african_craft", name: "Artisanat africain", icon: "globe.europe.africa.fill", gradientStartHex: "#92400E", gradientEndHex: "#F59E0B", isFeatured: true),
        .init(id: "traditional_clothes", name: "Tenues traditionnelles", icon: "person.fill", gradientStartHex: "#B45309", gradientEndHex: "#EC4899"),
        .init(id: "religion_events", name: "Religion & Événements", icon: "moon.stars.fill", gradientStartHex: "#111827", gradientEndHex: "#F59E0B"),

        .init(id: "professional", name: "Matériel professionnel", icon: "briefcase.fill", gradientStartHex: "#334155", gradientEndHex: "#2563EB"),
        .init(id: "construction", name: "Construction", icon: "building.2.fill", gradientStartHex: "#78716C", gradientEndHex: "#F97316"),
        .init(id: "agriculture", name: "Agriculture", icon: "tree.fill", gradientStartHex: "#166534", gradientEndHex: "#84CC16"),
        .init(id: "animals", name: "Animaux", icon: "pawprint.fill", gradientStartHex: "#A16207", gradientEndHex: "#F59E0B"),
        .init(id: "services", name: "Services", icon: "person.2.fill", gradientStartHex: "#0EA5E9", gradientEndHex: "#7C3AED")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        heroSection
                        searchSection
                        featuredCategoriesSection
                        allCategoriesSection
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Catégories")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Catégories Marketplace")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Beauté, coiffure, mode, téléphones, maison, auto et produits africains.")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(3)
                }

                Spacer()

                MarketplaceIconBadge(icon: "square.grid.2x2.fill", size: 58)
            }

            HStack(spacing: 10) {
                MarketplaceCategoryHeroChip(title: "Premium", icon: "crown.fill")
                MarketplaceCategoryHeroChip(title: "Afrique", icon: "globe.europe.africa.fill")
                MarketplaceCategoryHeroChip(title: "Local", icon: "location.fill")
            }
        }
        .padding(22)
        .background(MarketplaceUITheme.darkLuxuryGradient)
        .clipShape(RoundedRectangle(cornerRadius: MarketplaceUITheme.cornerXL, style: .continuous))
        .overlay(MarketplaceUITheme.premiumStroke(colorScheme: colorScheme, cornerRadius: MarketplaceUITheme.cornerXL))
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 16)
        .padding(.horizontal, 16)
    }

    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.secondary)

            TextField("Rechercher une catégorie...", text: $searchText)
                .font(.system(.body, design: .rounded).weight(.semibold))

            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(MarketplaceUITheme.glassBackground(colorScheme: colorScheme, cornerRadius: 24))
        .padding(.horizontal, 16)
    }

    private var featuredCategoriesSection: some View {
        VStack(spacing: 14) {
            MarketplaceSectionHeader(
                title: "Catégories populaires",
                subtitle: "Les univers les plus demandés",
                actionTitle: "Voir tout",
                action: {}
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(categories.filter { $0.isFeatured }) { category in
                        MarketplaceFeaturedCategoryCard(category: category)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var allCategoriesSection: some View {
        VStack(spacing: 14) {
            MarketplaceSectionHeader(
                title: "Toutes les catégories",
                subtitle: "Organisation prête pour sous-catégories et filtres",
                actionTitle: nil,
                action: nil
            )

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ], spacing: 14) {
                ForEach(filteredCategories) { category in
                    MarketplaceCategoryGridCard(
                        category: category,
                        isSelected: selectedCategoryId == category.id
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            selectedCategoryId = category.id
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var filteredCategories: [MarketplaceCategory] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return categories
        }

        return categories.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Components

private struct MarketplaceCategoryHeroChip: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(.caption2, design: .rounded).weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.14))
        .clipShape(Capsule())
    }
}

private struct MarketplaceFeaturedCategoryCard: View {
    let category: MarketplaceCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceIconBadge(icon: category.icon, size: 48)

            Spacer()

            Text(category.name)
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundStyle(.white)

            Text("Découvrir maintenant")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(width: 190, height: 160, alignment: .leading)
        .padding(16)
        .background(MarketplaceUITheme.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 12)
    }
}

private struct MarketplaceCategoryGridCard: View {
    let category: MarketplaceCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                MarketplaceIconBadge(icon: category.icon, size: 46)

                Text(category.name)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(isSelected ? "Sélectionnée" : "Voir les produits")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isSelected ? AnyView(MarketplaceUITheme.primaryGradient) : AnyView(Color.primary.opacity(0.06)))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 165, alignment: .leading)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(isSelected ? Color.orange.opacity(0.55) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MarketplaceCategoriesView()
}
