import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    @State private var navigateToClient = false
    @State private var navigateToBarber = false
    
    // Pour Apple Sign In
    @State private var currentNonce: String?
    
    // ✅ NOUVEAU : navigation vers inscription (TU L’AS DÉJÀ MIS — JE LE GARDE)
    @State private var navigateToRegister = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                Text("Connexion")
                    .font(.largeTitle)
                    .bold()
                
                // EMAIL FIELD
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                // PASSWORD FIELD
                SecureField("Mot de passe", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // BOUTON CONNEXION EMAIL
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Se connecter")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                }
                .disabled(isLoading)
                
                Text("OU")
                    .font(.headline)
                    .padding(.top, 10)
                
                // BOUTON APPLE SIGN IN
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.email, .fullName]
                        request.nonce = sha256(nonce)
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            handleAppleSignIn(authResults)
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                )
                .frame(height: 55)
                .cornerRadius(10)
                
                // ✅ BOUTON INSCRIPTION (TU L’AVAIS — JE GARDE)
                Button("Créer un compte") {
                    navigateToRegister = true
                }
                .foregroundColor(.blue)
                .padding(.top, 10)
                
                // NAVIGATIONS (SANS RIEN SUPPRIMER)
                NavigationLink(destination: ClientHomeView(), isActive: $navigateToClient) {
                    EmptyView()
                }
                
                NavigationLink(destination: BarberDashboardView(), isActive: $navigateToBarber) {
                    EmptyView()
                }
                
                // Navigation vers RegisterView (GARDÉE)
                NavigationLink(destination: RegisterView(), isActive: $navigateToRegister) {
                    EmptyView()
                }
                
            }
            .padding()
            .navigationTitle("Cutly")
        }
    }
    
    // MARK: - Connexion Email (TA FONCTION — GARDÉE)
    func login() {
        errorMessage = ""
        isLoading = true
        
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        Auth.auth().signIn(withEmail: cleanEmail, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }
            
            guard let userId = result?.user.uid else {
                self.errorMessage = "Utilisateur introuvable."
                self.isLoading = false
                return
            }


            // 📱 enregistrer appareil
            SessionManager.shared.registerSecureSession()

           
            fetchUserRole(userId: userId)
        }
    }
    
    // MARK: - Récupérer le rôle dans Firestore (TA LOGIQUE — GARDÉE)
    func fetchUserRole(userId: String) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Erreur Firestore: \(error.localizedDescription)"
                return
            }
            
            guard let data = snapshot?.data(),
                  let role = data["role"] as? String else {
                self.errorMessage = "Rôle utilisateur introuvable."
                return
            }
            
            print("ROLE =", role)
            
            if role == "client" {
                self.navigateToClient = true
            } else if role == "coiffeur" {
                self.navigateToBarber = true
            } else {
                self.errorMessage = "Rôle inconnu: \(role)"
            }
        }
    }
    
    // MARK: - Connexion Apple (TA VERSION — GARDÉE)
    func handleAppleSignIn(_ authResults: ASAuthorization) {
        guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
              let idTokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: idTokenData, encoding: .utf8),
              let nonce = currentNonce else {
            errorMessage = "Erreur lors de l’authentification Apple."
            return
        }
        
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user else {
                errorMessage = "Utilisateur introuvable."
                return
            }

            
            // 📱 enregistrer l'appareil
            SessionManager.shared.registerSecureSession()

          
            saveUserToFirestore(userId: user.uid, email: user.email)
        }
    }
    
    // ✅ AJOUT IMPORTANT (SANS SUPPRIMER) :
    // Si l’utilisateur Apple n’existe pas encore, on le crée comme "client"
    func saveUserToFirestore(userId: String, email: String?) {
        let db = Firestore.firestore()
        
        let userData: [String: Any] = [
            "email": email ?? "",
            "role": "client",
            "createdAt": Timestamp(),
            // 👉 On garde la cohérence avec RegisterView
            "isPro": false,
            "isCertified": false,
            "platformCommissionRate": 0.15
        ]
        
        db.collection("users").document(userId).setData(userData, merge: true) { error in
            if let error = error {
                errorMessage = "Erreur Firestore: \(error.localizedDescription)"
                return
            }
            
            navigateToClient = true
        }
    }
    
    // MARK: - Helpers pour Apple Sign In (TA VERSION — GARDÉE)
    func randomNonceString(length: Int = 32) -> String {
        let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            var random: UInt8 = 0
            SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
        
        return result
    }
    
    func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
