import SwiftUI
import UIKit
import AgoraRtcKit

struct AgoraVideoView: UIViewRepresentable {
    
    enum VideoType: Equatable {
        case local
        case remote(uid: UInt)
    }
    
    let videoType: VideoType
    var cornerRadius: CGFloat = 0
    
    func makeUIView(context: Context) -> AgoraRenderContainer {
        let view = AgoraRenderContainer()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.layer.cornerRadius = cornerRadius
        view.videoType = videoType
        return view
    }
    
    func updateUIView(_ uiView: AgoraRenderContainer, context: Context) {
        uiView.layer.cornerRadius = cornerRadius
        uiView.videoType = videoType
        uiView.attachVideoIfNeeded(force: true)
    }
}

final class AgoraRenderContainer: UIView {
    
    var videoType: AgoraVideoView.VideoType?
    private var lastAttachedType: AgoraVideoView.VideoType?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        attachVideoIfNeeded(force: false)
    }
    
    func attachVideoIfNeeded(force: Bool) {
        guard bounds.width > 10, bounds.height > 10 else {
            print("⚠️ Agora attach ignoré car taille 0:", bounds)
            return
        }
        
        guard let videoType = videoType else { return }
        
        if !force && lastAttachedType == videoType { return }
        lastAttachedType = videoType
        
        print("🎥 Agora attach FINAL =", bounds, "type =", videoType)
        
        switch videoType {
        case .local:
            LiveAgoraManager.shared.setupLocalVideo(view: self)
            
        case .remote(let uid):
            LiveAgoraManager.shared.setupRemoteVideo(uid: uid, view: self)
        }
    }
}
