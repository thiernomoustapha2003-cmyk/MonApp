import Foundation

struct ClientBookingDisplay: Identifiable {
    let id: String
    
    let barberName: String
    let barberPhoto: String?
    
    let date: Date
    let serviceName: String
    let price: Double
    let status: String
}
