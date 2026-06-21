//
//  CallScreenView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 21/06/2026.
//

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

enum CallMode {
    case audio
    case video
}

struct CallScreenView: View {
    
    let name: String
    let avatarURL: String?
    let mode: CallMode
    let callId: String?
    let conversationId: String
    let onEndCall: (Int) -> Void
    
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isMuted = false
    @State private var speakerOn = true
    @State private var cameraOn = true
    @State private var localVideoIsBig = false
    @State private var isMinimized = false
    @State private var showAddPeople = false
    @State private var showCallChat = false
    @State private var showMoreMenu = false
    @State private var duration = 0
    @State private var callAcceptedAt: Date? = nil
    @State private var isCallAccepted = false
    @StateObject private var agora = LiveAgoraManager.shared
    @State private var callListener: ListenerRegistration?
    
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if mode == .video {
                    videoCenter
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                } else {
                    audioCenter
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                VStack {
                    topControls
                        .padding(.top, geo.safeAreaInsets.top + 8)
                        .padding(.horizontal, 16)

                    Spacer()

                    bottomControls
                        .padding(.horizontal, 8)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 10)
                }
            }
        }
        .onAppear {
            listenCallStatus()
        }
        .onReceive(timer) { _ in
            guard isCallAccepted, let acceptedAt = callAcceptedAt else { return }
            duration = Int(Date().timeIntervalSince(acceptedAt))
        }
        .sheet(isPresented: $showAddPeople) {
            CallAddPeopleView()
        }
        .sheet(isPresented: $showCallChat) {
            CallChatView()
        }
        .confirmationDialog("Options d’appel", isPresented: $showMoreMenu) {
            Button("🎥 Enregistrement d’écran") { print("screen record") }
            Button("🔄 Changer caméra") { agora.switchCamera() }
            Button("📤 Partager l’appel") { print("share call") }
            Button("⏸ Mettre en attente") {
                isMuted = true
                cameraOn = false
                agora.muteLocalAudio(true)
                agora.enableCamera(false)
            }
            Button("⚙️ Paramètres d’appel") { print("settings") }
            Button("⚠️ Signaler un problème") { print("report") }
            Button("Annuler", role: .cancel) { }
        }
    }
    
    var callBackground: some View {
        Group {
            if mode == .video && cameraOn {
                Color.black
            } else {
                Color.black
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 180))
                            .foregroundColor(.white.opacity(0.04))
                    )
            }
        }
    }
    var topControls: some View {
        ZStack {
            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(isCallAccepted ? formatDuration(duration) : "Appel en cours...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(.horizontal, 85)

            HStack {
                callCircleButton("arrow.down.right.and.arrow.up.left") {
                    isMinimized = true
                    dismiss()
                }

                Spacer()

                VStack(spacing: 14) {
                    callCircleButton("person.badge.plus") {
                        showAddPeople = true
                    }

                    callCircleButton("message.fill") {
                        showCallChat = true
                    }

                    if mode == .video {
                        callCircleButton("camera.rotate.fill") {
                            agora.switchCamera()
                        }
                    }
                }
            }
        }
   }
    var audioCenter: some View {
        AsyncImage(url: URL(string: avatarURL ?? "")) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(width: 210, height: 210)
        .clipShape(Circle())
    }
    
    
    var videoCenter: some View {
        ZStack(alignment: .bottomTrailing) {

            // AVANT ACCEPTATION : moi en grand
            if !isCallAccepted {
                if cameraOn {
                    AgoraVideoRenderView(uid: 0, isLocal: true)
                        .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                }
            }

            // APRÈS ACCEPTATION
            else {
                if localVideoIsBig {
                    if cameraOn {
                        AgoraVideoRenderView(uid: 0, isLocal: true)
                            .ignoresSafeArea()
                    } else {
                        Color.black.ignoresSafeArea()
                    }
                } else {
                    if let remoteUid = agora.remoteUsers.first {
                        AgoraVideoRenderView(uid: remoteUid, isLocal: false)
                            .ignoresSafeArea()
                    } else {
                        Color.black
                            .overlay(
                                Text("Connexion vidéo...")
                                    .foregroundColor(.white.opacity(0.7))
                            )
                            .ignoresSafeArea()
                    }
                }

                Button {
                    withAnimation(.spring()) {
                        localVideoIsBig.toggle()
                    }
                } label: {
                    ZStack {
                        if localVideoIsBig {
                            if let remoteUid = agora.remoteUsers.first {
                                AgoraVideoRenderView(uid: remoteUid, isLocal: false)
                            } else {
                                Color.black
                            }
                        } else {
                            if cameraOn {
                                AgoraVideoRenderView(uid: 0, isLocal: true)
                            } else {
                                Color.black
                                    .overlay(
                                        Image(systemName: "video.slash.fill")
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    }
                    .frame(width: 125, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                }
                .padding(.trailing, 18)
                .padding(.bottom, 115)
            }
        }
    }
    var bottomControls: some View {
        HStack(spacing: 14) {
            callCircleButton("ellipsis") {
                showMoreMenu = true
            }

            if mode == .video {
                callCircleButton(cameraOn ? "video.fill" : "video.slash.fill") {
                    cameraOn.toggle()
                    agora.enableCamera(cameraOn)
                }
            }

            callCircleButton(speakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill") {
                speakerOn.toggle()
                agora.enableSpeaker(speakerOn)
            }

            callCircleButton(isMuted ? "mic.slash.fill" : "mic.fill") {
                isMuted.toggle()
                agora.muteLocalAudio(isMuted)
            }

            Button {
                agora.leaveCall()

                if let callId = callId {
                    CallService.shared.endCall(
                        callId: callId,
                        conversationId: conversationId,
                        type: mode == .video ? "video" : "audio",
                        duration: duration
                    )
                }

                callListener?.remove()
                dismiss()
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 62, height: 62)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity)
    }
    
    func callCircleButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(Color.black.opacity(0.45))
                .clipShape(Circle())
        }
    }
    
    func formatDuration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    func listenCallStatus() {
        guard let callId = callId else { return }

        callListener?.remove()

        callListener = Firestore.firestore()
            .collection("calls")
            .document(callId)
            .addSnapshotListener { snapshot, _ in

                guard let data = snapshot?.data() else { return }

                let status = data["status"] as? String ?? ""

                if status == "accepted" {
                    let acceptedDate = (data["acceptedAt"] as? Timestamp)?.dateValue() ?? Date()

                    if isCallAccepted == false {
                        callAcceptedAt = acceptedDate
                        isCallAccepted = true

                        let uid = UInt(abs((Auth.auth().currentUser?.uid ?? "").hashValue % 999999))

                        agora.joinCall(
                            channelName: callId,
                            uid: uid,
                            isVideo: mode == .video
                        )
                    }
                }
                if status == "declined" || status == "ended" || status == "missed" {
                    agora.leaveCall()
                    callListener?.remove()
                    dismiss()
                }
            }
    }
    
    
}

struct CallAddPeopleView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 50))
                Text("Ajouter une personne")
                    .font(.title2.bold())
                Text("Ici on branchera tes contacts et utilisateurs Cutly.")
                    .foregroundColor(.gray)
            }
            .padding()
            .navigationTitle("Ajouter")
        }
    }
}

struct CallChatView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "message.fill")
                    .font(.system(size: 50))
                Text("Messages de l’appel")
                    .font(.title2.bold())
                Text("Ici on branchera les messages pendant l’appel.")
                    .foregroundColor(.gray)
            }
            .padding()
            .navigationTitle("Discussion")
        }
    }
   
    
}
