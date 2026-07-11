//
//  MarketplaceAuthView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 02/07/2026.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit

struct MarketplaceAuthView: View {

    enum Mode {
        case login
        case register
        case forgotPassword
    }

    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .login

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""

    @State private var navigateToMarketplaceEntry = false

    @State private var currentNonce: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                headerSection

                formSection

                actionButton

                secondaryActions

                if mode != .forgotPassword {
                    appleSignInSection
                }

                NavigationLink(
                    destination: MarketplaceEntryView(),
                    isActive: $navigateToMarketplaceEntry
                ) {
                    EmptyView()
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
        }
        .navigationTitle("Compte Marketplace")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag.fill")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {

            TextField("Adresse e-mail", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if mode != .forgotPassword {
                SecureField("Mot de passe", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            if mode == .register {
                SecureField("Confirmer le mot de passe", text: $confirmPassword)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption.bold())
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if !successMessage.isEmpty {
                Text(successMessage)
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var actionButton: some View {
        Button {
            handleMainAction()
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(buttonTitle)
                        .font(.headline.bold())
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .disabled(isLoading)
    }

    private var secondaryActions: some View {
        VStack(spacing: 12) {

            if mode == .login {
                Button("Mot de passe oublié ?") {
                    resetMessages()
                    mode = .forgotPassword
                }

                Button("Créer un compte Marketplace") {
                    resetMessages()
                    mode = .register
                }
            }

            if mode == .register {
                Button("J’ai déjà un compte") {
                    resetMessages()
                    mode = .login
                }
            }

            if mode == .forgotPassword {
                Button("Retour à la connexion") {
                    resetMessages()
                    mode = .login
                }
            }
        }
        .font(.subheadline.bold())
        .foregroundStyle(.blue)
    }

    private var appleSignInSection: some View {
        VStack(spacing: 14) {
            Text("OU")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            SignInWithAppleButton(.signIn) { request in
                let nonce = randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.email, .fullName]
                request.nonce = sha256(nonce)
            } onCompletion: { result in
                switch result {
                case .success(let authResults):
                    handleAppleSignIn(authResults)
                case .failure:
                    errorMessage = "Connexion Apple impossible. Réessaie."
                }
            }
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var title: String {
        switch mode {
        case .login: return "Connexion Marketplace"
        case .register: return "Créer un compte Marketplace"
        case .forgotPassword: return "Réinitialiser le mot de passe"
        }
    }

    private var subtitle: String {
        switch mode {
        case .login:
            return "Connectez-vous pour acheter, vendre, gérer vos commandes et sécuriser votre profil."
        case .register:
            return "Créez votre compte avec une adresse e-mail et un mot de passe sécurisé."
        case .forgotPassword:
            return "Entrez votre adresse e-mail. Nous vous enverrons un lien sécurisé pour modifier votre mot de passe."
        }
    }

    private var buttonTitle: String {
        switch mode {
        case .login: return "Se connecter"
        case .register: return "Créer mon compte"
        case .forgotPassword: return "Envoyer le lien"
        }
    }

    private func handleMainAction() {
        resetMessages()

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard cleanEmail.contains("@"), cleanEmail.contains(".") else {
            errorMessage = "Adresse e-mail invalide."
            return
        }

        switch mode {
        case .login:
            login(email: cleanEmail)

        case .register:
            register(email: cleanEmail)

        case .forgotPassword:
            resetPassword(email: cleanEmail)
        }
    }

    private func login(email: String) {
        guard !password.isEmpty else {
            errorMessage = "Entre ton mot de passe."
            return
        }

        isLoading = true

        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            isLoading = false

            if let error = error as NSError? {
                errorMessage = firebaseAuthMessage(error)
                return
            }

            navigateToMarketplaceEntry = true
        }
    }

    private func register(email: String) {
        guard password.count >= 6 else {
            errorMessage = "Le mot de passe doit contenir au moins 6 caractères."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Les deux mots de passe ne correspondent pas."
            return
        }

        isLoading = true

        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            isLoading = false

            if let error = error as NSError? {
                errorMessage = firebaseAuthMessage(error)
                return
            }

            navigateToMarketplaceEntry = true
        }
    }

    private func resetPassword(email: String) {
        isLoading = true

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isLoading = false

            if let error = error as NSError? {
                errorMessage = firebaseAuthMessage(error)
                return
            }

            successMessage = "Un e-mail de réinitialisation a été envoyé. Ouvre le lien reçu pour créer un nouveau mot de passe."
        }
    }

    private func handleAppleSignIn(_ authResults: ASAuthorization) {
        guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
              let idTokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: idTokenData, encoding: .utf8),
              let nonce = currentNonce else {
            errorMessage = "Erreur lors de la connexion Apple."
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        isLoading = true

        Auth.auth().signIn(with: credential) { _, error in
            isLoading = false

            if let error = error as NSError? {
                errorMessage = firebaseAuthMessage(error)
                return
            }

            navigateToMarketplaceEntry = true
        }
    }

    private func firebaseAuthMessage(_ error: NSError) -> String {
        switch error.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "Adresse e-mail invalide."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Cette adresse e-mail est déjà utilisée."
        case AuthErrorCode.wrongPassword.rawValue:
            return "Mot de passe incorrect."
        case AuthErrorCode.userNotFound.rawValue:
            return "Aucun compte trouvé avec cette adresse e-mail."
        case AuthErrorCode.weakPassword.rawValue:
            return "Le mot de passe est trop faible."
        case AuthErrorCode.networkError.rawValue:
            return "Problème de connexion internet. Réessaie."
        default:
            return "Impossible de continuer. Vérifie les informations et réessaie."
        }
    }

    private func resetMessages() {
        errorMessage = ""
        successMessage = ""
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""

        while result.count < length {
            var random: UInt8 = 0
            SecRandomCopyBytes(kSecRandomDefault, 1, &random)

            if random < charset.count {
                result.append(charset[Int(random)])
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
