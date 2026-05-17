import SwiftUI
import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class AnalyticsViewModel: ObservableObject {
    
    // Followers analytics
    @Published var totalFollowers: Int = 0
    @Published var netFollowers: Int = 0
    @Published var followersGrowth: [FollowersGrowthData] = []
    // Spectators analytics
    @Published var totalSpectators: Int = 0
    @Published var newSpectators: Int = 0
    @Published var genderStats: [GenderStat] = []
    @Published var totalViews: Int = 0
    @Published var profileViews: Int = 0
    @Published var totalLikes: Int = 0
    @Published var totalComments: Int = 0
    @Published var totalShares: Int = 0
    
    @Published var dailyViews: [DailyViewData] = []
    
    @Published var forYou: Double = 0
    @Published var profile: Double = 0
    @Published var search: Double = 0
    @Published var sound: Double = 0
    @Published var following: Double = 0
    
    @Published var liveViewers: Int = 0
    @Published var liveGifts: Int = 0
    @Published var liveRevenue: Double = 0
    
    
    // Spectators charts
    @Published var spectatorsChart: [SpectatorChartData] = []
    
    // Audience
    @Published var maleAudience: Double = 0
    @Published var femaleAudience: Double = 0
    @Published var otherAudience: Double = 0
    
    // Activity
    @Published var activityHours: [ActivityHour] = []
    
    // Related creators
    @Published var relatedCreators: [RelatedCreator] = []
    
    // Related posts
    @Published var relatedPosts: [RelatedPost] = []
    
    
    
    
    
    // 🔵 AJOUTÉ POUR ContentAnalyticsView
    @Published var topVideos: [TopVideo] = []
    
    @Published var selectedRange: String = "7J"
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @Published var endDate: Date = Date()
    
    
    @Published var audienceCountries: [CountryAudience] = []
    @Published var audienceAges: [AgeAudience] = []
    
    @Published var returningViewers: Int = 0
    
    @Published var trafficSources: [TrafficSourceData] = []
    
    
    let db = Firestore.firestore()
    
    func loadAnalytics() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("posts")
            .whereField("creatorId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else { return }
                
                var views = 0
                var likes = 0
                var comments = 0
                var shares = 0
                
                for doc in docs {
                    
                    views += doc["viewsCount"] as? Int ?? 0
                    likes += doc["likesCount"] as? Int ?? 0
                    comments += doc["commentsCount"] as? Int ?? 0
                    shares += doc["sharesCount"] as? Int ?? 0
                    
                }
                
                DispatchQueue.main.async {
                    
                    self.totalViews = views
                    self.totalLikes = likes
                    self.totalComments = comments
                    self.totalShares = shares
                    
                }
            }
        
        self.calculateSpectatorsFromViews()
        
        // 🔥 AJOUTE CETTE LIGNE
        loadTopPosts()
    }
    // 🔵 FONCTION AJOUTÉE POUR TES TOP VIDEOS
    func loadTopVideos() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("posts")
            .whereField("creatorId", isEqualTo: userId)
            .order(by: "views", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    
                    self.topVideos = docs.compactMap { doc in
                        
                        let data = doc.data()
                        
                        return TopVideo(
                            id: doc.documentID,
                            caption: data["caption"] as? String ?? "",
                            thumbnail: data["mediaURL"] as? String ?? "",
                            views: data["views"] as? Int ?? 0,
                            likes: data["likes"] as? Int ?? 0,
                            comments: data["comments"] as? Int ?? 0,
                            shares: data["sharesCount"] as? Int ?? 0
                        )
                        
                    }
                }
            }
    }
    
    func loadFollowersAnalytics() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .getDocument { snapshot, error in
                
                guard let data = snapshot?.data() else { return }
                
                DispatchQueue.main.async {
                    
                    self.totalFollowers = data["followersCount"] as? Int ?? 0
                    self.netFollowers = data["netFollowers"] as? Int ?? 0
                }
            }
        
        db.collection("followersGrowth")
            .whereField("creatorId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    
                    self.followersGrowth = docs.compactMap { doc in
                        
                        let data = doc.data()
                        
                        return FollowersGrowthData(
                            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                            value: data["value"] as? Int ?? 0
                        )
                        
                    }
                    
                }
            }
    }
    func loadSpectatorsAnalytics() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // STEP 1 : récupérer les posts du créateur
        db.collection("posts")
            .whereField("creatorId", isEqualTo: userId)
            .getDocuments { postSnapshot, error in
                
                guard let postDocs = postSnapshot?.documents else { return }
                
                let postIds = postDocs.map { $0.documentID }
                
                if postIds.isEmpty { return }
                
                // STEP 2 : récupérer les vues de ces posts
                self.db.collection("postViews")
                    .whereField("ownerId", isEqualTo: userId)
                    .getDocuments { snapshot, error in
                        
                        guard let docs = snapshot?.documents else { return }
                        
                        var viewers: Set<String> = []
                        var countries: [String:Int] = [:]
                        var ages: [String:Int] = [:]
                        var returning: [String:Int] = [:]
                        
                        var male = 0
                        var female = 0
                        var other = 0
                        
                        var chart: [String:Int] = [:]
                        var traffic: [String:Int] = [:]
                        var hours: [Int:Int] = [:]
                        
                        for doc in docs {
                            
                            let data = doc.data()
                            
                            let viewer = data["viewerId"] as? String ?? ""
                            viewers.insert(viewer)
                            
                            let gender = data["gender"] as? String ?? ""
                            
                            if gender == "male" { male += 1 }
                            else if gender == "female" { female += 1 }
                            else { other += 1 }
                            
                            if let timestamp = data["createdAt"] as? Timestamp {
                                
                                let date = DateFormatter.localizedString(
                                    from: timestamp.dateValue(),
                                    dateStyle: .short,
                                    timeStyle: .none
                                )
                                
                                chart[date, default:0] += 1
                                
                                let hour = Calendar.current.component(.hour, from: timestamp.dateValue())
                                hours[hour, default:0] += 1
                                
                                let country = data["country"] as? String ?? "Unknown"
                                countries[country, default:0] += 1
                                
                                let birthYear = data["birthYear"] as? Int ?? 0
                                let age = Calendar.current.component(.year, from: Date()) - birthYear
                                
                                var ageRange = "Unknown"
                                
                                if age < 18 { ageRange = "13-17" }
                                else if age < 25 { ageRange = "18-24" }
                                else if age < 35 { ageRange = "25-34" }
                                else if age < 45 { ageRange = "35-44" }
                                else { ageRange = "45+" }
                                ages[ageRange, default:0] += 1
                                
                                returning[viewer, default:0] += 1
                            }
                            
                            let source = data["trafficSource"] as? String ?? "Autres"
                            traffic[source, default:0] += 1
                        }
                        
                        DispatchQueue.main.async {
                            
                            // Spectateurs
                            self.totalSpectators = viewers.count
                            self.newSpectators = viewers.count
                            
                            // Genre
                            let total = Double(male + female + other)
                            
                            if total > 0 {
                                self.maleAudience = Double(male) / total * 100
                                self.femaleAudience = Double(female) / total * 100
                                self.otherAudience = Double(other) / total * 100
                            }
                            
                            // Courbe spectateurs
                            self.spectatorsChart = chart.map {
                                SpectatorChartData(date: $0.key, value: $0.value)
                            }
                            
                            // Activité heure
                            self.activityHours = hours.map {
                                ActivityHour(hour: "\($0.key)h", value: $0.value)
                            }
                            
                            // Pays
                            self.audienceCountries = countries.map {
                                CountryAudience(country: $0.key, value: $0.value)
                            }
                            
                            // Age
                            self.audienceAges = ages.map {
                                AgeAudience(range: $0.key, value: $0.value)
                            }
                            
                            // Sources trafic
                            self.trafficSources = traffic.map {
                                TrafficSourceData(source: $0.key, value: $0.value)
                            }
                            
                            // Returning viewers
                            self.returningViewers = returning.filter { $0.value > 1 }.count
                        }
                    }
            }
        
        // Related creators
        
        db.collection("follows")
            .limit(to: 10)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else { return }
                
                var creators: [RelatedCreator] = []
                
                for doc in docs {
                    
                    let creatorId = doc["creatorId"] as? String ?? ""
                    
                    self.db.collection("users")
                        .document(creatorId)
                        .getDocument { snap, _ in
                            
                            guard let data = snap?.data() else { return }
                            
                            let creator = RelatedCreator(
                                name: data["name"] as? String ?? "",
                                avatar: data["avatar"] as? String ?? "",
                                followers: data["followersCount"] as? Int ?? 0
                            )
                            
                            creators.append(creator)
                            
                            DispatchQueue.main.async {
                                self.relatedCreators = creators
                            }
                        }
                }
            }
        
        // Related posts
        
        db.collection("posts")
            .order(by: "viewsCount", descending: true)
            .limit(to: 5)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    
                    self.relatedPosts = docs.compactMap { doc in
                        
                        let data = doc.data()
                        
                        return RelatedPost(
                            id: doc.documentID,
                            caption: data["caption"] as? String ?? "",
                            thumbnailURL: data["thumbnailURL"] as? String ?? "",
                            mediaURL: data["mediaURL"] as? String ?? "",
                            viewsCount: data["viewsCount"] as? Int ?? 0
                        )
                    }
                    
                }
            }
    }
    // 🔵 CALCUL SPECTATEURS DEPUIS postViews
    func calculateSpectatorsFromViews() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("postViews")
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else { return }
                
                var viewers: Set<String> = []
                var male = 0
                var female = 0
                
                var daily: [String: Int] = [:]
                
                for doc in docs {
                    
                    let data = doc.data()
                    
                    let viewerId = data["viewerId"] as? String ?? ""
                    viewers.insert(viewerId)
                    
                    let gender = data["gender"] as? String ?? ""
                    
                    if gender == "male" {
                        male += 1
                    }
                    
                    if gender == "female" {
                        female += 1
                    }
                    
                    if let timestamp = data["createdAt"] as? Timestamp {
                        
                        let date = DateFormatter.localizedString(
                            from: timestamp.dateValue(),
                            dateStyle: .short,
                            timeStyle: .none
                        )
                        
                        daily[date, default: 0] += 1
                    }
                }
                
                DispatchQueue.main.async {
                    
                    self.totalSpectators = viewers.count
                    self.newSpectators = viewers.count
                    
                    let total = max(male + female, 1)
                    
                    self.genderStats = [
                        
                        GenderStat(
                            gender: "Homme",
                            count: male,
                            percentage: Double(male) / Double(total) * 100
                        ),
                        
                        GenderStat(
                            gender: "Femme",
                            count: female,
                            percentage: Double(female) / Double(total) * 100
                        )
                        
                    ]
                    
                    self.dailyViews = daily.map {
                        DailyViewData(date: $0.key, views: $0.value)
                    }
                    .sorted { $0.date < $1.date }
                }
            }
    }
    
    
    
    
    func updateRange(_ range: String) {
        
        selectedRange = range
        
        let calendar = Calendar.current
        
        switch range {
            
        case "7J":
            startDate = calendar.date(byAdding: .day, value: -7, to: Date())!
            
        case "28J":
            startDate = calendar.date(byAdding: .day, value: -28, to: Date())!
            
        case "60J":
            startDate = calendar.date(byAdding: .day, value: -60, to: Date())!
            
        case "365J":
            startDate = calendar.date(byAdding: .day, value: -365, to: Date())!
            
        default:
            break
        }
        
        endDate = Date()
        
        loadSpectatorsAnalytics()
    }
    
    func loadTopPosts() {
        
        let db = Firestore.firestore()
        
        db.collection("posts")
            .order(by: "viewsCount", descending: true)
            .limit(to: 5)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    
                    self.relatedPosts = docs.compactMap { doc in
                        
                        let data = doc.data()
                        
                        return RelatedPost(
                            id: doc.documentID,
                            caption: data["caption"] as? String ?? "",
                            thumbnailURL: data["thumbnailURL"] as? String ?? "",
                            mediaURL: data["mediaURL"] as? String ?? "",
                            viewsCount: data["viewsCount"] as? Int ?? 0
                        )
                    }
                    
                }
                
            }
        
    }
    
    var currentRangeText: String {
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM"
        
        let end = Date()
        
        let days: Int
        
        switch selectedRange {
        case "7J":
            days = 7
        case "28J":
            days = 28
        case "60J":
            days = 60
        case "365J":
            days = 365
        default:
            days = 7
        }
        
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
        
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    // =========================
    // MARK: CUSTOM DATE RANGE
    // =========================

    func loadAnalytics(startDate: Date, endDate: Date) {

        let startTimestamp = Timestamp(date: startDate)
        let endTimestamp = Timestamp(date: endDate)

        db.collection("postViews")
            .whereField("createdAt", isGreaterThan: startTimestamp)
            .whereField("createdAt", isLessThan: endTimestamp)
            .getDocuments { snapshot, error in

                guard let docs = snapshot?.documents else { return }

                print("Custom analytics docs:", docs.count)

                // recalculer les stats ici si besoin
            }
    }
    
}
struct SpectatorChartData: Identifiable {
    let id = UUID()
    let date: String
    let value: Int
}

struct ActivityHour: Identifiable {
    let id = UUID()
    let hour: String
    let value: Int
}

struct RelatedCreator: Identifiable {
    let id = UUID()
    let name: String
    let avatar: String
    let followers: Int
}

struct RelatedPost: Identifiable {
    
    let id: String
    let caption: String
    let thumbnailURL: String
    let mediaURL: String
    let viewsCount: Int
    
}
