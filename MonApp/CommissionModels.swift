import Foundation

struct CommissionRule: Identifiable, Codable {
    let id: String
    var percentage: Double
    var fixedFee: Double
    var active: Bool
}

struct CommissionSummary: Codable {
    let totalFees: Double
    let totalBookings: Int
    let month: String
}
