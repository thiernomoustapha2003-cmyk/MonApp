import Foundation
import FirebaseFirestore

struct LoginEvent: Identifiable {
    var id: String
    var email: String
    var device: String
    var platform: String
    var date: Date
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard
            let email = data["email"] as? String,
            let device = data["device"] as? String,
            let platform = data["platform"] as? String,
            let timestamp = data["date"] as? Timestamp
        else { return nil }
        
        self.id = document.documentID
        self.email = email
        self.device = device
        self.platform = platform
        self.date = timestamp.dateValue()
    }
}
