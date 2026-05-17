import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class ContentAnalyticsService: ObservableObject {
    
    @Published var videos: [AnalyticsVideo] = []
    @Published var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @Published var customEndDate: Date = Date()
    
    private let db = Firestore.firestore()
    
    // Chargement avec filtre de période
    func loadVideos(period: AnalyticsPeriod) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        var startDate: Date
        var endDate: Date = Date()
        
        switch period {
            
        case .seven:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            
        case .twentyEight:
            startDate = Calendar.current.date(byAdding: .day, value: -28, to: Date())!
            
        case .sixty:
            startDate = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
            
        case .year:
            startDate = Calendar.current.date(byAdding: .day, value: -365, to: Date())!
            
        case .custom:
            startDate = customStartDate
            endDate = customEndDate
        }
        
        var query: Query = db.collection("posts")
            .whereField("creatorId", isEqualTo: uid)
            .whereField("createdAt", isGreaterThan: Timestamp(date: startDate))
        
        if period == .custom {
            query = query.whereField("createdAt", isLessThan: Timestamp(date: endDate))
        }
        
        query
            .order(by: "viewsCount", descending: true)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else { return }
                
                self.videos = documents.map { doc in
                    
                    let data = doc.data()
                    
                    let caption = data["caption"] as? String ?? ""
                    let thumbnail = data["thumbnailURL"] as? String ?? ""
                    let views = data["viewsCount"] as? Int ?? 0
                    
                    var formattedDate = ""
                    
                    if let timestamp = data["createdAt"] as? Timestamp {
                        
                        let date = timestamp.dateValue()
                        
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .none
                        
                        formattedDate = formatter.string(from: date)
                    }
                    
                    return AnalyticsVideo(
                        id: doc.documentID,
                        caption: caption,
                        thumbnail: thumbnail,
                        views: views,
                        date: formattedDate
                    )
                }
            }
    }
}
