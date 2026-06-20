import Foundation
import SwiftUI

//////////////////////////////////////////////////////////
// 🎁 ITEM ENVOYÉ EN LIVE
//////////////////////////////////////////////////////////

struct GiftItem: Identifiable {
    let id = UUID()
    let type: GiftType
    let senderName: String
    let senderAvatar: String
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


//////////////////////////////////////////////////////////
// 🎬 MP4 + SONS PREMIUM
//////////////////////////////////////////////////////////

extension GiftType {

    var assetName: String {
        switch self {
        case .rose: return "gift_rose"
        case .like: return "gift_like"
        case .clap: return "gift_clap"
        case .comb: return "gift_comb"
        case .perfume: return "gift_perfume"

        case .lipstick: return "gift_lipstick"
        case .makeup: return "gift_makeup"
        case .nails: return "gift_nails"
        case .straightener: return "gift_straightener"

        case .sunglasses: return "gift_sunglasses"
        case .hat: return "gift_hat"
        case .crown: return "gift_crown"

        case .giftBox: return "gift_box"
        case .fireworks: return "gift_fireworks"
        case .car: return "gift_car"

        case .lion: return "gift_lion"
        case .universe: return "gift_universe"
        case .royalScissors: return "gift_royal_scissors"
        }
    }

    var soundName: String {
        switch self {

        case .lion:
            return "sound_lion"

        case .universe:
            return "sound_universe"

        case .royalScissors:
            return "sound_scissors"

        case .car:
            return "sound_car"

        case .fireworks:
            return "sound_fireworks"

        default:
            return "sound_gift"
        }
    }

    var duration: Double {
        switch self {

        case .lion, .universe, .royalScissors:
            return 5.0

        case .car, .fireworks, .crown, .giftBox:
            return 4.0

        default:
            return 2.8
        }
    }
}

extension GiftType {

    var emoji: String {
        switch self {
        case .rose: return "🌹"
        case .like: return "❤️"
        case .clap: return "👏"
        case .comb: return "🪮"
        case .perfume: return "🧴"
        case .lipstick: return "💄"
        case .makeup: return "🎨"
        case .nails: return "💅"
        case .straightener: return "✨"
        case .sunglasses: return "🕶"
        case .hat: return "🎩"
        case .crown: return "👑"
        case .giftBox: return "🎁"
        case .fireworks: return "🎆"
        case .car: return "🏎"
        case .lion: return "🦁"
        case .universe: return "🌌"
        case .royalScissors: return "✂️"
        }
    }

    var glowColor: Color {
        switch self {
        case .lion, .royalScissors, .crown:
            return .yellow
        case .universe:
            return .purple
        case .rose, .like, .lipstick, .nails:
            return .pink
        case .fireworks, .car:
            return .red
        default:
            return .white
        }
    }
}
extension GiftType {

    var title: String {
        switch self {
        case .rose: return "Rose"
        case .like: return "Like"
        case .clap: return "Clap"
        case .comb: return "Peigne"
        case .perfume: return "Parfum"
        case .lipstick: return "Rouge à lèvres"
        case .makeup: return "Maquillage"
        case .nails: return "Ongles"
        case .straightener: return "Lisseur"
        case .sunglasses: return "Lunettes"
        case .hat: return "Chapeau"
        case .crown: return "Couronne"
        case .giftBox: return "Cadeau"
        case .fireworks: return "Feu d’artifice"
        case .car: return "Voiture"
        case .lion: return "Lion Royal"
        case .universe: return "Univers Cutly"
        case .royalScissors: return "Ciseaux Royal"
        }
    }
}
