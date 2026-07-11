//
//  MarketplaceStorageService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import Foundation
import FirebaseStorage
import UIKit

final class MarketplaceStorageService {
    
    static let shared = MarketplaceStorageService()
    
    private let storage = Storage.storage()
    
    private init() {}
    
    enum Folder {
        static let root = "marketplace"
        
        static let products = "marketplace/products"
        static let productVideos = "marketplace/product_videos"
        static let stores = "marketplace/stores"
        static let profiles = "marketplace/profiles"
        static let reviews = "marketplace/reviews"
        static let messages = "marketplace/messages"
        static let deliveryProofs = "marketplace/delivery_proofs"
        static let disputes = "marketplace/disputes"
        static let support = "marketplace/support"
        static let legal = "marketplace/legal"
    }
    
    enum MarketplaceStorageError: LocalizedError {
        case invalidImageData
        case invalidVideoData
        
        var errorDescription: String? {
            switch self {
            case .invalidImageData:
                return "Impossible de convertir l’image."
            case .invalidVideoData:
                return "Impossible de lire la vidéo."
            }
        }
    }
    
    // MARK: - Upload Image
    
    func uploadImage(
        _ image: UIImage,
        folder: String,
        fileName: String = UUID().uuidString,
        compressionQuality: CGFloat = 0.82
    ) async throws -> String {
        
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw MarketplaceStorageError.invalidImageData
        }
        
        let path = "\(folder)/\(fileName).jpg"
        let ref = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "module": "marketplace",
            "createdAutomatically": "true"
        ]
        
        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL().absoluteString
    }
    
    // MARK: - Upload Video
    
    func uploadVideo(
        fileURL: URL,
        folder: String,
        fileName: String = UUID().uuidString
    ) async throws -> String {
        
        let path = "\(folder)/\(fileName).mp4"
        let ref = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        metadata.customMetadata = [
            "module": "marketplace",
            "createdAutomatically": "true"
        ]
        
        _ = try await ref.putFileAsync(from: fileURL, metadata: metadata)
        return try await ref.downloadURL().absoluteString
    }
    
    // MARK: - Product Media
    
    func uploadProductImage(
        _ image: UIImage,
        productId: String
    ) async throws -> String {
        try await uploadImage(
            image,
            folder: "\(Folder.products)/\(productId)"
        )
    }
    
    func uploadProductVideo(
        fileURL: URL,
        productId: String
    ) async throws -> String {
        try await uploadVideo(
            fileURL: fileURL,
            folder: "\(Folder.productVideos)/\(productId)"
        )
    }
    
    // MARK: - Store / Profile
    
    func uploadStoreImage(
        _ image: UIImage,
        storeId: String
    ) async throws -> String {
        try await uploadImage(
            image,
            folder: "\(Folder.stores)/\(storeId)"
        )
    }
    
    func uploadProfileImage(
        _ image: UIImage,
        userId: String
    ) async throws -> String {
        try await uploadImage(
            image,
            folder: "\(Folder.profiles)/\(userId)"
        )
    }
    
    // MARK: - Reviews / Messages
    
    func uploadReviewImage(
        _ image: UIImage,
        reviewId: String
    ) async throws -> String {
        try await uploadImage(
            image,
            folder: "\(Folder.reviews)/\(reviewId)"
        )
    }
    
    func uploadMessageImage(
        _ image: UIImage,
        conversationId: String
    ) async throws -> String {
        try await uploadImage(
            image,
            folder: "\(Folder.messages)/\(conversationId)"
        )
    }
    
    // MARK: - Proofs / Disputes / Support
    
    func uploadDeliveryProofImage(
        _ image: UIImage,
        orderId: String
    ) async throws -> String {
        try await uploadImage(
            image,
            folder: "\(Folder.deliveryProofs)/\(orderId)"
        )
    }
    
    func uploadDisputeEvidenceImage(
        _ image: UIImage,
        disputeId: String
    ) async throws -> String {
        try await uploadImage(
            image,
            folder: "\(Folder.disputes)/\(disputeId)"
        )
    }
    
    func uploadSupportAttachmentImage(
        _ image: UIImage,
        ticketId: String
    ) async throws -> String {
        try await uploadImage(
            image,
            folder: "\(Folder.support)/\(ticketId)"
        )
    }
    
    // MARK: - Delete
    
    func deleteFile(from downloadURL: String) async throws {
        let ref = storage.reference(forURL: downloadURL)
        try await ref.delete()
    }
    // MARK: - Multiple Uploads

    func uploadProductImages(
        _ images: [UIImage],
        productId: String
    ) async throws -> [String] {
        var urls: [String] = []

        for image in images {
            let url = try await uploadProductImage(image, productId: productId)
            urls.append(url)
        }

        return urls
    }

    func uploadReviewImages(
        _ images: [UIImage],
        reviewId: String
    ) async throws -> [String] {
        var urls: [String] = []

        for image in images {
            let url = try await uploadReviewImage(image, reviewId: reviewId)
            urls.append(url)
        }

        return urls
    }

    func uploadDisputeEvidenceImages(
        _ images: [UIImage],
        disputeId: String
    ) async throws -> [String] {
        var urls: [String] = []

        for image in images {
            let url = try await uploadDisputeEvidenceImage(image, disputeId: disputeId)
            urls.append(url)
        }

        return urls
    }

    // MARK: - Generic File Upload

    func uploadFileData(
        data: Data,
        folder: String,
        fileName: String = UUID().uuidString,
        fileExtension: String,
        contentType: String
    ) async throws -> String {
        let path = "\(folder)/\(fileName).\(fileExtension)"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = contentType
        metadata.customMetadata = [
            "module": "marketplace",
            "createdAutomatically": "true"
        ]

        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL().absoluteString
    }

    func uploadPDF(
        data: Data,
        folder: String,
        fileName: String = UUID().uuidString
    ) async throws -> String {
        try await uploadFileData(
            data: data,
            folder: folder,
            fileName: fileName,
            fileExtension: "pdf",
            contentType: "application/pdf"
        )
    }

    func uploadLegalDocumentPDF(
        data: Data,
        documentId: String
    ) async throws -> String {
        try await uploadPDF(
            data: data,
            folder: "\(Folder.legal)/\(documentId)"
        )
    }

    func uploadSupportAttachmentPDF(
        data: Data,
        ticketId: String
    ) async throws -> String {
        try await uploadPDF(
            data: data,
            folder: "\(Folder.support)/\(ticketId)"
        )
    }

    // MARK: - Path Helpers

    func storagePath(
        folder: String,
        fileName: String,
        fileExtension: String
    ) -> String {
        "\(folder)/\(fileName).\(fileExtension)"
    }

    func uniqueFileName(prefix: String? = nil) -> String {
        let base = UUID().uuidString
        if let prefix, !prefix.isEmpty {
            return "\(prefix)_\(base)"
        }
        return base
    }
    
    
    
    
    
    
    
}
