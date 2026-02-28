import Foundation

struct NextPayoutResponse: Codable {
    let amount: Int
    let nextPayout: Int?
}
