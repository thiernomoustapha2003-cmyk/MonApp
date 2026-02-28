import Foundation
import FirebaseFirestore

final class EngagementService {

    static let db = Firestore.firestore()

    static func updatePostEngagement(postId: String) {

        db.collection("postViews")
            .whereField("postId", isEqualTo: postId)
            .getDocuments { viewSnap, _ in

                let views = viewSnap?.documents ?? []
                let totalViews = views.count

                var completedCount = 0
                var totalWatchDuration = 0

                for doc in views {
                    let data = doc.data()
                    let completed = data["completed"] as? Bool ?? false
                    let duration = data["watchDuration"] as? Int ?? 0

                    if completed { completedCount += 1 }
                    totalWatchDuration += duration
                }

                let completionRate = totalViews > 0
                    ? (Double(completedCount) / Double(totalViews)) * 100
                    : 0

                let avgWatchDuration = totalViews > 0
                    ? Double(totalWatchDuration) / Double(totalViews)
                    : 0

                db.collection("postLikes")
                    .whereField("postId", isEqualTo: postId)
                    .getDocuments { likeSnap, _ in

                        let totalLikes = likeSnap?.documents.count ?? 0

                        db.collection("postComments")
                            .whereField("postId", isEqualTo: postId)
                            .getDocuments { commentSnap, _ in

                                let totalComments = commentSnap?.documents.count ?? 0

                                let score =
                                (Double(totalLikes) * 3)
                                + (Double(totalComments) * 4)
                                + (completionRate * 2)
                                + (avgWatchDuration * 1.5)

                                db.collection("postEngagement")
                                    .document(postId)
                                    .setData([
                                        "postId": postId,
                                        "totalScore": score,
                                        "completionRate": completionRate,
                                        "avgWatchDuration": avgWatchDuration,
                                        "totalLikes": totalLikes,
                                        "totalComments": totalComments,
                                        "totalViews": totalViews,
                                        "lastUpdated": Timestamp()
                                    ])
                            }
                    }
            }
    }
}
