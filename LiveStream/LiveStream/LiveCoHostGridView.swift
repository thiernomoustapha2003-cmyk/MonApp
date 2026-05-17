//
//  LiveCoHostGridView.swift
//  MonApp
//

import SwiftUI
import FirebaseAuth
import AVFoundation

struct LiveCoHostGridView: View {
    
    let liveId: String
    let isHostView: Bool
    let hostSession: AVCaptureSession?
    let selectedFilter: String
    let currentPosition: AVCaptureDevice.Position
    let onInviteTap: (() -> Void)?
    
    @StateObject private var coHostService = LiveCoHostService.shared
    
    init(
        liveId: String,
        isHostView: Bool,
        hostSession: AVCaptureSession?,
        selectedFilter: String,
        currentPosition: AVCaptureDevice.Position,
        onInviteTap: (() -> Void)? = nil
    ) {
        self.liveId = liveId
        self.isHostView = isHostView
        self.hostSession = hostSession
        self.selectedFilter = selectedFilter
        self.currentPosition = currentPosition
        self.onInviteTap = onInviteTap
    }
    
    var participants: [LiveCoHost] {
        var items: [LiveCoHost] = []
        
        if let host = coHostService.host {
            items.append(host)
        }
        
        items.append(contentsOf: coHostService.activeGuests.prefix(9))
        return items
    }
    
    var totalSlots: Int {
        let count = max(participants.count, 4)
        return min(count, 10)
    }
    
    var body: some View {
        GeometryReader { geo in
            
            let layout = gridLayout(for: totalSlots)
            
            ZStack {
                Color.black.opacity(0.92)
                    .ignoresSafeArea()
                
                LazyVGrid(
                    columns: layout.columns,
                    spacing: layout.spacing
                ) {
                    ForEach(0..<totalSlots, id: \.self) { index in
                        
                        if index < participants.count {
                            let participant = participants[index]
                            
                            LiveVideoTileView(
                                liveId: liveId,
                                participant: participant,
                                videoType: videoType(for: participant),
                                isHostView: isHostView,
                                onGift: { selected in
                                    print("🎁 Cadeau pour \(selected.displayName)")
                                },
                                onSpotlight: isHostView ? { selected in
                                    print("📌 Agrandir \(selected.displayName)")
                                } : nil
                            )
                            .frame(
                                width: tileWidth(screenWidth: geo.size.width, columns: layout.count),
                                height: tileHeight(total: totalSlots, screenHeight: geo.size.height)
                            )
                            
                        } else {
                            inviteTile
                                .frame(
                                    width: tileWidth(screenWidth: geo.size.width, columns: layout.count),
                                    height: tileHeight(total: totalSlots, screenHeight: geo.size.height)
                                )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 95)
                .padding(.bottom, 125)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            coHostService.startListening(liveId: liveId)
        }
        .onDisappear {
            coHostService.stopListening()
        }
    }
    
    var inviteTile: some View {
        Button {
            onInviteTap?()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.045))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                
                VStack(spacing: 10) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    
                    Text("INVITER")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.75))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

extension LiveCoHostGridView {
    
    struct GridLayout {
        let columns: [GridItem]
        let count: Int
        let spacing: CGFloat
    }
    
    func gridLayout(for total: Int) -> GridLayout {
        let spacing: CGFloat = 6
        
        switch total {
        case 1:
            return GridLayout(
                columns: [GridItem(.flexible(), spacing: spacing)],
                count: 1,
                spacing: spacing
            )
            
        case 2:
            return GridLayout(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2),
                count: 2,
                spacing: spacing
            )
            
        case 3, 4:
            return GridLayout(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2),
                count: 2,
                spacing: spacing
            )
            
        case 5, 6:
            return GridLayout(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2),
                count: 2,
                spacing: spacing
            )
            
        default:
            return GridLayout(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3),
                count: 3,
                spacing: spacing
            )
        }
    }
    
    func tileWidth(screenWidth: CGFloat, columns: Int) -> CGFloat {
        let totalPadding: CGFloat = 24
        let totalSpacing: CGFloat = CGFloat(columns - 1) * 6
        return (screenWidth - totalPadding - totalSpacing) / CGFloat(columns)
    }
    
    func tileHeight(total: Int, screenHeight: CGFloat) -> CGFloat {
        switch total {
        case 1:
            return screenHeight * 0.58
        case 2:
            return screenHeight * 0.34
        case 3, 4:
            return screenHeight * 0.27
        case 5, 6:
            return screenHeight * 0.23
        default:
            return screenHeight * 0.18
        }
    }
    
    func videoType(for participant: LiveCoHost) -> AgoraVideoView.VideoType? {
        if participant.isHost && isHostView {
            return .local
        }
        
        let uid = UInt(abs(participant.userId.hashValue))
        return .remote(uid: uid)
    }
}
