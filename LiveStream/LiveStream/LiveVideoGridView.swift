//
//  LiveVideoGridView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 06/06/2026.
//

import SwiftUI

struct LiveVideoGridView: View {
    
    let videos: [AgoraVideoView.VideoType]
    
    var body: some View {
        GeometryReader { geo in
            
            let items = Array(videos.prefix(10))
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                if items.isEmpty {
                    Color.black.ignoresSafeArea()
                    
                } else if items.count == 1 {
                    fullVideo(items[0], geo: geo)
                    
                } else if items.count == 2 {
                    VStack(spacing: 2) {
                        videoCell(items[0])
                            .frame(width: geo.size.width, height: geo.size.height / 2)
                        
                        videoCell(items[1])
                            .frame(width: geo.size.width, height: geo.size.height / 2)
                    }
                    .ignoresSafeArea()
                    
                } else if items.count <= 4 {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 2
                    ) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, video in
                            videoCell(video)
                                .frame(
                                    width: geo.size.width / 2,
                                    height: geo.size.height / 2
                                )
                        }
                    }
                    .ignoresSafeArea()
                    
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 2
                    ) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, video in
                            videoCell(video)
                                .frame(
                                    width: geo.size.width / 3,
                                    height: geo.size.height / 3
                                )
                        }
                    }
                    .ignoresSafeArea()
                }
            }
        }
    }
    
    func fullVideo(_ video: AgoraVideoView.VideoType, geo: GeometryProxy) -> some View {
        AgoraVideoView(videoType: video)
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .ignoresSafeArea()
    }
    
    func videoCell(_ video: AgoraVideoView.VideoType) -> some View {
        ZStack(alignment: .bottomLeading) {
            AgoraVideoView(videoType: video)
                .clipped()
            
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.45)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            
            Text(label(for: video))
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.45))
                .clipShape(Capsule())
                .padding(8)
        }
        .background(Color.black)
    }
    
    func label(for video: AgoraVideoView.VideoType) -> String {
        switch video {
        case .local:
            return "Toi"
        case .remote:
            return "Invité"
        }
    }
}
