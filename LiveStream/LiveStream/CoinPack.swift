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

    CoinPack(
        coins: 50,
        priceEUR: 4.99,
        bonus: 0
    ),

    CoinPack(
        coins: 100,
        priceEUR: 9.99,
        bonus: 10
    ),

    CoinPack(
        coins: 500,
        priceEUR: 49.99,
        bonus: 75
    ),

    CoinPack(
        coins: 1000,
        priceEUR: 99.99,
        bonus: 200
    ),

    CoinPack(
        coins: 2500,
        priceEUR: 249.99,
        bonus: 700
    ),

    CoinPack(
        coins: 5000,
        priceEUR: 499.99,
        bonus: 1750
    ),

    CoinPack(
        coins: 10000,
        priceEUR: 999.99,
        bonus: 4500
    ),

    CoinPack(
        coins: 25000,
        priceEUR: 2499.99,
        bonus: 15000
    )
]
