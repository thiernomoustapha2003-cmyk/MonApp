import SwiftUI
import AVKit

struct PostCellView: View {
    
    let post: Post
    var isActive: Bool = true // ← sera contrôlé par le Feed
    
    @State private var showComments = false
    @State private var showHeart = false
    @State private var player: AVPlayer? // ✅ player persistant
    
    var body: some View {
        
        GeometryReader { geo in
            
            ZStack {
                
                // MARK: - VIDEO FULL SCREEN
                
                if let videoURL = URL(string: post.mediaURL) {
                    
                    VideoPlayer(player: player)
                        .frame(width: geo.size.width,
                               height: geo.size.height)
                        .ignoresSafeArea()
                        .onAppear {
                            player = AVPlayer(url: videoURL)
                            player?.actionAtItemEnd = .pause
                            
                            if isActive {
                                player?.play()
                            }
                        }
                        .onChange(of: isActive) { newValue in
                            if newValue {
                                player?.seek(to: .zero)
                                player?.play()
                            } else {
                                player?.pause()
                            }
                        }
                } else {
                    Color.black
                        .ignoresSafeArea()
                }
                
                // MARK: - DOUBLE TAP LIKE
                
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        showHeart = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            showHeart = false
                        }
                    }
                
                // MARK: - HEART ANIMATION
                
                if showHeart {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .frame(width: 120, height: 110)
                        .foregroundColor(.white)
                        .scaleEffect(showHeart ? 1.2 : 0.3)
                        .opacity(showHeart ? 0 : 1)
                        .animation(.easeOut(duration: 0.8), value: showHeart)
                }
                
                // MARK: - RIGHT COLUMN (UNCHANGED)
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        RightActionColumn(post: post)
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, 110)
                }
                
                // MARK: - BOTTOM TEXT AREA
                
                VStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        
                        // ✅ NOM PLUS DISTINGUÉ
                        Text("@\(post.creatorName)")
                            .font(.headline) // plus gros
                            .bold()
                            .foregroundColor(.white)
                        
                        // ✅ CAPTION NORMAL
                        Text(post.caption)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(3)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                            Text("Son original")
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
