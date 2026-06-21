//
//  StylesService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 20/06/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class StylesService {
    
    static let shared = StylesService()
    
    private let db = Firestore.firestore()
    
    func publishStyle(
        style: Style,
        completion: @escaping (Bool) -> Void
    ) {
        
        guard let id = style.id else {
            completion(false)
            return
        }
        
        do {
            
            try db.collection("styles")
                .document(id)
                .setData(from: style)
            
            completion(true)
            
        } catch {
            
            print(error.localizedDescription)
            completion(false)
        }
    }
    
    func loadStyles(
        completion: @escaping ([Style]) -> Void
    ) {
        
        db.collection("styles")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let styles = docs.compactMap {
                    try? $0.data(as: Style.self)
                }
                
                completion(styles)
            }
    }
    func toggleLike(style: Style, completion: @escaping () -> Void = {}) {
        guard let uid = Auth.auth().currentUser?.uid,
              let styleId = style.id else { return }

        let ref = db.collection("styles").document(styleId)
        let alreadyLiked = style.likedBy.contains(uid)

        ref.updateData([
            "likedBy": alreadyLiked ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid]),
            "likesCount": FieldValue.increment(Int64(alreadyLiked ? -1 : 1))
        ]) { _ in
            if !alreadyLiked {
                self.createStyleNotification(
                    ownerId: style.barberId,
                    type: "like",
                    message: "Quelqu’un a aimé votre style \(style.title)",
                    styleId: styleId
                )
            }
            completion()
        }
    }

    func addFavorite(style: Style, completion: @escaping () -> Void = {}) {
        guard let uid = Auth.auth().currentUser?.uid,
              let styleId = style.id else { return }

        db.collection("users")
            .document(uid)
            .collection("favoriteStyles")
            .document(styleId)
            .setData([
                "styleId": styleId,
                "barberId": style.barberId,
                "title": style.title,
                "imageUrl": style.imageUrl,
                "createdAt": Timestamp(date: Date())
            ])

        db.collection("styles")
            .document(styleId)
            .updateData([
                "favoritesCount": FieldValue.increment(Int64(1))
            ])

        createStyleNotification(
            ownerId: style.barberId,
            type: "favorite",
            message: "Quelqu’un a ajouté votre style en favori",
            styleId: styleId
        )

        completion()
    }

    func addComment(style: Style, text: String, completion: @escaping () -> Void = {}) {
        guard let uid = Auth.auth().currentUser?.uid,
              let styleId = style.id else { return }

        let commentRef = db.collection("styles")
            .document(styleId)
            .collection("comments")
            .document()

        commentRef.setData([
            "userId": uid,
            "text": text,
            "createdAt": Timestamp(date: Date())
        ])

        db.collection("styles")
            .document(styleId)
            .updateData([
                "commentsCount": FieldValue.increment(Int64(1))
            ])

        createStyleNotification(
            ownerId: style.barberId,
            type: "comment",
            message: "Nouveau commentaire sur votre style",
            styleId: styleId
        )

        completion()
    }

    func createStyleNotification(ownerId: String, type: String, message: String, styleId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard ownerId != uid else { return }

        db.collection("users")
            .document(ownerId)
            .collection("notifications")
            .addDocument(data: [
                "type": type,
                "message": message,
                "styleId": styleId,
                "fromUserId": uid,
                "isRead": false,
                "createdAt": Timestamp(date: Date())
            ])
    }
    
}
