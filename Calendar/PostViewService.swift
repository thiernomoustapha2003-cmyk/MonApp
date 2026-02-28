import FirebaseFirestore
import FirebaseAuth

final class PostViewService {
    
    private let db = Firestore.firestore()
    
    func registerView(postId: String, creatorId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let viewRef = db.collection("postViews").document()
        
        let data: [String: Any] = [
            "postId": postId,
            "viewerId": userId,
            "creatorId": creatorId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        viewRef.setData(data)
    }
}
