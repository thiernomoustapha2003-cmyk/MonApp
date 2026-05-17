import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreLocation
import Combine

class FollowersAnalyticsViewModel: ObservableObject {
    
    @Published var bestPostingHour: String = "--"
    @Published var bestPostingDay: String = "--"
    
    
    @Published var genderStats: [GenderStat] = []
    
    
    
    
    @Published var totalFollowers: Int = 0
    @Published var netFollowers: Int = 0
    @Published var activityHeatmap: [ActivityHeatmap] = []
    // MARK: CUSTOM DATE RANGE
    
    @Published var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @Published var customEndDate: Date = Date()
    
    @Published var followersHistory: [FollowersDaily] = []
    
    @Published var activityHours: [ActivityHour] = []
    @Published var bestHour: String = "--"
    
    @Published var ageStats: [AgeStat] = [
        AgeStat(range: "13-17", percentage: 12),
        AgeStat(range: "18-24", percentage: 38),
        AgeStat(range: "25-34", percentage: 30),
        AgeStat(range: "35-44", percentage: 12),
        AgeStat(range: "45+", percentage: 8)
    ]
    @Published var countryStats: [CountryStat] = [
        CountryStat(
            country: "France",
            percentage: 35,
            coordinate: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        ),
        
        CountryStat(
            country: "USA",
            percentage: 25,
            coordinate: CLLocationCoordinate2D(latitude: 37.0902, longitude: -95.7129)
        ),
        
        CountryStat(
            country: "Brésil",
            percentage: 15,
            coordinate: CLLocationCoordinate2D(latitude: -14.2350, longitude: -51.9253)
        )
    ]
    
    private let db = Firestore.firestore()
    
    // MARK: LOAD FOLLOWERS ANALYTICS
    
    func loadFollowersAnalytics() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        print("UID connecté :", uid)
        
        // Charger toutes les analytics
        loadTotalFollowers(uid)
        loadNetFollowers(uid)
        loadFollowersHistory(uid)
        loadGenderStats(uid)
        loadActivityHours()
        generateActivityHeatmap(uid)
        calculateBestPostingTime()
        loadCountryStats(uid)
        
    }
    // MARK: TOTAL FOLLOWERS
    
    private func loadTotalFollowers(_ uid: String) {
        
        db.collection("follows")
            .whereField("creatorId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                
                guard let docs = snapshot?.documents else { return }
                
                var total = 0
                
                for doc in docs {
                    
                    let status = doc["status"] as? String ?? "follow"
                    
                    if status == "follow" {
                        total += 1
                    }
                }
                
                print("Followers actifs :", total)
                
                DispatchQueue.main.async {
                    
                    self.totalFollowers = total
                }
            }
    }
    // MARK: FOLLOWERS HISTORY
    
    private func loadFollowersHistory(_ uid: String) {
        
        db.collection("analytics")
            .document(uid)
            .collection("followersDaily")
            .order(by: "date")
            .addSnapshotListener { snapshot, error in
                
                guard let docs = snapshot?.documents else {
                    print("No analytics followers data")
                    return
                }
                
                print("Followers analytics docs:", docs.count)
                
                var history: [FollowersDaily] = []
                
                for doc in docs {
                    
                    let data = doc.data()
                    
                    let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                    let gained = data["gained"] as? Int ?? 0
                    let lost = data["lost"] as? Int ?? 0
                    let total = data["total"] as? Int ?? 0
                    
                    history.append(
                        FollowersDaily(
                            date: date,
                            total: total,
                            gained: gained,
                            lost: lost
                        )
                    )
                }
                history.sort { $0.date < $1.date }
                DispatchQueue.main.async {
                    
                    self.followersHistory = history
                    
                    self.netFollowers = history.last?.total ?? 0
                    
                    print("Followers history loaded:", history.count)
                }
            }
    }
    
    // MARK: GENDER STATS
    
    private func loadGenderStats(_ uid: String) {
        
        print("Loading gender stats for:", uid)
        
        db.collection("follows")
            .whereField("creatorId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("Gender stats error:", error)
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    print("No followers found")
                    return
                }
                
                print("Followers found:", docs.count)
                
                var male = 0
                var female = 0
                var other = 0
                
                for doc in docs {
                    
                    let gender = (doc["gender"] as? String ?? "").lowercased()
                    
                    switch gender {
                        
                    case "male", "m", "homme":
                        male += 1
                        
                    case "female", "f", "femme":
                        female += 1
                        
                    default:
                        other += 1
                    }
                }
                
                let total = male + female + other
                
                // sécurité pour éviter NaN dans Charts
                let safeTotal = max(total, 1)
                
                let malePercent = Double(male) / Double(safeTotal) * 100
                let femalePercent = Double(female) / Double(safeTotal) * 100
                let otherPercent = Double(other) / Double(safeTotal) * 100
                
                print("Gender stats → male:", male, "female:", female, "other:", other)
                
                DispatchQueue.main.async {
                    
                    var stats: [GenderStat] = []
                    
                    if male > 0 {
                        stats.append(
                            GenderStat(
                                gender: "Hommes",
                                count: male,
                                percentage: malePercent
                            )
                        )
                    }
                    
                    if female > 0 {
                        stats.append(
                            GenderStat(
                                gender: "Femmes",
                                count: female,
                                percentage: femalePercent
                            )
                        )
                    }
                    
                    if other > 0 {
                        stats.append(
                            GenderStat(
                                gender: "Autre",
                                count: other,
                                percentage: otherPercent
                            )
                        )
                    }
                    
                    self.genderStats = [
                        
                        GenderStat(
                            gender: "Hommes",
                            count: male,
                            percentage: malePercent
                        ),
                        
                        GenderStat(
                            gender: "Femmes",
                            count: female,
                            percentage: femalePercent
                        ),
                        
                        GenderStat(
                            gender: "Autre",
                            count: other,
                            percentage: otherPercent
                        )
                    ]
                }
            }
    }
    // MARK: ACTIVITY HOURS
    
    private func loadActivityHours(_ uid: String) {
        
        db.collection("postViews")
            .whereField("ownerId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("Error loading activity hours:", error)
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    print("No documents found for activity hours")
                    return
                }
                
                var hours: [Int:Int] = [:]
                
                for doc in docs {
                    
                    let data = doc.data()
                    
                    if let ts = data["createdAt"] as? Timestamp {
                        
                        let hour = Calendar.current.component(.hour, from: ts.dateValue())
                        
                        hours[hour, default: 0] += 1
                    }
                }
                
                // Toujours créer les 24 heures
                
                var result: [ActivityHour] = []
                
                for h in 0..<24 {
                    
                    let count = hours[h] ?? 0
                    
                    let label: String
                    
                    switch h {
                        
                    case 0:
                        label = "12a"
                        
                    case 1..<12:
                        label = "\(h)a"
                        
                    case 12:
                        label = "12p"
                        
                    default:
                        label = "\(h-12)p"
                    }
                    
                    result.append(
                        ActivityHour(
                            hour: label,
                            value: count
                        )
                    )
                }
                
                print("Activity hours loaded:", result.count)
                
                DispatchQueue.main.async {
                    print("Activity hours count:", result.count)
                    self.activityHours = result
                    
                    if let best = result.max(by: { $0.value < $1.value }) {
                        self.bestHour = best.hour
                    }
                }
            }
    }
    
    // MARK: BEST POSTING TIME (TikTok Style)
    
    func calculateBestPostingTime() {
        
        guard !activityHours.isEmpty else {
            bestPostingHour = "--"
            bestPostingDay = "--"
            return
        }
        
        // =============================
        // 1️⃣ MEILLEURE HEURE
        // =============================
        
        if let bestHourData = activityHours.max(by: { $0.value < $1.value }) {
            bestPostingHour = bestHourData.hour
        }
        
        // =============================
        // 2️⃣ CALCUL DU JOUR LE PLUS ACTIF
        // =============================
        
        if !activityHeatmap.isEmpty {
            
            var dayTotals: [String:Int] = [:]
            
            for item in activityHeatmap {
                dayTotals[item.day, default: 0] += item.value
            }
            
            if let bestDay = dayTotals.max(by: { $0.value < $1.value }) {
                bestPostingDay = bestDay.key
            }
            
        } else {
            
            bestPostingDay = "Vendredi"
        }
        
        // =============================
        // 3️⃣ PLAGE HORAIRE OPTIMALE
        // =============================
        
        if let best = activityHours.max(by: { $0.value < $1.value }) {
            
            if let hourInt = Int(best.hour.replacingOccurrences(of: "h", with: "")) {
                
                let start = max(hourInt - 1, 0)
                let end = min(hourInt + 2, 23)
                
                bestPostingHour = "\(start)h-\(end)h"
            }
        }
        
        // =============================
        // 4️⃣ SCORE D'ACTIVITÉ (OPTION)
        // =============================
        
        let totalActivity = activityHours.reduce(0) { $0 + $1.value }
        
        if totalActivity == 0 {
            bestPostingHour = "--"
        }
    }
    // MARK: - TEST ACTIVITY HOURS (DEBUG)
    
    func loadActivityHours() {
        
        let hours = [
            
            ActivityHour(hour: "0h", value: 120),
            ActivityHour(hour: "1h", value: 80),
            ActivityHour(hour: "2h", value: 60),
            ActivityHour(hour: "3h", value: 40),
            ActivityHour(hour: "4h", value: 30),
            ActivityHour(hour: "5h", value: 20),
            
            ActivityHour(hour: "6h", value: 50),
            ActivityHour(hour: "7h", value: 70),
            ActivityHour(hour: "8h", value: 90),
            ActivityHour(hour: "9h", value: 110),
            
            ActivityHour(hour: "10h", value: 130),
            ActivityHour(hour: "11h", value: 150),
            ActivityHour(hour: "12h", value: 200),
            
            ActivityHour(hour: "13h", value: 180),
            ActivityHour(hour: "14h", value: 160),
            ActivityHour(hour: "15h", value: 140),
            
            ActivityHour(hour: "16h", value: 170),
            ActivityHour(hour: "17h", value: 220),
            ActivityHour(hour: "18h", value: 260),
            
            ActivityHour(hour: "19h", value: 300),
            ActivityHour(hour: "20h", value: 280),
            ActivityHour(hour: "21h", value: 240),
            
            ActivityHour(hour: "22h", value: 200),
            ActivityHour(hour: "23h", value: 160)
        ]
        
        activityHours = hours
        
        if let best = hours.max(by: { $0.value < $1.value }) {
            bestHour = best.hour
        }
    }
    // MARK: ACTIVITY HEATMAP (TikTok style)
    
    func generateActivityHeatmap(_ uid: String) {
        
        db.collection("postViews")
            .whereField("ownerId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("Heatmap error:", error)
                    return
                }
                
                guard let docs = snapshot?.documents else { return }
                
                print("Documents heatmap:", docs.count)
                
                var map: [String:[Int:Int]] = [:]
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "fr_FR")
                formatter.dateFormat = "EEE"
                
                for doc in docs {
                    
                    let data = doc.data()
                    
                    if let ts = data["createdAt"] as? Timestamp {
                        
                        let date = ts.dateValue()
                        
                        let dayRaw = formatter.string(from: date)
                        
                        let day: String
                        
                        switch dayRaw.lowercased() {
                        case "lun.", "lun":
                            day = "Lun"
                        case "mar.", "mar":
                            day = "Mar"
                        case "mer.", "mer":
                            day = "Mer"
                        case "jeu.", "jeu":
                            day = "Jeu"
                        case "ven.", "ven":
                            day = "Ven"
                        case "sam.", "sam":
                            day = "Sam"
                        case "dim.", "dim":
                            day = "Dim"
                        default:
                            day = "Lun"
                        }
                        
                        let hour = Calendar.current.component(.hour, from: date)
                        
                        map[day, default: [:]][hour, default: 0] += 1
                    }
                }
                
                var result: [ActivityHeatmap] = []
                
                let days = ["Lun","Mar","Mer","Jeu","Ven","Sam","Dim"]
                
                for day in days {
                    
                    for hour in 0..<24 {
                        
                        let value = map[day]?[hour] ?? 0
                        
                        result.append(
                            ActivityHeatmap(
                                day: day,
                                hour: hour,
                                value: value
                            )
                        )
                    }
                }
                
                DispatchQueue.main.async {
                    
                    print("Heatmap cells:", result.count)
                    
                    self.activityHeatmap = result
                }
            }
    }
    
    
    
    // MARK: NET FOLLOWERS
    
    func loadNetFollowers(_ uid: String) {
        
        db.collection("follows")
            .whereField("creatorId", isEqualTo: uid)
            .addSnapshotListener { snapshot, _ in
                
                guard let docs = snapshot?.documents else { return }
                
                var gained = 0
                var lost = 0
                
                for doc in docs {
                    
                    let status = doc["status"] as? String ?? "follow"
                    
                    if status == "follow" {
                        gained += 1
                    }
                    
                    if status == "unfollow" {
                        lost += 1
                    }
                }
                
                print("Followers gained:", gained)
                print("Followers lost:", lost)
                
                DispatchQueue.main.async {
                    
                    
                }
            }
    }
    
    // MARK: LOAD COUNTRY STATS
    
    func loadCountryStats(_ uid: String) {
        
        db.collection("postViews")
            .whereField("ownerId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("Country stats error:", error)
                    return
                }
                
                guard let docs = snapshot?.documents else { return }
                
                var countryCount: [String:Int] = [:]
                
                for doc in docs {
                    
                    let country = doc["country"] as? String ?? "Unknown"
                    countryCount[country, default: 0] += 1
                }
                
                let total = countryCount.values.reduce(0, +)
                
                var result: [CountryStat] = []
                
                for (country, count) in countryCount {
                    
                    let percent = Double(count) / Double(max(total,1)) * 100
                    
                    let coordinate = self.coordinateForCountry(country)
                    
                    result.append(
                        CountryStat(
                            country: country,
                            percentage: percent,
                            coordinate: coordinate
                        )
                    )
                }
                
                DispatchQueue.main.async {
                    self.countryStats = result
                }
            }
    }
    func coordinateForCountry(_ code: String) -> CLLocationCoordinate2D {

        switch code {

        case "FR":
            return CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)

        case "US":
            return CLLocationCoordinate2D(latitude: 37.0902, longitude: -95.7129)

        case "CA":
            return CLLocationCoordinate2D(latitude: 56.1304, longitude: -106.3468)

        case "BR":
            return CLLocationCoordinate2D(latitude: -14.2350, longitude: -51.9253)

        default:
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
    }
}
