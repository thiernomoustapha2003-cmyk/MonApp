import FirebaseFirestore
import FirebaseAuth

final class LikeService {

    static let shared = LikeService()
    private init() {}

    private let db = Firestore.firestore()

    // LIKE / UNLIKE
    func toggleLike(postId: String, completion: @escaping (Bool) -> Void) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        let likeId = "(uid)(postId)"
        let ref = db.collection("postLikes").document(likeId)

        ref.getDocument { snapshot, _ in

            if let snapshot = snapshot, snapshot.exists {

                // UNLIKE
                ref.delete()
                completion(false)

            } else {

                // LIKE
                ref.setData([
                    "postId": postId,
                    "userId": uid,
                    "createdAt": Timestamp(date: Date())
                ])
                completion(true)
            }
        }
    }

    // CHECK SI DEJA LIKÉ
    func isLiked(postId: String, completion: @escaping (Bool) -> Void) {

        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let likeId = "(uid)(postId)"

        db.collection("postLikes")
            .document(likeId)
            .getDocument { snapshot, _ in
                completion(snapshot?.exists ?? false)
            }
    }
}
