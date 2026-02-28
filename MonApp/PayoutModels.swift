import Foundation

// Réponse API
struct PayoutResponse: Codable {
    let totalEarned: Double
    let count: Int
    let payouts: [Payout]
}

// Un virement
struct Payout: Codable, Identifiable {

    let id: String
    let amount: Double
    let date: Double?
    let client: String

    // bookingId du JSON devient id dans l'app
    enum CodingKeys: String, CodingKey {
        case id = "bookingId"
        case amount
        case date
        case client
    }

    // Date formatée pour l'affichage
    var formattedDate: String {
        guard let date else { return "Date inconnue" }
        let d = Date(timeIntervalSince1970: date)
        return d.formatted(date: .long, time: .omitted)
    }
}
