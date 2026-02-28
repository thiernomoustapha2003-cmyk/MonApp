import FirebaseFirestore
import FirebaseAuth

final class CommentService {

    static let shared = CommentService()
    private let db = Firestore.firestore()

    func listenComments(postId: String, completion: @escaping ([PostComment]) -> Void) {

        db.collection("postComments")
            .whereField("postId", isEqualTo: postId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snap, _ in

                let comments = snap?.documents.compactMap {
                    try? $0.data(as: PostComment.self)
                } ?? []

                completion(comments)
            }
    }

    func send(postId: String, text: String) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("postComments").addDocument(data: [
            "postId": postId,
            "userId": uid,
            "text": text,
            "createdAt": Timestamp()
        ])
    }
}
