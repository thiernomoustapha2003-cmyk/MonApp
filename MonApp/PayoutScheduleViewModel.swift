import Foundation
import SwiftUI
import Foundation
import Combine

class PayoutScheduleViewModel: ObservableObject {

    @Published var interval: PayoutInterval = .daily
    @Published var weeklyAnchor: Int = 1
    @Published var monthlyAnchor: Int = 1
    @Published var delayDays: Int = 2
    @Published var saving = false
    @Published var saved = false

    func save() {

        saving = true

        let schedule = PayoutSchedule(
            interval: interval,
            weeklyAnchor: interval == .weekly ? weeklyAnchor : nil,
            monthlyAnchor: interval == .monthly ? monthlyAnchor : nil,
            delayDays: delayDays
        )

        PayoutScheduleService.shared.updateSchedule(schedule) { result in
            DispatchQueue.main.async {
                self.saving = false
                if case .success = result {
                    self.saved = true
                }
            }
        }
    }
}
