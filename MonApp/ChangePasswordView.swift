import SwiftUI
import Firebase
import FirebaseAuth

struct ChangePasswordView: View {

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var message = ""

    var body: some View {
        Form {

            Section(header: Text("Sécurité")) {

                SecureField("Mot de passe actuel", text: $currentPassword)
                SecureField("Nouveau mot de passe", text: $newPassword)
                SecureField("Confirmer", text: $confirmPassword)

                Button("Mettre à jour") {
                    changePassword()
                }
            }

            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Mot de passe")
    }

    func changePassword() {

        guard newPassword == confirmPassword else {
            message = "Les mots de passe ne correspondent pas"
            return
        }

        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            message = "Utilisateur introuvable"
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                message = "Mot de passe actuel incorrect"
                return
            }

            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    message = "Erreur: \(error.localizedDescription)"
                } else {
                    message = "Mot de passe mis à jour ✅"
                }
            }
        }
    }
}
