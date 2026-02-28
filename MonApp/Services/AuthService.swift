import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    // ✅ INSCRIPTION COIFFEUR (ALIGNÉE AVEC TON PROJET)
    func registerBarber(
        name: String,
        email: String,
        password: String,
        phone: String?,
        address: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let uid = result?.user.uid else {
                completion(.failure(
                    NSError(domain: "Auth", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "UID manquant"
                    ])
                ))
                return
            }

            // ✅ ON ÉCRIT DANS "users" (COMME RegisterView)
            let docData: [String: Any] = [
                "uid": uid,
                "name": name,
                "email": email,
                "role": "coiffeur",
                "phone": phone ?? "",
                "address": address ?? "",
                "createdAt": FieldValue.serverTimestamp(),

                // 🔥 IMPORTANT POUR TON APP
                "isPro": false,
                "isCertified": false,
                "platformCommissionRate": 0.15
            ]

            self.db.collection("users").document(uid).setData(docData) { err in
                if let err = err {
                    completion(.failure(err))
                    return
                }

                // ✅ On renvoie l'uid pour la suite (BarberRegisterView)
                completion(.success(uid))
            }
        }
    }

    // ✅ Connexion simple (tu peux garder)
    func signIn(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        auth.signIn(withEmail: email, password: password) { _, error in
            if let e = error {
                completion(.failure(e))
                return
            }
            completion(.success(()))
        }
    }
}
