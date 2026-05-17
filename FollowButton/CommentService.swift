import FirebaseFirestore
import FirebaseAuth

final class CommentService {

    static let shared = CommentService()
    private let db = Firestore.firestore()

    // =========================
    // LISTEN COMMENTS
    // =========================
    func listenComments(postId: String, completion: @escaping ([PostComment]) -> Void) {

        db.collection("postComments")
            .whereField("postId", isEqualTo: postId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snap, error in
                
                if let error = error {
                    print("🔥 Firestore listen error:", error.localizedDescription)
                    return
                }

                let comments = snap?.documents.compactMap {
                    try? $0.data(as: PostComment.self)
                } ?? []

                completion(comments)
            }
    }

    // =========================
    // LISTEN COUNT
    // =========================
    func listenCommentCount(postId: String, completion: @escaping (Int) -> Void) {

        db.collection("postComments")
            .whereField("postId", isEqualTo: postId)
            .addSnapshotListener { snap, _ in
                completion(snap?.documents.count ?? 0)
            }
    }

    // =========================
    // SEND COMMENT (avec replies)
    // =========================
    func send(postId: String, text: String, parentCommentId: String? = nil) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("postComments").addDocument(data: [
            "postId": postId,
            "userId": uid,
            "text": text,
            "likesCount": 0,
            "parentCommentId": parentCommentId as Any,
            "createdAt": Timestamp()
        ])
    }

    // =========================
    // TOGGLE LIKE COMMENT
    // =========================
    func toggleLike(comment: PostComment) {

        guard let uid = Auth.auth().currentUser?.uid,
              let commentId = comment.id else { return }

        let likeRef = db.collection("commentLikes")
            .document("\(uid)_\(commentId)")

        likeRef.getDocument { snapshot, _ in

            if snapshot?.exists == true {
                // 🔥 Unlike
                likeRef.delete()
                self.db.collection("postComments")
                    .document(commentId)
                    .updateData([
                        "likesCount": FieldValue.increment(Int64(-1))
                    ])
            } else {
                // 🔥 Like
                likeRef.setData([
                    "commentId": commentId,
                    "userId": uid,
                    "createdAt": Timestamp()
                ])

                self.db.collection("postComments")
                    .document(commentId)
                    .updateData([
                        "likesCount": FieldValue.increment(Int64(1))
                    ])
            }
        }
    }
}
