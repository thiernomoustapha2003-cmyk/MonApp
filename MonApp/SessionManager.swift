import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

class SessionManager {
    
    static let shared = SessionManager()
    private let db = Firestore.firestore()
    private let sessionKey = "sessionVersion"
    
    private init() {}
    
    // MARK: - Enregistrer appareil après login
    func registerSecureSession() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = db.collection("users").document(uid)
        
        ref.getDocument { snapshot, _ in
            let version = snapshot?.data()?["sessionVersion"] as? Int ?? 1
            self.saveLocalSessionVersion(version)
            self.startSessionListener()
        }
    }
    
    // MARK: - Listener déconnexion forcée
    private func startSessionListener() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid)
            .addSnapshotListener { snapshot, _ in
                
                guard
                    let data = snapshot?.data(),
                    let remoteVersion = data["sessionVersion"] as? Int
                else { return }
                
                let localVersion = self.getLocalSessionVersion()
                
                if remoteVersion != localVersion {
                    print("🚨 Déconnecté depuis un autre appareil")
                    try? Auth.auth().signOut()
                }
            }
    }
    
    // MARK: - Bouton : déconnecter tous les appareils
    func logoutFromAllDevices() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(uid)
            .updateData([
                "sessionVersion": FieldValue.increment(Int64(1))
            ]) { error in
                
                if let error = error {
                    print("Erreur invalidation session:", error.localizedDescription)
                    return
                }
                
                do {
                    try Auth.auth().signOut()
                    print("Déconnecté partout")
                } catch {
                    print("Erreur signOut:", error.localizedDescription)
                }
            }
    }
    
    // MARK: - Local cache
    private func saveLocalSessionVersion(_ version: Int) {
        UserDefaults.standard.set(version, forKey: sessionKey)
    }
    
    private func getLocalSessionVersion() -> Int {
        UserDefaults.standard.integer(forKey: sessionKey)
    }
    // Bouton "déconnecter tous les appareils"
    func forceLogoutAllDevices() async throws {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        let ref = db.collection("users").document(uid)

        try await ref.updateData([
            "sessionVersion": FieldValue.increment(Int64(1))
        ])

        try Auth.auth().signOut()
    }

}

