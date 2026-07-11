//
//  MarketplaceProfileService.swift .swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class MarketplaceProfileService {

    static let shared = MarketplaceProfileService()

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    private var uid: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - Lire profil

    func fetchMarketplaceProfile() async throws -> MarketplaceUserProfile? {
        guard let uid else { return nil }

        let doc = try await db.collection("marketplaceUsers")
            .document(uid)
            .getDocument()

        guard doc.exists else { return nil }
        return try doc.data(as: MarketplaceUserProfile.self)
    }

    func reloadProfile() async throws -> MarketplaceUserProfile? {
        try await fetchMarketplaceProfile()
    }

    // MARK: - Étape 1

    func saveStepOne(
        displayName: String,
        email: String,
        phone: String,
        countryCode: String,
        addressLine: String,
        postalCode: String,
        city: String,
        profileType: MarketplaceProfileType
    ) async throws {
        guard let uid else { return }

        try await db.collection("marketplaceUsers")
            .document(uid)
            .setData([
                "uid": uid,
                "displayName": displayName,

                "email": email,
                "contactEmail": email,
                "sellerEmail": email,

                "phone": phone,
                "sellerPhone": phone,
                "buyerPhone": phone,
                "countryCode": countryCode,

                "addressLine": addressLine,
                "postalCode": postalCode,
                "city": city,
                "fullAddress": [addressLine, postalCode, city]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", "),

                "profileType": profileType.rawValue,

                "buyerEnabled": true,
                "sellerEnabled": profileType != .personal,

                "profileCompleted": false,
                "currentStep": 1,

                "publicProfileVisible": true,
                "ratingAverage": 0.0,
                "ratingCount": 0,
                "salesCount": 0,
                "purchasesCount": 0,

                "updatedAt": FieldValue.serverTimestamp(),
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    // MARK: - Photo profil

    func uploadProfilePhoto(imageData: Data) async throws -> String {
        guard let uid else { throw NSError(domain: "Auth", code: 401) }

        let ref = storage.reference()
            .child("marketplaceProfiles")
            .child(uid)
            .child("profile.jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()

        try await db.collection("marketplaceUsers")
            .document(uid)
            .setData([
                "photoURL": url.absoluteString,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)

        return url.absoluteString
    }

    // MARK: - Étape 2

    func saveLocation(
        country: String,
        city: String,
        language: String,
        currency: String
    ) async throws {
        guard let uid else { return }

        try await db.collection("marketplaceUsers")
            .document(uid)
            .setData([
                "country": country,
                "city": city,
                "language": language,
                "currency": currency,
                "currentStep": 2,
                "locationCompleted": true,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    // MARK: - Étape 3

    func savePaymentMethod(method: String) async throws {
        guard let uid else { return }

        try await db.collection("marketplaceUsers")
            .document(uid)
            .setData([
                "paymentMethod": method,
                "paymentCompleted": false,
                "paymentVerified": false,
                "paymentStatus": "pending_verification",
                "currentStep": 3,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    // MARK: - Étape 4

    func saveVerification(method: MarketplaceVerificationMethod) async throws {
        guard let uid else { return }

        try await db.collection("marketplaceUsers")
            .document(uid)
            .setData([
                "marketplaceVerified": true,
                "verificationMethod": method.rawValue,
                "verifiedAt": FieldValue.serverTimestamp(),
                "currentStep": 4,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    // MARK: - Finalisation

    func completeProfile() async throws {
        guard let uid else { return }

        try await db.collection("marketplaceUsers")
            .document(uid)
            .setData([
                "profileCompleted": true,
                "currentStep": 5,
                "completedAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }
}

// MARK: - Model

struct MarketplaceUserProfile: Codable, Identifiable {
    @DocumentID var id: String?

    var uid: String?

    var displayName: String?
    var photoURL: String?

    var phone: String?
    var countryCode: String?
    var email: String?

    var profileType: String?

    var country: String?
    var city: String?
    var language: String?
    var currency: String?

    var profileCompleted: Bool?
    var marketplaceVerified: Bool?
    var verificationMethod: String?

    var paymentMethod: String?
    var paymentCompleted: Bool?
    var paymentVerified: Bool?
    var paymentStatus: String?

    var buyerEnabled: Bool?
    var sellerEnabled: Bool?
    var publicProfileVisible: Bool?

    var ratingAverage: Double?
    var ratingCount: Int?
    var salesCount: Int?
    var purchasesCount: Int?

    var currentStep: Int?
    var badgeVisible: Bool?
    var certificationStatus: String?
    var certificationPlan: String?
    
    var contactEmail: String?
    var sellerEmail: String?
    var sellerPhone: String?
    var buyerPhone: String?
    var addressLine: String?
    var postalCode: String?
    var fullAddress: String?
    
    
}
