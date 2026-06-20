//
//  ChatAudioService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 19/06/2026.
//

import Foundation
import FirebaseStorage

final class ChatAudioService {

    static let shared = ChatAudioService()
    private init() {}

    func uploadAudio(fileURL: URL, conversationId: String, completion: @escaping (String?) -> Void) {
        let fileName = UUID().uuidString + ".m4a"

        let ref = Storage.storage()
            .reference()
            .child("chat_media")
            .child(conversationId)
            .child("audios")
            .child(fileName)

        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"

        ref.putFile(from: fileURL, metadata: metadata) { _, error in
            if let error = error {
                print("❌ Upload audio:", error.localizedDescription)
                completion(nil)
                return
            }

            ref.downloadURL { url, error in
                if let error = error {
                    print("❌ URL audio:", error.localizedDescription)
                    completion(nil)
                    return
                }

                completion(url?.absoluteString)
            }
        }
    }
}
