import Foundation

struct AnalyticsMetric: Identifiable {
    

    let id = UUID()

    let title: String
    let value: String
    let change: String
    let positive: Bool
}

struct TrafficSource: Identifiable {
    let id = UUID()
    let name: String
    let percent: Double
}

struct VideoStat: Identifiable {

    let id = UUID()

    let title: String
    let views: String
    let date: String
    let thumbnail: String
}
