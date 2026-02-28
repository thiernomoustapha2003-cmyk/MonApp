import Foundation
import FirebaseStorage
import UIKit

final class ServiceImageUploader {

    static let shared = ServiceImageUploader()
    private init() {}

    func upload(images: [UIImage], barberId: String, completion: @escaping ([String]) -> Void) {

        guard !images.isEmpty else {
            completion([])
            return
        }

        var urls: [String] = []
        let group = DispatchGroup()

        for image in images {

            guard let data = image.jpegData(compressionQuality: 0.7) else { continue }

            group.enter()

            let filename = UUID().uuidString + ".jpg"
            let ref = Storage.storage().reference()
                .child("services")
                .child(barberId)
                .child(filename)

            ref.putData(data, metadata: nil) { _, error in
                if error != nil {
                    group.leave()
                    return
                }

                ref.downloadURL { url, _ in
                    if let url = url {
                        urls.append(url.absoluteString)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(urls)
        }
    }
}
