import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SmartRebookingView: View {

    @State private var autoRebook = false
    @State private var delayHours: Double = 2

    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 25) {

            Text("Rebooking intelligent")
                .font(.title2)
                .bold()

            Toggle("Reproposer un créneau automatiquement", isOn: $autoRebook)
                .padding()

            VStack {
                Text("Délai avant proposition : \(Int(delayHours))h")
                Slider(value: $delayHours, in: 1...24, step: 1)
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

    func load() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("automation").document(uid).getDocument { doc, _ in
            if let data = doc?.data() {
                autoRebook = data["autoRebook"] as? Bool ?? false
                delayHours = data["rebookDelay"] as? Double ?? 2
            }
        }
    }

    func save() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("automation").document(uid).setData([
            "autoRebook": autoRebook,
            "rebookDelay": delayHours
        ], merge: true)
    }
}
