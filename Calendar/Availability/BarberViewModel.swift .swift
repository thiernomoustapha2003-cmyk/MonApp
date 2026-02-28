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

                let barber = Barber(
                    id: doc.documentID,
                    name: name,
                    city: city,
                    description: description,
                    price: price,
                    street: street,
                    houseNumber: houseNumber,
                    postalCode: postalCode,
                    phone: phone,
                    latitude: 48.8566,   // 📍 Paris par défaut (temporaire)
                    longitude: 2.3522,
                    services: services,
                    imageUrl: imageUrl,
                    isFavorite: isFavorite
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
                            // ✅ On met à jour proprement (copie du tableau)
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
