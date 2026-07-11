//
//  SampleHandler.swift
//  CutlyScreenShareExtension
//

import ReplayKit
import AgoraRtcKit

final class SampleHandler: RPBroadcastSampleHandler {

    private var engine: AgoraRtcEngineKit?
    private var channelName = ""
    private var token = ""
    private var appId = ""
    private var uid: UInt = 0

    private let appGroupId = "group.com.monapp.screenshare"

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            finishBroadcastWithError(NSError(domain: "Cutly", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "App Group introuvable"
            ]))
            return
        }

        appId = defaults.string(forKey: "agora_app_id") ?? ""
        token = defaults.string(forKey: "agora_token") ?? ""
        channelName = defaults.string(forKey: "agora_channel") ?? ""
        uid = UInt(defaults.integer(forKey: "agora_screen_uid"))

        guard !appId.isEmpty, !token.isEmpty, !channelName.isEmpty, uid > 0 else {
            finishBroadcastWithError(NSError(domain: "Cutly", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Infos Agora manquantes pour partage écran"
            ]))
            return
        }

        let config = AgoraRtcEngineConfig()
        config.appId = appId

        let rtcEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: nil)
        rtcEngine.setChannelProfile(.communication)
        rtcEngine.enableVideo()
        rtcEngine.enableAudio()

        rtcEngine.setExternalVideoSource(
            true,
            useTexture: true,
            sourceType: .videoFrame
        )

        let options = AgoraRtcChannelMediaOptions()
        options.channelProfile = .communication
        options.publishCameraTrack = false
        options.publishMicrophoneTrack = false
        options.publishCustomVideoTrack = true
        options.autoSubscribeAudio = false
        options.autoSubscribeVideo = false

        rtcEngine.joinChannel(
            byToken: token,
            channelId: channelName,
            uid: uid,
            mediaOptions: options
        )

        engine = rtcEngine
    }

    override func broadcastFinished() {
        engine?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
        engine = nil
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .video else { return }
        guard let engine = engine else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let frame = AgoraVideoFrame()
        frame.format = 12
        frame.textureBuf = pixelBuffer
        frame.time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        engine.pushExternalVideoFrame(frame)
    }
}
