import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class AnalyticsViewModel: ObservableObject {
    
    @Published var countryStats: [CountryStat] = []
    @Published var genderStats: [GenderStat] = []
    @Published var ageStats: [AgeStat] = []
    @Published var totalLikes: Int = 0
    @Published var completionRate: Double = 0
    
    private let db = Firestore.firestore()
    
    func fetchAnalytics(for postId: String) {
        fetchLikes(postId: postId)
        fetchViews(postId: postId)
    }
    
    private func fetchLikes(postId: String) {
        db.collection("postLikes")
            .whereField("postId", isEqualTo: postId)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    DispatchQueue.main.async {
                        self.totalLikes = docs.count
                    }
                }
            }
    }
    
    private func fetchViews(postId: String) {
        db.collection("postViews")
            .whereField("postId", isEqualTo: postId)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else { return }
                
                let totalViews = documents.count
                var countryCount: [String: Int] = [:]
                var genderCount: [String: Int] = [:]
                var ageCount: [String: Int] = [:]
                var completedViews = 0
                
                for doc in documents {
                    let data = doc.data()
                    
                    let country = data["country"] as? String ?? "Unknown"
                    let gender = data["gender"] as? String ?? "Unknown"
                    let birthYear = data["birthYear"] as? Int ?? 2000
                    let completed = data["completed"] as? Bool ?? false
                    
                    if completed { completedViews += 1 }
                    
                    countryCount[country, default: 0] += 1
                    genderCount[gender, default: 0] += 1
                    
                    let age = Calendar.current.component(.year, from: Date()) - birthYear
                    let range = self.ageRange(from: age)
                    ageCount[range, default: 0] += 1
                }
                
                DispatchQueue.main.async {
                    self.countryStats = countryCount.map {
                        CountryStat(country: $0.key,
                                    percentage: Double($0.value) / Double(totalViews) * 100)
                    }
                    
                    self.genderStats = genderCount.map {
                        GenderStat(gender: $0.key,
                                   percentage: Double($0.value) / Double(totalViews) * 100)
                    }
                    
                    self.ageStats = ageCount.map {
                        AgeStat(range: $0.key,
                                percentage: Double($0.value) / Double(totalViews) * 100)
                    }
                    
                    self.completionRate =
                        totalViews > 0 ?
                        Double(completedViews) / Double(totalViews) * 100 : 0
                }
            }
    }
    
    private func ageRange(from age: Int) -> String {
        switch age {
        case 0...17: return "0-17"
        case 18...24: return "18-24"
        case 25...34: return "25-34"
        case 35...44: return "35-44"
        case 45...54: return "45-54"
        default: return "55+"
        }
    }
}
