//
//  LiveCoHostTileView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//

//
//
//  LiveCoHostTileView.swift
//  MonApp
//

import SwiftUI
import FirebaseAuth
import AVFoundation

struct LiveCoHostTileView: View {
    
    let liveId: String
    let participant: LiveCoHost
    let isHostView: Bool
    let hostSession: AVCaptureSession?
    let selectedFilter: String
    let currentPosition: AVCaptureDevice.Position
    
    @StateObject private var coHostService = LiveCoHostService.shared
    
    @State private var showMenu = false
    @State private var isPressed = false
    
    var isMe: Bool {
        Auth.auth().currentUser?.uid == participant.userId
    }
    
    // MARK: - BODY
    
    var body: some View {
        
        ZStack {
            
            // MARK: CAMERA / BACKGROUND
            
            Group {
                
                if participant.cameraEnabled {
                    
                    // 🔥 caméra plein écran TikTok
                    cameraPlaceholder
                    
                } else {
                    
                    // 🔥 avatar seulement si caméra OFF
                    avatarBackground
                }
            }
            
            // noir transparent TikTok
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // MARK: BORDER
            
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    participant.isHost
                    ? Color.yellow.opacity(0.95)
                    : Color.white.opacity(0.08),
                    lineWidth: participant.isHost ? 2.4 : 1
                )
            
            // MARK: UI
            
            VStack {
                
                // TOP
                topBar
                
                Spacer()
                
                // BOTTOM
                bottomBar
            }
            .padding(10)
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .scaleEffect(isPressed ? 0.96 : 1)
        .animation(.spring(), value: isPressed)
        .contentShape(Rectangle())
        .onLongPressGesture {
            showMenu = true
        }
        .contextMenu {
            
            Button("🎁 Envoyer cadeau") {
                print("Gift \(participant.displayName)")
            }
            
            Button("💬 Message privé") {
                print("DM \(participant.displayName)")
            }
            
            Button("📌 Agrandir") {
                print("Spotlight \(participant.displayName)")
            }
            
            if isHostView && !participant.isHost {
                
                Button("🔇 Couper micro") {
                    coHostService.hostMuteGuest(
                        liveId: liveId,
                        userId: participant.userId,
                        muted: !participant.mutedByHost
                    )
                }
                
                Button("📤 Retirer du live", role: .destructive) {
                    coHostService.removeGuest(
                        liveId: liveId,
                        userId: participant.userId
                    )
                }
            }
        }
    }
}

// MARK: - TOP BAR

extension LiveCoHostTileView {
    
    var topBar: some View {
        
        HStack(alignment: .top) {
            
            // HOST BADGE
            
            if participant.isHost {
                
                HStack(spacing: 5) {
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 9))
                    
                    Text("HOST")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.yellow)
                .clipShape(Capsule())
            }
            
            else {
                
                Text(roleText())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            // MIC
            
            Image(systemName:
                    participant.canSpeak
                  ? "mic.fill"
                  : "mic.slash.fill"
            )
            .font(.system(size: 11))
            .foregroundColor(
                participant.canSpeak
                ? .green
                : .red
            )
            .padding(8)
            .background(Color.black.opacity(0.5))
            .clipShape(Circle())
        }
    }
}

// MARK: - BOTTOM BAR

extension LiveCoHostTileView {
    
    var bottomBar: some View {
        
        VStack(alignment: .leading, spacing: 5) {
            
            // NOM
            
            Text(participant.displayName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // STATUS
            
            HStack(spacing: 5) {
                
                Circle()
                    .fill(
                        participant.canSpeak
                        ? Color.green
                        : Color.red
                    )
                    .frame(width: 7, height: 7)
                
                Text(
                    participant.canSpeak
                    ? "Peut parler"
                    : "Micro coupé"
                )
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.82))
            }
            
            // HOST CONTROLS
            
            if isHostView && !participant.isHost {
                
                HStack(spacing: 10) {
                    
                    actionButton(
                        icon: participant.mutedByHost
                        ? "mic.fill"
                        : "mic.slash.fill",
                        color: participant.mutedByHost
                        ? .green
                        : .orange
                    ) {
                        
                        coHostService.hostMuteGuest(
                            liveId: liveId,
                            userId: participant.userId,
                            muted: !participant.mutedByHost
                        )
                    }
                    
                    actionButton(
                        icon: "pin.fill",
                        color: .yellow
                    ) {
                        print("Spotlight")
                    }
                    
                    actionButton(
                        icon: "person.fill.xmark",
                        color: .red
                    ) {
                        
                        coHostService.removeGuest(
                            liveId: liveId,
                            userId: participant.userId
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - CAMERA

extension LiveCoHostTileView {
    
    var cameraPlaceholder: some View {
        
        ZStack {
            
            if participant.isHost, let hostSession = hostSession {
                
                CameraPreview(session: hostSession)
                    .ignoresSafeArea()
                
                FilterOverlayView(
                    session: hostSession,
                    filterName: selectedFilter,
                    currentPosition: currentPosition
                )
                .ignoresSafeArea()
                
            } else {
                
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.9),
                        Color.black.opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(spacing: 10) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.white)
                    
                    Text("Caméra active")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
    }
    
    var avatarBackground: some View {
        
        ZStack {
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color.black.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                
                avatarView
                
                Text(participant.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

// MARK: - AVATAR

extension LiveCoHostTileView {
    
    var avatarView: some View {
        
        ZStack {
            
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 74, height: 74)
            
            if let url = URL(string: participant.avatar),
               !participant.avatar.isEmpty {
                
                AsyncImage(url: url) { image in
                    
                    image
                        .resizable()
                        .scaledToFill()
                    
                } placeholder: {
                    
                    avatarFallback
                }
                .frame(width: 74, height: 74)
                .clipShape(Circle())
                
            } else {
                
                avatarFallback
            }
        }
    }
    
    var avatarFallback: some View {
        
        Text(
            String(
                participant.displayName.prefix(1)
            ).uppercased()
        )
        .font(.system(size: 28, weight: .bold))
        .foregroundColor(.white)
    }
}

// MARK: - HELPERS

extension LiveCoHostTileView {
    
    func roleText() -> String {
        
        switch participant.role {
            
        case .host:
            return "HOST"
            
        case .moderator:
            return "MOD"
            
        case .guest:
            return "INVITÉ"
        }
    }
    
    func actionButton(
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        
        Button(action: action) {
            
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.9))
                .clipShape(Circle())
        }
    }
}
