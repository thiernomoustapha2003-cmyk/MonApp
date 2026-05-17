import Foundation
import FirebaseFirestore
import FirebaseAuth

class AnalyticsDataService {

    private let db = Firestore.firestore()

    // MARK: - Fetch Metrics
    func fetchMetrics(completion: @escaping ([AnalyticsMetric]) -> Void) {

        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("analytics")
            .document(userId)
            .collection("metrics")
            .getDocuments { snapshot, error in

                if let error = error {
                    print("Analytics error:", error)
                    completion([])
                    return
                }

                let metrics = snapshot?.documents.compactMap { doc -> AnalyticsMetric? in

                    let data = doc.data()

                    return AnalyticsMetric(
                        title: data["title"] as? String ?? "",
                        value: data["value"] as? String ?? "",
                        change: data["change"] as? String ?? "",
                        positive: data["positive"] as? Bool ?? false
                    )
                } ?? []

                completion(metrics)
            }
    }

    // MARK: - Fetch Traffic
    func fetchTrafficSources(completion: @escaping ([TrafficSource]) -> Void) {

        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("analytics")
            .document(userId)
            .collection("traffic")
            .getDocuments { snapshot, error in

                if let error = error {
                    print(error)
                    completion([])
                    return
                }

                let traffic = snapshot?.documents.compactMap { doc -> TrafficSource? in

                    let data = doc.data()

                    return TrafficSource(
                        name: data["name"] as? String ?? "",
                        percent: data["percent"] as? Double ?? 0
                    )
                } ?? []

                completion(traffic)
            }
    }

    // MARK: - Fetch Top Videos
    func fetchTopVideos(completion: @escaping ([VideoStat]) -> Void) {

        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("videos")
            .whereField("creatorId", isEqualTo: userId)
            .order(by: "views", descending: true)
            .limit(to: 5)
            .getDocuments { snapshot, error in

                if let error = error {
                    print(error)
                    completion([])
                    return
                }

                let videos = snapshot?.documents.compactMap { doc -> VideoStat? in

                    let data = doc.data()

                    return VideoStat(
                        title: data["title"] as? String ?? "",
                        views: "\(data["views"] as? Int ?? 0)",
                        date: data["date"] as? String ?? "",
                        thumbnail: data["thumbnail"] as? String ?? ""
                    )
                } ?? []

                completion(videos)
            }
    }
}
