import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore

struct AppleAuthView: View {
    
    @State private var currentNonce: String?
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            SignInWithAppleButton(.signIn) { request in
                let nonce = randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    handleAppleSignIn(authorization)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
            .frame(height: 50)
            .padding()
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .navigationTitle("Connexion Apple")
    }
    
    // MARK: - Connexion Apple
    func handleAppleSignIn(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Erreur lors de l’authentification Apple."
            return
        }
        
        guard let nonce = currentNonce else {
            errorMessage = "Nonce introuvable."
            return
        }
        
        guard let idTokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: idTokenData, encoding: .utf8) else {
            errorMessage = "Impossible de récupérer le token Apple."
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
            
            saveUserToFirestore(userId: user.uid, email: user.email)
        }
    }
    
    func saveUserToFirestore(userId: String, email: String?) {
        let db = Firestore.firestore()
        
        let userData: [String: Any] = [
            "email": email ?? "",
            "role": "client",
            "createdAt": Timestamp()
        ]
        
        db.collection("users").document(userId).setData(userData, merge: true) { error in
            if let error = error {
                errorMessage = "Erreur Firestore: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Helpers Apple Sign In
    func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
