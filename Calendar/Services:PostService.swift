import Foundation
import FirebaseFirestore
import FirebaseAuth

final class PostService {

    static let shared = PostService()
    private let db = Firestore.firestore()

    func createPost(videoURL: String, caption: String) {

        guard let user = Auth.auth().currentUser else { return }

        let post = Post(
            creatorId: user.uid,
            creatorName: "Creator",
            creatorAvatar: "",
            mediaURL: videoURL,
            thumbnailURL: nil,
            caption: caption,
            type: .video,
            likesCount: 0,
            commentsCount: 0,
            viewsCount: 0,
            savesCount: 0,
            earnings: 0,
            isMonetized: false,
            createdAt: Date()
        )

        do {
            _ = try db.collection("posts").addDocument(from: post)
        } catch {
            print("POST ERROR", error)
        }
    }
}
