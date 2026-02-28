import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class BarberServiceManager: ObservableObject {
    
    @Published var barbers: [Barber] = []
    
    private let db = Firestore.firestore()
    
    func fetchBarbers() {
        db.collection("barbers").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Erreur Firestore :", error.localizedDescription)
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.barbers = documents.compactMap { doc -> Barber? in
                try? doc.data(as: Barber.self)
            }
        }
    }
}
