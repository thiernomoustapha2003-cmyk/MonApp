//
//  ChatViewOnceAudioBubble.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 19/06/2026.
//

import SwiftUI

struct ChatViewOnceAudioBubble: View {

    let audioUrl: String
    let duration: Double?
    let messageId: String
    let conversationId: String
    let listenedBy: [String]
    let isMine: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "1.circle")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary)

            Text("Message vocal")
                .font(.system(size: 13, weight: .medium))

            Text(formatTime(duration ?? 0))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isMine ? Color.green.opacity(0.28) : Color.white)
        .cornerRadius(18)
    }

    func formatTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%01d:%02d", m, s)
    }
}
