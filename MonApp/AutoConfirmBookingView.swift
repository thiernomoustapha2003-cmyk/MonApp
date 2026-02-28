import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AutoConfirmBookingView: View {

    @State private var enabled = false
    @State private var onlyPaid = true
    @State private var message =
"""
Votre rendez-vous est confirmé ✅ 
Merci pour votre réservation !
"""

    @State private var saved = false

    private let db = Firestore.firestore()

    var body: some View {

        VStack(spacing: 20) {

            Text("Confirmation automatique")
                .font(.title2)
                .bold()

            Toggle("Confirmer automatiquement les RDV", isOn: $enabled)
                .padding(.horizontal)

            Toggle("Uniquement si payé en ligne", isOn: $onlyPaid)
                .padding(.horizontal)

            VStack(alignment: .leading) {
                Text("Message envoyé au client")
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
                    enabled = data["autoConfirmEnabled"] as? Bool ?? false
                    onlyPaid = data["autoConfirmOnlyPaid"] as? Bool ?? true
                    message = data["autoConfirmMessage"] as? String ?? message
                }
            }
    }

    func save() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("automation")
            .document(uid)
            .setData([
                "autoConfirmEnabled": enabled,
                "autoConfirmOnlyPaid": onlyPaid,
                "autoConfirmMessage": message
            ], merge: true)

        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
    }
}
