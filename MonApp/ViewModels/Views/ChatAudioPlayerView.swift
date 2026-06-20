import SwiftUI
import AVFoundation
import FirebaseFirestore
import FirebaseAuth

struct ChatAudioPlayerView: View {

    let audioUrl: String
    let duration: Double?
    let messageId: String
    let conversationId: String
    let listenedBy: [String]
    let avatarURL: String?
    let isMine: Bool
    let isViewOnce: Bool

    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?

    private let bars: [CGFloat] = [12,18,24,16,28,20,14,22,26,15,24,18,12,21,16,10,18,14,20,11,17,13]

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 55) }

            HStack(spacing: 8) {

                if isMine {
                    avatarView
                }

                Button {
                    togglePlay()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(Array(bars.enumerated()), id: \.offset) { index, height in
                            Capsule()
                                .fill(indexProgress(index) ? Color.blue : Color.gray.opacity(0.45))
                                .frame(width: 3, height: height)
                        }
                    }

                    HStack {
                        Text(formatTime(currentTime))
                        Spacer()
                        Text(formatTime(duration ?? 0))
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
                .frame(width: 155)

                if !isMine {
                    avatarView
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isMine ? Color.green.opacity(0.22) : Color.white)
            .clipShape(ChatBubbleShape(isMine: isMine))
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)

            if !isMine { Spacer(minLength: 55) }
        }
        .onDisappear {
            stopAudio()
        }
    }

    var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            if let avatarURL = avatarURL,
               let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 36, height: 36)
            }

            Image(systemName: "mic.fill")
                .font(.system(size: 12))
                .foregroundColor(.blue)
                .padding(3)
                .background(Color.white)
                .clipShape(Circle())
        }
    }

    func indexProgress(_ index: Int) -> Bool {
        let total = max(duration ?? 1, 1)
        let progress = currentTime / total
        let activeBars = Int(progress * Double(bars.count))
        return index <= activeBars
    }

    func togglePlay() {
        if isPlaying {
            player?.pause()
            isPlaying = false
            stopTimer()
        } else {
            playAudio()
        }
    }

    func playAudio() {
        guard let url = URL(string: audioUrl) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                await MainActor.run {
                    do {
                        player = try AVAudioPlayer(data: data)
                        player?.prepareToPlay()
                        player?.play()
                        isPlaying = true
                        startTimer()
                        markAsListened()
                       
                    } catch {
                        print("❌ Lecture audio:", error.localizedDescription)
                    }
                }
            } catch {
                print("❌ Téléchargement audio:", error.localizedDescription)
            }
        }
    }

    func stopAudio() {
        player?.stop()
        player = nil
        isPlaying = false
        stopTimer()
        ChatPresenceService.shared.setListeningProgress(
            conversationId: conversationId,
            messageId: nil,
            progress: 0
        )
    }

    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            currentTime = player?.currentTime ?? 0
            let total = max(duration ?? 1, 1)
            let progress = currentTime / total

            ChatPresenceService.shared.setListeningProgress(
                conversationId: conversationId,
                messageId: messageId,
                progress: progress
            )
            if let player = player, !player.isPlaying {

                isPlaying = false
                stopTimer()

                if isViewOnce && !isMine {

                    Firestore.firestore()
                        .collection("conversations")
                        .document(conversationId)
                        .collection("messages")
                        .document(messageId)
                        .updateData([
                            "opened": true,
                            "openedAt": Timestamp(date: Date()),
                            "openedBy": FieldValue.arrayUnion([
                                Auth.auth().currentUser?.uid ?? ""
                            ])
                        ])
                }
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func markAsListened() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .updateData([
                "listenedBy": FieldValue.arrayUnion([uid])
            ])
    }

    func formatTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60

        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%01d:%02d", m, s)
        }
    }
}

struct ChatBubbleShape: Shape {
    let isMine: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius: CGFloat = 18
        let tail: CGFloat = 10

        if isMine {
            path.addRoundedRect(
                in: CGRect(x: 0, y: 0, width: rect.width - tail, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )

            path.move(to: CGPoint(x: rect.width - tail, y: rect.height - 20))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - 12))
            path.addLine(to: CGPoint(x: rect.width - tail, y: rect.height - 6))
        } else {
            path.addRoundedRect(
                in: CGRect(x: tail, y: 0, width: rect.width - tail, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )

            path.move(to: CGPoint(x: tail, y: rect.height - 20))
            path.addLine(to: CGPoint(x: 0, y: rect.height - 12))
            path.addLine(to: CGPoint(x: tail, y: rect.height - 6))
        }

        return path
    }
}
