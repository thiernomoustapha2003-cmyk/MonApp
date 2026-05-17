//
//  GiftCatalog.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY on 10/05/2026.
//

import Foundation

//////////////////////////////////////////////////////////
// 🎁 MODÈLE CADEAU
//////////////////////////////////////////////////////////

struct Gift: Identifiable {
    
    let id = UUID()
    
    let name: String
    let emoji: String
    
    // 🪙 coût en coins
    let coins: Int
    
    // 💶 valeur achat
    let priceEUR: Double
    
    // 🔥 niveau animation
    let rarity: GiftRarity
}

//////////////////////////////////////////////////////////
// 🔥 RARETÉ
//////////////////////////////////////////////////////////

enum GiftRarity {
    case basic
    case premium
    case epic
    case legendary
    case royal
}

//////////////////////////////////////////////////////////
// 🎁 CATALOGUE CUTLY LIVE
//////////////////////////////////////////////////////////

let giftCatalog: [Gift] = [
    
    //////////////////////////////////////////////////////
    // 💸 MINI CADEAUX
    //////////////////////////////////////////////////////
    
    Gift(
        name: "Rose",
        emoji: "🌹",
        coins: 5,
        priceEUR: 0.49,
        rarity: .basic
    ),
    
    Gift(
        name: "Like",
        emoji: "❤️",
        coins: 10,
        priceEUR: 0.99,
        rarity: .basic
    ),
    
    Gift(
        name: "Clap",
        emoji: "👏",
        coins: 20,
        priceEUR: 1.99,
        rarity: .basic
    ),
    
    Gift(
        name: "Peigne",
        emoji: "🪮",
        coins: 25,
        priceEUR: 2.49,
        rarity: .basic
    ),
    
    Gift(
        name: "Parfum",
        emoji: "🧴",
        coins: 35,
        priceEUR: 3.49,
        rarity: .basic
    ),
    
    //////////////////////////////////////////////////////
    // ✨ BEAUTÉ / MAKEUP
    //////////////////////////////////////////////////////
    
    Gift(
        name: "Rouge à lèvres",
        emoji: "💄",
        coins: 50,
        priceEUR: 4.99,
        rarity: .premium
    ),
    
    Gift(
        name: "Maquillage",
        emoji: "🎨",
        coins: 80,
        priceEUR: 7.99,
        rarity: .premium
    ),
    
    Gift(
        name: "Ongles",
        emoji: "💅",
        coins: 120,
        priceEUR: 11.99,
        rarity: .premium
    ),
    
    Gift(
        name: "Lisseur",
        emoji: "✨",
        coins: 180,
        priceEUR: 17.99,
        rarity: .premium
    ),
    
    //////////////////////////////////////////////////////
    // 😎 STYLE
    //////////////////////////////////////////////////////
    
    Gift(
        name: "Lunettes",
        emoji: "🕶",
        coins: 250,
        priceEUR: 24.99,
        rarity: .epic
    ),
    
    Gift(
        name: "Chapeau",
        emoji: "🎩",
        coins: 350,
        priceEUR: 34.99,
        rarity: .epic
    ),
    
    Gift(
        name: "Couronne",
        emoji: "👑",
        coins: 500,
        priceEUR: 49.99,
        rarity: .epic
    ),
    
    //////////////////////////////////////////////////////
    // 🎉 GROS CADEAUX
    //////////////////////////////////////////////////////
    
    Gift(
        name: "Cadeau",
        emoji: "🎁",
        coins: 800,
        priceEUR: 79.99,
        rarity: .legendary
    ),
    
    Gift(
        name: "Feu d'artifice",
        emoji: "🎆",
        coins: 1200,
        priceEUR: 119.99,
        rarity: .legendary
    ),
    
    Gift(
        name: "Voiture",
        emoji: "🏎",
        coins: 2500,
        priceEUR: 249.99,
        rarity: .legendary
    ),
    
    //////////////////////////////////////////////////////
    // 🐐 ULTRA PREMIUM
    //////////////////////////////////////////////////////
    
    Gift(
        name: "Lion",
        emoji: "🦁",
        coins: 5000,
        priceEUR: 499.99,
        rarity: .royal
    ),
    
    Gift(
        name: "Univers",
        emoji: "🌌",
        coins: 10000,
        priceEUR: 999.99,
        rarity: .royal
    ),
    
    //////////////////////////////////////////////////////
    // ✂️ CADEAU CUTLY OFFICIEL
    //////////////////////////////////////////////////////
    
    Gift(
        name: "Ciseaux Royal",
        emoji: "✂️",
        coins: 25000,
        priceEUR: 2499.99,
        rarity: .royal
    )
]
