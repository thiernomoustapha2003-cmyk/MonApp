import Foundation
import SwiftUI
import AgoraRtcKit
import Combine
import FirebaseAuth

final class LiveAgoraManager: NSObject, ObservableObject {
    
    static let shared = LiveAgoraManager()
    
    private let appId = "5a7d0d6f3da948eeacafa9a2defabd1c"
    private let tokenURL = "https://us-central1-afroconnect-7588d.cloudfunctions.net/generateAgoraToken"
    
    @Published var isJoined = false
    @Published var isMuted = false
    @Published var isCameraOff = false
    @Published var remoteUsers: [UInt] = []
    
    private var engine: AgoraRtcEngineKit?
    private var currentChannel: String?
    
    private override init() {
        super.init()
    }
}

// MARK: - SETUP

extension LiveAgoraManager {
    
    func setupEngine() {
        guard engine == nil else { return }
        
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        
        let rtcEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        rtcEngine.setChannelProfile(.liveBroadcasting)
        rtcEngine.enableVideo()
        rtcEngine.enableAudio()
        
        self.engine = rtcEngine
    }
}

// MARK: - TOKEN

extension LiveAgoraManager {
    
    func fetchAgoraToken(
        channelName: String,
        uid: UInt,
        role: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            print("❌ Aucun utilisateur Firebase connecté")
            completion(nil)
            return
        }
        
        user.getIDToken { idToken, error in
            
            if let error = error {
                print("❌ Firebase ID Token error:", error.localizedDescription)
                completion(nil)
                return
            }
            
            guard let idToken = idToken,
                  let url = URL(string: self.tokenURL) else {
                print("❌ Token Firebase ou URL invalide")
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
                "role": role
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                
                if let error = error {
                    print("❌ Erreur appel generateAgoraToken:", error.localizedDescription)
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    print("❌ Aucune data token Agora")
                    completion(nil)
                    return
                }
                
                if let raw = String(data: data, encoding: .utf8) {
                    print("📩 Réponse token Agora:", raw)
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let token = json["token"] as? String {
                        print("✅ Token Agora reçu")
                        completion(token)
                    } else {
                        print("❌ Token absent dans la réponse")
                        completion(nil)
                    }
                } catch {
                    print("❌ JSON token invalide:", error.localizedDescription)
                    completion(nil)
                }
                
            }.resume()
        }
    }
}

// MARK: - JOIN HOST / VIEWER

extension LiveAgoraManager {
    
    func joinAsHost(channelName: String) {
        
        let uid: UInt = 1001
        
        print("🟢 joinAsHost START")
        print("🎥 HOST CHANNEL =", channelName)
        
        fetchAgoraToken(channelName: channelName, uid: uid, role: "publisher") { token in
            
            guard let token = token else {
                print("❌ Impossible de rejoindre host: token nil")
                return
            }
            
            DispatchQueue.main.async {
                self.setupEngine()
                
                guard let engine = self.engine else {
                    print("❌ ENGINE NIL")
                    return
                }
                
                self.currentChannel = channelName
                
                engine.setChannelProfile(.liveBroadcasting)
                engine.setClientRole(.broadcaster)
                engine.enableVideo()
                engine.enableAudio()
                engine.enableLocalVideo(true)
                engine.muteLocalVideoStream(false)
                engine.muteLocalAudioStream(false)
               
                
                let options = AgoraRtcChannelMediaOptions()
                options.channelProfile = .liveBroadcasting
                options.clientRoleType = .broadcaster
                options.publishCameraTrack = true
                options.publishMicrophoneTrack = true
                options.autoSubscribeAudio = true
                options.autoSubscribeVideo = true
                
                let result = engine.joinChannel(
                    byToken: token,
                    channelId: channelName,
                    uid: uid,
                    mediaOptions: options
                )
                
                print("🔥 HOST JOIN RESULT =", result)
            }
        }
    }
    
    func joinAsViewer(channelName: String) {
        
        let uid: UInt = 2001
        
        print("👀 joinAsViewer START channel =", channelName)
        
        fetchAgoraToken(channelName: channelName, uid: uid, role: "subscriber") { token in
            
            guard let token = token else {
                print("❌ Impossible de rejoindre viewer: token nil")
                return
            }
            
            DispatchQueue.main.async {
                self.setupEngine()
                
                guard let engine = self.engine else {
                    print("❌ VIEWER ENGINE NIL")
                    return
                }
                
                self.remoteUsers.removeAll()
                self.isJoined = false
                self.currentChannel = channelName
                
                engine.setChannelProfile(.liveBroadcasting)
                engine.setClientRole(.audience)
                engine.enableVideo()
                engine.enableAudio()
                engine.startPreview()
                
                let options = AgoraRtcChannelMediaOptions()
                options.channelProfile = .liveBroadcasting
                options.clientRoleType = .audience
                options.publishCameraTrack = false
                options.publishMicrophoneTrack = false
                options.autoSubscribeAudio = true
                options.autoSubscribeVideo = true
                
                let result = engine.joinChannel(
                    byToken: token,
                    channelId: channelName,
                    uid: uid,
                    mediaOptions: options
                )
                
                print("👀 VIEWER JOIN RESULT =", result)
            }
        }
    }
    
    func backToViewer() {
        guard let engine = engine else { return }

        engine.setClientRole(.audience)
        engine.stopPreview()

        let options = AgoraRtcChannelMediaOptions()
        options.clientRoleType = .audience
        options.publishCameraTrack = false
        options.publishMicrophoneTrack = false
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = true

        engine.updateChannel(with: options)

        print("👀 Retour spectateur")
    }
    
    func leaveChannel() {
        engine?.leaveChannel(nil)
        engine?.stopPreview()
        
        DispatchQueue.main.async {
            self.isJoined = false
            self.remoteUsers.removeAll()
            self.currentChannel = nil
        }
    }
}

// MARK: - VIDEO RENDER

extension LiveAgoraManager {
    
    func setupLocalVideo(view: UIView) {
        guard let engine = engine else { return }

        view.backgroundColor = .black

        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = 1001
        canvas.view = view
        canvas.renderMode = .hidden

        engine.setupLocalVideo(canvas)

        print("🎥 setupLocalVideo OK view:", view.bounds)
    }
    
    func setupRemoteVideo(uid: UInt, view: UIView) {
        guard let engine = engine else { return }

        view.backgroundColor = .black

        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = uid
        canvas.view = view
        canvas.renderMode = .hidden

        engine.setupRemoteVideo(canvas)

        print("🎥 setupRemoteVideo OK uid:", uid, "view:", view.bounds)
    }
}

// MARK: - MIC / CAMERA

extension LiveAgoraManager {
    
    func toggleMic() {
        isMuted.toggle()
        engine?.muteLocalAudioStream(isMuted)
    }
    
    func toggleCamera() {
        isCameraOff.toggle()
        engine?.muteLocalVideoStream(isCameraOff)
    }
    
    func switchCamera() {
        engine?.switchCamera()
    }
}

// MARK: - DELEGATE

extension LiveAgoraManager: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        DispatchQueue.main.async {
            self.isJoined = true
        }
        print("✅ Agora rejoint:", channel, "uid:", uid)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        DispatchQueue.main.async {
            if !self.remoteUsers.contains(uid) {
                self.remoteUsers.append(uid)
            }
        }
        print("👤 Utilisateur distant rejoint:", uid)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        DispatchQueue.main.async {
            self.remoteUsers.removeAll { $0 == uid }
        }
        print("👋 Utilisateur distant parti:", uid)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteReason, elapsed: Int) {
        print("📡 REMOTE VIDEO STATE uid:", uid, "state:", state.rawValue, "reason:", reason.rawValue)
        
        DispatchQueue.main.async {
            if !self.remoteUsers.contains(uid) {
                self.remoteUsers.append(uid)
                print("✅ REMOTE AJOUTÉ VIA VIDEO STATE:", uid)
            }
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
        print("🎥 FIRST REMOTE VIDEO FRAME uid:", uid, "size:", size)
        
        DispatchQueue.main.async {
            if !self.remoteUsers.contains(uid) {
                self.remoteUsers.append(uid)
                print("✅ REMOTE AJOUTÉ VIA FIRST FRAME:", uid)
            }
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("❌ AGORA ERROR:", errorCode.rawValue)
    }
}
