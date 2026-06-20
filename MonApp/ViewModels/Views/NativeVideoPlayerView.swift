//
//  NativeVideoPlayerView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 19/06/2026.
//

import SwiftUI
import AVKit

struct ChatVideoItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct NativeVideoPlayerScreen: View {

    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NativeVideoPlayerController(url: url)
                .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.white)
                    .padding(.top, 55)
                    .padding(.trailing, 20)
            }
        }
        .background(Color.black)
    }
}

struct NativeVideoPlayerController: UIViewControllerRepresentable {

    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)

        context.coordinator.player = player

        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            player.play()
        }

        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {}

    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.player = nil
        controller.player = nil
    }

    class Coordinator {
        var player: AVPlayer?
    }
}
