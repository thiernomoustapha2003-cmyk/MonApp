//
//  ChatViewOnceAudioBubble.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 19/06/2026.
//

import SwiftUI
import Combine
import AVFoundation
import FirebaseFirestore
import FirebaseAuth

struct ChatViewOnceAudioBubble: View {

    let audioUrl: String
    let duration: Double?
    let messageId: String
    let conversationId: String
    let listenedBy: [String]
    let isMine: Bool

    @StateObject private var audioManager = ViewOnceAudioManager()

    @State private var hasFinished = false
    @State private var isLoading = false
    @State private var timer: Timer?

    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var alreadyListened: Bool {
        if isMine { return false }
        return hasFinished || listenedBy.contains(currentUserId)
    }

    var body: some View {
        Group {
            if alreadyListened {
                HStack(spacing: 8) {
                    Image(systemName: "mic.slash.fill")
                        .foregroundColor(.gray)

                    Text("Vocal déjà écouté")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .italic()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(18)

            } else if isMine {
                HStack(spacing: 8) {
                    Image(systemName: "1.circle")
                    Text("Vocal vue unique")
                    Text(formatTime(duration ?? 0))
                        .foregroundColor(.gray)
                }
                .font(.caption)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.28))
                .cornerRadius(18)

            } else {
                Button {
                    playOnce()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(.blue)

                        Image(systemName: "1.circle")

                        Text("Vocal vue unique")
                            .font(.system(size: 14, weight: .medium))

                        Text(formatTime(duration ?? 0))
                            .foregroundColor(.gray)

                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(18)
                }
                .buttonStyle(.plain)
                .disabled(isLoading || audioManager.isPlaying)
            }
        }
        .onAppear {
            audioManager.onFinish = {
                stopProgressTimer()
                hasFinished = true
                markAsOpenedAfterFinish()
            }
        }
        .onDisappear {
            audioManager.stop()
            stopProgressTimer()
        }
    }

    func playOnce() {
        guard !alreadyListened else { return }
        guard let url = URL(string: audioUrl) else { return }

        isLoading = true

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                await MainActor.run {
                    isLoading = false
                    audioManager.play(data: data)
                    startProgressTimer()
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("❌ Téléchargement vocal vue unique:", error.localizedDescription)
            }
        }
    }

    func startProgressTimer() {
        stopProgressTimer()

        ChatPresenceService.shared.setListeningProgress(
            conversationId: conversationId,
            messageId: messageId,
            progress: 0
        )

        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            let total = max(duration ?? 1, 1)
            let current = audioManager.currentTime
            let progress = min(current / total, 1)

            ChatPresenceService.shared.setListeningProgress(
                conversationId: conversationId,
                messageId: messageId,
                progress: progress
            )
        }
    }

    func stopProgressTimer() {
        timer?.invalidate()
        timer = nil

        ChatPresenceService.shared.setListeningProgress(
            conversationId: conversationId,
            messageId: nil,
            progress: 0
        )
    }

    func markAsOpenedAfterFinish() {
        guard !isMine else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .updateData([
                "opened": true,
                "openedAt": Timestamp(date: Date()),
                "openedBy": FieldValue.arrayUnion([uid]),
                "listenedBy": FieldValue.arrayUnion([uid])
            ])
    }

    func formatTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%01d:%02d", m, s)
    }
}

final class ViewOnceAudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {

    @Published var isPlaying = false

    private var player: AVAudioPlayer?
    var onFinish: (() -> Void)?

    var currentTime: Double {
        player?.currentTime ?? 0
    }

    func play(data: Data) {
        do {
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
        } catch {
            isPlaying = false
            print("❌ Lecture vocal vue unique:", error.localizedDescription)
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.player = nil
            self.onFinish?()
        }
    }
}
