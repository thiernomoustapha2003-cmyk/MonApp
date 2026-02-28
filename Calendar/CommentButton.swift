import SwiftUI

struct CommentButton: View {
    
    let postId: String
    @State private var open = false
    
    var body: some View {
        
        Button {
            open = true
        } label: {
            Image(systemName: "bubble.right")
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundColor(.white)
        }
        .sheet(isPresented: $open) {
            CommentsView(postId: postId)
        }
    }
    
}
