//
//  CallAgoraManager.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 23/06/2026.
//

//
//  CallAgoraManager.swift
//  MonApp
//
//  Gestion Agora UNIQUEMENT pour les appels privés audio/vidéo.
//  IMPORTANT : ne pas mélanger avec LiveAgoraManager.swift.
//  LiveAgoraManager = lives TikTok.
//  CallAgoraManager = appels WhatsApp-like.
//

import Foundation
import SwiftUI
import AgoraRtcKit
import FirebaseAuth
import AVFoundation
import Combine
import ReplayKit
import UIKit

final class CallAgoraManager: NSObject, ObservableObject {

    static let shared = CallAgoraManager()

    private let appId = "5a7d0d6f3da948eeacafa9a2defabd1c"
    private let tokenURL = "https://us-central1-afroconnect-7588d.cloudfunctions.net/generateAgoraToken"

    @Published var isJoined = false
    @Published var remoteUsers: [UInt] = []
    @Published var isMuted = false
    @Published var isCameraOff = false
    @Published var isSpeakerOn = true
    @Published var noiseReductionEnabled = true
    @Published var speakerBoostEnabled = true
    @Published var lowDataModeEnabled = false
    @Published var beautyModeEnabled = false
    @Published var backgroundBlurEnabled = false
    

    private var engine: AgoraRtcEngineKit?
    private var currentChannel: String?
    private var currentUid: UInt = 0
    private var currentIsVideo = false

    private override init() {
        super.init()
    }

    // MARK: - SETUP APPEL PRIVÉ

    private func setupEngineForCall(isVideo: Bool) {
        if engine == nil {
            let config = AgoraRtcEngineConfig()
            config.appId = appId

            let rtcEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)

            // IMPORTANT :
            // Pour les appels privés type WhatsApp, on utilise communication.
            // Ne pas utiliser liveBroadcasting ici.
            rtcEngine.setChannelProfile(.communication)

            rtcEngine.enableAudio()
            rtcEngine.setAudioProfile(.default, scenario: .chatRoom)
            rtcEngine.setEnableSpeakerphone(isSpeakerOn)
            rtcEngine.adjustRecordingSignalVolume(100)
            rtcEngine.adjustPlaybackSignalVolume(100)
            applyAudioSettings()
            
            
            

            self.engine = rtcEngine
        }

        guard let engine = engine else { return }

        engine.setChannelProfile(.communication)
        engine.enableAudio()
        engine.muteLocalAudioStream(false)

        if isVideo {
            engine.enableVideo()
            engine.enableLocalVideo(true)
            engine.muteLocalVideoStream(false)
            engine.startPreview()
            isCameraOff = false
        } else {
            engine.disableVideo()
            engine.stopPreview()
            isCameraOff = true
        }

        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ AudioSession appel privé configurée")
        } catch {
            print("❌ AudioSession appel privé error:", error.localizedDescription)
        }
    }

    // MARK: - TOKEN AGORA

    private func fetchAgoraToken(
        channelName: String,
        uid: UInt,
        completion: @escaping (String?) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            print("❌ Aucun utilisateur Firebase connecté pour Agora Call")
            completion(nil)
            return
        }

        user.getIDToken { idToken, error in
            if let error = error {
                print("❌ Firebase ID Token Call error:", error.localizedDescription)
                completion(nil)
                return
            }

            guard let idToken = idToken,
                  let url = URL(string: self.tokenURL) else {
                print("❌ Token Firebase ou URL Agora Call invalide")
                completion(nil)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "channelName": channelName,
                "uid": uid,
                "role": "publisher"
            ]

            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    print("❌ Erreur generateAgoraToken Call:", error.localizedDescription)
                    completion(nil)
                    return
                }

                guard let data = data else {
                    print("❌ Aucune data token Agora Call")
                    completion(nil)
                    return
                }

                if let raw = String(data: data, encoding: .utf8) {
                    print("📩 Réponse token Agora Call:", raw)
                }

                do {
                    guard
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let token = json["token"] as? String
                    else {
                        print("❌ Token Agora Call absent")
                        completion(nil)
                        return
                    }

                    print("✅ Token Agora Call reçu")
                    completion(token)

                } catch {
                    print("❌ JSON Agora Call invalide:", error.localizedDescription)
                    completion(nil)
                }
            }.resume()
        }
    }

    // MARK: - JOIN APPEL

    func joinCall(channelName: String, uid: UInt, isVideo: Bool) {
        if isJoined && currentChannel == channelName {
            print("⚠️ Déjà connecté à l'appel:", channelName)
            return
        }

        if isJoined && currentChannel != channelName {
            leaveCall()
        }

        currentChannel = channelName
        currentUid = uid
        currentIsVideo = isVideo
        remoteUsers.removeAll()

        setupEngineForCall(isVideo: isVideo)

        fetchAgoraToken(channelName: channelName, uid: uid) { token in
            guard let token = token else {
                print("❌ Join appel annulé : token nil")
                return
            }

            DispatchQueue.main.async {
                guard let engine = self.engine else {
                    print("❌ Engine Agora Call nil")
                    return
                }

                let options = AgoraRtcChannelMediaOptions()

                // IMPORTANT :
                // Profil communication = appel privé.
                options.channelProfile = .communication

                // Les deux participants publient audio.
                options.publishMicrophoneTrack = true
                options.autoSubscribeAudio = true

                // Vidéo publiée seulement si appel vidéo.
                options.publishCameraTrack = isVideo
                options.autoSubscribeVideo = isVideo

                let result = engine.joinChannel(
                    byToken: token,
                    channelId: channelName,
                    uid: uid,
                    mediaOptions: options
                )

                print("📞 Agora Call join result:", result)
            }
        }
    }

    // MARK: - LEAVE APPEL

    func leaveCall() {
        engine?.leaveChannel(nil)
        engine?.stopPreview()

        DispatchQueue.main.async {
            self.isJoined = false
            self.remoteUsers.removeAll()
            self.currentChannel = nil
            self.currentUid = 0
            self.currentIsVideo = false
            self.isMuted = false
            self.isCameraOff = false
        }

        print("📴 Agora Call quitté")
    }

    // MARK: - AUDIO / VIDEO CONTROLS

    func muteLocalAudio(_ muted: Bool) {
        engine?.muteLocalAudioStream(muted)
        isMuted = muted
        print(muted ? "🔇 Micro coupé" : "🎙️ Micro activé")
    }

    func enableSpeaker(_ enabled: Bool) {
        engine?.setEnableSpeakerphone(enabled)
        isSpeakerOn = enabled
        print(enabled ? "🔊 Haut-parleur activé" : "🔈 Haut-parleur désactivé")
    }

    func enableCamera(_ enabled: Bool) {
        guard currentIsVideo else {
            print("⚠️ Caméra ignorée : appel audio")
            return
        }

        engine?.muteLocalVideoStream(!enabled)
        isCameraOff = !enabled
        print(enabled ? "📹 Caméra activée" : "📷 Caméra coupée")
    }

    func switchCamera() {
        engine?.switchCamera()
        print("🔄 Caméra inversée")
    }

    // MARK: - CALL SETTINGS

    func setNoiseReduction(_ enabled: Bool) {
        noiseReductionEnabled = enabled
        applyAudioSettings()
        print(enabled ? "✅ Réduction du bruit activée" : "❌ Réduction du bruit désactivée")
    }

    func setSpeakerBoost(_ enabled: Bool) {
        speakerBoostEnabled = enabled
        applyAudioSettings()
        print(enabled ? "🔊 Volume renforcé activé" : "🔈 Volume normal")
    }

    func setLowDataMode(_ enabled: Bool) {
        lowDataModeEnabled = enabled

        if enabled {
            engine?.adjustPlaybackSignalVolume(80)
            engine?.adjustRecordingSignalVolume(80)
        } else {
            applyAudioSettings()
        }

        print(enabled ? "📶 Mode faible connexion activé" : "📶 Mode normal activé")
    }

    func setBeautyMode(_ enabled: Bool) {
        beautyModeEnabled = enabled

        if enabled {
            print("✨ Mode beauté demandé")
            print("⚠️ Extension beauté Agora non trouvée dans ce SDK actuel")
            print("➡️ À brancher plus tard avec setBeautyEffectOptions quand disponible")
        } else {
            print("✨ Mode beauté désactivé")
        }
    }

    func setBackgroundBlur(_ enabled: Bool) {
        backgroundBlurEnabled = enabled

        if enabled {
            print("🌫 Flou arrière-plan demandé")
            print("⚠️ enableVirtualBackground introuvable dans ce SDK actuel")
            print("➡️ À brancher plus tard avec extension Virtual Background Agora")
        } else {
            print("🌫 Flou arrière-plan désactivé")
        }
    }

    private func applyAudioSettings() {
        if noiseReductionEnabled {
            engine?.setParameters("{\"che.audio.ans.enable\":true}")
            engine?.setParameters("{\"che.audio.aec.enable\":true}")
            engine?.setParameters("{\"che.audio.agc.enable\":true}")
        } else {
            engine?.setParameters("{\"che.audio.ans.enable\":false}")
        }

        if speakerBoostEnabled {
            engine?.adjustPlaybackSignalVolume(130)
            engine?.adjustRecordingSignalVolume(110)
        } else {
            engine?.adjustPlaybackSignalVolume(100)
            engine?.adjustRecordingSignalVolume(100)
        }
    }
    
    // MARK: - SCREEN SHARE PRODUCTION

    func startScreenShare() {
        guard currentIsVideo else {
            print("⚠️ Partage écran ignoré : appel audio")
            return
        }

        guard let currentChannel = currentChannel, !currentChannel.isEmpty else {
            print("❌ Partage écran impossible : channel vide")
            return
        }

        print("🖥️ Ouverture Broadcast Picker iOS")

        DispatchQueue.main.async {
            let picker = RPSystemBroadcastPickerView(
                frame: CGRect(x: 0, y: 0, width: 50, height: 50)
            )

            picker.preferredExtension = "com.monapp--test.MonApp.CutlyScreenShareExtension"
            picker.showsMicrophoneButton = false

            guard let button = picker.subviews.compactMap({ $0 as? UIButton }).first else {
                print("❌ Bouton Broadcast Picker introuvable")
                return
            }

            button.sendActions(for: .touchUpInside)
            print("✅ Broadcast Picker ouvert")
        }
    }

    func stopScreenShare() {
        print("🛑 Arrêt partage écran demandé")

        // Important :
        // Le vrai arrêt du broadcast se fait depuis la barre rouge iOS /
        // le centre de contrôle / ou quand l'appel se termine.
    }

   
    private func pushScreenShareFrameToAgora(_ sampleBuffer: CMSampleBuffer) {
        guard let engine = engine else {
            print("❌ Agora engine nil pour screen share")
            return
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("❌ PixelBuffer screen share nil")
            return
        }

        let videoFrame = AgoraVideoFrame()
        videoFrame.format = 12
        videoFrame.textureBuf = pixelBuffer
        videoFrame.time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        let result = engine.pushExternalVideoFrame(videoFrame)

        if result == false {
            print("❌ pushExternalVideoFrame failed")
        } else {
            print("✅ Frame écran envoyée à Agora")
        }
    }
    
    
    
    
    
    // MARK: - RENDER VIDEO

    func setupLocalVideo(view: UIView) {
        guard let engine = engine else {
            print("❌ setupLocalVideo Call impossible : engine nil")
            return
        }

        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = currentUid
        canvas.view = view
        canvas.renderMode = .hidden

        engine.setupLocalVideo(canvas)
        print("🎥 Call local video branchée")
    }

    func setupRemoteVideo(uid: UInt, view: UIView) {
        guard let engine = engine else {
            print("❌ setupRemoteVideo Call impossible : engine nil")
            return
        }

        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = uid
        canvas.view = view
        canvas.renderMode = .hidden

        engine.setupRemoteVideo(canvas)
        print("🎥 Call remote video branchée uid:", uid)
    }
}

// MARK: - DELEGATE AGORA APPELS

extension CallAgoraManager: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinChannel channel: String,
                   withUid uid: UInt,
                   elapsed: Int) {

        DispatchQueue.main.async {
            self.isJoined = true
            self.currentChannel = channel
        }

        print("✅ Agora Call rejoint:", channel, "uid:", uid)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinedOfUid uid: UInt,
                   elapsed: Int) {

        DispatchQueue.main.async {
            if !self.remoteUsers.contains(uid) {
                self.remoteUsers.append(uid)
            }
        }

        print("👤 Participant appel rejoint:", uid)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didOfflineOfUid uid: UInt,
                   reason: AgoraUserOfflineReason) {

        DispatchQueue.main.async {
            self.remoteUsers.removeAll { $0 == uid }
        }

        print("👋 Participant appel parti:", uid)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   remoteVideoStateChangedOfUid uid: UInt,
                   state: AgoraVideoRemoteState,
                   reason: AgoraVideoRemoteReason,
                   elapsed: Int) {

        print("📡 Call remote video state uid:", uid, "state:", state.rawValue, "reason:", reason.rawValue)

        DispatchQueue.main.async {
            if !self.remoteUsers.contains(uid) {
                self.remoteUsers.append(uid)
            }
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   firstRemoteVideoFrameOfUid uid: UInt,
                   size: CGSize,
                   elapsed: Int) {

        DispatchQueue.main.async {
            if !self.remoteUsers.contains(uid) {
                self.remoteUsers.append(uid)
            }
        }

        print("🎥 First remote call video frame uid:", uid, "size:", size)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didOccurError errorCode: AgoraErrorCode) {
        print("❌ Agora Call error:", errorCode.rawValue)
    }
}
