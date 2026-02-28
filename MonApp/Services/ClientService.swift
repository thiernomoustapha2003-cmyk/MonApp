import FirebaseFirestore
import FirebaseAuth

class ClientService {
    
    private let db = Firestore.firestore()
    
    func fetchClients(completion: @escaping ([Client]) -> Void) {
        guard let barberId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("barbers")
            .document(barberId)
            .collection("clients")
            .getDocuments { snapshot, _ in
                
                guard let docs = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let clients = docs.compactMap { doc in
                    try? doc.data(as: Client.self)
                }
                
                completion(clients)
            }
    }
    
    func blacklistClient(clientId: String, value: Bool) {
        guard let barberId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("barbers")
            .document(barberId)
            .collection("clients")
            .document(clientId)
            .updateData([
                "isBlacklisted": value
            ])
    }
}
