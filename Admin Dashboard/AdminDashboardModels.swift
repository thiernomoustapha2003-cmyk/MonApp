//
//  AdminDashboardModels.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY on 29/06/2026.
//

import SwiftUI
import FirebaseFirestore

enum AdminDashboardTab: String, CaseIterable, Identifiable {
    case home = "Tableau"
    case revenue = "Revenus"
    case users = "Utilisateurs"
    case reports = "Signalements"
    case bookings = "Réservations"
    case messages = "Messages"
    case calls = "Appels"
    case lives = "Lives"
    case gifts = "Cadeaux"
    case shop = "Boutique"
    case orders = "Commandes"
    case withdrawals = "Retraits"
    case transactions = "Transactions"
    case analytics = "Statistiques"
    case marketplace = "Marketplace"
    case appeals = "Contestations"
    case settings = "Paramètres"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "square.grid.2x2.fill"
        case .revenue: return "banknote.fill"
        case .users: return "person.3.fill"
        case .reports: return "exclamationmark.triangle.fill"
        case .bookings: return "calendar.badge.checkmark"
        case .messages: return "message.fill"
        case .calls: return "phone.fill"
        case .lives: return "dot.radiowaves.left.and.right"
        case .gifts: return "gift.fill"
        case .shop: return "cart.fill"
        case .orders: return "shippingbox.fill"
        case .withdrawals: return "creditcard.fill"
        case .transactions: return "creditcard.and.123"
        case .analytics: return "chart.bar.xaxis"
        case .marketplace: return "bag.fill"
        case .appeals:
            return "doc.badge.gearshape.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct AdminStatCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let icon: String
}

struct AdminReportItem: Identifiable {
    let id: String
    let reason: String
    let details: String
    let reportedUserId: String
    let reportedBy: String
    let status: String
    let createdAt: Date
}

struct AdminUserItem: Identifiable {
    let id: String
    let name: String
    let email: String
    let role: String
    let isBanned: Bool
    let isRestricted: Bool
}

struct AdminBookingItem: Identifiable {
    let id: String
    let status: String
    let paymentStatus: String
    let amount: Double
    let commission: Double
    let createdAt: Date
}

struct AdminTransactionItem: Identifiable {
    let id: String
    let title: String
    let senderName: String
    let category: String
    let amount: Double
    let commission: Double
    let status: String
    let date: Date
}
