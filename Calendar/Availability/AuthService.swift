import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    // Inscrire un coiffeur -> crée l'utilisateur Firebase Auth puis enregistre le profil "barber"
    func registerBarber(name: String, email: String, password: String, phone: String?, address: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let uid = result?.user.uid else {
                completion(.failure(NSError(domain:"Auth", code:0, userInfo:[NSLocalizedDescriptionKey:"UID manquant"])))
                return
            }
            let docData: [String: Any] = [
                "uid": uid,
                "name": name,
                "email": email,
                "role": "barber",
                "phone": phone ?? "",
                "address": address ?? "",
                "createdAt": FieldValue.serverTimestamp()
            ]
            self.db.collection("barbers").document(uid).setData(docData) { err in
                if let err = err { completion(.failure(err)); return }
                completion(.success(()))
            }
        }
    }

    // Connexion simple (si tu veux la réutiliser)
    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(()))
        }
    }
}
