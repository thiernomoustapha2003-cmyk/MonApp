import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ClientRegisterView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                Text("Inscription Client")
                    .font(.title)
                    .bold()
                
                TextField("Prénom", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Nom", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Mot de passe", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    registerClient()
                }) {
                    Text("S'inscrire")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Créer un compte")
            .navigationBarTitleDisplayMode(.inline)
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK") { }
            }
        }
    }
    
    // =============================
    // 🔥 INSCRIPTION CLIENT
    // =============================
    
    func registerClient() {
        
        guard !firstName.isEmpty,
              !lastName.isEmpty,
              !email.isEmpty,
              !password.isEmpty else {
            
            alertMessage = "❌ Veuillez remplir tous les champs."
            showAlert = true
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            
            if let error = error as NSError? {
                
                switch error.code {
                    
                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    alertMessage = "❌ Cette adresse e-mail est déjà utilisée."
                    
                case AuthErrorCode.invalidEmail.rawValue:
                    alertMessage = "❌ Adresse e-mail invalide."
                    
                case AuthErrorCode.weakPassword.rawValue:
                    alertMessage = "❌ Mot de passe trop faible."
                    
                default:
                    alertMessage = "❌ Une erreur est survenue."
                }
                
                showAlert = true
                return
            }
            
            guard let user = result?.user else { return }
            
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = "\(firstName) \(lastName)"
            
            changeRequest.commitChanges { _ in }
            
            Firestore.firestore().collection("users").document(user.uid).setData([
                "uid": user.uid,
                "firstName": firstName,
                "lastName": lastName,
                "name": "\(firstName) \(lastName)",
                "email": email,
                "role": "client",
                "emailVerified": false,
                "createdAt": Timestamp()
            ]) { error in
                
                if let error = error {
                    print("❌ Firestore:", error.localizedDescription)
                    alertMessage = "❌ Impossible de créer le profil."
                    showAlert = true
                    return
                }
                
                user.sendEmailVerification { error in
                    
                    if let error = error {
                        print("❌ Email:", error.localizedDescription)
                        alertMessage = "❌ Impossible d'envoyer l'e-mail de vérification."
                        showAlert = true
                        return
                    }
                    
                    try? Auth.auth().signOut()
                    
                    alertMessage = "✅ Compte créé. Vérifie ton e-mail avant de te connecter."
                    showAlert = true
                }
            }
        }
    }
}
