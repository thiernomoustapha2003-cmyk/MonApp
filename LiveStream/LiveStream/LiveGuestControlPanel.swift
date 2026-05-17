//
//  LiveGuestControlPanel.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//

//
//  LiveGuestControlPanel.swift
//  MonApp
//

import SwiftUI
import FirebaseAuth

struct LiveGuestControlPanel: View {
    
    let liveId: String
    let guest: LiveCoHost
    
    @StateObject private var coHostService = LiveCoHostService.shared
    
    @State private var showLeaveAlert = false
    @State private var showMutedInfo = false
    
    var body: some View {
        VStack(spacing: 14) {
            
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 44, height: 5)
                .padding(.top, 8)
            
            Text("Mes contrôles")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            if guest.mutedByHost {
                mutedBanner
            }
            
            LiveSpeakingTimerView(
                seconds: guest.timerSeconds,
                isActive: guest.canSpeak
            )
            
            HStack(spacing: 14) {
                
                guestAction(
                    icon: guest.micEnabled ? "mic.fill" : "mic.slash.fill",
                    title: guest.micEnabled ? "Micro ON" : "Micro OFF",
                    color: guest.micEnabled ? .green : .red
                ) {
                    if guest.mutedByHost {
                        showMutedInfo = true
                    } else {
                        coHostService.toggleMyMic(liveId: liveId)
                    }
                }
                
                guestAction(
                    icon: guest.cameraEnabled ? "video.fill" : "video.slash.fill",
                    title: guest.cameraEnabled ? "Caméra ON" : "Caméra OFF",
                    color: guest.cameraEnabled ? .purple : .gray
                ) {
                    coHostService.toggleMyCamera(liveId: liveId)
                }
                
                guestAction(
                    icon: "hand.raised.fill",
                    title: "Parole",
                    color: .blue
                ) {
                    requestSpeakingTurn()
                }
                
                guestAction(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Quitter",
                    color: .red
                ) {
                    showLeaveAlert = true
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .alert("Micro bloqué", isPresented: $showMutedInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Le créateur a coupé ton micro. Tu peux parler seulement quand il le réactive.")
        }
        .alert("Quitter le live ?", isPresented: $showLeaveAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Quitter", role: .destructive) {
                leaveLive()
            }
        } message: {
            Text("Tu vas descendre du live, mais tu pourras continuer à regarder comme spectateur.")
        }
    }
}

extension LiveGuestControlPanel {
    
    var mutedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "mic.slash.fill")
                .foregroundColor(.red)
            
            Text("Ton micro est coupé par le créateur")
                .font(.caption.bold())
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.25))
        )
    }
    
    func guestAction(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(color.opacity(0.9))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    func requestSpeakingTurn() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        LiveChatService().sendSystemMessage(
            liveId: liveId,
            text: "🙋 \(guest.displayName) demande la parole"
        )
        
        print("🙋 Demande de parole envoyée par \(uid)")
    }
    
    func leaveLive() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        LiveCoHostService.shared.removeGuest(
            liveId: liveId,
            userId: uid
        )

        LiveAgoraManager.shared.backToViewer()

        LiveChatService().sendSystemMessage(
            liveId: liveId,
            text: "👋 \(guest.displayName) est descendu du live"
        )
    }
}
