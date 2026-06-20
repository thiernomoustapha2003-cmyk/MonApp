import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var password = ""
    @State private var role = "client" // client ou coiffeur
    @State private var errorMessage = ""
    @State private var isLoading = false

    // ✅ Navigation après inscription (CORRIGÉ)
    @State private var goToBarberRegister = false   // <-- NOUVEAU (PROFIL COIFFEUR)
    @State private var goToClientHome = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                
                Text("Cutly")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                TextField("Nom", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Téléphone", text: $phone)
                    .keyboardType(.phonePad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Mot de passe", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Rôle", selection: $role) {
                    Text("Client").tag("client")
                    Text("Coiffeur").tag("coiffeur")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 10)
                
                Button(action: register) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Créer le compte")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                // ✅ NAVIGATION CORRIGÉE → PROFIL COIFFEUR (BarberRegisterView)
                NavigationLink(
                    destination: BarberRegisterView(),
                    isActive: $goToBarberRegister
                ) {
                    EmptyView()
                }
                .hidden()

                // ✅ NAVIGATION CLIENT (inchangée)
                NavigationLink(
                    destination: ClientHomeView(),
                    isActive: $goToClientHome
                ) {
                    EmptyView()
                }
                .hidden()
                
            }
            .padding()
        }
    }
    
    // ✅ FONCTION INSCRIPTION FIREBASE (TA LOGIQUE — JUSTE LA NAVIGATION CHANGÉE)
    func register() {
        
        errorMessage = ""
        
        if name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty {
            errorMessage = "❌ Remplis tous les champs."
            return
        }
        
        let cleanEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        isLoading = true
        
        Auth.auth().createUser(withEmail: cleanEmail, password: password) { authResult, error in
            
            if let error = error as NSError? {
                DispatchQueue.main.async {
                    isLoading = false
                    
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
                return
            }
            
            guard let user = authResult?.user else {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "❌ Impossible de récupérer l'utilisateur."
                }
                return
            }
            
            let userId = user.uid
            let db = Firestore.firestore()
            
            let data: [String: Any] = [
                "uid": userId,
                "name": name,
                "phone": phone,
                "email": cleanEmail,
                "role": role,
                "emailVerified": false,
                "createdAt": Timestamp(),
                "isPro": false,
                "isCertified": false,
                "platformCommissionRate": 0.15
            ]
            
            db.collection("users").document(userId).setData(data) { error in
                
                if let error = error {
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage = "❌ Impossible de créer le profil utilisateur."
                    }
                    print("❌ Firestore error:", error.localizedDescription)
                    return
                }
                
                user.sendEmailVerification { error in
                    
                    if let error = error {
                        DispatchQueue.main.async {
                            isLoading = false
                            errorMessage = "❌ Impossible d’envoyer l’e-mail de vérification."
                        }
                        print("❌ Email verification error:", error.localizedDescription)
                        return
                    }
                    
                    try? Auth.auth().signOut()
                    
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage = "✅ Compte créé. Vérifie ton e-mail avant de te connecter."
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}
