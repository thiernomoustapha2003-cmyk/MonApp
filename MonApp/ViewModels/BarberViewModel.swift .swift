import SwiftUI
import FirebaseFirestore
import CoreLocation
import Combine

class BarberViewModel: ObservableObject {

    @Published var barbers: [Barber] = []
    @Published var isLoading: Bool = true

    private let db = Firestore.firestore()
    private let geocoder = CLGeocoder()

    func fetchBarbers() {

        isLoading = true
        print("📡 Début du chargement des coiffeurs...")

        db.collection("barbers").getDocuments { snapshot, error in

            if let error = error {
                print("❌ Erreur Firestore:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            guard let documents = snapshot?.documents else {
                print("⚠️ Aucun document trouvé dans barbers")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            print("📄 \(documents.count) documents trouvés dans Firestore")

            var loadedBarbers: [Barber] = []

            // 1️⃣ CRÉATION RAPIDE DES COIFFEURS (SANS BLOQUER L’UI)
            for doc in documents {

                let data = doc.data()

                let authId = data["authId"] as? String ?? ""
                let name = data["name"] as? String ?? ""
                let description = data["description"] as? String ?? ""
                let price = data["price"] as? Double ?? 0
                let street = data["street"] as? String ?? ""
                let houseNumber = data["houseNumber"] as? String ?? ""
                let postalCode = data["postalCode"] as? String ?? ""
                let city = data["city"] as? String ?? ""
                let phone = data["phone"] as? String ?? ""
                let imageUrl = data["imageUrl"] as? String
                let services = data["services"] as? [String] ?? []
                let isFavorite = data["isFavorite"] as? Bool ?? false

                // 🔹 IMPORTANT : id = documentID (c’est ce qu’on utilise pour les slots)
                let barber = Barber(
                    id: doc.documentID,   // ✅ CLÉ : ID DOCUMENT FIRESTORE
                    authId: authId,       // ✅ Gardé pour d’autres usages (dashboard, etc.)
                    name: name,
                    city: city,
                    description: description,
                    price: price,

                    street: street,
                    houseNumber: houseNumber,
                    postalCode: postalCode,
                    phone: phone,
                    latitude: 48.8566,   // Valeur temporaire
                    longitude: 2.3522,   // Valeur temporaire
                    services: services,
                    imageUrl: imageUrl,
                    isFavorite: isFavorite,

                    // 🔽 Valeurs par défaut (pour éviter les crashs)
                    isPro: data["isPro"] as? Bool ?? false,
                    isCertified: data["isCertified"] as? Bool ?? false,
                    acceptsOnlinePayment: data["acceptsOnlinePayment"] as? Bool ?? false,
                    platformCommissionRate: data["platformCommissionRate"] as? Double ?? 0.15,
                    stripeAccountId: data["stripeAccountId"] as? String,
                    payoutEnabled: data["payoutEnabled"] as? Bool ?? false,

                    averageRating: data["averageRating"] as? Double ?? 0.0,
                    totalReviews: data["totalReviews"] as? Int ?? 0,
                    isCurrentlyAvailable: data["isCurrentlyAvailable"] as? Bool ?? true
                )

                loadedBarbers.append(barber)
            }

            // 2️⃣ ON AFFICHE IMMÉDIATEMENT LA LISTE (très important)
            DispatchQueue.main.async {
                self.barbers = loadedBarbers
                self.isLoading = false
                print("✅ Liste affichée : \(loadedBarbers.count) coiffeurs")
            }

            // 3️⃣ GÉOCODAGE APRÈS (SANS BLOQUER L’UI)
            for index in 0..<loadedBarbers.count {

                let fullAddress = """
                \(loadedBarbers[index].street) \
                \(loadedBarbers[index].houseNumber), \
                \(loadedBarbers[index].postalCode) \
                \(loadedBarbers[index].city), France
                """

                self.geocoder.geocodeAddressString(fullAddress) { placemarks, _ in

                    if let coordinate = placemarks?.first?.location?.coordinate {

                        DispatchQueue.main.async {
                            var updatedBarbers = self.barbers
                            updatedBarbers[index].latitude = coordinate.latitude
                            updatedBarbers[index].longitude = coordinate.longitude
                            self.barbers = updatedBarbers
                        }
                    } else {
                        print("⚠️ Géocodage échoué pour : \(fullAddress)")
                    }
                }
            }
        }
    }
}
