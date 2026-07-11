//
//  MarketplaceProductCard.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 08/07/2026.
//

//
//  MarketplaceProductCard.swift
//  MonApp
//

import SwiftUI

// MARK: - Product Visual Extras

struct MarketplaceProductVisualExtras {

    let badgeText: String?
    let badgeColor: Color
    let originalPriceText: String?
    let rating: Double

    init(product: MarketplaceHomeProduct) {

        originalPriceText = product.originalPriceText

        rating = product.rating ?? 0.0

        if let discount = product.discountPercent,
           discount > 0 {

            badgeText = "-\(discount)%"
            badgeColor = .purple

        } else {

            badgeText = nil
            badgeColor = .purple

        }
    }
}

// MARK: - Promotion Badge

struct MarketplaceProductBadge: View {

    let title: String
    let color: Color

    var body: some View {

        Text(title)
            .font(.system(size: 11,
                          weight: .bold,
                          design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(Capsule())

    }

}

// MARK: - Seller Initials Badge

struct MarketplaceSellerInitialsBadge: View {

    let name: String

    private var initials: String {

        let letters = name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()

        return letters.isEmpty ? "CT" : letters.uppercased()

    }

    var body: some View {

        Text(initials)
            .font(.system(size: 10,
                          weight: .black))
            .foregroundStyle(.white)
            .frame(width: 22,
                   height: 22)
            .background(MarketplaceUITheme.primaryGradient)
            .clipShape(Circle())

    }

}

// MARK: - Price Formatter

func marketplaceCardPrice(_ text: String) -> String {

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
// MARK: - Marketplace Product Card

struct MarketplaceProductCard: View {
    
    let product: MarketplaceHomeProduct
    let onFavoriteTap: () -> Void
    
    private var details: MarketplaceProductVisualExtras {
        MarketplaceProductVisualExtras(product: product)
    }
    
    private let imageHeight: CGFloat = 92
    private let cardHeight: CGFloat = 208
    
    private var productLocationText: String {
        
        let city = product.city.trimmingCharacters(in: .whitespacesAndNewlines)
        let country = product.country.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !city.isEmpty && !country.isEmpty {
            return "\(city), \(country)"
        }
        
        if !city.isEmpty {
            return city
        }
        
        if !country.isEmpty {
            return country
        }
        
        return "Localisation non renseignée"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                productImage

                if let badgeText = details.badgeText {
                    MarketplaceProductBadge(title: badgeText, color: details.badgeColor)
                        .padding(10)
                }

                HStack {
                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            onFavoriteTap()
                        }
                    } label: {
                        Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(product.isFavorite ? .red : .white)
                            .frame(width: 30, height: 30)
                            .background(.black.opacity(0.38))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                }
            }
            .frame(height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                if details.badgeText != nil {
                    Label("Promotion", systemImage: "bolt.fill")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.purple)
                        .clipShape(Capsule())
                }

                Text(product.title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(marketplaceCardPrice(product.priceText))
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.purple)
                        .lineLimit(1)

                    if let originalPriceText = details.originalPriceText {
                        Text(originalPriceText)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .strikethrough()
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9, weight: .bold))

                    Text(productLocationText)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)

                Divider().opacity(0.18)

                HStack(spacing: 5) {
                    sellerAvatar

                    Text(product.sellerName.isEmpty ? "Vendeur Cutly" : product.sellerName)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .layoutPriority(1)

                    if product.sellerVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.blue)
                    }

                    Spacer(minLength: 4)

                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.yellow)

                        Text(String(format: "%.1f", details.rating))
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(width: 34, alignment: .trailing)
                    .clipped()
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 9)
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .clipped()
    }
    
    @ViewBuilder
    private var sellerAvatar: some View {
        if let url = URL(string: product.sellerPhotoURL),
           !product.sellerPhotoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                default:
                    MarketplaceSellerInitialsBadge(name: product.sellerName)
                }
            }
            .frame(width: 22, height: 22)
            .clipShape(Circle())
            .clipped()
        } else {
            MarketplaceSellerInitialsBadge(name: product.sellerName)
        }
    }

    private var productImage: some View {
        GeometryReader { proxy in
            ZStack {
                Color.primary.opacity(0.06)

                if let imageURL = product.imageURL,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            MarketplaceSkeletonView(cornerRadius: 18)

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipped()

                        default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .clipped()
        }
        .frame(height: imageHeight)
    }

    private var placeholderImage: some View {
        ZStack {
            MarketplaceUITheme.primaryGradient

            Image(systemName: "bag.fill")
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
    
    
}
// MARK: - Marketplace Product List Card

struct MarketplaceProductListCard: View {
    let product: MarketplaceHomeProduct

    private var extras: MarketplaceProductVisualExtras {
        MarketplaceProductVisualExtras(product: product)
    }

    var body: some View {
        let details = extras

        HStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.06))

                if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            MarketplaceSkeletonView(cornerRadius: 16)
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Image(systemName: "bag.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "bag.fill")
                        .foregroundStyle(.secondary)
                }

                if let badgeText = details.badgeText {
                    Text(badgeText)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(details.badgeColor)
                        .clipShape(Capsule())
                        .padding(6)
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .clipped()

            VStack(alignment: .leading, spacing: 5) {
                Text(product.title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(marketplaceCardPrice(product.priceText))
                        .font(.system(.headline, design: .rounded).weight(.black))
                        .foregroundStyle(Color.purple)

                    if let originalPriceText = details.originalPriceText {
                        Text(originalPriceText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .strikethrough()
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text(product.country.isEmpty ? "Non renseigné" : product.country)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    sellerAvatar

                    Text(product.sellerName.isEmpty ? "Vendeur Cutly" : product.sellerName)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if product.sellerVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.blue)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.yellow)

                        Text(String(format: "%.1f", details.rating))
                            .font(.caption2.weight(.bold))
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var sellerAvatar: some View {
        if let url = URL(string: product.sellerPhotoURL),
           !product.sellerPhotoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    MarketplaceSellerInitialsBadge(name: product.sellerName)
                }
            }
            .frame(width: 22, height: 22)
            .clipShape(Circle())
        } else {
            MarketplaceSellerInitialsBadge(name: product.sellerName)
        }
    }
}
