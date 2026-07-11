//
//  MarketplaceCountries.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import Foundation

struct MarketplaceCountry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let flag: String
    let phoneCode: String
    let defaultLanguage: String
    let defaultCurrency: String
    let mainCities: [String]
}

enum MarketplaceCountries {
    static let all: [MarketplaceCountry] = [
        MarketplaceCountry(
            name: "France",
            flag: "🇫🇷",
            phoneCode: "+33",
            defaultLanguage: "Français",
            defaultCurrency: "EUR (€)",
            mainCities: ["Paris", "Rennes", "Lyon", "Marseille", "Bordeaux", "Lille", "Nantes", "Toulouse"]
        ),
        MarketplaceCountry(
            name: "Guinée",
            flag: "🇬🇳",
            phoneCode: "+224",
            defaultLanguage: "Français",
            defaultCurrency: "GNF",
            mainCities: ["Conakry", "Labé", "Kindia", "Kankan", "Nzérékoré", "Mamou", "Boké"]
        ),
        MarketplaceCountry(
            name: "Sénégal",
            flag: "🇸🇳",
            phoneCode: "+221",
            defaultLanguage: "Français",
            defaultCurrency: "XOF",
            mainCities: ["Dakar", "Thiès", "Touba", "Saint-Louis", "Kaolack", "Ziguinchor"]
        ),
        MarketplaceCountry(
            name: "Côte d’Ivoire",
            flag: "🇨🇮",
            phoneCode: "+225",
            defaultLanguage: "Français",
            defaultCurrency: "XOF",
            mainCities: ["Abidjan", "Bouaké", "Yamoussoukro", "Daloa", "San Pedro", "Korhogo"]
        ),
        MarketplaceCountry(
            name: "Mali",
            flag: "🇲🇱",
            phoneCode: "+223",
            defaultLanguage: "Français",
            defaultCurrency: "XOF",
            mainCities: ["Bamako", "Sikasso", "Mopti", "Kayes", "Ségou"]
        ),
        MarketplaceCountry(
            name: "Maroc",
            flag: "🇲🇦",
            phoneCode: "+212",
            defaultLanguage: "Français",
            defaultCurrency: "MAD",
            mainCities: ["Casablanca", "Rabat", "Marrakech", "Fès", "Tanger", "Agadir"]
        ),
        MarketplaceCountry(
            name: "États-Unis",
            flag: "🇺🇸",
            phoneCode: "+1",
            defaultLanguage: "English",
            defaultCurrency: "USD ($)",
            mainCities: ["New York", "Los Angeles", "Atlanta", "Houston", "Chicago", "Miami"]
        ),
        MarketplaceCountry(
            name: "Canada",
            flag: "🇨🇦",
            phoneCode: "+1",
            defaultLanguage: "Français / English",
            defaultCurrency: "CAD ($)",
            mainCities: ["Montréal", "Toronto", "Ottawa", "Vancouver", "Québec"]
        ),
        MarketplaceCountry(
            name: "Belgique",
            flag: "🇧🇪",
            phoneCode: "+32",
            defaultLanguage: "Français",
            defaultCurrency: "EUR (€)",
            mainCities: ["Bruxelles", "Anvers", "Liège", "Charleroi", "Gand"]
        ),
        MarketplaceCountry(
            name: "Espagne",
            flag: "🇪🇸",
            phoneCode: "+34",
            defaultLanguage: "Español",
            defaultCurrency: "EUR (€)",
            mainCities: ["Madrid", "Barcelone", "Valence", "Séville", "Bilbao"]
        )
    ]
}
