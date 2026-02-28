import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AutoReminderView: View {

    @State private var enabled = false
    @State private var hoursBefore: Int = 2
    @State private var message =
"""
Rappel ⏰
Vous avez un rendez-vous bientôt !
"""

    @State private var saved = false

    private let db = Firestore.firestore()

    var body: some View {

        VStack(spacing: 20) {

            Text("Rappels automatiques")
                .font(.title2)
                .bold()

            Toggle("Activer les rappels", isOn: $enabled)
                .padding(.horizontal)

            Stepper("Envoyer \(hoursBefore) heure(s) avant",
                    value: $hoursBefore,
                    in: 1...48)
                .padding(.horizontal)

            VStack(alignment: .leading) {
                Text("Message envoyé")
                    .font(.headline)

                TextEditor(text: $message)
                    .frame(height: 160)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding()

            Button(action: save) {
                Text(saved ? "Enregistré ✔︎" : "Enregistrer")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(saved ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
        .onAppear(perform: load)
    }

    func load() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("automation")
            .document(uid)
            .getDocument { doc, _ in

                if let data = doc?.data() {
                    enabled = data["reminderEnabled"] as? Bool ?? false
                    hoursBefore = data["reminderHoursBefore"] as? Int ?? 2
                    message = data["reminderMessage"] as? String ?? message
                }
            }
    }

    func save() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("automation")
            .document(uid)
            .setData([
                "reminderEnabled": enabled,
                "reminderHoursBefore": hoursBefore,
                "reminderMessage": message
            ], merge: true)

        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
    }
}
