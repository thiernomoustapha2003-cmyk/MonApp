import Foundation
import FirebaseFirestore

class BarberService {

    private let db = Firestore.firestore()

    func fetchBarbers(completion: @escaping ([Barber]) -> Void) {
        db.collection("barbers").getDocuments { snapshot, error in
            
            if let error = error {
                print("❌ Erreur Firestore barbers:", error.localizedDescription)
                completion([])
                return
            }

            var barbers: [Barber] = []

            snapshot?.documents.forEach { doc in
                let data = doc.data()
                
                let authId = data["authId"] as? String ?? doc.documentID

                let barber = Barber(
                    id: doc.documentID,
                    authId: authId,
                    name: data["name"] as? String ?? "",
                    city: data["city"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    price: data["price"] as? Double ?? 0.0,

                    street: data["street"] as? String ?? "",
                    houseNumber: data["houseNumber"] as? String ?? "",
                    postalCode: data["postalCode"] as? String ?? "",
                    phone: data["phone"] as? String ?? "",

                    latitude: data["latitude"] as? Double ?? 0.0,
                    longitude: data["longitude"] as? Double ?? 0.0,

                    services: data["services"] as? [String] ?? [],
                    imageUrl: data["imageUrl"] as? String ?? nil,
                    isFavorite: data["isFavorite"] as? Bool ?? false
                )

                barbers.append(barber)
            }

            completion(barbers)
        }
    }
}
