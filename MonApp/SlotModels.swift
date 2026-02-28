import Foundation
import FirebaseFirestore

// ================================
// 🔥 ENUM UNIQUE POUR TOUT LE PROJET
// ================================
enum SlotStatus: String, Codable {
    case available = "available"   // 🟢
    case booked = "booked"         // 🔴
    case notWorking = "notWorking" // 🟡
}

// ================================
// ✂️ MODÈLE DE CRÉNEAU UNIQUE (PARTOUT)
// ================================
struct AvailabilitySlot: Identifiable, Codable {
    @DocumentID var id: String?
    let barberId: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let isBooked: Bool
    let status: SlotStatus
}
