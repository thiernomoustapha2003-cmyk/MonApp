//
//  ViewOnceMediaViewer.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 19/06/2026.
//

import SwiftUI
import AVKit

struct ViewOnceMediaViewer: View {

    let type: String
    let url: String
    let onClose: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isScreenCaptured = UIScreen.main.isCaptured

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isScreenCaptured {
                VStack(spacing: 14) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 46))
                        .foregroundColor(.white)

                    Text("Contenu masqué")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("La capture ou l’enregistrement d’écran n’est pas autorisé.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                if type == "image", let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .ignoresSafeArea()
                    } placeholder: {
                        ProgressView()
                            .tint(.white)
                    }

                } else if type == "video", let videoURL = URL(string: url) {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .ignoresSafeArea()
                }
            }

            VStack {
                HStack {
                    Button {
                        onClose()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.white)
                            .padding()
                    }

                    Spacer()
                }

                Spacer()
            }
        }
        .onAppear {
            UIScreen.main.isCaptured
            NotificationCenter.default.addObserver(
                forName: UIScreen.capturedDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                isScreenCaptured = UIScreen.main.isCaptured
            }
        }
        .onDisappear {
            onClose()
        }
    }
}
