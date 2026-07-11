//
//  MarketplaceWalletView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI

struct MarketplaceWalletView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCurrency: MarketplaceCurrency = .eur
    @State private var showWithdrawSheet = false
    @State private var animateHeader = false
    
    @State private var showSecuritySheet = false
    @State private var showKYCInfo = false
    

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        walletHeroSection
                        walletStatsSection
                        currencySection
                        paymentMethodsSection
                        withdrawalMethodsSection
                        securityKYCSection
                        recentTransactionsSection
                        walletReadySection
                        Spacer(minLength: 120)
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Portefeuille")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var walletHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Solde disponible")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.75))

                    Text(cutlyWalletPriceText("1248.90 €"))
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Revenus vendeur • Retraits • Paiements • Commissions Cutly")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                }

                Spacer()

                MarketplaceIconBadge(icon: "wallet.pass.fill", size: 62)
            }

            HStack(spacing: 10) {
                MarketplaceWalletChip(title: "Stripe", icon: "creditcard.fill")
                MarketplaceWalletChip(title: "PayPal", icon: "p.circle.fill")
                MarketplaceWalletChip(title: "Mobile Money", icon: "iphone.gen1.radiowaves.left.and.right")
            }

            Button {
                showWithdrawSheet = true
            } label: {
                Label("Demander un retrait", systemImage: "arrow.down.circle.fill")
            }
            .buttonStyle(MarketplacePremiumButtonStyle())
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
        .sheet(isPresented: $showWithdrawSheet) {
            MarketplaceWithdrawSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var walletStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            MarketplaceWalletStatCard(title: "En attente", value: "320 €", icon: "clock.fill")
            MarketplaceWalletStatCard(title: "Revenus", value: "4 980 €", icon: "chart.line.uptrend.xyaxis")
            MarketplaceWalletStatCard(title: "Retiré", value: "3 420 €", icon: "arrow.down.circle.fill")
            MarketplaceWalletStatCard(title: "Frais Cutly", value: "248 €", icon: "percent")
        }
        .padding(.horizontal, 16)
    }
    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Devise du portefeuille",
                subtitle: "Préparé pour Europe, Afrique et international",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)

            Picker("Devise", selection: $selectedCurrency) {
                ForEach(MarketplaceCurrency.allCases) { currency in
                    Text("\(currency.rawValue) \(currency.symbol)").tag(currency)
                }
            }
            .pickerStyle(.menu)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            MarketplaceWalletMethodRow(
                icon: "globe.europe.africa.fill",
                title: "Conversion multi-devises",
                subtitle: "EUR, USD, GNF, XOF, XAF, MAD, NGN, GHS, KES, ZAR et autres devises prévues."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var securityKYCSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Sécurité & vérification",
                subtitle: "Protection contre fraude, faux comptes et retraits suspects",
                actionTitle: "Sécurité",
                action: {
                    showSecuritySheet = true
                }
            )
            .padding(.horizontal, 0)

            MarketplaceWalletMethodRow(
                icon: "person.badge.shield.checkmark.fill",
                title: "Vérification identité / KYC",
                subtitle: "Prévu pour vendeurs, boutiques certifiées, gros montants et retraits sensibles."
            )

            MarketplaceWalletMethodRow(
                icon: "brain.head.profile",
                title: "IA anti-fraude",
                subtitle: "Analyse des remboursements abusifs, blanchiment, retraits anormaux et comptes multiples."
            )

            MarketplaceWalletMethodRow(
                icon: "lock.shield.fill",
                title: "Protection paiement",
                subtitle: "Historique, traçabilité, litiges, preuves et validation admin si nécessaire."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
        .sheet(isPresented: $showSecuritySheet) {
            MarketplaceWalletSecuritySheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var walletReadySection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.green)

            Text("Portefeuille prêt pour Stripe, PayPal, Apple Pay, cartes, Mobile Money, virements, commissions Cutly, retraits, KYC et IA anti-fraude.")
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
    
    
    
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Moyens de paiement acceptés",
                subtitle: "Europe, Afrique, international et wallet Cutly",
                actionTitle: "Gérer",
                action: {}
            )
            .padding(.horizontal, 0)

            MarketplaceWalletMethodRow(icon: "creditcard.fill", title: "Cartes bancaires", subtitle: "Visa, Mastercard, American Express selon pays")
            MarketplaceWalletMethodRow(icon: "apple.logo", title: "Apple Pay", subtitle: "Paiement rapide sur iPhone")
            MarketplaceWalletMethodRow(icon: "p.circle.fill", title: "PayPal", subtitle: "Paiement international et protection acheteur")
            MarketplaceWalletMethodRow(icon: "iphone.gen1.radiowaves.left.and.right", title: "Mobile Money Afrique", subtitle: "Orange Money, Wave, MTN, Moov, Airtel, M-Pesa, Free Money, TMoney, Flooz")
            MarketplaceWalletMethodRow(icon: "building.columns.fill", title: "Virement bancaire", subtitle: "IBAN, RIB, compte bancaire professionnel ou personnel selon pays")
            MarketplaceWalletMethodRow(icon: "wallet.pass.fill", title: "Wallet Cutly", subtitle: "Solde interne, cashback, remboursements et revenus vendeur")
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }

    
    
    
    
    
    private var withdrawalMethodsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Méthodes de retrait",
                subtitle: "Retire tes revenus selon ton pays",
                actionTitle: "Ajouter",
                action: {}
            )
            .padding(.horizontal, 0)

            MarketplaceWalletMethodRow(icon: "creditcard.fill", title: "Stripe Connect", subtitle: "Retraits bancaires en Europe et pays compatibles")
            MarketplaceWalletMethodRow(icon: "p.circle.fill", title: "PayPal", subtitle: "Retrait international quand disponible")
            MarketplaceWalletMethodRow(icon: "iphone.gen1.radiowaves.left.and.right", title: "Mobile Money", subtitle: "Orange Money, Wave, MTN, Moov, Airtel Money, M-Pesa")
            MarketplaceWalletMethodRow(icon: "building.columns.fill", title: "Compte bancaire", subtitle: "IBAN, RIB ou informations bancaires locales")
            MarketplaceWalletMethodRow(icon: "person.fill.checkmark", title: "Retrait manuel", subtitle: "Pour pays nécessitant validation ou traitement partenaire")
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }

    
    
    
    
    
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Historique récent",
                subtitle: "Ventes, retraits, commissions et remboursements",
                actionTitle: "Tout voir",
                action: {}
            )
            .padding(.horizontal, 0)

            MarketplaceWalletTransactionRow(title: "Vente #CMD-000184", amount: "+89 €", icon: "cart.fill", isPositive: true)
            MarketplaceWalletTransactionRow(title: "Commission Cutly", amount: "-4,45 €", icon: "percent", isPositive: false)
            MarketplaceWalletTransactionRow(title: "Retrait PayPal", amount: "-250 €", icon: "p.circle.fill", isPositive: false)
            MarketplaceWalletTransactionRow(title: "Cashback acheteur", amount: "+3 €", icon: "gift.fill", isPositive: true)
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
}

// MARK: - Components

private struct MarketplaceWalletChip: View {
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

private struct MarketplaceWalletStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            MarketplaceIconBadge(icon: icon, size: 42)

            Text(cutlyWalletPriceText(value))
                .font(.system(.headline, design: .rounded).weight(.black))

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 122)
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct MarketplaceWalletMethodRow: View {
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

private struct MarketplaceWalletTransactionRow: View {
    let title: String
    let amount: String
    let icon: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 38)

            Text(title)
                .font(.subheadline.weight(.bold))

            Spacer()

            Text(cutlyWalletPriceText(amount))
                .font(.headline.weight(.black))
                .foregroundStyle(isPositive ? .green : .red)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct MarketplaceWithdrawSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMethod: MarketplaceWithdrawalMethod = .paypal
    @State private var amount = ""

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 22) {
                    MarketplaceIconBadge(icon: "arrow.down.circle.fill", size: 64)

                    Text("Demander un retrait")
                        .font(.system(.title2, design: .rounded).weight(.black))

                    Picker("Méthode", selection: $selectedMethod) {
                        ForEach(MarketplaceWithdrawalMethod.allCases) { method in
                            Text(method.title).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(16)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.horizontal, 16)

                    TextField("Montant", text: $amount)
                        .keyboardType(.decimalPad)
                        .padding(16)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .padding(.horizontal, 16)

                    Button {
                        dismiss()
                    } label: {
                        Label("Valider la demande", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(MarketplacePremiumButtonStyle())
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.top, 30)
            }
            .navigationTitle("Retrait")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
private struct MarketplaceWalletSecuritySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    MarketplaceIconBadge(icon: "lock.shield.fill", size: 66)

                    Text("Sécurité du portefeuille")
                        .font(.system(.title2, design: .rounded).weight(.black))

                    Text("Cette zone préparera la vérification d’identité, les limites de retrait, les alertes fraude, les validations admin et la protection contre les paiements suspects.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)

                    MarketplaceWalletMethodRow(
                        icon: "person.text.rectangle.fill",
                        title: "KYC vendeur",
                        subtitle: "Document d’identité, boutique, pays, téléphone, compte bancaire ou Mobile Money."
                    )

                    MarketplaceWalletMethodRow(
                        icon: "exclamationmark.shield.fill",
                        title: "Alertes IA",
                        subtitle: "Retraits fréquents, remboursements anormaux, blanchiment ou compte à risque."
                    )

                    Button {
                        dismiss()
                    } label: {
                        Label("Compris", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(MarketplacePremiumButtonStyle())
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.top, 30)
                .padding(.horizontal, 16)
            }
            .navigationTitle("Sécurité")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
private func cutlyWalletPriceText(_ text: String) -> String {
    let cleaned = text
        .replacingOccurrences(of: "EUR", with: "")
        .replacingOccurrences(of: "Euro", with: "")
        .replacingOccurrences(of: "€", with: "")
        .replacingOccurrences(of: "+", with: "")
        .replacingOccurrences(of: "-", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: ",", with: ".")

    guard let value = Double(cleaned) else {
        return text.replacingOccurrences(of: "EUR", with: "€")
    }

    let sign = text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("-") ? "-" :
               text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("+") ? "+" : ""

    if value.truncatingRemainder(dividingBy: 1) == 0 {
        return "\(sign)\(Int(value)) €"
    }

    return "\(sign)\(String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")) €"
}



#Preview {
    MarketplaceWalletView()
}
