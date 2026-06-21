//
//  Style.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 20/06/2026.
//

import Foundation

struct Style: Identifiable, Codable {

    var id: String?

    var barberId: String

    var barberName: String

    var title: String

    var description: String

    var imageUrl: String

    var price: Double

    var duration: Int

    var likesCount: Int

    var createdAt: Date
    var likedBy: [String]
    var favoritesCount: Int
    var commentsCount: Int
    

    init(
        id: String? = nil,
        barberId: String,
        barberName: String,
        title: String,
        description: String,
        imageUrl: String,
        price: Double,
        duration: Int,
        likesCount: Int = 0,
        createdAt: Date = Date(),
        likedBy: [String] = [],
        favoritesCount: Int = 0,
        commentsCount: Int = 0
    ) {
        self.id = id
        self.barberId = barberId
        self.barberName = barberName
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.price = price
        self.duration = duration
        self.likesCount = likesCount
        self.createdAt = createdAt
        self.likedBy = likedBy
        self.favoritesCount = favoritesCount
        self.commentsCount = commentsCount
    }
}
