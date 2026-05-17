import SwiftUI
import AVKit
import FirebaseFirestore

struct LiveReplayDetailView: View {
    
    var replay: LiveReplay
    
    @State private var player: AVPlayer?
    
    @State private var startTime: Double = 0
    @State private var endTime: Double = 15
    
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    
    @State private var caption: String = ""
    @State private var frames: [UIImage] = []
    
    @State private var timer: Timer?
    
    var body: some View {
        
        ZStack {
            
            // 🎥 VIDEO
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
            // OVERLAY
            LinearGradient(
                colors: [.clear, .black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                
                Spacer()
                
                // ⏱ TIMELINE
                VStack {
                    
                    HStack {
                        Text(formatTime(currentTime))
                        Spacer()
                        Text(formatTime(duration))
                    }
                    .foregroundColor(.white)
                    .font(.caption)
                    
                    Slider(value: Binding(
                        get: { currentTime },
                        set: { newValue in
                            currentTime = newValue
                            player?.seek(to: CMTime(seconds: newValue, preferredTimescale: 600))
                        }
                    ), in: 0...max(duration, 1))
                    .tint(.white)
                }
                .padding(.horizontal)
                
                // 🎬 FRAMES
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        
                        ForEach(Array(frames.enumerated()), id: \.offset) { index, image in
                            
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 110)
                                .clipped()
                                .cornerRadius(8)
                                .onTapGesture {
                                    let time = Double(index) * (duration / Double(max(frames.count,1)))
                                    player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // ✂️ CUT
                VStack(spacing: 10) {
                    
                    Text("Découper le clip")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Slider(value: $startTime, in: 0...duration)
                        .tint(.white)
                    
                    Slider(value: $endTime, in: 0...duration)
                        .tint(.red)
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // ✍️ TEXT
                TextField("Ajouter un texte...", text: $caption)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                // 🔥 BOUTONS
                HStack(spacing: 12) {
                    
                    Button {
                        player?.pause()
                    } label: {
                        Text("Pause")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }
                    
                    Button {
                        publishReplay()
                    } label: {
                        Text("Publier")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            
            // 👉 ACTIONS DROITE
            VStack(spacing: 25) {
                
                Button {
                    print("Download")
                } label: {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                
                Button {
                    print("Delete")
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                
                Button {
                    print("Share")
                } label: {
                    Image(systemName: "arrowshape.turn.up.right")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

// MARK: - FUNCTIONS
extension LiveReplayDetailView {
    
    func setupPlayer() {
        guard let url = URL(string: replay.videoURL), !replay.videoURL.isEmpty else {
            print("❌ URL VIDEO VIDE")
            print("🎥 URL VIDEO =", replay.videoURL)
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        player?.play()
        
        // 🔥 attendre que la vidéo charge
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let seconds = playerItem.asset.duration.seconds
            
            if seconds > 0 && seconds.isFinite {
                duration = seconds
                endTime = seconds
            }
        }
        
        // 🖼 frames
        VideoFrameExtractor.generateFrames(url: url) { images in
            DispatchQueue.main.async {
                self.frames = images
            }
        }
        
        startTimer()
    }
    
    func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = player {
                currentTime = player.currentTime().seconds
            }
        }
    }
    
    func publishReplay() {
        
        let db = Firestore.firestore()
        
        db.collection("posts").addDocument(data: [
            "videoURL": replay.videoURL,
            "caption": caption,
            "startTime": startTime,
            "endTime": endTime,
            "createdAt": Timestamp(date: Date()),
            "likes": 0,
            "views": 0,
            "type": "clip"
        ]) { error in
            
            if let error = error {
                print("❌ erreur:", error.localizedDescription)
            } else {
                print("✅ publié")
            }
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        let min = Int(seconds) / 60
        let sec = Int(seconds) % 60
        return String(format: "%02d:%02d", min, sec)
    }
}
