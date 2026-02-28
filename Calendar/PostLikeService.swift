import Foundation
import FirebaseFirestore
import FirebaseAuth

class PostLikeService {

    private let db = Firestore.firestore()

    // MARK: Like / Unlike
    func toggleLike(postId: String, creatorId: String, completion: @escaping (Bool) -> Void) {

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let likeRef = db.collection("postLikes").document("\(postId)_\(userId)")

        likeRef.getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                // UNLIKE
                likeRef.delete { _ in
                    self.updateLikeCount(postId: postId, increment: -1)
                    self.updateCreatorLikes(creatorId: creatorId, increment: -1)
                    completion(false)
                }
            } else {
                // LIKE
                likeRef.setData([
                    "postId": postId,
                    "userId": userId,
                    "createdAt": FieldValue.serverTimestamp()
                ]) { _ in
                    self.updateLikeCount(postId: postId, increment: 1)
                    self.updateCreatorLikes(creatorId: creatorId, increment: 1)
                    completion(true)
                }
            }
        }
    }

    // MARK: Count likes on post
    private func updateLikeCount(postId: String, increment: Int) {
        let postRef = db.collection("posts").document(postId)

        postRef.updateData([
            "likesCount": FieldValue.increment(Int64(increment))
        ])
    }

    // MARK: Update creator stats
    private func updateCreatorLikes(creatorId: String, increment: Int) {
        let statsRef = db.collection("creatorStats").document(creatorId)

        statsRef.updateData([
            "totalLikes": FieldValue.increment(Int64(increment))
        ])
    }

    // MARK: Check if liked
    func isPostLiked(postId: String, completion: @escaping (Bool) -> Void) {

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let likeRef = db.collection("postLikes").document("\(postId)_\(userId)")

        likeRef.getDocument { snapshot, _ in
            completion(snapshot?.exists ?? false)
        }
    }
}
