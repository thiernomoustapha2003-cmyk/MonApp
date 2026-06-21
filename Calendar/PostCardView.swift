import SwiftUI
import AVKit

struct PostCardView: View {
    
    let post: Post
    @State private var player: AVPlayer?
    @State private var showStyleAssistant = false
    
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
                
                LikeButton(post: post)
                CommentButton(postId: post.id ?? "")
                SaveButton(postId: post.id ?? "")

                if post.safeType == .image && post.isServicePost {
                    Button {
                        showStyleAssistant = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "scissors")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Réserver")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                        }
                        .padding(10)
                        .background(Color.black.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
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
        
        StyleBookingAssistantView(
            imageUrl: post.mediaURL,
            preferredStyleId: post.safeStyleId
        )
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
