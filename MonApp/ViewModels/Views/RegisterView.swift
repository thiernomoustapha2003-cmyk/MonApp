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
            
            isLoading = false
            
            if let error = error {
                print("❌ Firebase Auth error:", error.localizedDescription)
                errorMessage = error.localizedDescription
                return
            }
            
            guard let userId = authResult?.user.uid else {
                errorMessage = "❌ Impossible de récupérer l'utilisateur."
                return
            }
            
            let db = Firestore.firestore()
            
            let data: [String: Any] = [
                "name": name,
                "phone": phone,
                "email": cleanEmail,
                "role": role,
                "createdAt": Timestamp(),

                // Champs profil coiffeur par défaut (TU LES GARDES)
                "isPro": false,
                "isCertified": false,
                "platformCommissionRate": 0.15
            ]
            
            db.collection("users").document(userId).setData(data) { error in
                if let error = error {
                    print("❌ Firestore error:", error.localizedDescription)
                    errorMessage = error.localizedDescription
                } else {
                    print("✅ Compte créé avec succès")

                    // ✅ REDIRECTION CORRIGÉE
                    if role == "coiffeur" {
                        goToBarberRegister = true   // 👉 PROFIL COIFFEUR D'ABORD
                    } else {
                        goToClientHome = true      // 👉 Client va directement à l’app
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}
