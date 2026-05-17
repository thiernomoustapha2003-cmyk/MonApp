import Foundation
import SwiftUI

//////////////////////////////////////////////////////////
// 🎁 ITEM ENVOYÉ EN LIVE
//////////////////////////////////////////////////////////

struct GiftItem: Identifiable {
    let id = UUID()
    let type: GiftType
}

//////////////////////////////////////////////////////////
// 🎁 TYPES DE CADEAUX
//////////////////////////////////////////////////////////

enum GiftType {
    
    // 💸 petits
    case rose
    case like
    case clap
    case comb
    case perfume
    
    // 💄 beauté
    case lipstick
    case makeup
    case nails
    case straightener
    
    // 😎 style
    case sunglasses
    case hat
    case crown
    
    // 🎉 gros
    case giftBox
    case fireworks
    case car
    
    // 🐐 premium
    case lion
    case universe
    case royalScissors
}

//////////////////////////////////////////////////////////
// 🔥 CONVERSION GIFT -> TYPE
//////////////////////////////////////////////////////////

extension GiftType {
    
    static func fromGiftName(_ name: String) -> GiftType {
        
        switch name {
            
        case "Rose":
            return .rose
            
        case "Like":
            return .like
            
        case "Clap":
            return .clap
            
        case "Peigne":
            return .comb
            
        case "Parfum":
            return .perfume
            
        case "Rouge à lèvres":
            return .lipstick
            
        case "Maquillage":
            return .makeup
            
        case "Ongles":
            return .nails
            
        case "Lisseur":
            return .straightener
            
        case "Lunettes":
            return .sunglasses
            
        case "Chapeau":
            return .hat
            
        case "Couronne":
            return .crown
            
        case "Cadeau":
            return .giftBox
            
        case "Feu d'artifice":
            return .fireworks
            
        case "Voiture":
            return .car
            
        case "Lion":
            return .lion
            
        case "Univers":
            return .universe
            
        case "Ciseaux Royal":
            return .royalScissors
            
        default:
            return .rose
        }
    }
}
