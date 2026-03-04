import SwiftUI
import FirebaseFirestore

struct CommentButton: View {
    
    let postId: String
    
    @State private var open = false
    @State private var commentCount: Int = 0
    
    var body: some View {
        
        VStack(spacing: 4) {
            
            Button {
                open = true
            } label: {
                Image(systemName: "bubble.right.fill")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)
            }
            
            Text(formatNumber(commentCount))
                .font(.caption2)
                .foregroundColor(.white)
        }
        .onAppear {
            CommentService.shared.listenCommentCount(postId: postId) { count in
                self.commentCount = count
            }
        }
        .sheet(isPresented: $open) {
            CommentsView(postId: postId)
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
}
