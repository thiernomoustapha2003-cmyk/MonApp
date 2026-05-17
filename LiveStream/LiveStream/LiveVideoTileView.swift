//
//  LiveVideoTileView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//

//
//  LiveVideoTileView.swift
//  MonApp
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AgoraRtcKit

struct LiveVideoTileView: View {
    
    let liveId: String
    let participant: LiveCoHost
    let videoType: AgoraVideoView.VideoType?
    let isHostView: Bool
    
    var onGift: ((LiveCoHost) -> Void)? = nil
    var onSpotlight: ((LiveCoHost) -> Void)? = nil
    
    @StateObject private var coHostService = LiveCoHostService.shared
    @State private var showActions = false
    @State private var showPrivateMessageAlert = false
    
    var body: some View {
        ZStack {
            
            videoContent
            
            LinearGradient(
                colors: [.clear, .black.opacity(0.15), .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            RoundedRectangle(cornerRadius: 18)
                .stroke(participant.isHost ? Color.yellow : Color.white.opacity(0.18),
                        lineWidth: participant.isHost ? 2.2 : 1)
            
            VStack {
                topBadge
                Spacer()
                bottomInfo
            }
            .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(Rectangle())
        .onTapGesture {
            showActions = true
        }
        .confirmationDialog(
            participant.displayName,
            isPresented: $showActions,
            titleVisibility: .visible
        ) {
            Button("🎁 Envoyer un cadeau") {
                onGift?(participant)
            }
            
            Button("💬 Message privé") {
                createPrivateMessageRequest()
            }
            
            if isHostView {
                Button("📌 Agrandir") {
                    onSpotlight?(participant)
                }
            }
            
            if isHostView && !participant.isHost {
                Button(participant.mutedByHost ? "🎙️ Réactiver micro" : "🔇 Couper micro") {
                    coHostService.hostMuteGuest(
                        liveId: liveId,
                        userId: participant.userId,
                        muted: !participant.mutedByHost
                    )
                }
                
                Button("⏱️ Mettre 5 minutes") {
                    coHostService.setSpeakingTimer(
                        liveId: liveId,
                        userId: participant.userId,
                        seconds: 300
                    )
                }
                
                Button("📤 Descendre du live", role: .destructive) {
                    coHostService.removeGuest(
                        liveId: liveId,
                        userId: participant.userId
                    )
                }
            }
        }
        .alert("Demande envoyée", isPresented: $showPrivateMessageAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Une demande de message privé a été enregistrée.")
        }
    }
}

extension LiveVideoTileView {
    
    var videoContent: some View {
        ZStack {
            if let videoType = videoType {
                AgoraVideoView(videoType: videoType, cornerRadius: 18)
                    .id("tile-video-\(participant.userId)-\(participant.isHost)")
                    .clipped()
            } else {
                avatarFallback
            }
        }
    }
    
    var avatarFallback: some View {
        ZStack {
            Color.black.opacity(0.92)
            
            VStack(spacing: 12) {
                if let url = URL(string: participant.avatar), !participant.avatar.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        avatarLetter
                    }
                    .frame(width: 74, height: 74)
                    .clipShape(Circle())
                } else {
                    avatarLetter
                }
                
                Text(participant.displayName)
                    .foregroundColor(.white.opacity(0.9))
                    .font(.caption.bold())
            }
        }
    }
    
    var avatarLetter: some View {
        Circle()
            .fill(Color.white.opacity(0.14))
            .frame(width: 74, height: 74)
            .overlay(
                Text(String(participant.displayName.prefix(1)).uppercased())
                    .foregroundColor(.white)
                    .font(.title.bold())
            )
    }
    
    var topBadge: some View {
        HStack {
            if participant.isHost {
                Label("HOST", systemImage: "crown.fill")
                    .font(.caption2.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.yellow)
                    .clipShape(Capsule())
            } else {
                Text(participant.canModerate ? "MOD" : "INVITÉ")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Image(systemName: participant.canSpeak ? "mic.fill" : "mic.slash.fill")
                .foregroundColor(participant.canSpeak ? .green : .red)
                .padding(8)
                .background(Color.black.opacity(0.55))
                .clipShape(Circle())
        }
    }
    
    var bottomInfo: some View {
        HStack(spacing: 7) {
            Image(systemName: participant.canSpeak ? "mic.fill" : "mic.slash.fill")
                .foregroundColor(participant.canSpeak ? .cyan : .red)
            
            Text(participant.displayName)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.48))
        .clipShape(Capsule())
    }
    
    func createPrivateMessageRequest() {
        guard let user = Auth.auth().currentUser else { return }
        
        Firestore.firestore()
            .collection("lives")
            .document(liveId)
            .collection("privateMessageRequests")
            .addDocument(data: [
                "fromUserId": user.uid,
                "fromName": user.displayName ?? "Spectateur",
                "toUserId": participant.userId,
                "toName": participant.displayName,
                "status": "pending",
                "createdAt": Timestamp()
            ])
        
        showPrivateMessageAlert = true
    }
}
