//
//  IncomingCallView.swift
//  MonApp
//
//  Écran d'appel entrant dans l'app.
//  IMPORTANT :
//  - CallKit gère l'écran natif iPhone / écran verrouillé.
//  - Cette vue gère l'appel entrant quand l'utilisateur est déjà dans Cutly.
//  - Ne branche pas Agora ici.
//  - Agora démarre dans CallScreenView via CallAgoraManager.
//

import SwiftUI

struct IncomingCallView: View {

    let callerName: String
    let callType: String
    let onAccept: () -> Void
    let onDecline: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var isProcessingAccept = false
    @State private var isProcessingDecline = false
    @State private var pulse = false

    private var isVideoCall: Bool {
        callType == "video"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.04, green: 0.04, blue: 0.07),
                    Color(red: 0.01, green: 0.01, blue: 0.02)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                callerAvatar

                VStack(spacing: 8) {
                    Text(callerName)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(isVideoCall ? "Appel vidéo entrant" : "Appel audio entrant")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.68))

                    Text("Cutly")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.top, 2)
                }

                Spacer()

                HStack(spacing: 78) {
                    actionButton(
                        icon: "phone.down.fill",
                        title: "Refuser",
                        color: .red,
                        isLoading: isProcessingDecline
                    ) {
                        guard !isProcessingAccept && !isProcessingDecline else { return }

                        isProcessingDecline = true

                        // Refus immédiat, comme WhatsApp.
                        onDecline()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            dismiss()
                        }
                    }

                    actionButton(
                        icon: isVideoCall ? "video.fill" : "phone.fill",
                        title: "Accepter",
                        color: .green,
                        isLoading: isProcessingAccept
                    ) {
                        guard !isProcessingAccept && !isProcessingDecline else { return }

                        isProcessingAccept = true

                        // Acceptation immédiate.
                        // Firestore passe à accepted dans MessageDetailView / CallKitManager.
                        // CallScreenView ouvre ensuite Agora via CallAgoraManager.
                        onAccept()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            dismiss()
                        }
                    }
                }
                .padding(.bottom, 58)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.1)
                .repeatForever(autoreverses: true)
            ) {
                pulse = true
            }
        }
    }

    private var callerAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(pulse ? 0.14 : 0.06))
                .frame(width: 196, height: 196)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 170, height: 170)

            Image(systemName: isVideoCall ? "video.circle.fill" : "person.crop.circle.fill")
                .font(.system(size: isVideoCall ? 118 : 116))
                .foregroundColor(.white.opacity(0.95))
        }
    }

    private func actionButton(
        icon: String,
        title: String,
        color: Color,
        isLoading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 12) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 78, height: 78)
                        .shadow(color: color.opacity(0.35), radius: 18, x: 0, y: 8)

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(isProcessingAccept || isProcessingDecline)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}
