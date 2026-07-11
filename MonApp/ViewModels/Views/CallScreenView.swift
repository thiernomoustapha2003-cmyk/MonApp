//
//  CallScreenView.swift
//  MonApp
//
//  Écran d'appel privé audio/vidéo.
//  IMPORTANT : ce fichier utilise CallAgoraManager.
//  Ne pas utiliser LiveAgoraManager ici.
//  LiveAgoraManager = Lives TikTok.
//  CallAgoraManager = Appels privés WhatsApp-like.
//

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth
import ReplayKit
import UIKit

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
    
    @StateObject private var agora = CallAgoraManager.shared
    
    
    
    private let startRecordingURL = URL(string: "https://us-central1-afroconnect-7588d.cloudfunctions.net/startCallRecording")!
    private let stopRecordingURL = URL(string: "https://stopcallrecording-jzvik52b6a-uc.a.run.app")!
    
    @State private var isMuted = false
    @State private var speakerOn = true
    @State private var cameraOn = true
    @State private var localVideoIsBig = false
    
    @State private var screenShareListener: ListenerRegistration?
    @State private var remoteUserIsSharingScreen = false
    
    
    @State private var activeRecordingId: String?
    @State private var recordingStartedAt = Date()
    
    @State private var showRecordingsHistory = false
    
    @State private var showAddPeople = false
    @State private var showCallChat = false
    @State private var showCallNotes = false
    @State private var showRecordingConsentAlert = false
    @State private var isRecordingCall = false
    @State private var recordingRequested = false
    
    @State private var screenShareCountdown: Int? = nil
    @State private var isPreparingScreenShare = false
    
    
    @State private var incomingRecordingRequest = false
    @State private var recordingRequestFromUserId: String?
    @State private var recordingConsentListener: ListenerRegistration?
    
    @State private var showScreenShareConsentAlert = false
    @State private var isSharingScreen = false
    @State private var showCallSettings = false
    @State private var showReportSheet = false
    @State private var showMoreMenu = false
    
    
    
    
    
    @State private var duration = 0
    @State private var callAcceptedAt: Date?
    @State private var isCallAccepted = false
    @State private var hasJoinedAgora = false
    @State private var hasEndedLocally = false
    
    @State private var isOnHold = false
    @State private var cameraWasOnBeforeHold = true
    
    
    @State private var callListener: ListenerRegistration?
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
                
                if isRecordingCall {
                    VStack {
                        HStack {
                            RecordingBadgeView()
                            Spacer()
                        }
                        .padding(.top, geo.safeAreaInsets.top + 70)
                        .padding(.leading, 20)
                        
                        Spacer()
                    }
                    .transition(.opacity)
                }
                if let countdown = screenShareCountdown {
                    VStack {
                        Spacer()

                        Text("\(countdown)")
                            .font(.system(size: 90, weight: .bold))
                            .foregroundColor(.white)
                            .padding(40)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Circle())

                        Text("Partage d’écran en préparation")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 12)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.35))
                    .transition(.opacity)
                }
                if remoteUserIsSharingScreen {
                    VStack {
                        Spacer()

                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.on.rectangle")
                            Text("L’autre personne partage son écran")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Capsule())
                        .padding(.bottom, 130)
                    }
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
            listenRecordingConsent()
            listenScreenShareState()
        }
        .onDisappear {
            if isRecordingCall {
                stopCallRecording()
            }

            if isSharingScreen {
                stopScreenShare()
            }
            callListener?.remove()
            recordingConsentListener?.remove()
            screenShareListener?.remove()
            
        }
        .onReceive(timer) { _ in
            guard isCallAccepted, let acceptedAt = callAcceptedAt else { return }
            duration = max(0, Int(Date().timeIntervalSince(acceptedAt)))
        }
        .sheet(isPresented: $showAddPeople) {
            CallAddPeopleView()
        }
        .sheet(isPresented: $showCallChat) {
            CallChatView()
        }
        .sheet(isPresented: $showCallNotes) {
            CallNotesView(
                conversationId: conversationId
            )
        }
        .sheet(isPresented: $showRecordingsHistory) {
            CallRecordingsHistoryView()
        }
        .sheet(isPresented: $showCallSettings) {
            CallSettingsView()
        }
        .sheet(isPresented: $showReportSheet) {
            CallReportView()
        }
        .alert("Enregistrer l’appel ?", isPresented: $showRecordingConsentAlert) {
            Button("Annuler", role: .cancel) { }
            
            Button(isRecordingCall ? "Arrêter" : "Demander l’accord") {
                if isRecordingCall {
                    stopCallRecording()
                } else {
                    requestCallRecordingConsent()
                }
                
                // Étape suivante :
                // ici on enverra une demande Firestore à l’autre personne
                // puis l’enregistrement commencera seulement si elle accepte.
                
            }
        } message: {
            Text("Pour respecter la confidentialité, l’enregistrement doit être accepté par les deux personnes avant de commencer.")
        }
        
        .alert("Partager l’écran ?", isPresented: $showScreenShareConsentAlert) {
            Button("Annuler", role: .cancel) { }

            Button("Commencer") {
                startScreenShareCountdown()
            }
        } message: {
            Text("Le partage d’écran permettra à l’autre personne de voir ce qui est affiché sur ton écran pendant l’appel.")
        }
        .alert("Demande d’enregistrement", isPresented: $incomingRecordingRequest) {
            Button("Refuser", role: .cancel) {
                Firestore.firestore()
                    .collection("calls")
                    .document(callId ?? "")
                    .setData([
                        "recording": [
                            "requested": false,
                            "status": "declined",
                            "declinedAt": FieldValue.serverTimestamp()
                        ]
                    ], merge: true)
            }
            
            Button("Accepter") {
                Firestore.firestore()
                    .collection("calls")
                    .document(callId ?? "")
                    .setData([
                        "recording": [
                            "requested": false,
                            "status": "accepted",
                            "acceptedAt": FieldValue.serverTimestamp()
                        ]
                    ], merge: true)
            }
        } message: {
            Text("L’autre personne souhaite enregistrer cet appel. L’enregistrement ne commencera que si tu acceptes.")
        }
        
        
        
        .confirmationDialog("Options d’appel", isPresented: $showMoreMenu) {
            
            
            
            Button {
                if isSharingScreen {
                    stopScreenShare()
                } else {
                    showScreenShareConsentAlert = true
                }
            } label: {
                Label(
                    isSharingScreen ? "Arrêter le partage" : "Partager l’écran",
                    systemImage: isSharingScreen ? "rectangle.slash" : "rectangle.on.rectangle"
                )
            }
            .disabled(isPreparingScreenShare)
            
            Button {
                showRecordingConsentAlert = true
            } label: {
                Label(
                    isRecordingCall ? "Arrêter l’enregistrement" : "Enregistrer l’appel",
                    systemImage: isRecordingCall ? "stop.circle.fill" : "record.circle"
                )
            }
            Button {
                showRecordingsHistory = true
            } label: {
                Label("Enregistrements", systemImage: "record.circle.fill")
            }
            
            Button("🔄 Changer caméra") {
                agora.switchCamera()
            }
            
            Button(isOnHold ? "▶️ Reprendre l’appel" : "⏸ Mettre en attente") {
                toggleHold()
            }
            
            Button("📝 Notes rapides") {
                showCallNotes = true
            }
            
            Button("🌍 Traduction en direct") {
                print("🌍 TODO : sous-titres/traduction live")
            }
            
            Button("⚙️ Paramètres d’appel") {
                showCallSettings = true
            }
            
            Button("⚠️ Signaler un problème") {
                showReportSheet = true
            }
            .tint(.red)
            
            Button("Annuler", role: .cancel) { }
        }
        
    }
    private var topControls: some View {
        ZStack {
            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(isOnHold ? "En attente" : (isCallAccepted ? formatDuration(duration) : "Connexion..."))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(.horizontal, 85)
            
            HStack {
                callCircleButton("arrow.down.right.and.arrow.up.left") {
                    print("⚠️ Mini-player pas encore branché")
                
                    // TODO : plus tard, brancher mini-player d'appel.
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
    
    private var audioCenter: some View {
        VStack(spacing: 26) {
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
            
            if !isCallAccepted {
                Text("Appel en attente...")
                    .foregroundColor(.white.opacity(0.65))
                    .font(.system(size: 16, weight: .medium))
            }
        }
    }
    
    private var videoCenter: some View {
        ZStack(alignment: .bottomTrailing) {
            
            if !isCallAccepted {
                if cameraOn {
                    CallVideoRenderView(uid: 0, isLocal: true)
                        .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                }
            } else {
                if localVideoIsBig {
                    if cameraOn {
                        CallVideoRenderView(uid: 0, isLocal: true)
                            .ignoresSafeArea()
                    } else {
                        Color.black.ignoresSafeArea()
                    }
                } else {
                    if let remoteUid = agora.remoteUsers.first {
                        CallVideoRenderView(uid: remoteUid, isLocal: false)
                            .ignoresSafeArea()
                    } else {
                        Color.black
                            .overlay(
                                VStack(spacing: 10) {
                                    ProgressView()
                                    Text("Connexion vidéo...")
                                        .foregroundColor(.white.opacity(0.7))
                                }
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
                                CallVideoRenderView(uid: remoteUid, isLocal: false)
                            } else {
                                Color.black
                            }
                        } else {
                            if cameraOn {
                                CallVideoRenderView(uid: 0, isLocal: true)
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
    
    private var bottomControls: some View {
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
                endCallSafely()
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
    
    private func callCircleButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(Color.black.opacity(0.45))
                .clipShape(Circle())
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    
    private func listenCallStatus() {
        guard let callId = callId else {
            print("❌ CallScreenView ouvert sans callId")
            return
        }
        
        callListener?.remove()
        
        callListener = Firestore.firestore()
            .collection("calls")
            .document(callId)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("❌ listenCallStatus error:", error.localizedDescription)
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("❌ Call document introuvable")
                    return
                }
                
                let status = data["status"] as? String ?? ""
                
                if status == "accepted" || status == "ongoing" {
                    handleAcceptedCall(data: data, callId: callId)
                }
                
                if status == "declined" || status == "ended" || status == "missed" {
                    handleRemoteEnd(status: status)
                }
            }
    }
    
    private func handleAcceptedCall(data: [String: Any], callId: String) {
        let startDate =
        (data["acceptedAt"] as? Timestamp)?.dateValue()
        ?? (data["startedAt"] as? Timestamp)?.dateValue()
        ?? Date()
        
        if !isCallAccepted {
            callAcceptedAt = startDate
            isCallAccepted = true
            duration = max(0, Int(Date().timeIntervalSince(startDate)))
        }
        
        guard !hasJoinedAgora else { return }
        
        hasJoinedAgora = true
        
        let uid = stableAgoraUid(from: Auth.auth().currentUser?.uid ?? UUID().uuidString)
        
        print("📞 Rejoindre Agora appel privé:", callId, "uid:", uid)
        
        agora.joinCall(
            channelName: callId,
            uid: uid,
            isVideo: mode == .video
        )
    }
    
    private func handleRemoteEnd(status: String) {
        guard !hasEndedLocally else { return }
        
        print("📴 Appel terminé côté distant:", status)
        
        hasEndedLocally = true
        agora.leaveCall()
        callListener?.remove()
        dismiss()
    }
    
    private func endCallLocally() {
        guard !hasEndedLocally else { return }
        
        hasEndedLocally = true
        
        agora.leaveCall()
        
        if let callId = callId {
            CallService.shared.endCall(
                callId: callId,
                conversationId: conversationId,
                type: mode == .video ? "video" : "audio",
                duration: duration
            )
        } else {
            onEndCall(duration)
        }
        
        callListener?.remove()
        dismiss()
    }
    
    private func toggleHold() {
        if isOnHold {
            isOnHold = false
            
            isMuted = false
            agora.muteLocalAudio(false)
            
            if mode == .video && cameraWasOnBeforeHold {
                cameraOn = true
                agora.enableCamera(true)
            }
            
            print("▶️ Appel repris")
            
        } else {
            isOnHold = true
            
            cameraWasOnBeforeHold = cameraOn
            
            isMuted = true
            agora.muteLocalAudio(true)
            
            if mode == .video {
                cameraOn = false
                agora.enableCamera(false)
            }
            
            print("⏸ Appel mis en attente")
        }
    }
    
    
    private func stableAgoraUid(from text: String) -> UInt {
        var hash: UInt32 = 2166136261
        
        for byte in text.utf8 {
            hash = (hash ^ UInt32(byte)) &* 16777619
        }
        
        let value = hash % 900_000 + 10_000
        return UInt(value)
    }
    private func requestCallRecordingConsent() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard let callId = callId, !callId.isEmpty else { return }
        let db = Firestore.firestore()
        
        db.collection("calls")
            .document(callId)
            .setData([
                "recording": [
                    "requested": true,
                    "requestedBy": currentUserId,
                    "status": "pending",
                    "requestedAt": FieldValue.serverTimestamp()
                ]
            ], merge: true)
        
        recordingRequested = true
    }
    private func listenRecordingConsent() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard let callId = callId, !callId.isEmpty else { return }
        
        recordingConsentListener = Firestore.firestore()
            .collection("calls")
            .document(callId)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data(),
                      let recording = data["recording"] as? [String: Any] else {
                    return
                }
                
                let requested = recording["requested"] as? Bool ?? false
                let requestedBy = recording["requestedBy"] as? String
                let status = recording["status"] as? String ?? "none"
                
                if requested == true,
                   status == "pending",
                   requestedBy != currentUserId {
                    recordingRequestFromUserId = requestedBy
                    incomingRecordingRequest = true
                }
                
                if status == "accepted" {
                    let recordingId = recording["recordingId"] as? String

                    if let recordingId = recordingId, !recordingId.isEmpty {
                        activeRecordingId = recordingId
                    }

                    if requestedBy == currentUserId && activeRecordingId == nil {
                        startCallRecordingMetadata()
                    }

                    isRecordingCall = true
                    recordingRequested = false
                }
                
                if status == "stopped" || status == "declined" {
                    isRecordingCall = false
                    recordingRequested = false
                }
            }
    }
    private func stopCallRecording() {
        guard let callId = callId, !callId.isEmpty else { return }

        let duration = Int(Date().timeIntervalSince(recordingStartedAt))

        if let activeRecordingId = activeRecordingId {
            stopCloudRecording(recordingId: activeRecordingId)
            Firestore.firestore()
                .collection("callRecordings")
                .document(activeRecordingId)
                .setData([
                    "status": "stopped",
                    "durationSeconds": duration,
                    "stoppedAt": FieldValue.serverTimestamp()
                ], merge: true)
        }

        Firestore.firestore()
            .collection("calls")
            .document(callId)
            .setData([
                "recording": [
                    "requested": false,
                    "status": "stopped",
                    "stoppedAt": FieldValue.serverTimestamp()
                ]
            ], merge: true)

        isRecordingCall = false
        recordingRequested = false
        activeRecordingId = nil
    }
    private func startScreenShareCountdown() {
        guard !isPreparingScreenShare else { return }

        isPreparingScreenShare = true
        screenShareCountdown = 3

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            screenShareCountdown = 2
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            screenShareCountdown = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            screenShareCountdown = nil
            isPreparingScreenShare = false
            startScreenShare()

            // Étape suivante :
            // ici on branchera ReplayKit + Agora.
        }
    }

    private func stopScreenShare() {
        isSharingScreen = false
        CallAgoraManager.shared.stopScreenShare()

        // Étape suivante :
        // ici on arrêtera ReplayKit + Agora screen share.
    }
    private func startScreenShare() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard let callId = callId, !callId.isEmpty else { return }

        isSharingScreen = true
        CallAgoraManager.shared.startScreenShare()

        Firestore.firestore()
            .collection("calls")
            .document(callId)
            .setData([
                "screenShare": [
                    "isActive": true,
                    "sharedBy": currentUserId,
                    "startedAt": FieldValue.serverTimestamp()
                ]
            ], merge: true)
    }

    private func listenScreenShareState() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard let callId = callId, !callId.isEmpty else { return }

        screenShareListener = Firestore.firestore()
            .collection("calls")
            .document(callId)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data(),
                      let screenShare = data["screenShare"] as? [String: Any] else {
                    return
                }

                let isActive = screenShare["isActive"] as? Bool ?? false
                let sharedBy = screenShare["sharedBy"] as? String ?? ""

                remoteUserIsSharingScreen = isActive && sharedBy != currentUserId
            }
    }
    private func startCallRecordingMetadata() {
        guard let callId = callId, !callId.isEmpty else { return }
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard activeRecordingId == nil else { return }

        let db = Firestore.firestore()
        let recordingRef = db.collection("callRecordings").document()
        let recordingId = recordingRef.documentID

        activeRecordingId = recordingId
        recordingStartedAt = Date()

        recordingRef.setData([
            "id": recordingId,
            "callId": callId,
            "createdBy": currentUserId,
            "status": "starting",
            "storagePath": "",
            "downloadURL": "",
            "durationSeconds": 0,
            "createdAt": FieldValue.serverTimestamp(),
            "startedAt": FieldValue.serverTimestamp()
        ], merge: true)

        db.collection("calls")
            .document(callId)
            .setData([
                "recording": [
                    "recordingId": recordingId,
                    "requested": false,
                    "requestedBy": currentUserId,
                    "status": "accepted",
                    "startedAt": FieldValue.serverTimestamp()
                ]
            ], merge: true)

        startCloudRecording(recordingId: recordingId)
    }
    private func endCallSafely() {
        if isRecordingCall {
            stopCallRecording()
        }

        if isSharingScreen {
            stopScreenShare()
        }

        endCallLocally()
    }
    
    
    
    private func startCloudRecording(recordingId: String) {
        guard let callId = callId, !callId.isEmpty else { return }

        let body: [String: Any] = [
            "callId": callId,
            "channelName": callId,
            "recordingId": recordingId
        ]

        var request = URLRequest(url: startRecordingURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ startCloudRecording:", error.localizedDescription)
                return
            }

            if let data = data,
               let raw = String(data: data, encoding: .utf8) {
                print("🎥 startCloudRecording response:", raw)
            }
        }.resume()
    }
    private func stopCloudRecording(recordingId: String) {
        let body: [String: Any] = [
            "recordingId": recordingId
        ]

        var request = URLRequest(url: stopRecordingURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ stopCloudRecording:", error.localizedDescription)
                return
            }

            if let data = data,
               let raw = String(data: data, encoding: .utf8) {
                print("🛑 stopCloudRecording response:", raw)
            }
        }.resume()
    }
    
    private func openBroadcastPicker() {
        print("🖥️ Ouverture Broadcast Picker iOS")

        isSharingScreen = true

        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        picker.preferredExtension = "com.monapp--test.MonApp.CutlyScreenShareExtension"
        picker.showsMicrophoneButton = false

        if let button = picker.subviews.compactMap({ $0 as? UIButton }).first {
            button.sendActions(for: .touchUpInside)
        }
    }
    
    
    
}
struct RecordingBadgeView: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)

            Text("REC")
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.9))
        .clipShape(Capsule())
        .shadow(radius: 4)
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

                Text("TODO : brancher contacts Cutly pour appels de groupe plus tard.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
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

                Text("TODO : brancher les messages pendant l’appel plus tard.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Discussion")
        }
    }
}
import SwiftUI
import FirebaseFirestore

struct CallNotesView: View {

    let conversationId: String

    @Environment(\.dismiss) private var dismiss

    @State private var notes = ""

    var body: some View {

        NavigationStack {

            VStack {

                TextEditor(text: $notes)
                    .padding()

                Spacer()
            }
            .navigationTitle("Notes d'appel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button("Enregistrer") {

                        saveNote()

                        dismiss()
                    }
                }
            }
        }
    }

    private func saveNote() {

        Firestore.firestore()
            .collection("conversations")
            .document(conversationId)
            .collection("callNotes")
            .addDocument(data: [

                "content": notes,
                "createdAt": Timestamp(date: Date())
            ])

        print("📝 Note enregistrée")
    }
}
struct CallSettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var agora = CallAgoraManager.shared

    var body: some View {
        NavigationStack {
            Form {

                Section("Audio") {
                    Toggle("Réduction du bruit", isOn: $agora.noiseReductionEnabled)
                        .onChange(of: agora.noiseReductionEnabled) { _, value in
                            agora.setNoiseReduction(value)
                        }

                    Toggle("Volume haut-parleur renforcé", isOn: $agora.speakerBoostEnabled)
                        .onChange(of: agora.speakerBoostEnabled) { _, value in
                            agora.setSpeakerBoost(value)
                        }
                }

                Section("Vidéo") {
                    Toggle("Mode beauté léger", isOn: $agora.beautyModeEnabled)
                        .onChange(of: agora.beautyModeEnabled) { _, value in
                            agora.setBeautyMode(value)
                        }

                    Toggle("Flou arrière-plan", isOn: $agora.backgroundBlurEnabled)
                        .onChange(of: agora.backgroundBlurEnabled) { _, value in
                            agora.setBackgroundBlur(value)
                        }
                }

                Section("Connexion") {
                    Toggle("Mode faible connexion", isOn: $agora.lowDataModeEnabled)
                        .onChange(of: agora.lowDataModeEnabled) { _, value in
                            agora.setLowDataMode(value)
                        }
                }
            }
            .navigationTitle("Paramètres d’appel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}
struct CallReportView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason = ""
    @State private var details = ""
    @State private var reportSent = false

    let reasons = [
        "🚨 Menace",
        "🚨 Harcèlement",
        "🚨 Chantage",
        "🚨 Arnaque",
        "🚨 Usurpation d'identité",
        "🚨 Images privées diffusées",
        "⚠️ Racisme",
        "⚠️ Discrimination",
        "⚠️ Insultes",
        "⚠️ Spam",
        "⚠️ Contenu sexuel",
        "⚠️ Mineur en danger",
        "📞 Mauvais audio",
        "📞 Mauvaise vidéo",
        "📞 Coupures",
        "📞 Écho",
        "📞 Bug caméra",
        "📞 Bug micro",
        "📝 Autre"
    ]

    var body: some View {

        NavigationStack {

            Form {

                Section("Motif") {

                    Picker("Choisir", selection: $selectedReason) {
                        ForEach(reasons, id: \.self) {
                            Text($0)
                        }
                    }
                }

                Section("Description") {

                    TextEditor(text: $details)
                        .frame(height: 120)
                }

                Section {

                    Button {
                        ReportService.shared.sendReport(
                            reason: selectedReason,
                            details: details,
                            callId: nil,
                            conversationId: nil
                        )

                        reportSent = true
                    } label: {

                        Text("Envoyer le signalement")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Signalement")
            .alert(
                "Signalement envoyé",
                isPresented: $reportSent
            ) {

                Button("OK") {
                    dismiss()
                }

            } message: {

                Text("Merci de contribuer à la sécurité de la communauté Cutly.")
            }
        }
    }
}
