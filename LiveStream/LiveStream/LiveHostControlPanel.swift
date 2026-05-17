//
//  LiveHostControlPanel.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//

//
//  LiveHostControlPanel.swift
//  MonApp
//

import SwiftUI

struct LiveHostControlPanel: View {
    
    let liveId: String
    
    @Binding var spotlightUserId: String?
    @Binding var showJoinRequests: Bool
    @Binding var showModeration: Bool
    
    @StateObject private var coHostService = LiveCoHostService.shared
    
    var body: some View {
        VStack(spacing: 14) {
            
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 44, height: 5)
                .padding(.top, 8)
            
            Text("Contrôle du LIVE")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                
                hostAction(
                    icon: "person.crop.circle.badge.plus",
                    title: "Demandes",
                    color: .cyan
                ) {
                    showJoinRequests = true
                }
                
                hostAction(
                    icon: "mic.slash.fill",
                    title: "Mute tous",
                    color: .orange
                ) {
                    coHostService.hostMuteAll(liveId: liveId, muted: true)
                }
                
                hostAction(
                    icon: "mic.fill",
                    title: "Unmute",
                    color: .green
                ) {
                    coHostService.hostMuteAll(liveId: liveId, muted: false)
                }
                
                hostAction(
                    icon: "shield.lefthalf.filled",
                    title: "Modération",
                    color: .purple
                ) {
                    showModeration = true
                }
            }
            
            if !coHostService.activeGuests.isEmpty {
                guestsSection
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
    }
}

extension LiveHostControlPanel {
    
    var guestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text("Invités en direct")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.8))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(coHostService.activeGuests) { guest in
                        guestControlCard(guest)
                    }
                }
            }
        }
    }
    
    func guestControlCard(_ guest: LiveCoHost) -> some View {
        VStack(spacing: 8) {
            
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 54, height: 54)
                    .overlay(
                        Text(String(guest.displayName.prefix(1)).uppercased())
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    )
                
                if spotlightUserId == guest.userId {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                        .padding(5)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                }
            }
            
            Text(guest.displayName)
                .font(.caption2.bold())
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 76)
            
            HStack(spacing: 6) {
                
                Button {
                    spotlightUserId = spotlightUserId == guest.userId ? nil : guest.userId
                } label: {
                    miniIcon(
                        spotlightUserId == guest.userId ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                        color: .yellow
                    )
                }
                
                Button {
                    coHostService.hostMuteGuest(
                        liveId: liveId,
                        userId: guest.userId,
                        muted: !guest.mutedByHost
                    )
                } label: {
                    miniIcon(
                        guest.mutedByHost ? "mic.fill" : "mic.slash.fill",
                        color: guest.mutedByHost ? .green : .orange
                    )
                }
                
                Button {
                    coHostService.removeGuest(
                        liveId: liveId,
                        userId: guest.userId
                    )
                } label: {
                    miniIcon("xmark", color: .red)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.45))
        )
    }
    
    func hostAction(
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
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.9))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption2.bold())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    func miniIcon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(7)
            .background(color.opacity(0.9))
            .clipShape(Circle())
    }
}
