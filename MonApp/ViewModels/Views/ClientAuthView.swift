import SwiftUI
import FirebaseAuth

struct ClientAuthView: View {

    var onSuccess: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {

            Text(isRegistering ? "Créer un compte" : "Connexion")
                .font(.title2)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)

            SecureField("Mot de passe", text: $password)
                .textFieldStyle(.roundedBorder)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button(isRegistering ? "S'inscrire" : "Se connecter") {
                isRegistering ? register() : login()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(12)

            Button(isRegistering ? "Déjà un compte ?" : "Créer un compte") {
                isRegistering.toggle()
            }
        }
        .padding()
    }

    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                onSuccess()
                dismiss()
            }
        }
    }

    func register() {
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user else { return }
            
            user.sendEmailVerification()
            // 🔥 Création automatique du displayName
            let changeRequest = user.createProfileChangeRequest()
            
            let username = email.components(separatedBy: "@").first ?? "Client"
            
            changeRequest.displayName = username
            
            changeRequest.commitChanges { error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                onSuccess()
                dismiss()
            }
        }
    }
}

