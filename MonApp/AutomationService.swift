import Foundation
import FirebaseFirestore
import FirebaseAuth

class AutomationService {
    
    private let db = Firestore.firestore()
    
    func saveSettings(_ settings: AutomationSettings) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            try db.collection("users")
                .document(uid)
                .collection("automation")
                .document("settings")
                .setData(from: settings)
            
            print("✅ Automatisations sauvegardées")
            
        } catch {
            print("❌ Erreur sauvegarde automation:", error)
        }
    }
    
    func loadSettings(completion: @escaping (AutomationSettings) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(uid)
            .collection("automation")
            .document("settings")
            .getDocument { snap, _ in
                
                if let data = try? snap?.data(as: AutomationSettings.self) {
                    completion(data)
                } else {
                    completion(AutomationSettings())
                }
            }
    }
}
