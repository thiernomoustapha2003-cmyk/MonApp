import Foundation

class AnalyticsDataService {
    
    static let shared = AnalyticsDataService()
    
    // MARK: - Vues sur 30 jours
    
    func getDailyViews() -> [DailyStat] {
        var data: [DailyStat] = []
        
        for i in 0..<30 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let views = Int.random(in: 5000...50000)
            data.append(DailyStat(date: date, views: views))
        }
        
        return data.reversed()
    }
    
    // MARK: - Pays du monde
    
    func getCountryStats() -> [CountryStat] {
        return [
            CountryStat(country: "United States", percentage: 22),
            CountryStat(country: "France", percentage: 18),
            CountryStat(country: "Brazil", percentage: 12),
            CountryStat(country: "Nigeria", percentage: 9),
            CountryStat(country: "Germany", percentage: 7),
            CountryStat(country: "India", percentage: 6),
            CountryStat(country: "Canada", percentage: 5),
            CountryStat(country: "United Kingdom", percentage: 4),
            CountryStat(country: "Other", percentage: 17)
        ]
    }
    
    // MARK: - Audience
    
    func getAudienceStats() -> AudienceStat {
        return AudienceStat(
            followersPercentage: 35,
            nonFollowersPercentage: 65,
            femalePercentage: 58,
            malePercentage: 42
        )
    }
}
