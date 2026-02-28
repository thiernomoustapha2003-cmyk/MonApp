import Foundation
import FirebaseFirestore
import FirebaseAuth

class AvailabilityService {

    private let db = Firestore.firestore()

    // =====================================================
    // MARK: - CRÉER / METTRE À JOUR DES CRÉNEAUX (VERSION CORRIGÉE)
    // =====================================================
    /// Crée ou met à jour plusieurs créneaux dans la collection **slots**
    func createSlots(
        slots: [AvailabilitySlot],
        completion: @escaping (Bool) -> Void
    ) {
        let batch = db.batch()

        // 🔹 IMPORTANT : on utilise l'AUTH UID du coiffeur
        guard let barberAuthId = Auth.auth().currentUser?.uid else {
            print("❌ ERREUR: Aucun utilisateur connecté")
            completion(false)
            return
        }

        for slot in slots {

            // On garde l’ID si déjà existant, sinon on en génère un
            let docId = slot.id ?? UUID().uuidString

            let ref = db
                .collection("slots")
                .document(docId)

            let data: [String: Any] = [
                // ⚠️ ON NE MET PAS "id" DANS LES DONNÉES (Firestore le gère avec @DocumentID)
                "barberId": barberAuthId,   // 🔥 CLÉ CRUCIALE (DOIT MATCHER LE FILTRE CLIENT)
                "date": Timestamp(date: slot.date),
                "startTime": Timestamp(date: slot.startTime),
                "endTime": Timestamp(date: slot.endTime),
                "status": slot.status.rawValue,
                "createdAt": Timestamp(date: Date())
            ]

            batch.setData(data, forDocument: ref, merge: true)
        }

        batch.commit { error in
            if let error = error {
                print("❌ ERREUR création créneaux :", error.localizedDescription)
                completion(false)
            } else {
                print("✅ TOUS LES CRÉNEAUX ENREGISTRÉS (collection: slots)")
                completion(true)
            }
        }
    }

    // =====================================================
    // MARK: - SUPPRIMER TOUS LES CRÉNEAUX D’UN BARBER
    // =====================================================
    /// Supprime tous les créneaux d’un barber donné (par son AUTH ID)
    func deleteAllSlots(for barberAuthId: String, completion: @escaping (Bool) -> Void) {

        db.collection("slots")
            .whereField("barberId", isEqualTo: barberAuthId)
            .getDocuments { snapshot, error in

                if let error = error {
                    print("❌ Erreur suppression slots :", error.localizedDescription)
                    completion(false)
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("⚠️ Aucun slot à supprimer pour ce barber")
                    completion(true)
                    return
                }

                let batch = self.db.batch()

                documents.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }

                batch.commit { err in
                    if let err = err {
                        print("❌ Erreur batch delete :", err.localizedDescription)
                        completion(false)
                    } else {
                        print("✅ Tous les slots supprimés pour barber \(barberAuthId)")
                        completion(true)
                    }
                }
            }
    }
}
