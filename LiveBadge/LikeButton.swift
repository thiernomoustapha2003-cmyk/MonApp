import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LikeButton: View {
    
    let post: Post
    
    @State private var liked = false
    @State private var likesCount: Int = 0
    
    private let db = Firestore.firestore()
    
    var body: some View {
        
        VStack(spacing: 4) {
            
            Button {
                LikeService.shared.toggleLike(post: post) { isLiked in
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        liked = isLiked
                    }
                }
            } label: {
                Image(systemName: liked ? "heart.fill" : "heart")
                    .resizable()
                    .frame(width: 30, height: 28)
                    .foregroundColor(liked ? .red : .white)
                    .scaleEffect(liked ? 1.2 : 1)
                    .animation(.spring(), value: liked)
            }
            
            Text(formatNumber(likesCount))
                .font(.caption2)
                .foregroundColor(.white)
        }
        .onAppear {
            setupInitialState()
            listenLikesCount()
        }
    }
    
    // 🔥 Vérifie si déjà liké
    private func setupInitialState() {
        guard let uid = Auth.auth().currentUser?.uid,
              let postId = post.id else { return }
        
        likesCount = post.likesCount ?? 0
        
        db.collection("postLikes")
            .document("\(postId)_\(uid)")
            .getDocument { doc, _ in
                liked = doc?.exists ?? false
            }
    }
    
    // 🔥 Écoute compteur temps réel
    private func listenLikesCount() {
        guard let postId = post.id else { return }
        
        db.collection("posts")
            .document(postId)
            .addSnapshotListener { snap, _ in
                if let data = snap?.data(),
                   let count = data["likesCount"] as? Int {
                    likesCount = count
                }
            }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number)/1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number)/1_000)
        } else {
            return "\(number)"
        }
    }
}
