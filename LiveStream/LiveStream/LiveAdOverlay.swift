//
//  LiveAdOverlay.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 16/05/2026.
//

import SwiftUI

struct LiveAdOverlay: View {
    
    var onSkip: () -> Void
    
    @State private var seconds = 3
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.97)
                .ignoresSafeArea()
            
            VStack(spacing: 22) {
                
                HStack {
                    Text("CUTLY LIVE")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("AD")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
                
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.red,
                                Color.purple,
                                Color.black
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 300)
                    .overlay {
                        VStack(spacing: 14) {
                            Text("✂️")
                                .font(.system(size: 70))
                                .scaleEffect(pulse ? 1.15 : 1.0)
                            
                            Text("Découvre les meilleurs coiffeurs en direct")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Lives, cadeaux, tendances coiffure et créateurs.")
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                
                Button {
                    if seconds == 0 {
                        onSkip()
                    }
                } label: {
                    Text(seconds > 0 ? "Ignorer dans \(seconds)s" : "Ignorer la publicité")
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(seconds > 0 ? Color.gray : Color.red)
                        .cornerRadius(26)
                        .padding(.horizontal)
                }
                .disabled(seconds > 0)
            }
        }
        .onAppear {
            pulse = true
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if seconds > 0 {
                    seconds -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}
