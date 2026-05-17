import Foundation
import FirebaseFirestore
import Combine

class ForYouFeedEngine: ObservableObject {

    @Published var recommendedPosts: [QueryDocumentSnapshot] = []

    let db = Firestore.firestore()

    func loadFeed() {

        db.collection("posts")
            .order(by: "viralScore", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in

                guard let docs = snapshot?.documents else { return }

                DispatchQueue.main.async {

                    self.recommendedPosts = docs
                }
            }
    }
}
