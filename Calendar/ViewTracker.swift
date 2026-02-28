import Foundation
import FirebaseFirestore
import FirebaseAuth

final class ViewTracker {

    static let shared = ViewTracker()
    private let db = Firestore.firestore()

    private init() {}

    func track(postId: String, watchDuration: Int, completed: Bool) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        let userRef = db.collection("users").document(uid)

        userRef.getDocument { snapshot, _ in

            guard let data = snapshot?.data() else { return }

            let country = data["country"] as? String ?? "Unknown"
            let gender = data["gender"] as? String ?? "Unknown"
            let birthYear = data["birthYear"] as? Int ?? 2000

            self.db.collection("postViews").addDocument(data: [
                "postId": postId,
                "viewerId": uid,
                "country": country,
                "gender": gender,
                "birthYear": birthYear,
                "watchDuration": watchDuration,
                "completed": completed,
                "createdAt": Timestamp()
            ])
        }
    }
}
