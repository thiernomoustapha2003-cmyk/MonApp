//
//  ShareSheet.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 19/06/2026.
//

import SwiftUI
import UIKit

struct ChatShareSheet: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
