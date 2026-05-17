//
//  PaymentMethod.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY on 17/05/2026.
//

import Foundation
import SwiftUI

//////////////////////////////////////////////////////////
// 🌍 PAYMENT METHOD
//////////////////////////////////////////////////////////

struct PaymentMethod: Identifiable, Hashable {
    
    let id = UUID()
    
    //////////////////////////////////////////////////////
    // 🔥 INFOS
    //////////////////////////////////////////////////////
    
    let type: PaymentMethodType
    
    let title: String
    let subtitle: String
    
    //////////////////////////////////////////////////////
    // 🌍 REGION
    //////////////////////////////////////////////////////
    
    let countryCode: String
    let currencyCode: String
    
    //////////////////////////////////////////////////////
    // 🎨 UI
    //////////////////////////////////////////////////////
    
    let icon: String
    let color: Color
    
    //////////////////////////////////////////////////////
    // ⚙️ STATUS
    //////////////////////////////////////////////////////
    
    let isAvailable: Bool
    let isRecommended: Bool
    let processingTime: String
}

//////////////////////////////////////////////////////////
// 💳 TYPES
//////////////////////////////////////////////////////////

enum PaymentMethodType: String, Codable {
    
    //////////////////////////////////////////////////////
    // 💳 BANK
    //////////////////////////////////////////////////////
    
    case stripeCard
    case applePay
    
    //////////////////////////////////////////////////////
    // 🌍 AFRICA
    //////////////////////////////////////////////////////
    
    case orangeMoney
    case wave
    case mobileMoney
    case mtnMoney
    case moovMoney
    
    //////////////////////////////////////////////////////
    // 🔮 FUTURE
    //////////////////////////////////////////////////////
    
    case paypal
    case crypto
}

//////////////////////////////////////////////////////////
// 🌍 DEFAULT METHODS
//////////////////////////////////////////////////////////

extension PaymentMethod {
    
    static let defaultMethods: [PaymentMethod] = [
        
        //////////////////////////////////////////////////////
        // 🍎 APPLE PAY
        //////////////////////////////////////////////////////
        
        PaymentMethod(
            type: .applePay,
            title: "Apple Pay",
            subtitle: "Paiement instantané sécurisé",
            countryCode: "FR",
            currencyCode: "EUR",
            icon: "apple.logo",
            color: .white,
            isAvailable: true,
            isRecommended: true,
            processingTime: "Instantané"
        ),
        
        //////////////////////////////////////////////////////
        // 💳 STRIPE CARD
        //////////////////////////////////////////////////////
        
        PaymentMethod(
            type: .stripeCard,
            title: "Carte bancaire",
            subtitle: "Visa • Mastercard • Amex",
            countryCode: "GLOBAL",
            currencyCode: "EUR",
            icon: "creditcard.fill",
            color: .blue,
            isAvailable: true,
            isRecommended: true,
            processingTime: "Instantané"
        ),
        
        //////////////////////////////////////////////////////
        // 🟠 ORANGE MONEY
        //////////////////////////////////////////////////////
        
        PaymentMethod(
            type: .orangeMoney,
            title: "Orange Money",
            subtitle: "Guinée • Mali • Côte d’Ivoire",
            countryCode: "GN",
            currencyCode: "GNF",
            icon: "iphone.gen3.radiowaves.left.and.right",
            color: .orange,
            isAvailable: false,
            isRecommended: true,
            processingTime: "30 sec"
        ),
        
        //////////////////////////////////////////////////////
        // 🌊 WAVE
        //////////////////////////////////////////////////////
        
        PaymentMethod(
            type: .wave,
            title: "Wave",
            subtitle: "Sénégal • Côte d’Ivoire",
            countryCode: "SN",
            currencyCode: "XOF",
            icon: "water.waves",
            color: .cyan,
            isAvailable: false,
            isRecommended: true,
            processingTime: "30 sec"
        ),
        
        //////////////////////////////////////////////////////
        // 📱 MOBILE MONEY
        //////////////////////////////////////////////////////
        
        PaymentMethod(
            type: .mobileMoney,
            title: "Mobile Money",
            subtitle: "Paiement mobile Afrique",
            countryCode: "GLOBAL",
            currencyCode: "XOF",
            icon: "simcard.fill",
            color: .green,
            isAvailable: false,
            isRecommended: false,
            processingTime: "1 min"
        ),
        
        //////////////////////////////////////////////////////
        // 🟡 MTN MONEY
        //////////////////////////////////////////////////////
        
        PaymentMethod(
            type: .mtnMoney,
            title: "MTN Money",
            subtitle: "Afrique Mobile Payment",
            countryCode: "CM",
            currencyCode: "XAF",
            icon: "antenna.radiowaves.left.and.right",
            color: .yellow,
            isAvailable: false,
            isRecommended: false,
            processingTime: "1 min"
        ),
        
        //////////////////////////////////////////////////////
        // 🔵 MOOV MONEY
        //////////////////////////////////////////////////////
        
        PaymentMethod(
            type: .moovMoney,
            title: "Moov Money",
            subtitle: "Paiement Mobile Moov",
            countryCode: "CI",
            currencyCode: "XOF",
            icon: "network",
            color: .purple,
            isAvailable: false,
            isRecommended: false,
            processingTime: "1 min"
        )
    ]
}

//////////////////////////////////////////////////////////
// 🌍 HELPERS
//////////////////////////////////////////////////////////

extension PaymentMethod {
    
    var isAfricanMethod: Bool {
        switch type {
        case .orangeMoney,
                .wave,
                .mobileMoney,
                .mtnMoney,
                .moovMoney:
            return true
            
        default:
            return false
        }
    }
    
    var requiresExternalApp: Bool {
        switch type {
        case .orangeMoney,
                .wave,
                .mobileMoney,
                .mtnMoney,
                .moovMoney:
            return true
            
        default:
            return false
        }
    }
    
    var badgeText: String {
        if isRecommended {
            return "Populaire"
        }
        
        if !isAvailable {
            return "Bientôt"
        }
        
        return "Disponible"
    }
}
