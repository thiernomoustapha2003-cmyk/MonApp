import Foundation
import FirebaseFirestore

class BarberService {

    private let db = Firestore.firestore()

    func fetchBarbers(completion: @escaping ([Barber]) -> Void) {
        db.collection("users")
            .whereField("role", isEqualTo: "coiffeur")
            .whereField("profileCompleted", isEqualTo: true)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Erreur Firestore users/coiffeurs:", error.localizedDescription)
                    completion([])
                    return
                }

                var barbers: [Barber] = []

                snapshot?.documents.forEach { doc in
                    let data = doc.data()

                    let barber = Barber(
                        id: doc.documentID,
                        authId: doc.documentID,
                        name: data["fullName"] as? String ?? data["name"] as? String ?? "",
                        city: data["city"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        price: data["price"] as? Double ?? 0.0,

                        street: data["streetAddress"] as? String ?? data["street"] as? String ?? "",
                        houseNumber: data["buildingNumber"] as? String ?? data["houseNumber"] as? String ?? "",
                        postalCode: data["postalCode"] as? String ?? "",
                        phone: data["phone"] as? String ?? "",

                        latitude: data["latitude"] as? Double ?? 0.0,
                        longitude: data["longitude"] as? Double ?? 0.0,

                        services: data["services"] as? [String] ?? [],
                        imageUrl: data["imageUrl"] as? String,
                        isFavorite: data["isFavorite"] as? Bool ?? false
                    )

                    barbers.append(barber)
                }

                completion(barbers)
            }
    }
}
