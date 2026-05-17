import Foundation

struct CountryAudience: Identifiable {

    let id = UUID()
    let country: String
    let value: Int
    
    var percentage: Double {
        Double(value)
    }
}

struct AgeAudience: Identifiable {

    let id = UUID()
    let range: String
    let value: Int
    
    var percentage: Double {
        Double(value)
    }
}
