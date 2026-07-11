//
//  MarketplaceVerificationView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import SwiftUI
import FirebaseFunctions
import FirebaseAuth

struct MarketplaceVerificationView: View {
    
    private let functions = Functions.functions(region: "us-central1")
    
    
    @State private var goToProfileSetup = false
    
    @State private var currentStep = 4
    @State private var profileCompletion = 0.80
    
    @State private var verificationMethod: MarketplaceVerificationMethod = .email
    @State private var verificationCode = ""
    
    @State private var codeSent = false
    @State private var isLoading = false
    @State private var navigateNext = false
    
    @State private var errorMessage = ""
    @State private var showError = false
    
    @State private var verificationEmail = ""
    @State private var verificationPhone = ""
    @State private var firebaseVerificationID = ""
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                progressSection
                headerSection
                methodSection
                codeSection
                nextStepPreview
                continueButton
                
                NavigationLink(
                    destination: MarketplaceProfileSetupView(),
                    isActive: $goToProfileSetup
                ) {
                    EmptyView()
                }
                
                NavigationLink(
                    destination: MarketplaceSetupSummaryView(),
                    isActive: $navigateNext
                ) {
                    EmptyView()
                }
            }
            .padding(.vertical, 30)
        }
        .navigationTitle("Vérification")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    goToProfileSetup = true
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {

            if let user = Auth.auth().currentUser {
                print("✅ UID :", user.uid)
                print("✅ Email :", user.email ?? "aucun")
            } else {
                print("❌ Aucun utilisateur Firebase connecté")
            }

            loadExistingVerification()
        }
        .onAppear {
            codeSent = false
            verificationCode = ""
            firebaseVerificationID = ""
            errorMessage = ""
            showError = false
        }
        
        
    }
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Étape \(currentStep) / 5")
                    .font(.headline)

                Spacer()

                Text("\(Int(profileCompletion * 100)) %")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }

            ProgressView(value: profileCompletion)
                .tint(.blue)
        }
        .padding(.horizontal)
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 58, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Vérifiez votre compte")
                .font(.title2.bold())

            Text("Choisissez comment recevoir votre code. Cette vérification est demandée une seule fois pour sécuriser votre profil Marketplace.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var methodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Méthode de vérification")
                .font(.title3.bold())

            ForEach(MarketplaceVerificationMethod.allCases) { method in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        verificationMethod = method
                        codeSent = false
                        verificationCode = ""
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: method.icon)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(verificationMethod == method ? .white : .blue)
                            .frame(width: 48, height: 48)
                            .background(
                                verificationMethod == method
                                ? LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.blue.opacity(0.14), .purple.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(method.title)
                                .font(.headline)

                            Text(method.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: verificationMethod == method ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(verificationMethod == method ? .blue : .gray)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(verificationMethod == method ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.04), radius: 10)
        .padding(.horizontal)
    }
    private var codeSection: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Code de vérification")
                .font(.title3.bold())

            // Champ e-mail uniquement si la méthode choisie est E-mail
            if verificationMethod == .email {

                TextField("Adresse e-mail de réception", text: $verificationEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

            }
            if verificationMethod == .phone {
                TextField("Numéro au format international", text: $verificationPhone)
                    .keyboardType(.phonePad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Text("Exemple : +33612345678 ou +2246XXXXXXX")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            
            
            if !codeSent {

                Button {

                    sendVerificationCode()

                } label: {

                    Label(
                        verificationMethod == .email
                        ? "Envoyer le code par e-mail"
                        : "Envoyer le code par SMS",
                        systemImage: "paperplane.fill"
                    )
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                }
                .buttonStyle(.plain)

            } else {

                TextField("Entrer le code reçu", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Button {

                    sendVerificationCode()

                } label: {

                    Text("Renvoyer le code")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)

                }

            }

        }
        .padding(22)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.04), radius: 10)
        .padding(.horizontal)

    }
    private var nextStepPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Étape suivante", systemImage: "checkmark.seal.fill")
                .font(.headline)

            Text("Finaliser votre profil Marketplace.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }

    private var continueButton: some View {
        VStack(spacing: 14) {
            Button {
                guard codeSent else { return }
                guard verificationCode.count >= 4 else { return }

                isLoading = true

                saveMarketplaceVerification()
            } label: {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Vérifier et terminer")
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
            .buttonStyle(.plain)

            Text("La vérification sera demandée une seule fois.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private func sendVerificationCode() {

        isLoading = true
        errorMessage = ""
        showError = false

        if verificationMethod == .phone {

            let phone = verificationPhone.trimmingCharacters(in: .whitespacesAndNewlines)

            guard phone.hasPrefix("+"), phone.count >= 8 else {
                isLoading = false
                errorMessage = "Entre un numéro valide au format international, ex : +33612345678"
                showError = true
                return
            }

            PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { verificationID, error in
                DispatchQueue.main.async {
                    isLoading = false

                    if let error = error {

                        print("❌ Firebase Phone Auth Error :", error)

                        let nsError = error as NSError
                        print("❌ Code :", nsError.code)
                        print("❌ Domaine :", nsError.domain)
                        print("❌ Infos :", nsError.userInfo)

                        errorMessage = error.localizedDescription
                        showError = true
                        return
                    }

                    firebaseVerificationID = verificationID ?? ""
                    codeSent = true
                }
            }

            return
        }

        let cleanEmail = verificationEmail
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard cleanEmail.contains("@"), cleanEmail.contains(".") else {
            isLoading = false
            errorMessage = "Entre une adresse e-mail valide."
            showError = true
            return
        }

        Task {
            do {
                let result = try await functions
                    .httpsCallable("sendMarketplaceVerificationCode")
                    .call([
                        "method": "email",
                        "email": cleanEmail
                    ])

                print("✅ Code envoyé :", result.data)

                await MainActor.run {
                    isLoading = false
                    codeSent = true
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    private func saveMarketplaceVerification() {

        guard codeSent else { return }

        let cleanCode = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanCode.count >= 4 else {
            errorMessage = "Entre le code reçu."
            showError = true
            return
        }

        isLoading = true
        errorMessage = ""
        showError = false

        if verificationMethod == .phone {

            guard !firebaseVerificationID.isEmpty else {
                isLoading = false
                errorMessage = "Code SMS introuvable. Renvoyez un code."
                showError = true
                return
            }

            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: firebaseVerificationID,
                verificationCode: cleanCode
            )

            guard let user = Auth.auth().currentUser else {
                isLoading = false
                errorMessage = "Utilisateur non connecté."
                showError = true
                return
            }

            func finishAfterPhoneVerified() {
                Task {
                    do {
                        try await MarketplaceProfileService.shared.saveVerification(method: verificationMethod)

                        await MainActor.run {
                            isLoading = false
                            navigateNext = true
                        }
                    } catch {
                        await MainActor.run {
                            isLoading = false
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }

            if user.phoneNumber != nil {
                user.unlink(fromProvider: PhoneAuthProviderID) { _, _ in
                    user.link(with: credential) { _, error in
                        if let error = error {
                            DispatchQueue.main.async {
                                isLoading = false
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                            return
                        }

                        finishAfterPhoneVerified()
                    }
                }
            } else {
                user.link(with: credential) { _, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            isLoading = false
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                        return
                    }

                    finishAfterPhoneVerified()
                }
            }

            return
        }

        Task {
            do {
                let result = try await functions
                    .httpsCallable("verifyMarketplaceVerificationCode")
                    .call([
                        "code": cleanCode
                    ])

                print("✅ Code vérifié :", result.data)

                try await MarketplaceProfileService.shared.saveVerification(method: verificationMethod)

                await MainActor.run {
                    isLoading = false
                    navigateNext = true
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    private func loadExistingVerification() {
        Task {
            do {
                if let profile = try await MarketplaceProfileService.shared.reloadProfile() {
                    await MainActor.run {
                        if let method = profile.verificationMethod,
                           let savedMethod = MarketplaceVerificationMethod(rawValue: method) {
                            verificationMethod = savedMethod
                        }
                    }
                }
            } catch {
                print("❌ loadExistingVerification:", error.localizedDescription)
            }
        }
    }
    private func firebasePhoneErrorMessage(_ error: Error) -> String {
        let nsError = error as NSError

        switch nsError.code {
        case AuthErrorCode.invalidPhoneNumber.rawValue:
            return "Numéro invalide. Entre ton numéro au format international, par exemple +33612345678."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Trop de tentatives. Attends quelques minutes avant de réessayer."
        case AuthErrorCode.quotaExceeded.rawValue:
            return "Le service SMS est momentanément limité. Réessaie plus tard."
        default:
            return "Impossible d’envoyer le SMS. Vérifie ton numéro et réessaie."
        }
    }
    
    
}

enum MarketplaceVerificationMethod: String, CaseIterable, Identifiable {
    case email
    case phone

    var id: String { rawValue }

    var title: String {
        switch self {
        case .email: return "E-mail"
        case .phone: return "Téléphone"
        }
    }

    var icon: String {
        switch self {
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .email: return "Recevoir un code par e-mail"
        case .phone: return "Recevoir un code par SMS"
        }
    }
}
