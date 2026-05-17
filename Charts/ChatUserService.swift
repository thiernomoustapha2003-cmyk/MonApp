import FirebaseFirestore
import FirebaseAuth

class ChatUserService {

    static func fetchOtherUserName(conversationId: String, completion: @escaping (String) -> Void) {

        guard let myUid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()

        db.collection("conversations")
            .document(conversationId)
            .getDocument { snap, _ in

                guard let data = snap?.data(),
                      let participants = data["participants"] as? [String] else { return }

                // Trouver l'autre personne
                guard let otherUid = participants.first(where: { $0 != myUid }) else { return }

                // Aller chercher son profil
                db.collection("users")
                    .document(otherUid)
                    .getDocument { userSnap, _ in

                        let name = userSnap?.data()?["name"] as? String ?? "Utilisateur"
                        completion(name)
                    }
            }
    }
}
