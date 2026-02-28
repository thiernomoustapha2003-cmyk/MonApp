import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NoShowProtectionView: View {

    @State private var enabled = false
    @State private var penaltyPercent: Double = 50
    @State private var loading = true

    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 25) {

            Text("Protection anti-no-show")
                .font(.title2)
                .bold()

            Toggle("Activer la protection", isOn: $enabled)
                .padding()

            VStack {
                Text("Frais en cas d'absence : \(Int(penaltyPercent))%")
                Slider(value: $penaltyPercent, in: 0...100, step: 10)
            }
            .padding()

            Button("Enregistrer") {
                save()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .onAppear(perform: load)
    }

    // 🔹 LOAD
    func load() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("automation").document(uid).getDocument { doc, _ in
            if let data = doc?.data() {
                enabled = data["noShowEnabled"] as? Bool ?? false
                penaltyPercent = data["noShowPercent"] as? Double ?? 50
            }
            loading = false
        }
    }

    // 🔹 SAVE
    func save() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("automation").document(uid).setData([
            "noShowEnabled": enabled,
            "noShowPercent": penaltyPercent
        ], merge: true)
    }
}
