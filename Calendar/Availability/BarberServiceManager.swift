import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class BarberServiceManager: ObservableObject {
    
    @Published var barbers: [Barber] = []
    
    private let db = Firestore.firestore()
    
    init() {
        fetchBarbers()
    }
    
    func fetchBarbers() {
        db.collection("barbers").addSnapshotListener { snapshot, error in
            
            if let error = error {
                print("❌ Erreur Firestore :", error.localizedDescription)
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("⚠️ Aucun document trouvé")
                return
            }
            
            self.barbers = documents.compactMap { doc -> Barber? in
                do {
                    return try doc.data(as: Barber.self)
                } catch {
                    print("❌ Erreur décodage Barber :", error.localizedDescription)
                    return nil
                }
            }
            
            print("✅ Coiffeurs chargés :", self.barbers.count)
        }
    }
}
