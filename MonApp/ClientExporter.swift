import Foundation
import FirebaseFirestore

class ClientExporter {

    static func generateClientsCSV(completion: @escaping (URL?) -> Void) {

        let db = Firestore.firestore()

        db.collection("users")
            .whereField("role", isEqualTo: "client")
            .getDocuments { snapshot, error in

                guard let documents = snapshot?.documents else {
                    completion(nil)
                    return
                }

                var csv = "Nom,Email,Telephone\n"

                for doc in documents {

                    let data = doc.data()

                    let name = data["name"] as? String ?? "Inconnu"
                    let email = data["email"] as? String ?? ""
                    let phone = data["phone"] as? String ?? ""

                    csv += "\"\(name)\",\"\(email)\",\"\(phone)\"\n"
                }

                let path = FileManager.default.temporaryDirectory
                    .appendingPathComponent("clients.csv")

                do {
                    try csv.write(to: path, atomically: true, encoding: .utf8)
                    completion(path)
                } catch {
                    print("Erreur écriture CSV:", error)
                    completion(nil)
                }
            }
    }
}
