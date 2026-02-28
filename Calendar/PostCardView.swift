import SwiftUI
import AVKit

struct PostCardView: View {
    
    let post: Post
    @State private var player: AVPlayer?
    
    var body: some View {
        
        ZStack {
            
            if let url = URL(string: post.mediaURL) {
                
                if post.type == .video {
                    
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                    
                } else {
                    
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    } placeholder: {
                        Color.black
                    }
                }
            }
            
            
            VStack(spacing: 26) {
                Spacer()
                
                LikeButton(postId: post.id ?? "")
                CommentButton(postId: post.id ?? "")
                SaveButton(postId: post.id ?? "")
            }
            .padding(.trailing, 12)
            .padding(.bottom, 110)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            
            VStack(alignment: .leading) {
                Spacer()
                
                Text(post.caption)
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black)
        .onAppear {
            setupPlayer()
            FeedPlaybackManager.shared.setCurrent(postId: post.id ?? "")
        }
        .onReceive(FeedPlaybackManager.shared.$currentVisiblePostId) { visibleId in
            
            guard let player else { return }
            
            if visibleId == post.id {
                player.play()
            } else {
                player.pause()
            }
        }
    }
    
    
    private func setupPlayer() {
        guard player == nil,
              post.type == .video,
              let url = URL(string: post.mediaURL)
        else { return }
        
        player = AVPlayer(url: url)
        player?.automaticallyWaitsToMinimizeStalling = true
    }
}
