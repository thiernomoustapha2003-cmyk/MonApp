import SwiftUI

import AVKit
struct PostCellView: View {

    let post: Post
    @State private var showComments = false
    @State private var liked = false

    var body: some View {

        ZStack(alignment: .bottomTrailing) {

            // 🎬 PLAYER VIDEO FIREBASE
            if let videoURL = URL(string: post.mediaURL) {

                VideoPlayer(player: AVPlayer(url: videoURL))
                    .ignoresSafeArea()

            } else {
                Color.black
            }
            VStack(alignment: .trailing, spacing: 22) {

                Button {
                    LikeService.shared.toggleLike(postId: post.id!) { isLiked in
                        liked = isLiked
                    }
                } label: {
                    Image(systemName: liked ? "heart.fill" : "heart")
                        .font(.system(size: 28))
                }

                Button {
                    showComments = true
                } label: {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 28))
                }

                Button {
                    print("share")
                } label: {
                    Image(systemName: "arrowshape.turn.up.right")
                        .font(.system(size: 28))
                }
            }
            .foregroundColor(.white)
            .padding(.trailing, 14)
            .padding(.bottom, 90)
        }
        .sheet(isPresented: $showComments) {
            CommentsView(postId: post.id!)
        }
    }
}
