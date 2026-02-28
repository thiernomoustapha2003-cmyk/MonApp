import Foundation
import AVFoundation
import FirebaseStorage

final class VideoUploadService {

    static let shared = VideoUploadService()
    private init() {}

    // public entry: convert->upload then return URL string in completion
    func uploadVideo(originalURL: URL, completion: @escaping (String?) -> Void) {

        convertToMP4(inputURL: originalURL) { mp4URL in
            guard let mp4URL = mp4URL else {
                completion(nil)
                return
            }
            self.uploadFile(fileURL: mp4URL, completion: completion)
        }
    }
}

// MARK: - CONVERT TO MP4
private extension VideoUploadService {

    func convertToMP4(inputURL: URL, completion: @escaping (URL?) -> Void) {

        let asset = AVURLAsset(url: inputURL)
        // Use a reasonable preset (1080p) to reduce file size but keep quality.
        let preset = AVAssetExportPreset1920x1080

        guard let export = AVAssetExportSession(asset: asset, presetName: preset) else {
            completion(nil)
            return
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mp4")

        export.outputURL = outputURL
        export.outputFileType = .mp4
        export.shouldOptimizeForNetworkUse = true

        export.exportAsynchronously {
            DispatchQueue.main.async {
                if export.status == .completed {
                    print("🎬 CONVERSION MP4 OK ->", outputURL)
                    completion(outputURL)
                } else {
                    print("❌ CONVERSION FAILED:", export.error?.localizedDescription ?? "unknown")
                    completion(nil)
                }
            }
        }
    }
}

// MARK: - UPLOAD
private extension VideoUploadService {

    func uploadFile(fileURL: URL, completion: @escaping (String?) -> Void) {

        let filename = UUID().uuidString + ".mp4"
        let ref = Storage.storage().reference().child("posts/videos/\(filename)")

        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"

        // Use putFile to upload from disk (good for large files)
        ref.putFile(from: fileURL, metadata: metadata) { meta, error in
            if let error = error {
                print("❌ UPLOAD ERROR:", error.localizedDescription)
                completion(nil)
                return
            }
            ref.downloadURL { url, err in
                if let url = url {
                    print("✅ FIREBASE URL:", url.absoluteString)
                    completion(url.absoluteString)
                } else {
                    print("❌ downloadURL error:", err?.localizedDescription ?? "")
                    completion(nil)
                }
            }
        }
    }
}
