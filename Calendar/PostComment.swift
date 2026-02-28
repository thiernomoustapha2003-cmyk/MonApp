import Foundation
import FirebaseFirestore

struct PostComment: Identifiable, Codable {

    @DocumentID var id: String?
    let postId: String
    let userId: String
    let text: String
    let createdAt: Timestamp
}
