//
//  MarketplaceUITheme.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI

// MARK: - Marketplace UI Theme

enum MarketplaceUITheme {

    static let cornerSmall: CGFloat = 12
    static let cornerMedium: CGFloat = 18
    static let cornerLarge: CGFloat = 26
    static let cornerXL: CGFloat = 34

    static let spacingXS: CGFloat = 6
    static let spacingS: CGFloat = 10
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    static let cardShadowRadius: CGFloat = 18
    static let premiumBlur: CGFloat = 22

    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.78, blue: 0.30),
            Color(red: 0.95, green: 0.38, blue: 0.28),
            Color(red: 0.50, green: 0.18, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let darkLuxuryGradient = LinearGradient(
        colors: [
            Color.black,
            Color(red: 0.08, green: 0.07, blue: 0.12),
            Color(red: 0.14, green: 0.09, blue: 0.22)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let softBackgroundGradient = LinearGradient(
        colors: [
            Color(.systemBackground),
            Color(.secondarySystemBackground),
            Color(.systemBackground)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static func premiumCardBackground(colorScheme: ColorScheme) -> some View {
        RoundedRectangle(cornerRadius: cornerLarge, style: .continuous)
            .fill(
                colorScheme == .dark
                ? Color.white.opacity(0.075)
                : Color.white.opacity(0.92)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerLarge, style: .continuous)
                    .stroke(
                        colorScheme == .dark
                        ? Color.white.opacity(0.12)
                        : Color.black.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.08),
                radius: cardShadowRadius,
                x: 0,
                y: 12
            )
    }

    static func glassBackground(colorScheme: ColorScheme, cornerRadius: CGFloat = cornerLarge) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        colorScheme == .dark
                        ? Color.white.opacity(0.16)
                        : Color.white.opacity(0.55),
                        lineWidth: 1
                    )
            )
    }

    static func premiumStroke(colorScheme: ColorScheme, cornerRadius: CGFloat = cornerLarge) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                colorScheme == .dark
                ? Color.white.opacity(0.12)
                : Color.black.opacity(0.06),
                lineWidth: 1
            )
    }
}

// MARK: - Marketplace Premium Button

struct MarketplacePremiumButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 15)
            .padding(.horizontal, 22)
            .background(MarketplaceUITheme.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: MarketplaceUITheme.cornerMedium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 10)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

// MARK: - Marketplace Icon Badge

struct MarketplaceIconBadge: View {
    let icon: String
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            Circle()
                .fill(MarketplaceUITheme.primaryGradient)

            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 8)
    }
}

// MARK: - Marketplace Skeleton

struct MarketplaceSkeletonView: View {
    @State private var isAnimating = false

    var cornerRadius: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.16),
                        Color.gray.opacity(0.28),
                        Color.gray.opacity(0.16)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                    isAnimating.toggle()
                }
            }
    }
}

// MARK: - Marketplace Section Header

struct MarketplaceSectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))

                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
        }
        .padding(.horizontal, MarketplaceUITheme.spacingM)
    }
}
// MARK: - Cutly Verified Badge

struct CutlyVerifiedBadge: View {
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.50, blue: 1.00),
                            Color(red: 0.00, green: 0.32, blue: 0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "checkmark")
                .font(.system(size: size * 0.55, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: .blue.opacity(0.35), radius: 4, x: 0, y: 2)
        .accessibilityLabel("Profil vérifié Cutly")
    }
}
