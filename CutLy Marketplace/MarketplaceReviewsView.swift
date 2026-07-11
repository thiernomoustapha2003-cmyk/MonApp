//
//  MarketplaceReviewsView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI

struct MarketplaceReviewsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedFilter: MarketplaceReviewFilter = .all
    @State private var animateHeader = false
    @State private var searchText = ""
    @State private var showWriteReviewSheet = false
    
    
    
    
    
    private let filters: [MarketplaceReviewFilter] = [.all, .photos, .videos, .verified, .recent, .critical]
    
    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        reviewsHeaderSection
                        ratingSummarySection
                        writeReviewSearchSection
                        filtersSection
                        reviewInsightsSection
                        reviewsListSection
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Avis")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var reviewsHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Avis Marketplace")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Photos, vidéos, achats vérifiés et détection IA des faux avis.")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(3)
                }
                
                Spacer()
                
                MarketplaceIconBadge(icon: "star.bubble.fill", size: 58)
            }
            
            HStack(spacing: 10) {
                MarketplaceReviewHeroChip(title: "4,8 ★", icon: "star.fill")
                MarketplaceReviewHeroChip(title: "Vérifiés", icon: "checkmark.seal.fill")
                MarketplaceReviewHeroChip(title: "IA", icon: "brain.head.profile")
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
    
    private var ratingSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MarketplaceSectionHeader(
                title: "Résumé des notes",
                subtitle: "Analyse globale prête pour Firestore",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)
            
            HStack(alignment: .center, spacing: 18) {
                VStack(spacing: 6) {
                    Text("4,8")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                    
                    Text("★★★★★")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    
                    Text("128 avis")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 110)
                
                VStack(spacing: 8) {
                    MarketplaceRatingBar(title: "5", progress: 0.78)
                    MarketplaceRatingBar(title: "4", progress: 0.14)
                    MarketplaceRatingBar(title: "3", progress: 0.05)
                    MarketplaceRatingBar(title: "2", progress: 0.02)
                    MarketplaceRatingBar(title: "1", progress: 0.01)
                }
            }
            
            HStack(spacing: 10) {
                MarketplaceReviewStatPill(title: "94 vérifiés", icon: "checkmark.seal.fill")
                MarketplaceReviewStatPill(title: "36 photos", icon: "photo.fill")
                MarketplaceReviewStatPill(title: "12 vidéos", icon: "play.rectangle.fill")
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    private var writeReviewSearchSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.secondary)
                
                TextField("Rechercher dans les avis...", text: $searchText)
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
            
            Button {
                showWriteReviewSheet = true
            } label: {
                Label("Écrire un avis", systemImage: "square.and.pencil")
            }
            .buttonStyle(MarketplacePremiumButtonStyle())
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showWriteReviewSheet) {
            MarketplaceWriteReviewSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    
    
    
    
    
    
    private var filtersSection: some View {
        VStack(spacing: 14) {
            MarketplaceSectionHeader(
                title: "Filtres avis",
                subtitle: "Trier les avis utiles rapidement",
                actionTitle: nil,
                action: nil
            )
            
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
    }
    private var reviewInsightsSection: some View {
        VStack(spacing: 14) {
            
            MarketplaceSectionHeader(
                title: "Analyse intelligente",
                subtitle: "L'IA résume automatiquement les retours des acheteurs",
                actionTitle: "Détails",
                action: {}
            )
            
            VStack(spacing: 14) {
                
                MarketplaceReviewInsightCard(
                    icon: "brain.head.profile",
                    title: "Résumé IA",
                    subtitle: "94 % des acheteurs recommandent ce produit. Les points les plus cités sont la qualité, la rapidité de livraison et la conformité."
                )
                
                MarketplaceReviewInsightCard(
                    icon: "camera.fill",
                    title: "Photos & vidéos",
                    subtitle: "36 photos et 12 vidéos publiées par les acheteurs."
                )
                
                MarketplaceReviewInsightCard(
                    icon: "checkmark.seal.fill",
                    title: "Authenticité",
                    subtitle: "Les avis sont analysés automatiquement afin de détecter les faux commentaires."
                )
                
                MarketplaceReviewInsightCard(
                    icon: "globe",
                    title: "Traduction automatique",
                    subtitle: "Les avis peuvent être lus dans la langue de l'utilisateur."
                )
            }
            .padding(.horizontal, 16)
        }
    }
    
    
    private var reviewsListSection: some View {
        VStack(spacing: 12) {
            ForEach(filteredReviews) { review in
                MarketplaceReviewPremiumCard(review: review)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    private var filteredReviews: [MarketplaceReviewMockItem] {
        let cleanSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanSearch.isEmpty {
            return MarketplaceReviewPreviewData.items
        }

        return MarketplaceReviewPreviewData.items.filter { review in
            review.name.localizedCaseInsensitiveContains(cleanSearch)
            || review.text.localizedCaseInsensitiveContains(cleanSearch)
            || review.translatedText.localizedCaseInsensitiveContains(cleanSearch)
            || review.sellerReply.localizedCaseInsensitiveContains(cleanSearch)
        }
    }
    
}



// MARK: - Filter

enum MarketplaceReviewFilter: String, CaseIterable, Identifiable {
    case all
    case photos
    case videos
    case verified
    case recent
    case critical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Tous"
        case .photos: return "Photos"
        case .videos: return "Vidéos"
        case .verified: return "Vérifiés"
        case .recent: return "Récents"
        case .critical: return "Critiques"
        }
    }

    var icon: String {
        switch self {
        case .all: return "star.fill"
        case .photos: return "photo.fill"
        case .videos: return "play.rectangle.fill"
        case .verified: return "checkmark.seal.fill"
        case .recent: return "clock.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Components

private struct MarketplaceReviewHeroChip: View {
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

private struct MarketplaceRatingBar: View {
    let title: String
    let progress: CGFloat

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .frame(width: 12)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))

                    Capsule()
                        .fill(MarketplaceUITheme.primaryGradient)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}

private struct MarketplaceReviewStatPill: View {
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

private struct MarketplaceReviewPremiumCard: View {
    let review: MarketplaceReviewMockItem

    @State private var isUseful = false
    @State private var showTranslation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Text(showTranslation ? review.translatedText : review.text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            if review.hasMedia {
                mediaStrip
            }

            aiTrustBox
            sellerReplyBox
            actionBar
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            MarketplaceIconBadge(icon: "person.fill", size: 42)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(review.name)
                        .font(.subheadline.weight(.bold))

                    if review.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                    }
                }

                Text("★★★★★")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)

                Text("Achat vérifié • Livraison en \(review.deliveryDays) jours")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(review.date)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var mediaStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(MarketplaceUITheme.primaryGradient)
                        .frame(width: 76, height: 76)
                        .overlay(
                            Image(systemName: index == 0 ? "photo.fill" : "play.rectangle.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
            }
        }
    }

    private var aiTrustBox: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: "brain.head.profile", size: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text("Fiabilité IA : \(review.aiTrustScore)%")
                    .font(.caption.weight(.bold))

                Text("Avis analysé contre les faux commentaires.")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var sellerReplyBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Réponse du vendeur", systemImage: "storefront.fill")
                .font(.caption.weight(.bold))

            Text(review.sellerReply)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.primary.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var actionBar: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    isUseful.toggle()
                }
            } label: {
                Label(isUseful ? "Utile ✓" : "Utile", systemImage: "hand.thumbsup.fill")
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    showTranslation.toggle()
                }
            } label: {
                Label(showTranslation ? "Original" : "Traduire", systemImage: "globe")
            }

            Button {
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
    }
}

// MARK: - Preview Data

struct MarketplaceReviewMockItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let text: String
    let translatedText: String
    let date: String
    let isVerified: Bool
    let hasMedia: Bool
    let deliveryDays: Int
    let aiTrustScore: Int
    let sellerReply: String
}

enum MarketplaceReviewPreviewData {
    static let items: [MarketplaceReviewMockItem] = [
        .init(
            name: "Aïssata",
            text: "Produit très propre, vendeur sérieux, livraison rapide et les photos correspondent bien.",
            translatedText: "Very clean product, serious seller, fast delivery and the photos match well.",
            date: "Aujourd’hui",
            isVerified: true,
            hasMedia: true,
            deliveryDays: 4,
            aiTrustScore: 96,
            sellerReply: "Merci beaucoup pour votre confiance. Nous sommes heureux que le produit vous plaise."
        ),
        .init(
            name: "Mariam",
            text: "Bonne qualité, emballage correct, je recommande cette boutique.",
            translatedText: "Good quality, proper packaging, I recommend this store.",
            date: "Hier",
            isVerified: true,
            hasMedia: false,
            deliveryDays: 6,
            aiTrustScore: 93,
            sellerReply: "Merci pour votre retour, nous restons disponibles pour votre prochaine commande."
        ),
        .init(
            name: "Fatou",
            text: "Très satisfaite. La couleur et la qualité sont conformes à la description.",
            translatedText: "Very satisfied. The color and quality match the description.",
            date: "Il y a 3 jours",
            isVerified: true,
            hasMedia: true,
            deliveryDays: 3,
            aiTrustScore: 98,
            sellerReply: "Merci Fatou, votre satisfaction est très importante pour nous."
        )
    ]
}
private struct MarketplaceReviewInsightCard: View {

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {

        HStack(alignment: .top, spacing: 14) {

            MarketplaceIconBadge(icon: icon, size: 44)

            VStack(alignment: .leading, spacing: 6) {

                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
        )
    }
}
private struct MarketplaceWriteReviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var rating = 5
    @State private var comment = ""

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        MarketplaceIconBadge(icon: "star.bubble.fill", size: 64)

                        Text("Écrire un avis")
                            .font(.system(.title2, design: .rounded).weight(.black))

                        Text("Partage ton expérience avec photos, vidéos, note, livraison et conformité du produit.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    rating = star
                                }
                            } label: {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextEditor(text: $comment)
                        .frame(minHeight: 150)
                        .padding(12)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)

                    Button {
                        dismiss()
                    } label: {
                        Label("Publier l’avis", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(MarketplacePremiumButtonStyle())
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.top, 28)
            }
            .navigationTitle("Nouvel avis")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}







#Preview {
    MarketplaceReviewsView()
}
