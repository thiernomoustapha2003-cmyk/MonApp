import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChooseRoleView: View {

    private let db = Firestore.firestore()
    private var uid: String { Auth.auth().currentUser?.uid ?? "" }

    var body: some View {
        VStack(spacing: 40) {

            Text("Bienvenue 👋")
                .font(.largeTitle)
                .bold()

            Text("Tu veux utiliser l'application en tant que :")
                .foregroundColor(.gray)

            // CLIENT
            Button(action: {
                createUser(role: "client")
            }) {
                Text("Je suis un client")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            // COIFFEUR
            // COIFFEUR
            Button(action: {
                createUser(role: "barber")
            }) {
                Text("Je suis un coiffeur")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
    }

    // 🔥 Création du document Firestore
    func createUser(role: String) {

        let data: [String: Any] = [
            "role": role,
            "profileCompleted": false,
            "createdAt": Timestamp()
        ]

        db.collection("users").document(uid).setData(data) { error in
            if let error = error {
                print("❌ Erreur création user:", error)
            } else {
                print("✅ User créé avec role:", role)
            }
        }
    }
}
