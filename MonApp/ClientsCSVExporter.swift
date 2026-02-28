import Foundation
import FirebaseFirestore

// Génère un fichier CSV contenant tous les clients
func generateClientsCSV(completion: @escaping (URL?) -> Void) {

    let db = Firestore.firestore()

    db.collection("users")
        .whereField("role", isEqualTo: "client")
        .getDocuments { snapshot, error in

            guard let documents = snapshot?.documents else {
                print("❌ Impossible de récupérer les clients")
                completion(nil)
                return
            }

            print("✅ \(documents.count) clients trouvés")

            var csv = "Nom,Email,Telephone\n"

            for doc in documents {

                let data = doc.data()

                let name = data["name"] as? String ?? "Sans nom"
                let email = data["email"] as? String ?? "Sans email"
                let phone = data["phone"] as? String ?? "Sans téléphone"

                csv += "\(name),\(email),\(phone)\n"
            }

            let fileName = "clients.csv"
            let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            do {
                try csv.write(to: path, atomically: true, encoding: .utf8)
                print("📄 CSV créé :", path)
                completion(path)
            } catch {
                print("❌ Erreur écriture CSV:", error)
                completion(nil)
            }
        }
}
