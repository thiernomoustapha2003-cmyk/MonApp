//
//  LiveAgoraManager.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//

//
//
//  LiveAgoraManager.swift
//  MonApp
//

import Foundation
import SwiftUI
import AgoraRtcKit
import Combine

final class LiveAgoraManager: NSObject, ObservableObject {
    
    static let shared = LiveAgoraManager()
    
    // ⚠️ À remplacer par ton vrai Agora App ID
    private let appId = "5a7d0d6f3da948eeacafa9a2defabd1c"
    
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

// MARK: - JOIN HOST / VIEWER

extension LiveAgoraManager {
    
    func joinAsHost(channelName: String) {
        
        print("🟢 joinAsHost START")
        
        setupEngine()
        
        guard let engine = engine else {
            print("❌ ENGINE NIL")
            return
        }
        
        print("✅ ENGINE OK")
        
        currentChannel = channelName
        
        engine.setClientRole(.broadcaster)
        
        print("✅ ROLE BROADCASTER")
        
        engine.enableVideo()
        engine.enableAudio()
        
        print("✅ VIDEO + AUDIO ENABLED")
        
        engine.enableLocalVideo(true)
        engine.muteLocalVideoStream(false)
        engine.muteLocalAudioStream(false)
        
        print("✅ LOCAL TRACKS ENABLED")
        
        engine.startPreview()
        
        print("✅ PREVIEW STARTED")
        
        let options = AgoraRtcChannelMediaOptions()
        
        options.channelProfile = .liveBroadcasting
        options.clientRoleType = .broadcaster
        options.publishCameraTrack = true
        options.publishMicrophoneTrack = true
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = true
        
        print("✅ OPTIONS READY")
        
        let result = engine.joinChannel(
            byToken: nil,
            channelId: channelName,
            uid: 0,
            mediaOptions: options
        )
        
        print("🔥 JOIN RESULT =", result)
    }
    
    func joinAsViewer(channelName: String) {
        setupEngine()
        guard let engine = engine else { return }
        
        currentChannel = channelName
        
        engine.setClientRole(.audience)
        
        let options = AgoraRtcChannelMediaOptions()
        options.channelProfile = .liveBroadcasting
        options.clientRoleType = .audience
        options.publishCameraTrack = false
        options.publishMicrophoneTrack = false
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = true
        
        engine.joinChannel(
            byToken: nil,
            channelId: channelName,
            uid: 0,
            mediaOptions: options
        )
    }
    
    func becomeCoHost() {
        guard let engine = engine else { return }
        
        engine.setClientRole(.broadcaster)
        engine.startPreview()
        
        let options = AgoraRtcChannelMediaOptions()
        options.clientRoleType = .broadcaster
        options.publishCameraTrack = true
        options.publishMicrophoneTrack = true
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = true
        
        if let channel = currentChannel {
            engine.updateChannel(with: options)
            print("🎥 Devenu co-host dans:", channel)
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
    
    func destroyEngine() {
        leaveChannel()
        AgoraRtcEngineKit.destroy()
        engine = nil
    }
}

// MARK: - VIDEO RENDER

extension LiveAgoraManager {
    
    func setupLocalVideo(view: UIView) {
        guard let engine = engine else { return }
        
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = 0
        canvas.view = view
        canvas.renderMode = .hidden
        
        engine.setupLocalVideo(canvas)
        engine.startPreview()
    }
    
    func setupRemoteVideo(uid: UInt, view: UIView) {
        guard let engine = engine else { return }
        
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = uid
        canvas.view = view
        canvas.renderMode = .hidden
        
        engine.setupRemoteVideo(canvas)
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
    
    func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didJoinChannel channel: String,
        withUid uid: UInt,
        elapsed: Int
    ) {
        DispatchQueue.main.async {
            self.isJoined = true
        }
        
        print("✅ Agora rejoint:", channel, "uid:", uid)
    }
    
    func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didJoinedOfUid uid: UInt,
        elapsed: Int
    ) {
        DispatchQueue.main.async {
            if !self.remoteUsers.contains(uid) {
                self.remoteUsers.append(uid)
            }
        }
        
        print("👤 Utilisateur distant rejoint:", uid)
    }
    
    func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didOfflineOfUid uid: UInt,
        reason: AgoraUserOfflineReason
    ) {
        DispatchQueue.main.async {
            self.remoteUsers.removeAll { $0 == uid }
        }
        
        print("👋 Utilisateur distant parti:", uid)
    }
}
