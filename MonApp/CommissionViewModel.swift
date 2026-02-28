import Foundation
import FirebaseAuth
import Combine

@MainActor
final class CommissionViewModel: ObservableObject {

    // MARK: - UI STATE
    @Published var percentage: Double = 15
    @Published var fixedFee: Double = 0
    @Published var active: Bool = true

    @Published var isLoading: Bool = false
    @Published var saved: Bool = false

    // MARK: - LOAD
    func load() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        isLoading = true

        CommissionService.shared.fetchCommission(barberId: uid) { [weak self] result in
            guard let self else { return }

            self.isLoading = false

            switch result {

            case .success(let rule):
                self.percentage = rule.percentage
                self.fixedFee = rule.fixedFee
                self.active = rule.active

            case .failure(let error):
                print("Commission load error:", error.localizedDescription)
            }
        }
    }

    // MARK: - SAVE
    func save() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        saved = false

        let rule = CommissionRule(
            id: uid,
            percentage: percentage,
            fixedFee: fixedFee,
            active: active
        )

        CommissionService.shared.updateCommission(rule: rule, barberId: uid) { [weak self] result in
            guard let self else { return }

            self.isLoading = false

            switch result {
            case .success:
                self.saved = true
            case .failure(let error):
                print("Commission save error:", error.localizedDescription)
            }
        }
    }
}
