//
//  AgoraVideoRenderView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 21/06/2026.
//

import SwiftUI
import AgoraRtcKit

struct AgoraVideoRenderView: UIViewRepresentable {

    let uid: UInt
    let isLocal: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        DispatchQueue.main.async {
            if isLocal {
                LiveAgoraManager.shared.setupLocalVideo(view: view)
            } else {
                LiveAgoraManager.shared.setupRemoteVideo(uid: uid, view: view)
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
