import Foundation
import FirebaseFirestore

// ✅ Modèle principal du coiffeur
struct Barber: Identifiable, Codable {
    
    var id: String   // id du document Firestore
    
    var name: String
    var city: String
    var description: String
    var photoURL: String
    
    var latitude: Double
    var longitude: Double
    
    // ✅ Liste des services avec prix
    var services: [BarberService]
}

// ✅ Modèle d’un service (prix détaillé)
struct BarberService: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var minPrice: Double
    var maxPrice: Double
}
