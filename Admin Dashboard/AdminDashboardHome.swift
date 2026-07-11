//
//  AdminDashboardHome.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI

struct AdminDashboardHome: View {

    let totalRevenue: Double
    let usersCount: Int
    let reportsCount: Int
    let bookingsCount: Int
    let transactionsCount: Int
    let liveRevenue: Double
    let bookingRevenue: Double
    let shopRevenue: Double
    let adsRevenue: Double

    let onOpenReports: () -> Void
    let onOpenUsers: () -> Void
    let onOpenRevenue: () -> Void
    let onOpenBookings: () -> Void
    let onOpenAI: () -> Void

    var body: some View {
        VStack(spacing: 22) {

            AdminPremiumHeader(
                title: "Centre de contrôle Cutly",
                subtitle: "Vue globale de la plateforme, revenus, utilisateurs, signalements et activité en temps réel.",
                icon: "sparkles"
            )

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {

                AdminDashboardActionCard(
                    title: "Revenus totaux",
                    value: formatEUR(totalRevenue),
                    subtitle: "Lives + réservations + boutique + publicités",
                    icon: "banknote.fill",
                    gradient: [.green, .mint],
                    action: onOpenRevenue
                )

                AdminDashboardActionCard(
                    title: "Utilisateurs",
                    value: "\(usersCount)",
                    subtitle: "Clients, coiffeurs, créateurs",
                    icon: "person.3.fill",
                    gradient: [.purple, .blue],
                    action: onOpenUsers
                )

                AdminDashboardActionCard(
                    title: "Signalements",
                    value: "\(reportsCount)",
                    subtitle: "À vérifier ou traiter",
                    icon: "exclamationmark.triangle.fill",
                    gradient: [.orange, .red],
                    action: onOpenReports
                )

                AdminDashboardActionCard(
                    title: "Réservations",
                    value: "\(bookingsCount)",
                    subtitle: "Rendez-vous et paiements",
                    icon: "calendar.badge.checkmark",
                    gradient: [.blue, .cyan],
                    action: onOpenBookings
                )

                AdminDashboardActionCard(
                    title: "Transactions",
                    value: "\(transactionsCount)",
                    subtitle: "Cadeaux, coins, commissions",
                    icon: "creditcard.fill",
                    gradient: [.indigo, .purple],
                    action: onOpenRevenue
                )

                AdminDashboardActionCard(
                    title: "Cutly AI",
                    value: "Actif",
                    subtitle: "Assistant intelligent pour support, modération et sécurité",
                    icon: "brain.head.profile",
                    gradient: [.pink, .purple],
                    action: onOpenAI
                )
            }

            AdminSectionBox(title: "Répartition des revenus", icon: "chart.pie.fill") {
                VStack(spacing: 12) {
                    AdminRevenueLine(title: "Lives", value: liveRevenue, total: totalRevenue, icon: "gift.fill")
                    AdminRevenueLine(title: "Réservations", value: bookingRevenue, total: totalRevenue, icon: "scissors")
                    AdminRevenueLine(title: "Boutique", value: shopRevenue, total: totalRevenue, icon: "cart.fill")
                    AdminRevenueLine(title: "Publicités", value: adsRevenue, total: totalRevenue, icon: "megaphone.fill")
                }
            }

            AdminSectionBox(title: "Actions rapides", icon: "bolt.fill") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    AdminQuickAction(title: "Traiter les signalements", icon: "shield.lefthalf.filled", action: onOpenReports)
                    AdminQuickAction(title: "Voir utilisateurs", icon: "person.crop.circle.badge.checkmark", action: onOpenUsers)
                    AdminQuickAction(title: "Contrôler les revenus", icon: "eurosign.circle.fill", action: onOpenRevenue)
                    AdminQuickAction(title: "Ouvrir Cutly AI", icon: "bubble.left.and.text.bubble.right.fill", action: onOpenAI)
                }
            }
        }
    }

    func formatEUR(_ value: Double) -> String {
        String(format: "%.2f €", value)
    }
}

struct AdminDashboardActionCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.32))
                            .frame(width: 50, height: 50)

                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.title3.bold())
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                }

                Text(value)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 185, alignment: .leading)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(Color.white.opacity(0.32), lineWidth: 1)
            )
            .cornerRadius(26)
            .shadow(color: gradient.first?.opacity(0.32) ?? .black.opacity(0.12), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }
}

struct AdminRevenueLine: View {
    let title: String
    let value: Double
    let total: Double
    let icon: String

    var progress: Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)

                Text(title)
                    .font(.subheadline.bold())

                Spacer()

                Text(String(format: "%.2f €", value))
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 9)
        }
    }
}

struct AdminQuickAction: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .font(.title3.bold())
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.bold())
                    .foregroundColor(.black.opacity(0.75))
            }
            .padding(18)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
            )
            .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }
}
