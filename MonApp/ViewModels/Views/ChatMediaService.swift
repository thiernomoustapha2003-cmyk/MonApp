//
//  ChatMediaService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 18/06/2026.
//

import Foundation
import FirebaseStorage
import UIKit

class ChatMediaService {

    static let shared = ChatMediaService()
    private init() {}

    private let storage = Storage.storage()

    func uploadImage(
        _ image: UIImage,
        conversationId: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let imageData = image.jpegData(compressionQuality: 0.95) else {
            completion(nil)
            return
        }

        let fileName = UUID().uuidString + ".jpg"

        let ref = storage.reference()
            .child("chat_media")
            .child(conversationId)
            .child("images")
            .child(fileName)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        ref.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("❌ Upload image:", error.localizedDescription)
                completion(nil)
                return
            }

            ref.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }

    func uploadVideo(
        fileURL: URL,
        conversationId: String,
        completion: @escaping (String?) -> Void
    ) {
        let fileName = UUID().uuidString + ".mov"

        let ref = storage.reference()
            .child("chat_media")
            .child(conversationId)
            .child("videos")
            .child(fileName)

        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"

        ref.putFile(from: fileURL, metadata: metadata) { _, error in
            if let error = error {
                print("❌ Upload vidéo:", error.localizedDescription)
                completion(nil)
                return
            }

            ref.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }
}
