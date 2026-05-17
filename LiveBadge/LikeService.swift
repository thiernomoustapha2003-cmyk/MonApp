import FirebaseFirestore
import FirebaseAuth

final class LikeService {
    
    static let shared = LikeService()
    private let db = Firestore.firestore()
    
    func toggleLike(post: Post, completion: @escaping (Bool) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid,
              let postId = post.id else {
            completion(false)
            return
        }
        
        let likeRef = db.collection("postLikes").document("\(postId)_\(uid)")
        let postRef = db.collection("posts").document(postId)
        
        db.runTransaction({ transaction, errorPointer in
            
            let likeDoc: DocumentSnapshot
            do {
                likeDoc = try transaction.getDocument(likeRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            var isNowLiked = false
            
            if likeDoc.exists {
                
                transaction.deleteDocument(likeRef)
                transaction.updateData([
                    "likesCount": FieldValue.increment(Int64(-1))
                ], forDocument: postRef)
                
                isNowLiked = false
                
            } else {
                
                transaction.setData([
                    "postId": postId,
                    "userId": uid,
                    "createdAt": Timestamp()
                ], forDocument: likeRef)
                
                transaction.updateData([
                    "likesCount": FieldValue.increment(Int64(1))
                ], forDocument: postRef)
                
                isNowLiked = true
            }
            
            return isNowLiked
            
        }) { object, error in
            
            if let error = error {
                print("🔥 Like transaction error:", error)
                completion(false)
                return
            }
            
            if let result = object as? Bool {
                completion(result)
            } else {
                completion(false)
            }
        }
    }
}
