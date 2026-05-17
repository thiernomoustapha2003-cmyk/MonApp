import SwiftUI
import AVKit
import FirebaseFirestore


struct PostCardView: View {
    
    let post: Post
    
    @State private var player: AVPlayer?
    @State private var audioPlayer: AVPlayer?
    @State private var showHeart = false
    @State private var hasTrackedView = false
    @State private var viewTimer: Timer?
    var body: some View {
        
        ZStack {
            
            // =========================
            // MARK: - MEDIA
            // =========================
            
            mediaView
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    likeWithAnimation()
                    LikeService.shared.toggleLike(post: post) { _ in }
                }
            
            
            // =========================
            // MARK: - DOUBLE TAP HEART
            // =========================
            
            if showHeart {
                Image(systemName: "heart.fill")
                    .resizable()
                    .frame(width: 110, height: 100)
                    .foregroundColor(.white)
                    .scaleEffect(showHeart ? 1 : 0.5)
                    .opacity(showHeart ? 1 : 0)
                    .animation(.easeOut(duration: 0.35), value: showHeart)
                    .zIndex(3)
            }
            
            
            // =========================
            // MARK: - RIGHT ACTION COLUMN (TikTok position)
            // =========================
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    RightActionColumn(post: post)
                        .padding(.trailing, 12)
                        .padding(.bottom, 90) // 🔥 Position exacte TikTok
                }
            }
            .zIndex(4)
            
            // =========================
            // MARK: - CAPTION (Left anchored like TikTok)
            // =========================
            
            VStack {
                Spacer()
                
                HStack {
                    
                    VStack(alignment: .leading, spacing: 6) {
                        
                        // NOM + TEMPS
                        HStack(spacing: 6) {
                            
                            Text(post.safeCreatorName)
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                            
                            Text("•")
                                .foregroundColor(.gray)
                            
                            Text(timeAgoString(from: post.createdAt))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        ExpandableCaption(text: post.caption)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.72, alignment: .leading)
                    .padding(.leading, 14)
                    
                    Spacer() // 🔥 IMPORTANT → pousse tout à gauche
                }
                .padding(.bottom, 100)
            }
            
            .zIndex(2)
        }
        // =========================
        // MARK: - PLAYER SETUP
        // =========================
        
        .onAppear {
            setupPlayer()
        }
        
        // 🔥 Détection cellule visible (solution définitive)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onChange(of: geo.frame(in: .global).midY) { value in
                        
                        let screenMid = UIScreen.main.bounds.midY
                        let distance = abs(value - screenMid)
                        
                        if distance < 40 {
                            FeedPlaybackManager.shared.setCurrent(postId: post.id ?? "")
                        }
                    }
            }
        )
        
        
        // =========================
        // MARK: - PLAYBACK CONTROL
        // =========================
        
        .onReceive(FeedPlaybackManager.shared.$currentVisiblePostId) { visibleId in
            
            guard let player else { return }
            
            if visibleId == post.id {
                
                player.play()
                audioPlayer?.seek(to: .zero)
                audioPlayer?.play()
                
                // 🔥 DÉMARRER TIMER 3 SECONDES
                if !hasTrackedView {
                    
                    viewTimer?.invalidate()
                    
                    viewTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                        
                        hasTrackedView = true
                        
                        ViewTracker.shared.track(
                            postId: post.id ?? "",
                            soundId: post.soundId,
                            watchDuration: 3,
                            completed: false
                        )
                    }
                }
                
            } else {
                
                player.pause()
                audioPlayer?.pause()
                
                // 🔥 Annuler si on scroll avant 3 secondes
                viewTimer?.invalidate()
            }
        }
        // =========================
        // MARK: - SAFETY STOP
        // =========================
        
        .onDisappear {
            player?.pause()
            viewTimer?.invalidate()
        }
    }
    
    
    // =========================
    // MARK: - MEDIA VIEW
    // =========================
    
    @ViewBuilder
    private var mediaView: some View {
        
        if let url = URL(string: post.mediaURL) {
            
            if post.safeType == .video {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePlayPause()
                    }
                
            } else {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                } placeholder: {
                    Color.black
                }
            }
            
        } else {
            Color.black
        }
    }
    
    // =========================
    // MARK: - LIKE ANIMATION
    // =========================
    
    private func likeWithAnimation() {
        showHeart = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showHeart = false
        }
    }
    
    private func togglePlayPause() {
        guard let player else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
            audioPlayer?.pause()
        } else {
            player.play()
            audioPlayer?.play()
        }
    }
    
    // =========================
    // MARK: - PLAYER
    // =========================
    
    private func setupPlayer() {
        guard player == nil,
              let url = URL(string: post.mediaURL)
        else { return }
        
        let videoPlayer = AVPlayer(url: url)
        videoPlayer.automaticallyWaitsToMinimizeStalling = true
        
        // 🎵 Si un son est attaché → mute la vidéo
        if post.soundId != nil {
            videoPlayer.isMuted = true
            loadAndPlaySound()
        } else {
            videoPlayer.isMuted = false
        }
        
        player = videoPlayer
    }
    private func loadAndPlaySound() {
        guard let soundId = post.soundId else { return }

        Firestore.firestore()
            .collection("sounds")
            .document(soundId)
            .getDocument { snapshot, error in

                if let data = snapshot?.data(),
                   let audioURLString = data["audioURL"] as? String,
                   let audioURL = URL(string: audioURLString) {

                    let newAudioPlayer = AVPlayer(url: audioURL)
                    newAudioPlayer.volume = 1.0

                    DispatchQueue.main.async {
                        self.audioPlayer = newAudioPlayer
                    }
                }
            }
    }
}
struct ExpandableCaption: View {
    
    let text: String
    @State private var expanded = false
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 4) {
            
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline)
                .lineLimit(expanded ? nil : 2)
            
            if text.count > 80 {
                Button(expanded ? "Voir moins" : "Voir plus") {
                    withAnimation {
                        expanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
        }
    }
}
// =========================
// MARK: - TIME FORMATTER
// =========================

private func timeAgoString(from timestamp: Date?) -> String {
    
    guard let date = timestamp else { return "" }
    
    let seconds = Int(Date().timeIntervalSince(date))
    
    if seconds < 60 {
        return "à l’instant"
    } else if seconds < 3600 {
        return "\(seconds / 60) min"
    } else if seconds < 86400 {
        return "\(seconds / 3600) h"
    } else {
        return "\(seconds / 86400) j"
    }
}

