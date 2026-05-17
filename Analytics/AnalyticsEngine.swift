import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

struct DailyAnalytics: Identifiable {
    let id = UUID()
    let date: Date
    let views: Int
}

struct HourlyAudience: Identifiable {
    let id = UUID()
    let hour: Int
    let viewers: Int
}



import Foundation

struct TopVideo: Identifiable {

    let id: String
    let caption: String
    let thumbnail: String
    let views: Int
    let likes: Int
    let comments: Int
    let shares: Int

}

class AnalyticsEngine: ObservableObject {

    @Published var dailyViews: [DailyAnalytics] = []
    @Published var hourlyAudience: [HourlyAudience] = []
    @Published var trafficSources: [TrafficSource] = []
    @Published var followersGrowth: [DailyAnalytics] = []
    @Published var topVideos: [TopVideo] = []

    private let db = Firestore.firestore()

    init() {
        loadDailyViews()
        loadHourlyAudience()
        loadTrafficSources()
        loadFollowersGrowth()
        loadTopVideos()
    }

    // MARK: DAILY VIEWS GRAPH

    func loadDailyViews() {

        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("videoViews")
            .whereField("creatorId", isEqualTo: userId)
            .getDocuments { snapshot, error in

                guard let docs = snapshot?.documents else { return }

                var map: [Date: Int] = [:]

                for doc in docs {

                    let data = doc.data()

                    if let timestamp = data["createdAt"] as? Timestamp {

                        let date = Calendar.current.startOfDay(for: timestamp.dateValue())

                        map[date, default: 0] += 1
                    }
                }

                DispatchQueue.main.async {

                    self.dailyViews = map.map { DailyAnalytics(date: $0.key, views: $0.value) }
                        .sorted { $0.date < $1.date }
                }
            }
    }

    // MARK: HOURLY AUDIENCE

    func loadHourlyAudience() {

        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("videoViews")
            .whereField("creatorId", isEqualTo: userId)
            .getDocuments { snapshot, error in

                guard let docs = snapshot?.documents else { return }

                var hours: [Int: Int] = [:]

                for doc in docs {

                    let data = doc.data()

                    if let timestamp = data["createdAt"] as? Timestamp {

                        let hour = Calendar.current.component(.hour, from: timestamp.dateValue())

                        hours[hour, default: 0] += 1
                    }
                }

                DispatchQueue.main.async {

                    self.hourlyAudience = hours.map { HourlyAudience(hour: $0.key, viewers: $0.value) }
                        .sorted { $0.hour < $1.hour }
                }
            }
    }

    // MARK: TRAFFIC SOURCES

    func loadTrafficSources() {

        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("videoViews")
            .whereField("creatorId", isEqualTo: userId)
            .getDocuments { snapshot, error in

                guard let docs = snapshot?.documents else { return }

                var sources: [String: Int] = [:]

                for doc in docs {

                    let data = doc.data()

                    let source = data["source"] as? String ?? "unknown"

                    sources[source, default: 0] += 1
                }

                let total = sources.values.reduce(0, +)

                DispatchQueue.main.async {

                    self.trafficSources = sources.map {

                        TrafficSource(
                            name: $0.key,
                            percent: Double($0.value) / Double(max(total,1)) * 100
                        )
                    }
                }
            }
    }

    // MARK: FOLLOWERS GROWTH

    func loadFollowersGrowth() {

        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("follows")
            .whereField("creatorId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in

                guard let docs = snapshot?.documents else { return }

                var map: [Date: Int] = [:]

                for doc in docs {

                    let data = doc.data()

                    if let timestamp = data["createdAt"] as? Timestamp {

                        let date = Calendar.current.startOfDay(for: timestamp.dateValue())

                        map[date, default: 0] += 1
                    }
                }

                DispatchQueue.main.async {

                    self.followersGrowth = map.map {
                        DailyAnalytics(date: $0.key, views: $0.value)
                    }
                    .sorted { $0.date < $1.date }
                }
            }
    }

    // MARK: TOP VIDEOS

    func loadTopVideos() {

        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("posts")
            .whereField("creatorId", isEqualTo: userId)
            .order(by: "views", descending: true)
            .limit(to: 5)
            .getDocuments { snapshot, error in

                guard let docs = snapshot?.documents else { return }

                DispatchQueue.main.async {

                    self.topVideos = docs.map {

                        let data = $0.data()

                        return TopVideo(
                            id: $0.documentID,
                            caption: data["caption"] as? String ?? "",
                            thumbnail: data["mediaURL"] as? String ?? "",
                            views: data["viewsCount"] as? Int ?? 0,
                            likes: data["likesCount"] as? Int ?? 0,
                            comments: data["commentsCount"] as? Int ?? 0,
                            shares: data["sharesCount"] as? Int ?? 0
                        )

                    }
                }
            }
    }
}
