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
            
            alertMessage = "Veuillez remplir tous les champs"
            showAlert = true
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                return
            }
            
            guard let user = result?.user else { return }
            
            // 🔥 1️⃣ Mettre le displayName automatiquement
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = "\(firstName) \(lastName)"
            
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Erreur displayName:", error.localizedDescription)
                }
            }
            
            // 🔥 2️⃣ Créer le document Firestore
            Firestore.firestore().collection("users").document(user.uid).setData([
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "role": "client",
                "createdAt": Timestamp()
            ])
            
            alertMessage = "Compte créé avec succès 🎉"
            showAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                dismiss()
            }
        }
    }
}
