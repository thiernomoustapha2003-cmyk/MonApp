//
//  ChatMediaPreviewView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 18/06/2026.
//

import SwiftUI
import AVKit

struct ChatPreviewMedia: Identifiable {
    let id = UUID()
    let type: String
    let data: Data
    let image: UIImage?
    let videoURL: URL?
}

struct ChatMediaPreviewView: View {

    @Binding var medias: [ChatPreviewMedia]
    @Binding var sendAsViewOnce: Bool

    let onCancel: () -> Void
    let onSend: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                if medias.isEmpty {
                    Spacer()
                    Text("Aucun média sélectionné")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    TabView {
                        ForEach(medias) { media in
                            ZStack(alignment: .topTrailing) {

                                Color.black.opacity(0.95)
                                    .ignoresSafeArea()

                                if media.type == "image", let image = media.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .padding()

                                } else if media.type == "video", let url = media.videoURL {
                                    VideoPlayer(player: AVPlayer(url: url))
                                        .padding()
                                }

                                Button {
                                    medias.removeAll { $0.id == media.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 34))
                                        .foregroundColor(.white)
                                        .shadow(radius: 5)
                                        .padding()
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page)
                }

                VStack(spacing: 12) {

                    Toggle(isOn: $sendAsViewOnce) {
                        HStack(spacing: 8) {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(sendAsViewOnce ? .blue : .gray)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Vue unique")
                                    .font(.headline)

                                Text("Le média disparaît après une seule ouverture")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    Button {
                        onSend()
                    } label: {
                        HStack {
                            Image(systemName: sendAsViewOnce ? "lock.fill" : "paperplane.fill")
                            Text(sendAsViewOnce ? "Envoyer en vue unique" : "Envoyer \(medias.count) fichier(s)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(medias.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(medias.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Aperçu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        onCancel()
                    }
                }
            }
        }
    }
}
