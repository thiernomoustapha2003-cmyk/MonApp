import SwiftUI

struct PayoutScheduleView: View {

    @StateObject private var vm = PayoutScheduleViewModel()

    var body: some View {

        NavigationStack {

            Form {

                Section("Fréquence des virements") {

                    Picker("Intervalle", selection: $vm.interval) {
                        ForEach(PayoutInterval.allCases) {
                            Text($0.title).tag($0)
                        }
                    }
                }

                if vm.interval == .weekly {
                    Section("Jour de versement") {
                        Stepper("Jour \(vm.weeklyAnchor)", value: $vm.weeklyAnchor, in: 1...7)
                    }
                }

                if vm.interval == .monthly {
                    Section("Date du mois") {
                        Stepper("Jour \(vm.monthlyAnchor)", value: $vm.monthlyAnchor, in: 1...28)
                    }
                }

                Section("Délai de sécurité") {
                    Stepper("\(vm.delayDays) jours", value: $vm.delayDays, in: 0...7)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aperçu")
                            .font(.headline)

                        Text("Les paiements seront envoyés après \(vm.delayDays) jours")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(vm.saving ? "Enregistrement..." : "Enregistrer") {
                        vm.save()
                    }
                    .disabled(vm.saving)
                }
            }
            .navigationTitle("Plan de paiement")
        }
    }
}
