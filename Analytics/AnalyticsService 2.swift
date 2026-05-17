import Foundation
import Combine

class AnalyticsService: ObservableObject {

    private let dataService = AnalyticsDataService()

    @Published var metrics: [AnalyticsMetric] = []
    @Published var trafficSources: [TrafficSource] = []
    @Published var videos: [VideoStat] = []

    func loadAnalytics() {

        loadMetrics()
        loadTraffic()
        loadVideos()
    }

    func loadMetrics() {

        dataService.fetchMetrics { [weak self] metrics in
            DispatchQueue.main.async {
                self?.metrics = metrics
            }
        }
    }

    func loadTraffic() {

        dataService.fetchTrafficSources { [weak self] traffic in
            DispatchQueue.main.async {
                self?.trafficSources = traffic
            }
        }
    }

    func loadVideos() {

        dataService.fetchTopVideos { [weak self] videos in
            DispatchQueue.main.async {
                self?.videos = videos
            }
        }
    }
}
