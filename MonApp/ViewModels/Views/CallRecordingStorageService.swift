//
//  CallRecordingStorageService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 24/06/2026.
//

import Foundation
import FirebaseStorage
import FirebaseFirestore

final class CallRecordingStorageService {
    
    static let shared = CallRecordingStorageService()
    
    private init() {}
    
    func uploadRecordingFile(
        localFileURL: URL,
        recordingId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let storagePath = "callRecordings/\(recordingId)/recording.mp4"
        
        let storageRef = Storage.storage().reference().child(storagePath)
        
        storageRef.putFile(from: localFileURL, metadata: nil) { _, error in
            if let error = error {
                print("❌ Upload recording error:", error.localizedDescription)
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ DownloadURL recording error:", error.localizedDescription)
                    completion(.failure(error))
                    return
                }
                
                guard let url = url else {
                    completion(.failure(NSError(
                        domain: "CallRecordingStorageService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "URL Firebase Storage introuvable"]
                    )))
                    return
                }
                
                Firestore.firestore()
                    .collection("callRecordings")
                    .document(recordingId)
                    .setData([
                        "storagePath": storagePath,
                        "downloadURL": url.absoluteString,
                        "status": "available",
                        "uploadedAt": FieldValue.serverTimestamp()
                    ], merge: true)
                
                print("✅ Enregistrement uploadé:", url.absoluteString)
                completion(.success(url.absoluteString))
            }
        }
    }
    func createTestRecordingFile() -> URL? {
        let text = "Test enregistrement appel Cutly"
        let fileName = "test_recording.mp4"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try text.data(using: .utf8)?.write(to: url)
            print("✅ Fichier test créé:", url.path)
            return url
        } catch {
            print("❌ Création fichier test impossible:", error.localizedDescription)
            return nil
        }
    }
    
    
    
}
