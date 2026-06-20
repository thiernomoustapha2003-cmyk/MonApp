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
    
    @State private var navigateToBarberProfile = false
    
    @State private var navigateToClient = false
    @State private var navigateToBarber = false
    
    @State private var showVerificationActions = false
    
    // Pour Apple Sign In
    @State private var currentNonce: String?
    
    // ✅ NOUVEAU : navigation vers inscription (TU L’AS DÉJÀ MIS — JE LE GARDE)
    @State private var navigateToRegister = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    Text("Connexion")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 30)
                    
                    // EMAIL FIELD
                    TextField("Exemple : nom@gmail.com", text: $email)
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
                            .multilineTextAlignment(.center)
                    }
                    
                    if showVerificationActions {
                        Button("📧 Renvoyer l'email de vérification") {
                            resendVerificationEmail()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                        Button("✅ J’ai confirmé mon email") {
                            checkEmailVerification()
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                    }
                    
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
                            case .failure:
                                errorMessage = "❌ Connexion Apple impossible. Réessaie."
                            }
                        }
                    )
                    .frame(height: 55)
                    .cornerRadius(10)
                    
                    Button("Créer un compte") {
                        navigateToRegister = true
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 10)
                    
                    
                    NavigationLink(destination: BarberProfileView(), isActive: $navigateToBarberProfile) {
                        EmptyView()
                    }
                    
                    
                    NavigationLink(destination: ClientHomeView(), isActive: $navigateToClient) {
                        EmptyView()
                    }
                    
                    NavigationLink(destination: BarberDashboardView(), isActive: $navigateToBarber) {
                        EmptyView()
                    }
                    
                    NavigationLink(destination: RegisterView(), isActive: $navigateToRegister) {
                        EmptyView()
                    }
                }
                .padding()
            }
            .navigationTitle("Cutly")
        }
    }
    
    // MARK: - Connexion Email (TA FONCTION — GARDÉE)
    func login() {
        errorMessage = ""
        showVerificationActions = false
        isLoading = true
        
        let cleanEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        Auth.auth().signIn(withEmail: cleanEmail, password: password) { result, error in
            
            if let error = error as NSError? {
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch error.code {
                    case AuthErrorCode.invalidEmail.rawValue:
                        self.errorMessage = "❌ Adresse e-mail invalide."
                        
                    case AuthErrorCode.userNotFound.rawValue:
                        self.errorMessage = "❌ Aucun compte trouvé avec cette adresse e-mail."
                        
                    case AuthErrorCode.wrongPassword.rawValue:
                        self.errorMessage = "❌ Mot de passe incorrect."
                        
                    case AuthErrorCode.userDisabled.rawValue:
                        self.errorMessage = "❌ Ce compte a été désactivé."
                        
                    default:
                        self.errorMessage = "❌ Email ou mot de passe incorrect."
                    }
                }
                return
            }
            
            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "❌ Utilisateur introuvable."
                }
                return
            }
            
            user.reload { error in
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "❌ Impossible de vérifier votre compte."
                    }
                    print("❌ Reload user error:", error.localizedDescription)
                    return
                }
                
                let refreshedUser = Auth.auth().currentUser
                
                if refreshedUser?.isEmailVerified == false {
                    DispatchQueue.main.async {
                        self.errorMessage = "📧 Vérifie ton adresse e-mail avant de continuer."
                        self.showVerificationActions = true
                        self.isLoading = false
                    }
                    return
                }
                
                SessionManager.shared.registerSecureSession()
                fetchUserRole(userId: user.uid)
            }
        }
    }
    
    func resendVerificationEmail() {
        
        guard let user = Auth.auth().currentUser else {
            errorMessage = "❌ Reconnecte-toi pour renvoyer l'e-mail."
            return
        }
        
        user.sendEmailVerification { error in
            
            if let error = error {
                print("❌ Erreur envoi email :", error.localizedDescription)
                self.errorMessage = "❌ Impossible d'envoyer l'e-mail de vérification."
                return
            }
            
            self.errorMessage = "✅ E-mail de vérification renvoyé."
        }
    }

    func checkEmailVerification() {
        
        guard let user = Auth.auth().currentUser else {
            errorMessage = "❌ Utilisateur introuvable."
            return
        }
        
        isLoading = true
        
        user.reload { error in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "❌ Impossible de vérifier ton adresse e-mail."
                }
                print("❌ Reload verification error:", error.localizedDescription)
                return
            }
            
            if Auth.auth().currentUser?.isEmailVerified == true {
                DispatchQueue.main.async {
                    self.showVerificationActions = false
                    SessionManager.shared.registerSecureSession()
                    self.fetchUserRole(userId: user.uid)
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "⚠️ E-mail pas encore confirmé. Clique sur le lien reçu dans ta boîte mail."
                }
            }
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
            
            let profileCompleted = data["profileCompleted"] as? Bool ?? false
            
            print("ROLE =", role)
            print("PROFILE COMPLETED =", profileCompleted)
            
            if role == "client" {
                self.navigateToClient = true
            } else if role == "coiffeur" {
                if profileCompleted {
                    self.navigateToBarber = true
                } else {
                    self.navigateToBarberProfile = true
                    // On va corriger la navigation juste après
                }
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
            errorMessage = "❌ Erreur lors de l’authentification Apple."
            return
        }
        
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        Auth.auth().signIn(with: credential) { result, error in
            
            if let error = error {
                print("❌ Apple Sign In error:", error.localizedDescription)
                errorMessage = "❌ Connexion Apple impossible. Réessaie."
                return
            }
            
            guard let user = result?.user else {
                errorMessage = "❌ Utilisateur introuvable."
                return
            }
            
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
