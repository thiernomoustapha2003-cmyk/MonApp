import Foundation

struct GenderStat: Identifiable {

    let id = UUID()
    let gender: String
    let count: Int
    let percentage: Double
}
