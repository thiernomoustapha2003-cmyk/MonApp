import SwiftUI
import Foundation

// ============================================
// SlotStatus.swift
// ============================================

enum SlotStatus: String, Codable {
    case available
    case booked
    case pending
}

// ============================================
// COULEURS DES CRÉNEAUX (EXACTEMENT COMME TON IMAGE)
// ============================================

func colorForStatus(_ status: SlotStatus) -> Color {
    switch status {
    case .available:
        return .green

    case .booked:
        return .red

    case .pending:
        return .orange
    }
}

// ============================================
// TEXTE AFFICHÉ DANS L’APP
// ============================================

func labelForStatus(_ status: SlotStatus) -> String {
    switch status {
    case .available:
        return "Disponible"

    case .booked:
        return "Réservé"

    case .pending:
        return "En attente"
    }
}
