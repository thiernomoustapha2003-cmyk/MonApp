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
        
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            
            if let error = error as NSError? {

                switch error.code {

                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    errorMessage = "❌ Cette adresse e-mail est déjà utilisée."

                case AuthErrorCode.invalidEmail.rawValue:
                    errorMessage = "❌ Adresse e-mail invalide."

                case AuthErrorCode.weakPassword.rawValue:
                    errorMessage = "❌ Mot de passe trop faible."

                default:
                    errorMessage = "❌ Une erreur est survenue."
                }
            }
            
            guard let user = result?.user else { return }
            
            user.reload { error in
                
                if let error = error as NSError? {

                    switch error.code {

                    case AuthErrorCode.emailAlreadyInUse.rawValue:
                        errorMessage = "❌ Cette adresse e-mail est déjà utilisée."

                    case AuthErrorCode.invalidEmail.rawValue:
                        errorMessage = "❌ Adresse e-mail invalide."

                    case AuthErrorCode.weakPassword.rawValue:
                        errorMessage = "❌ Mot de passe trop faible."

                    default:
                        errorMessage = "❌ Une erreur est survenue."
                    }
                }
                
                if Auth.auth().currentUser?.isEmailVerified == true {
                    onSuccess()
                    dismiss()
                } else {
                    errorMessage = "⚠️ Tu dois confirmer ton adresse e-mail avant de continuer."
                    try? Auth.auth().signOut()
                }
            }
        }
    }

    func register() {
        
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            
            if let error = error as NSError? {

                switch error.code {

                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    errorMessage = "❌ Cette adresse e-mail est déjà utilisée."

                case AuthErrorCode.invalidEmail.rawValue:
                    errorMessage = "❌ Adresse e-mail invalide."

                case AuthErrorCode.weakPassword.rawValue:
                    errorMessage = "❌ Mot de passe trop faible."

                default:
                    errorMessage = "❌ Une erreur est survenue."
                }
            }
            
            guard let user = result?.user else { return }
            
            let changeRequest = user.createProfileChangeRequest()
            let username = email.components(separatedBy: "@").first ?? "Client"
            changeRequest.displayName = username
            
            changeRequest.commitChanges { error in
                if let error = error as NSError? {

                    switch error.code {

                    case AuthErrorCode.emailAlreadyInUse.rawValue:
                        errorMessage = "❌ Cette adresse e-mail est déjà utilisée."

                    case AuthErrorCode.invalidEmail.rawValue:
                        errorMessage = "❌ Adresse e-mail invalide."

                    case AuthErrorCode.weakPassword.rawValue:
                        errorMessage = "❌ Mot de passe trop faible."

                    default:
                        errorMessage = "❌ Une erreur est survenue."
                    }
                }
                
                user.sendEmailVerification { error in
                    if let error = error as NSError? {

                        switch error.code {

                        case AuthErrorCode.emailAlreadyInUse.rawValue:
                            errorMessage = "❌ Cette adresse e-mail est déjà utilisée."

                        case AuthErrorCode.invalidEmail.rawValue:
                            errorMessage = "❌ Adresse e-mail invalide."

                        case AuthErrorCode.weakPassword.rawValue:
                            errorMessage = "❌ Mot de passe trop faible."

                        default:
                            errorMessage = "❌ Une erreur est survenue."
                        }
                    }
                    
                    errorMessage = "✅ Compte créé. Vérifie ton adresse e-mail avant de te connecter."
                    isRegistering = false
                    
                    try? Auth.auth().signOut()
                }
            }
        }
    }
}

