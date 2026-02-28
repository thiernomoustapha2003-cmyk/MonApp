import Foundation
import Combine

@MainActor
class AutoReminderViewModel: ObservableObject {

    @Published var settings = ReminderSettings()
    @Published var saved = false

    private let key = "barber_auto_reminder"

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(ReminderSettings.self, from: data)
        else { return }

        settings = decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
        saved = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.saved = false
        }
    }
}
