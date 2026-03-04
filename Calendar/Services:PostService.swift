import Foundation
import FirebaseFirestore
import FirebaseAuth

final class PostService {

    static let shared = PostService()
    private let db = Firestore.firestore()

    // MARK: - CREATE POST

    func createPost(videoURL: String, caption: String, soundId: String? = nil) {

        guard let user = Auth.auth().currentUser else { return }

        let post = Post(
            creatorId: user.uid,
            creatorName: user.displayName ?? "Creator",
            creatorAvatar: user.photoURL?.absoluteString ?? "",
            soundId: soundId,   // 🔥 AJOUT IMPORTANT
            mediaURL: videoURL,
            thumbnailURL: nil,
            caption: caption,
            type: .video,
            likesCount: 0,
            commentsCount: 0,
            viewsCount: 0,
            savesCount: 0,
            sharesCount: 0,
            earnings: 0,
            isMonetized: false,
            createdAt: Date(),
            totalViews: 0,
            countryStats: [:],
           
        )

        do {
            let docRef = try db.collection("posts").addDocument(from: post)

            // ============================
            // 🔥 SI UN SON EST UTILISÉ
            // ============================

            if let soundId = soundId {
                SoundService.shared.incrementUsage(soundId: soundId)
            }

        } catch {
            print("POST ERROR:", error)
        }
    }
}
