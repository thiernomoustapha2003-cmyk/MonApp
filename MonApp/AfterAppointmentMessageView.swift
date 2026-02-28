import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AfterAppointmentMessageView: View {

    @State private var enabled = false
    @State private var messageText =
"""
Merci pour ta visite 🙌
N’hésite pas à laisser un avis ⭐️
À très bientôt !
"""

    @State private var saved = false

    private let db = Firestore.firestore()

    var body: some View {

        VStack(spacing: 20) {

            Text("Message après rendez-vous")
                .font(.title2)
                .bold()

            Toggle("Envoyer automatiquement", isOn: $enabled)
                .padding(.horizontal)

            VStack(alignment: .leading) {
                Text("Message envoyé au client")
                    .font(.headline)

                TextEditor(text: $messageText)
                    .frame(height: 180)
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

    // LOAD
    func load() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("automation")
            .document(uid)
            .getDocument { doc, _ in

                if let data = doc?.data() {
                    enabled = data["afterMessageEnabled"] as? Bool ?? false
                    messageText = data["afterMessageText"] as? String ?? messageText
                }
            }
    }

    // SAVE
    func save() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("automation")
            .document(uid)
            .setData([
                "afterMessageEnabled": enabled,
                "afterMessageText": messageText
            ], merge: true)

        saved = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            saved = false
        }
    }
}
