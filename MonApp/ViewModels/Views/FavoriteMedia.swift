//
//  FavoriteMedia.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 20/06/2026.
//

import Foundation
import FirebaseFirestore

struct FavoriteMedia: Identifiable {

    let id: String
    let mediaUrl: String
    let type: String
    let createdAt: Date

    init(document: DocumentSnapshot) {

        let data = document.data() ?? [:]

        self.id = document.documentID
        self.mediaUrl = data["mediaUrl"] as? String ?? ""
        self.type = data["type"] as? String ?? "image"
        self.createdAt =
        (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}
