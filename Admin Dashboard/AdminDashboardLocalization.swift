//
//  AdminDashboardLocalization.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import Foundation

enum AdminLanguage: String, CaseIterable, Identifiable {

    case fr
    case en
    case es
    case it
    case tr
    case de
    case pt
    case zh
    case ar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fr: return "Français 🇫🇷"
        case .en: return "English 🇬🇧"
        case .es: return "Español 🇪🇸"
        case .it: return "Italiano 🇮🇹"
        case .tr: return "Türkçe 🇹🇷"
        case .de: return "Deutsch 🇩🇪"
        case .pt: return "Português 🇵🇹"
        case .zh: return "中文 🇨🇳"
        case .ar: return "العربية 🇸🇦"
        }
    }
}

final class AdminLocalization {

    static let shared = AdminLocalization()

    var language: AdminLanguage = .fr

    func text(_ key: String) -> String {

        let dict = translations[language] ?? [:]

        return dict[key] ?? key
    }

    private let translations: [AdminLanguage : [String:String]] = [

        .fr: [

            "dashboard":"Dashboard",

            "overview":"Résumé",

            "users":"Utilisateurs",

            "reports":"Signalements",

            "transactions":"Transactions",

            "bookings":"Réservations",

            "messages":"Messages",

            "calls":"Appels",

            "live":"Lives",

            "marketplace":"Marketplace",

            "withdraw":"Retraits",

            "analytics":"Statistiques",

            "settings":"Paramètres",

            "support":"Support",

            "ai":"Cutly AI",

            "logout":"Déconnexion",

            "save":"Enregistrer",

            "cancel":"Annuler",

            "delete":"Supprimer",

            "ban":"Bannir",

            "restrict":"Restreindre",

            "warning":"Avertir",

            "approved":"Approuvé",

            "pending":"En attente",

            "completed":"Terminé",

            "loading":"Chargement..."
        ],

        .en: [

            "dashboard":"Dashboard",

            "overview":"Overview",

            "users":"Users",

            "reports":"Reports",

            "transactions":"Transactions",

            "bookings":"Bookings",

            "messages":"Messages",

            "calls":"Calls",

            "live":"Live",

            "marketplace":"Marketplace",

            "withdraw":"Withdraw",

            "analytics":"Analytics",

            "settings":"Settings",

            "support":"Support",

            "ai":"Cutly AI",

            "logout":"Logout",

            "save":"Save",

            "cancel":"Cancel",

            "delete":"Delete",

            "ban":"Ban",

            "restrict":"Restrict",

            "warning":"Warn",

            "approved":"Approved",

            "pending":"Pending",

            "completed":"Completed",

            "loading":"Loading..."
        ],

        .es: [:],

        .it: [:],

        .tr: [:],

        .de: [:],

        .pt: [:],

        .zh: [:],

        .ar: [:]
    ]
}
