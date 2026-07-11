//
//  MarketplaceSettingsView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI

struct MarketplaceSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedLanguage = "Français"
    @State private var selectedCurrency: MarketplaceCurrency = .eur
    @State private var selectedCountry = "France"

    @State private var notificationsEnabled = true
    @State private var privateProfile = false
    @State private var aiPersonalization = true
    @State private var securityAlerts = true
    @State private var animateHeader = false

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        settingsHeroSection
                        localizationSection
                        deliveryPaymentSection
                        privacySecuritySection
                        certificationLegalSection
                        settingsReadySection
                        Spacer(minLength: 120)
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var settingsHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paramètres Marketplace")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Langue, pays, devise, livraison, paiements, sécurité et confidentialité.")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(3)
                }

                Spacer()

                MarketplaceIconBadge(icon: "gearshape.fill", size: 62)
            }

            HStack(spacing: 10) {
                MarketplaceSettingsChip(title: "Confidentialité", icon: "lock.shield.fill")
                MarketplaceSettingsChip(title: "Paiements", icon: "creditcard.fill")
                MarketplaceSettingsChip(title: "Pays", icon: "globe.europe.africa.fill")
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

    private var localizationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Langue, pays & devise",
                subtitle: "Adapter l’expérience selon la zone",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)

            MarketplaceSettingsRow(icon: "globe", title: "Langue", value: selectedLanguage)
            MarketplaceSettingsRow(icon: "mappin.and.ellipse", title: "Pays", value: selectedCountry)

            Picker("Devise", selection: $selectedCurrency) {
                ForEach(MarketplaceCurrency.allCases) { currency in
                    Text("\(currency.rawValue) \(currency.symbol)").tag(currency)
                }
            }
            .pickerStyle(.menu)
            .padding(16)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .marketplaceSettingsCard()
    }

    private var deliveryPaymentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Livraison & paiements",
                subtitle: "Europe, Afrique et international",
                actionTitle: "Gérer",
                action: {}
            )
            .padding(.horizontal, 0)

            MarketplaceSettingsRow(
                icon: "shippingbox.fill",
                title: "Livraison",
                value: "Domicile, relais, poste, agence, GPS, main propre"
            )

            MarketplaceSettingsRow(
                icon: "creditcard.fill",
                title: "Paiements",
                value: "Stripe, Apple Pay, PayPal, cartes, Mobile Money"
            )

            MarketplaceSettingsRow(
                icon: "wallet.pass.fill",
                title: "Wallet Cutly",
                value: "Solde, retraits, remboursements, commissions"
            )
        }
        .marketplaceSettingsCard()
    }

    private var privacySecuritySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                MarketplaceSectionHeader(
                    title: "Politique, confidentialité & sécurité",
                    subtitle: "Protection du profil, des paiements et des données",
                    actionTitle: nil,
                    action: nil
                )
                .padding(.horizontal, 0)

                Spacer()

                NavigationLink {
                    MarketplaceLegalPrivacyView()
                } label: {
                    Text("Voir")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(MarketplaceUITheme.primaryGradient)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 0)

            Toggle("Notifications Marketplace", isOn: $notificationsEnabled)
                .marketplaceSettingsToggle()

            Toggle("Profil privé", isOn: $privateProfile)
                .marketplaceSettingsToggle()

            Toggle("Personnalisation IA", isOn: $aiPersonalization)
                .marketplaceSettingsToggle()

            Toggle("Alertes sécurité", isOn: $securityAlerts)
                .marketplaceSettingsToggle()

            MarketplaceSettingsRow(
                icon: "doc.text.fill",
                title: "Politique de confidentialité",
                value: "Données, paiements, IA, messages et sécurité"
            )

            MarketplaceSettingsRow(
                icon: "scroll.fill",
                title: "Conditions Marketplace",
                value: "Vente, achat, retours, litiges, remboursements"
            )
        }
        .marketplaceSettingsCard()
        
    }

    private var certificationLegalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Certification Cutly",
                subtitle: "Disponible pour tous les profils et boutiques",
                actionTitle: "Demander",
                action: {}
            )
            .padding(.horizontal, 0)

            MarketplaceSettingsRow(
                icon: "checkmark.seal.fill",
                title: "Badge certifié",
                value: "Particulier, vendeur, acheteur-vendeur ou boutique"
            )

            MarketplaceSettingsRow(
                icon: "brain.head.profile",
                title: "IA anti-fraude",
                value: "Faux vendeurs, faux avis, contrefaçons, litiges suspects"
            )
        }
        .marketplaceSettingsCard()
    }

    private var settingsReadySection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)

            Text("Paramètres prêts pour Firestore : langue, devise, pays, livraison, paiements, confidentialité, politique, sécurité, certification et IA.")
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
}

// MARK: - Components

private struct MarketplaceSettingsChip: View {
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

private struct MarketplaceSettingsRow: View {
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

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}



private extension View {
    func marketplaceSettingsCard() -> some View {
        self
            .padding(18)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(.horizontal, 16)
    }

    func marketplaceSettingsToggle() -> some View {
        self
            .padding(16)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    MarketplaceSettingsView()
}
