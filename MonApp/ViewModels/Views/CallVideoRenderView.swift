//
//  CallVideoRenderView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 23/06/2026.
//

//
//  CallVideoRenderView.swift
//  MonApp
//
//  Affichage vidéo UNIQUEMENT pour les appels privés audio/vidéo.
//  IMPORTANT : ne pas utiliser ce fichier pour les Lives TikTok.
//  Lives TikTok = AgoraVideoRenderView + LiveAgoraManager
//  Appels privés = CallVideoRenderView + CallAgoraManager
//

import SwiftUI
import AgoraRtcKit

struct CallVideoRenderView: UIViewRepresentable {

    let uid: UInt
    let isLocal: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.clipsToBounds = true

        DispatchQueue.main.async {
            if isLocal {
                // Vidéo locale de l'appel privé
                CallAgoraManager.shared.setupLocalVideo(view: view)
            } else {
                // Vidéo distante de l'appel privé
                CallAgoraManager.shared.setupRemoteVideo(uid: uid, view: view)
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Ici on pourra plus tard gérer rotation, qualité vidéo, changement caméra.
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        uiView.subviews.forEach { $0.removeFromSuperview() }
    }
}
