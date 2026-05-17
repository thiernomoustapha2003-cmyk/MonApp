//
//  LiveSpeakingTimerView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//

//
//  LiveSpeakingTimerView.swift
//  MonApp
//

import SwiftUI

struct LiveSpeakingTimerView: View {
    
    let seconds: Int
    let isActive: Bool
    
    var progress: Double {
        guard seconds > 0 else { return 0 }
        return min(Double(seconds) / 300.0, 1.0)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            
            Image(systemName: "timer")
                .foregroundColor(timerColor())
            
            Text(formatTime(seconds))
                .font(.caption.bold())
                .foregroundColor(.white)
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 55)
                .tint(timerColor())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.55))
                .overlay(
                    Capsule()
                        .stroke(timerColor().opacity(0.7), lineWidth: 1)
                )
        )
        .opacity(isActive ? 1 : 0.55)
    }
    
    func formatTime(_ value: Int) -> String {
        let minutes = value / 60
        let seconds = value % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func timerColor() -> Color {
        if seconds <= 30 {
            return .red
        } else if seconds <= 90 {
            return .orange
        } else {
            return .green
        }
    }
}
