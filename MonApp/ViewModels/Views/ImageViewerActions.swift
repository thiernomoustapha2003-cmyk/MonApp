//
//  ImageViewerActions.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 20/06/2026.
//

import SwiftUI
import Photos
import UIKit

enum ImageViewerAction: String, Identifiable, CaseIterable {
    case save
    case share
    case report
    case favorite
    case readText
    case aiDescribe
    case scanQR
    case bookStyle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .save: return "Enregistrer"
        case .share: return "Partager"
        case .report: return "Signaler"
        case .favorite: return "Favori"
        case .readText: return "Lire texte"
        case .aiDescribe: return "IA image"
        case .scanQR: return "Scanner QR"
        case .bookStyle: return "Réserver style"
        }
    }

    var icon: String {
        switch self {
        case .save: return "square.and.arrow.down"
        case .share: return "arrowshape.turn.up.right"
        case .report: return "exclamationmark.triangle"
        case .favorite: return "star"
        case .readText: return "text.viewfinder"
        case .aiDescribe: return "sparkles"
        case .scanQR: return "qrcode.viewfinder"
        case .bookStyle: return "scissors"
        }
    }
}
