//
//  CurrencyConverter.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY on 17/05/2026.
//

import Foundation
import SwiftUI
import Combine

//////////////////////////////////////////////////////////
// 🌍 CURRENCY CONVERTER
//////////////////////////////////////////////////////////

final class CurrencyConverter: ObservableObject {
    
    //////////////////////////////////////////////////////
    // 🔥 SINGLETON
    //////////////////////////////////////////////////////
    
    static let shared = CurrencyConverter()
    
    //////////////////////////////////////////////////////
    // 🌍 LIVE RATES
    //////////////////////////////////////////////////////
    
    @Published var eurToGNF: Double = 9300
    @Published var eurToXOF: Double = 655
    @Published var eurToXAF: Double = 655
    @Published var eurToUSD: Double = 1.08
    
    //////////////////////////////////////////////////////
    // 🔒 INIT
    //////////////////////////////////////////////////////
    
    private init() {}
}

//////////////////////////////////////////////////////////
// 💱 CONVERSIONS
//////////////////////////////////////////////////////////

extension CurrencyConverter {
    
    //////////////////////////////////////////////////////
    // 🇬🇳 EUR -> GNF
    //////////////////////////////////////////////////////
    
    func convertEURToGNF(
        _ amount: Double
    ) -> Int {
        
        Int(amount * eurToGNF)
    }
    
    //////////////////////////////////////////////////////
    // 🇸🇳 EUR -> XOF
    //////////////////////////////////////////////////////
    
    func convertEURToXOF(
        _ amount: Double
    ) -> Int {
        
        Int(amount * eurToXOF)
    }
    
    //////////////////////////////////////////////////////
    // 🇨🇲 EUR -> XAF
    //////////////////////////////////////////////////////
    
    func convertEURToXAF(
        _ amount: Double
    ) -> Int {
        
        Int(amount * eurToXAF)
    }
    
    //////////////////////////////////////////////////////
    // 🇺🇸 EUR -> USD
    //////////////////////////////////////////////////////
    
    func convertEURToUSD(
        _ amount: Double
    ) -> Double {
        
        amount * eurToUSD
    }
}

//////////////////////////////////////////////////////////
// 💶 FORMATTERS
//////////////////////////////////////////////////////////

extension CurrencyConverter {
    
    //////////////////////////////////////////////////////
    // 🇬🇳 GNF
    //////////////////////////////////////////////////////
    
    func formatGNF(
        _ amount: Int
    ) -> String {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        return "\(formatter.string(from: NSNumber(value: amount)) ?? "\(amount)") GNF"
    }
    
    //////////////////////////////////////////////////////
    // 🇸🇳 XOF
    //////////////////////////////////////////////////////
    
    func formatXOF(
        _ amount: Int
    ) -> String {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        return "\(formatter.string(from: NSNumber(value: amount)) ?? "\(amount)") FCFA"
    }
    
    //////////////////////////////////////////////////////
    // 🇨🇲 XAF
    //////////////////////////////////////////////////////
    
    func formatXAF(
        _ amount: Int
    ) -> String {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        return "\(formatter.string(from: NSNumber(value: amount)) ?? "\(amount)") XAF"
    }
    
    //////////////////////////////////////////////////////
    // 💶 EUR
    //////////////////////////////////////////////////////
    
    func formatEUR(
        _ amount: Double
    ) -> String {
        
        String(format: "€%.2f", amount)
    }
}

//////////////////////////////////////////////////////////
// 🌍 COUNTRY DETECTION
//////////////////////////////////////////////////////////

extension CurrencyConverter {
    
    func detectedCurrencyCode() -> String {
        
        let region = Locale.current.region?.identifier ?? "FR"
        
        switch region {
            
        case "GN":
            return "GNF"
            
        case "SN", "CI", "ML", "BF":
            return "XOF"
            
        case "CM", "GA", "TD":
            return "XAF"
            
        case "US":
            return "USD"
            
        default:
            return "EUR"
        }
    }
    
    //////////////////////////////////////////////////////
    // 🌍 LOCAL DISPLAY
    //////////////////////////////////////////////////////
    
    func localizedPrice(
        eurAmount: Double
    ) -> String {
        
        let currency = detectedCurrencyCode()
        
        switch currency {
            
        //////////////////////////////////////////////////////
        // 🇬🇳 GNF
        //////////////////////////////////////////////////////
            
        case "GNF":
            
            return formatGNF(
                convertEURToGNF(eurAmount)
            )
            
        //////////////////////////////////////////////////////
        // 🇸🇳 FCFA
        //////////////////////////////////////////////////////
            
        case "XOF":
            
            return formatXOF(
                convertEURToXOF(eurAmount)
            )
            
        //////////////////////////////////////////////////////
        // 🇨🇲 XAF
        //////////////////////////////////////////////////////
            
        case "XAF":
            
            return formatXAF(
                convertEURToXAF(eurAmount)
            )
            
        //////////////////////////////////////////////////////
        // 🇺🇸 USD
        //////////////////////////////////////////////////////
            
        case "USD":
            
            return String(
                format: "$%.2f",
                convertEURToUSD(eurAmount)
            )
            
        //////////////////////////////////////////////////////
        // 💶 DEFAULT EUR
        //////////////////////////////////////////////////////
            
        default:
            return formatEUR(eurAmount)
        }
    }
}

//////////////////////////////////////////////////////////
// 🌍 FUTURE LIVE API
//////////////////////////////////////////////////////////

extension CurrencyConverter {
    
    //////////////////////////////////////////////////////
    // 🔮 UPDATE RATES
    //////////////////////////////////////////////////////
    
    func refreshRates() {
        
        //////////////////////////////////////////////////////
        // FUTURE:
        // - exchangeratesapi.io
        // - openexchange
        // - forex
        // - firebase cache
        //////////////////////////////////////////////////////
        
        print("🌍 Currency rates refreshed")
    }
}
