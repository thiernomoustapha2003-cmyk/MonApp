import Foundation

enum SlotStatus {
    case available   // 🟢
    case booked      // 🔴
    case notWorking  // 🟡
}

struct BarberSlot: Identifiable {
    let id: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let isBooked: Bool

    var status: SlotStatus {
        if isBooked { return .booked }

        let weekday = Calendar.current.component(.weekday, from: date)
        if weekday == 1 { // Dimanche
            return .notWorking
        }

        return .available
    }
}
