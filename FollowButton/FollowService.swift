import FirebaseFirestore
import FirebaseAuth

final class FollowService {
    
    static let shared = FollowService()
    private let db = Firestore.firestore()
    
    func toggleFollow(targetUserId: String, completion: @escaping (Bool) -> Void) {
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let followRef = db.collection("userFollows")
            .document("\(targetUserId)_\(currentUserId)")
        
        followRef.getDocument { doc, _ in
            
            if doc?.exists == true {
                followRef.delete()
                completion(false)
            } else {
                followRef.setData([
                    "targetUserId": targetUserId,
                    "currentUserId": currentUserId,
                    "createdAt": Timestamp()
                ])
                completion(true)
            }
        }
    }
}
