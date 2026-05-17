//
//  CoinPack.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 10/05/2026.
//


import Foundation

// 🪙 PACKS DE COINS (achat)
struct CoinPack: Identifiable {
    let id = UUID()
    let coins: Int
    let priceEUR: Double
    let bonus: Int
    
    var totalCoins: Int {
        coins + bonus
    }
}



// 🔥 CATALOGUE COINS
let coinPacks: [CoinPack] = [
    CoinPack(coins: 500,  priceEUR: 5,  bonus: 0),
    CoinPack(coins: 1000, priceEUR: 10, bonus: 100),
    CoinPack(coins: 5000, priceEUR: 50, bonus: 1000),
    CoinPack(coins: 10000, priceEUR: 100, bonus: 3000)
]

