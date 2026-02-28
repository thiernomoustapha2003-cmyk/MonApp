import SwiftUI

struct CommissionSettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = CommissionViewModel()

    var body: some View {

        NavigationStack {

            Form {

                Section("Activation") {

                    Toggle("Activer les commissions plateforme", isOn: $vm.active)
                }

                Section("Commission (%)") {

                    HStack {
                        Slider(value: $vm.percentage, in: 0...40, step: 1)
                        Text("\(Int(vm.percentage))%")
                            .frame(width: 50)
                    }
                }

                Section("Frais fixe (€)") {

                    Stepper(value: $vm.fixedFee, in: 0...10, step: 0.5) {
                        Text("\(vm.fixedFee, specifier: "%.2f") € par réservation")
                    }
                }

                if vm.saved {
                    Section {
                        Text("Modifications enregistrées ✅")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Commissions")
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {

                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Button("Enregistrer") { vm.save() }
                    }
                }
            }
            .onAppear { vm.load() }
        }
    }
}
