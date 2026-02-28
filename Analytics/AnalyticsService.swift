import Foundation
import FirebaseFirestore

final class AnalyticsService {

    static let db = Firestore.firestore()

    static func fetchStats(postId: String,
                           completion: @escaping (
                                [CountryStat],
                                [GenderStat],
                                [AgeStat],
                                Int
                           ) -> Void) {

        db.collection("postViews")
            .whereField("postId", isEqualTo: postId)
            .getDocuments { snapshot, _ in

                guard let docs = snapshot?.documents else {
                    completion([], [], [], 0)
                    return
                }

                let total = docs.count

                if total == 0 {
                    completion([], [], [], 0)
                    return
                }

                var countryDict: [String: Int] = [:]
                var genderDict: [String: Int] = [:]
                var ageDict: [String: Int] = [:]

                let currentYear = Calendar.current.component(.year, from: Date())

                for doc in docs {

                    let data = doc.data()

                    let country = data["country"] as? String ?? "Unknown"
                    let gender = data["gender"] as? String ?? "Unknown"
                    let birthYear = data["birthYear"] as? Int ?? 2000

                    countryDict[country, default: 0] += 1
                    genderDict[gender, default: 0] += 1

                    let age = currentYear - birthYear

                    let range: String

                    switch age {
                    case 18...24: range = "18-24"
                    case 25...34: range = "25-34"
                    case 35...44: range = "35-44"
                    case 45...54: range = "45-54"
                    default: range = "55+"
                    }

                    ageDict[range, default: 0] += 1
                }

                let countryStats = countryDict.map {
                    CountryStat(
                        country: $0.key,
                        percentage: Double($0.value) / Double(total) * 100
                    )
                }.sorted { $0.percentage > $1.percentage }

                let genderStats = genderDict.map {
                    GenderStat(
                        gender: $0.key,
                        percentage: Double($0.value) / Double(total) * 100
                    )
                }

                let ageStats = ageDict.map {
                    AgeStat(
                        range: $0.key,
                        percentage: Double($0.value) / Double(total) * 100
                    )
                }

                completion(countryStats, genderStats, ageStats, total)
            }
    }
}
