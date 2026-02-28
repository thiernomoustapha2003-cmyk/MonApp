import Foundation

// MARK: - Daily Stats (vues par jour)

struct DailyStat: Identifiable {
    let id = UUID()
    let date: Date
    let views: Int
}

// MARK: - Country Stats

struct CountryStat: Identifiable {
    let id = UUID()
    let country: String
    let percentage: Double
}

// MARK: - Audience Demographics

struct AudienceStat {
    let followersPercentage: Double
    let nonFollowersPercentage: Double
    let femalePercentage: Double
    let malePercentage: Double
}
