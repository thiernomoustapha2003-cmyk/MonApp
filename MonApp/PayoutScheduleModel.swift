import Foundation

enum PayoutInterval: String, CaseIterable, Identifiable, Codable {
    case daily
    case weekly
    case monthly
    case manual
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .daily: return "Quotidien"
        case .weekly: return "Hebdomadaire"
        case .monthly: return "Mensuel"
        case .manual: return "Manuel (Stripe conserve)"
        }
    }
}

struct PayoutSchedule: Codable {
    var interval: PayoutInterval
    var weeklyAnchor: Int?
    var monthlyAnchor: Int?
    var delayDays: Int
}
