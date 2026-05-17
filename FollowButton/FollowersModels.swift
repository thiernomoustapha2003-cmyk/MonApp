import Foundation
import CoreLocation

struct FollowersDaily: Identifiable {

    let id = UUID()
    let date: Date
    let total: Int
    let gained: Int
    let lost: Int
}

struct CountryStat: Identifiable {

    let id = UUID()
    let country: String
    let percentage: Double
    let coordinate: CLLocationCoordinate2D
}

struct CityStat: Identifiable {

    let id = UUID()
    let city: String
    let percentage: Double
}


struct ActivityHeatmap: Identifiable {

    let id = UUID()
    let day: String
    let hour: Int
    let value: Int
}
