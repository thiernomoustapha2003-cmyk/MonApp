import Foundation
import FirebaseFirestore
import FirebaseFirestore

final class SoundService {
    
    static let shared = SoundService()
    private let db = Firestore.firestore()
    
    // 🔹 Create sound
    func createSound(audioURL: String, title: String, creatorId: String) {
        
        let sound = Sound(
            audioURL: audioURL,
            creatorId: creatorId,
            title: title,
            usageCount: 0,
            totalViews: 0,
            totalRevenue: 0,
            createdAt: Date()
        )
        
        do {
            _ = try db.collection("sounds").addDocument(from: sound)
        } catch {
            print("❌ Sound creation error:", error)
        }
    }
    
    // 🔹 Increment usage
    func incrementUsage(soundId: String) {
        db.collection("sounds")
            .document(soundId)
            .updateData([
                "usageCount": FieldValue.increment(Int64(1))
            ])
    }
    
    // 🔹 Add views + calculate revenue
    func addViews(soundId: String, views: Int) {
        
        let revenuePerView = 0.0001 // 🔥 ton modèle économique
        
        let revenue = Double(views) * revenuePerView
        
        db.collection("sounds")
            .document(soundId)
            .updateData([
                "totalViews": FieldValue.increment(Int64(views)),
                "totalRevenue": FieldValue.increment(revenue)
            ])
    }
}
