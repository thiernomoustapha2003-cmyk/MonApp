//
//  MarketplaceSupportView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI

struct MarketplaceSupportView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategory: MarketplaceSupportCategory = .orders
    @State private var searchText = ""
    @State private var animateHeader = false
    
    @State private var showTicketSheet = false
    @State private var showEmergencySheet = false

    private let categories: [MarketplaceSupportCategory] = [
        .orders, .payments, .delivery, .returns, .disputes, .security, .certification, .account
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        supportHeroSection
                        searchSection
                        categoriesSection
                        quickHelpSection
                        faqSection
                        contactSupportSection
                        supportReadySection
                        Spacer(minLength: 120)
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var supportHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Support Marketplace")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Aide pour commandes, paiements, livraison, litiges, sécurité et certification.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(3)
                }

                Spacer()

                MarketplaceIconBadge(icon: "headset", size: 62)
            }

            HStack(spacing: 10) {
                MarketplaceSupportChip(title: "24/7", icon: "clock.fill")
                MarketplaceSupportChip(title: "Litiges", icon: "shield.fill")
                MarketplaceSupportChip(title: "IA", icon: "brain.head.profile")
            }
        }
        .padding(22)
        .background(MarketplaceUITheme.darkLuxuryGradient)
        .clipShape(RoundedRectangle(cornerRadius: MarketplaceUITheme.cornerXL, style: .continuous))
        .overlay(MarketplaceUITheme.premiumStroke(colorScheme: colorScheme, cornerRadius: MarketplaceUITheme.cornerXL))
        .padding(.horizontal, 16)
        .scaleEffect(animateHeader ? 1 : 0.97)
        .opacity(animateHeader ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                animateHeader = true
            }
        }
    }

    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Rechercher dans l’aide...", text: $searchText)
                .font(.system(.body, design: .rounded).weight(.semibold))
        }
        .padding(16)
        .background(MarketplaceUITheme.glassBackground(colorScheme: colorScheme, cornerRadius: 24))
        .padding(.horizontal, 16)
    }

    private var categoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories) { category in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            selectedCategory = category
                        }
                    } label: {
                        Label(category.title, systemImage: category.icon)
                            .font(.caption.bold())
                            .foregroundStyle(selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                selectedCategory == category
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

    private var quickHelpSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Aide rapide",
                subtitle: "Solutions fréquentes selon ton problème",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)

            MarketplaceSupportRow(icon: "cart.fill", title: "Problème de commande", subtitle: "Commande non reçue, annulée, retardée ou différente.")
            MarketplaceSupportRow(icon: "creditcard.fill", title: "Paiement ou retrait", subtitle: "Stripe, PayPal, Mobile Money, Wallet Cutly ou remboursement.")
            MarketplaceSupportRow(icon: "shippingbox.fill", title: "Livraison", subtitle: "DHL, relais, poste, agence locale, GPS ou main propre.")
            MarketplaceSupportRow(icon: "exclamationmark.shield.fill", title: "Litige sécurisé", subtitle: "Preuves, messages, médiation Cutly et décision admin.")
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: "Questions fréquentes",
                subtitle: "Réponses rapides pour les cas les plus courants",
                actionTitle: "Tout voir",
                action: {}
            )
            .padding(.horizontal, 0)

            MarketplaceSupportRow(
                icon: "clock.fill",
                title: "Combien de temps prend un remboursement ?",
                subtitle: "Selon le moyen de paiement : carte, PayPal, Mobile Money ou Wallet Cutly."
            )

            MarketplaceSupportRow(
                icon: "qrcode.viewfinder",
                title: "Comment confirmer une remise en main propre ?",
                subtitle: "Avec QR Code, code de confirmation, signature ou preuve photo."
            )

            MarketplaceSupportRow(
                icon: "checkmark.seal.fill",
                title: "Comment obtenir la certification Cutly ?",
                subtitle: "Vérification identité, activité, boutique optionnelle et respect des règles."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    
    
    
    private var contactSupportSection: some View {
        VStack(spacing: 12) {
            Button {
                showTicketSheet = true
            } label: {
                Label("Créer un ticket support", systemImage: "paperplane.fill")
            }
            .buttonStyle(MarketplacePremiumButtonStyle())

            Button {
                showEmergencySheet = true
            } label: {
                Label("Urgence litige / fraude", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.primary)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $showTicketSheet) {
            MarketplaceSupportTicketSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEmergencySheet) {
            MarketplaceSupportEmergencySheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var supportReadySection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)

            Text("Support prêt pour Firestore : tickets, litiges, preuves, messages, paiements, livraison, certification et sécurité IA.")
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

enum MarketplaceSupportCategory: String, CaseIterable, Identifiable {
    case orders, payments, delivery, returns, disputes, security, certification, account

    var id: String { rawValue }

    var title: String {
        switch self {
        case .orders: return "Commandes"
        case .payments: return "Paiements"
        case .delivery: return "Livraison"
        case .returns: return "Retours"
        case .disputes: return "Litiges"
        case .security: return "Sécurité"
        case .certification: return "Certification"
        case .account: return "Compte"
        }
    }

    var icon: String {
        switch self {
        case .orders: return "cart.fill"
        case .payments: return "creditcard.fill"
        case .delivery: return "shippingbox.fill"
        case .returns: return "arrow.uturn.backward.circle.fill"
        case .disputes: return "exclamationmark.shield.fill"
        case .security: return "lock.shield.fill"
        case .certification: return "checkmark.seal.fill"
        case .account: return "person.fill"
        }
    }
}

private struct MarketplaceSupportChip: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.14))
            .clipShape(Capsule())
    }
}

private struct MarketplaceSupportRow: View {
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

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
private struct MarketplaceSupportTicketSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var subject = ""
    @State private var message = ""

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    MarketplaceIconBadge(icon: "paperplane.fill", size: 64)

                    Text("Créer un ticket")
                        .font(.system(.title2, design: .rounded).weight(.black))

                    TextField("Sujet", text: $subject)
                        .padding(16)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal, 16)

                    TextField("Explique le problème", text: $message, axis: .vertical)
                        .lineLimit(5)
                        .padding(16)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal, 16)

                    Button {
                        dismiss()
                    } label: {
                        Label("Envoyer au support", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(MarketplacePremiumButtonStyle())
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.top, 30)
            }
            .navigationTitle("Ticket support")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct MarketplaceSupportEmergencySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    MarketplaceIconBadge(icon: "exclamationmark.shield.fill", size: 66)

                    Text("Urgence Marketplace")
                        .font(.system(.title2, design: .rounded).weight(.black))

                    Text("Utilise cette zone pour fraude, arnaque, paiement suspect, faux vendeur, contrefaçon, menace, litige grave ou livraison bloquée.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)

                    MarketplaceSupportRow(icon: "brain.head.profile", title: "Analyse IA", subtitle: "Le ticket pourra être priorisé automatiquement selon le risque.")
                    MarketplaceSupportRow(icon: "photo.badge.plus", title: "Preuves", subtitle: "Photos, vidéos, captures, suivi colis, messages et documents.")
                    MarketplaceSupportRow(icon: "person.badge.shield.checkmark.fill", title: "Support admin", subtitle: "Escalade vers l’équipe Cutly en cas de danger ou fraude.")

                    Button {
                        dismiss()
                    } label: {
                        Label("J’ai compris", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(MarketplacePremiumButtonStyle())
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.top, 30)
                .padding(.horizontal, 16)
            }
            .navigationTitle("Urgence")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}



#Preview {
    MarketplaceSupportView()
}
