import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FeedRankingEngine: ObservableObject {

    @Published var recommendedPosts: [String] = []

    private let db = Firestore.firestore()

    func loadRecommendedFeed() {

        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("postAnalytics")
            .order(by: "viralScore", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in

                guard let docs = snapshot?.documents else { return }

                var rankedPosts: [(String, Double)] = []

                for doc in docs {

                    let data = doc.data()

                    let postId = data["postId"] as? String ?? ""
                    let viralScore = data["viralScore"] as? Double ?? 0
                    let engagementRate = data["engagementRate"] as? Double ?? 0
                    let completionRate = data["completionRate"] as? Double ?? 0
                    let watchTime = data["avgWatchTime"] as? Double ?? 0

                    let score =
                        (viralScore * 0.4) +
                        (engagementRate * 100 * 0.3) +
                        (completionRate * 100 * 0.2) +
                        (watchTime * 0.1)

                    rankedPosts.append((postId, score))
                }

                rankedPosts.sort { $0.1 > $1.1 }

                DispatchQueue.main.async {
                    self.recommendedPosts = rankedPosts.map { $0.0 }
                }
            }
    }
}
