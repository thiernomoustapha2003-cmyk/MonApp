import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

struct Donator: Identifiable {
    var id: String
    var name: String
    var coins: Int
}

class LiveAnalyticsViewModel: ObservableObject {
    
    @Published var viewers = 0
    @Published var likes = 0
    @Published var comments = 0
    @Published var shares = 0
    @Published var duration = 0
    @Published var newFollowers = 0
    
    @Published var diamonds = 0
    @Published var missionRewards = 0.0
    @Published var weeklyRewards = 0.0
    
    @Published var liveStep = 1
    @Published var pointsNeeded = 4
    
    @Published var campaignCount = 0
    
    @Published var topDonators: [Donator] = []
    
    private let db = Firestore.firestore()
    
    func listenLiveData() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // LIVE DATA
        db.collection("lives")
            .whereField("barberId", isEqualTo: userId)
            .whereField("isLive", isEqualTo: true)
            .addSnapshotListener { snapshot, _ in
                
                guard let doc = snapshot?.documents.first else { return }
                let data = doc.data()
                
                DispatchQueue.main.async {
                    self.viewers = data["viewers"] as? Int ?? 0
                    self.likes = data["likes"] as? Int ?? 0
                    self.comments = data["comments"] as? Int ?? 0
                    self.shares = data["shares"] as? Int ?? 0
                    self.duration = data["duration"] as? Int ?? 0
                    self.newFollowers = data["newFollowers"] as? Int ?? 0
                }
            }
        
        
        // DONATORS
        db.collection("lives")
            .whereField("isLive", isEqualTo: true)
            .limit(to: 1)
            .addSnapshotListener { snapshot, _ in
                
                guard let doc = snapshot?.documents.first else { return }
                
                guard let userId = Auth.auth().currentUser?.uid else { return }
                print("USER ID:", userId)
                
                self.db.collection("lives")
                    .document(doc.documentID)
                    .collection("donators")
                    .order(by: "coins", descending: true)
                    .limit(to: 3)
                    .addSnapshotListener { snapshot, _ in
                        
                        guard let docs = snapshot?.documents else { return }
                        
                        DispatchQueue.main.async {
                            self.topDonators = docs.map {
                                Donator(
                                    id: $0.documentID,
                                    name: $0["name"] as? String ?? "",
                                    coins: $0["coins"] as? Int ?? 0
                                )
                            }
                        }
                    }
            }
        
        // CAMPAIGNS
        db.collection("campaigns")
            .addSnapshotListener { snapshot, _ in
                DispatchQueue.main.async {
                    self.campaignCount = snapshot?.documents.count ?? 0
                }
            }
    }
}
