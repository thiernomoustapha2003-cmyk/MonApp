//
//  MarketplaceStoreView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI

struct MarketplaceStoreView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var isFollowing = false
    @State private var selectedTab: MarketplaceStoreTab = .products
    @State private var animateHeader = false
    @State private var showFirestoreReadyBadge = true
    
    
    
    

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        storeHeroSection
                        storeStatsSection
                        certificationSection
                        certificationPlanSection
                        storeTrustSection
                        storeTabsSection
                        storeContentSection
                        MarketplaceStoreActionPanel()
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Boutique")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var storeHeroSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: MarketplaceUITheme.cornerXL, style: .continuous)
                    .fill(MarketplaceUITheme.darkLuxuryGradient)
                    .frame(height: 230)
                    .overlay(
                        ZStack {
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 88, weight: .black))
                                .foregroundStyle(.white.opacity(0.16))

                            VStack {
                                HStack {
                                    Spacer()

                                    MarketplaceStorePremiumBadge()
                                        .padding(16)
                                }

                                Spacer()
                           }
                            if showFirestoreReadyBadge {
                                VStack {
                                    Spacer()

                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(.green)

                                        Text("Boutique prête pour Firestore, Storage, avis, produits et paiements.")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white.opacity(0.88))
                                            .lineLimit(2)

                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(.white.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .padding(16)
                                }
                            }
                            
                            
                            
                        }
                    )

                HStack(alignment: .bottom, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(MarketplaceUITheme.primaryGradient)
                            .frame(width: 86, height: 86)

                        Image(systemName: "storefront.fill")
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.85), lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 12)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text("Afro Beauty Store")
                                .font(.system(.title2, design: .rounded).weight(.black))
                                .foregroundStyle(.white)

                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.blue)
                        }

                        Text("Conakry, Guinée • Boutique depuis 2026")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    Spacer()
                }
                .padding(18)
            }
            .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        isFollowing.toggle()
                    }
                } label: {
                    Label(isFollowing ? "Suivi" : "Suivre", systemImage: isFollowing ? "checkmark.circle.fill" : "plus.circle.fill")
                }
                .buttonStyle(MarketplacePremiumButtonStyle())

                Button {
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 54, height: 54)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
        .scaleEffect(animateHeader ? 1 : 0.97)
        .opacity(animateHeader ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                animateHeader = true
            }
        }
    }

    private var storeStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            MarketplaceStoreStatCard(title: "Produits", value: "248", icon: "bag.fill")
            MarketplaceStoreStatCard(title: "Ventes", value: "1,2K", icon: "cart.fill")
            MarketplaceStoreStatCard(title: "Note", value: "4,8", icon: "star.fill")
            MarketplaceStoreStatCard(title: "Followers", value: "18K", icon: "person.2.fill")
            MarketplaceStoreStatCard(title: "Réponse", value: "8 min", icon: "bolt.fill")
            MarketplaceStoreStatCard(title: "Pays", value: "12", icon: "globe.europe.africa.fill")
        }
        .padding(.horizontal, 16)
    }

    private var certificationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Certification Cutly",
                subtitle: "Badge payant, vérification et confiance acheteur",
                actionTitle: "En savoir plus",
                action: {}
            )
            .padding(.horizontal, 0)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Boutique certifiée Cutly")
                        .font(.system(.headline, design: .rounded).weight(.black))

                    Text("Identité vérifiée • Boutique contrôlée • Visibilité boostée • Anti-fraude IA")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                MarketplaceStoreCertificationPill(title: "Payant", icon: "crown.fill")
                MarketplaceStoreCertificationPill(title: "Vérifié", icon: "checkmark.shield.fill")
                MarketplaceStoreCertificationPill(title: "Priorité", icon: "arrow.up.circle.fill")
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    private var certificationPlanSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Certification payante",
                subtitle: "Comme un badge vérifié, mais pensé pour les boutiques Cutly",
                actionTitle: "S’abonner",
                action: {}
            )
            .padding(.horizontal, 0)

            HStack(spacing: 14) {
                MarketplaceIconBadge(icon: "crown.fill", size: 54)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Cutly Verified Store")
                        .font(.system(.headline, design: .rounded).weight(.black))

                    Text("Badge premium • Vérification identité • Visibilité renforcée • Confiance acheteurs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer()

                Text("Premium")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(MarketplaceUITheme.primaryGradient)
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                MarketplaceCertificationBenefit(title: "Priorité recherche", icon: "magnifyingglass")
                MarketplaceCertificationBenefit(title: "Badge visible", icon: "checkmark.seal.fill")
                MarketplaceCertificationBenefit(title: "Anti-fraude IA", icon: "brain.head.profile")
                MarketplaceCertificationBenefit(title: "Plus de confiance", icon: "shield.fill")
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var storeTrustSection: some View {
        VStack(spacing: 14) {
            MarketplaceSectionHeader(
                title: "Signaux de confiance",
                subtitle: "Ce que les acheteurs voient avant de commander",
                actionTitle: nil,
                action: nil
            )

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                MarketplaceStoreTrustCard(title: "Identité vérifiée", value: "Oui", icon: "person.badge.shield.checkmark.fill")
                MarketplaceStoreTrustCard(title: "Taux réponse", value: "98%", icon: "bolt.fill")
                MarketplaceStoreTrustCard(title: "Retours", value: "2,1%", icon: "arrow.uturn.backward.circle.fill")
                MarketplaceStoreTrustCard(title: "Litiges", value: "0,4%", icon: "exclamationmark.shield.fill")
            }
            .padding(.horizontal, 16)
        }
    }
    
    
    
    
    
    
    private var storeTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MarketplaceStoreTab.allCases) { tab in
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

    private var storeContentSection: some View {
        VStack(spacing: 14) {
            switch selectedTab {
            case .products:
                MarketplaceStoreProductsGrid()

            case .reviews:
                MarketplaceStoreReviewsPreview()

            case .about:
                MarketplaceStoreAboutSection()

            case .shipping:
                MarketplaceStoreShippingSection()

            case .live:
                MarketplaceStoreLiveSection()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}

// MARK: - Tabs

enum MarketplaceStoreTab: String, CaseIterable, Identifiable {
    case products
    case reviews
    case about
    case shipping
    case live

    var id: String { rawValue }

    var title: String {
        switch self {
        case .products: return "Produits"
        case .reviews: return "Avis"
        case .about: return "À propos"
        case .shipping: return "Livraison"
        case .live: return "Live"
        }
    }

    var icon: String {
        switch self {
        case .products: return "bag.fill"
        case .reviews: return "star.fill"
        case .about: return "info.circle.fill"
        case .shipping: return "shippingbox.fill"
        case .live: return "video.fill"
        }
    }
}

// MARK: - Components

private struct MarketplaceStorePremiumBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
            Text("Certifié")
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
    }
}

private struct MarketplaceStoreStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            MarketplaceIconBadge(icon: icon, size: 38)

            Text(value)
                .font(.system(.headline, design: .rounded).weight(.black))

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 118)
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct MarketplaceStoreCertificationPill: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

private struct MarketplaceStoreProductsGrid: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ], spacing: 14) {
            ForEach(0..<6, id: \.self) { index in
                MarketplaceStoreProductCard(index: index)
            }
        }
    }
}

private struct MarketplaceStoreProductCard: View {
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(MarketplaceUITheme.primaryGradient)
                .frame(height: 150)
                .overlay(
                    Image(systemName: ["bag.fill", "sparkles", "person.crop.circle", "shippingbox.fill"][index % 4])
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                )

            Text(["Perruque premium", "Kit beauté", "Extensions", "Pack soin"][index % 4])
                .font(.subheadline.weight(.bold))
                .lineLimit(1)

            Text(["49 €", "22 €", "40 €", "18 €"][index % 4])
                .font(.headline.weight(.black))

            Text("Boutique certifiée")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct MarketplaceStorePlaceholder: View {
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
private struct MarketplaceCertificationBenefit: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(MarketplaceUITheme.primaryGradient)
                .clipShape(Circle())

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer()
        }
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct MarketplaceStoreTrustCard: View {
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
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 126)
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
private struct MarketplaceStoreReviewsPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            MarketplaceStorePlaceholder(
                title: "4,8 / 5",
                subtitle: "Avis boutique, photos, vidéos, achats vérifiés et analyse IA des faux avis.",
                icon: "star.bubble.fill"
            )

            MarketplaceStoreTrustCard(title: "Avis vérifiés", value: "94%", icon: "checkmark.seal.fill")
        }
    }
}

private struct MarketplaceStoreAboutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "À propos de la boutique",
                subtitle: "Profil vendeur complet et vérification",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)

            Text("Afro Beauty Store propose des produits beauté, perruques, extensions et accessoires premium pour l’Europe et l’Afrique. La boutique est vérifiée par Cutly et bénéficie d’un contrôle IA anti-fraude.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            MarketplaceStoreInfoRow(icon: "mappin.and.ellipse", title: "Localisation", value: "Conakry, Guinée")
            MarketplaceStoreInfoRow(icon: "calendar", title: "Ancienneté", value: "Boutique active depuis 2026")
            MarketplaceStoreInfoRow(icon: "checkmark.shield.fill", title: "Vérification", value: "Identité et boutique contrôlées")
            MarketplaceStoreInfoRow(icon: "globe.europe.africa.fill", title: "Zones", value: "Afrique, Europe, International")
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

private struct MarketplaceStoreShippingSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Livraison boutique",
                subtitle: "Transporteurs internationaux et solutions locales",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)

            MarketplaceStoreInfoRow(icon: "airplane", title: "International", value: "DHL, UPS, FedEx, Chronopost, Colissimo")
            MarketplaceStoreInfoRow(icon: "shippingbox.fill", title: "Afrique", value: "Poste, agences, bus, coursiers locaux, relais commerçants")
            MarketplaceStoreInfoRow(icon: "mappin.and.ellipse", title: "Adresse flexible", value: "Adresse complète, repère, GPS ou téléphone")
            MarketplaceStoreInfoRow(icon: "hand.raised.fill", title: "Main propre", value: "Validation sécurisée dans l’application")
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

private struct MarketplaceStoreLiveSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(MarketplaceUITheme.darkLuxuryGradient)
                    .frame(height: 220)

                VStack(alignment: .leading, spacing: 10) {
                    MarketplaceIconBadge(icon: "video.fill", size: 54)

                    Text("Live Shopping boutique")
                        .font(.system(.title3, design: .rounded).weight(.black))
                        .foregroundStyle(.white)

                    Text("Présente les produits en direct, reçois des commandes et réponds aux acheteurs.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(3)
                }
                .padding(18)
            }

            Button {
            } label: {
                Label("Entrer dans le live", systemImage: "play.circle.fill")
            }
            .buttonStyle(MarketplacePremiumButtonStyle())
        }
    }
}

private struct MarketplaceStoreInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))

                Text(value)
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
private struct MarketplaceStoreActionPanel: View {
    var body: some View {
        VStack(spacing: 12) {
            Button {
            } label: {
                Label("Voir tous les produits", systemImage: "bag.fill")
            }
            .buttonStyle(MarketplacePremiumButtonStyle())

            Button {
            } label: {
                Label("Demander la certification Cutly", systemImage: "checkmark.seal.fill")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.primary)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
    }
}




#Preview {
    MarketplaceStoreView()
}
