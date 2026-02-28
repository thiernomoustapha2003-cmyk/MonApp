import Foundation
import FirebaseFirestore

// ============================================
// AvailabilitySlot.swift
// ============================================

struct AvailabilitySlot: Identifiable, Codable {
    @DocumentID var id: String?

    var barberId: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var status: SlotStatus

    enum CodingKeys: String, CodingKey {
        case id
        case barberId
        case date
        case startTime
        case endTime
        case status
    }
}
