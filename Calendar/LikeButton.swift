import SwiftUI

struct LikeButton: View {

    let postId: String

    @State private var isLiked = false
    @State private var anim = false

    var body: some View {

        Button {

            LikeService.shared.toggleLike(postId: postId) { liked in
                isLiked = liked
                anim = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    anim = false
                }
            }

        } label: {

            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 28))
                .foregroundColor(isLiked ? .red : .white)
                .scaleEffect(anim ? 1.35 : 1)
                .animation(.spring(response: 0.25), value: anim)
        }
        .onAppear {
            LikeService.shared.isLiked(postId: postId) { liked in
                isLiked = liked
            }
        }
    }
}
