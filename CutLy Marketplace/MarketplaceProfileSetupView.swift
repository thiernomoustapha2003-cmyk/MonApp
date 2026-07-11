//
//  MarketplaceProfileSetupView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore


struct MarketplaceProfileSetupView: View {
    
    
    @State private var selectedPhotoData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    
    @State private var displayName = ""
    @State private var email = Auth.auth().currentUser?.email ?? ""
    @State private var phone = ""
    @State private var addressLine = ""
    @State private var postalCode = ""
    @State private var city = ""
    
    @State private var selectedCountry = ""
    @State private var selectedCity = ""
    
    @State private var selectedLanguage = "Français"
    @State private var selectedCurrency = "EUR (€)"
    
    @State private var profileType: MarketplaceProfileType = .personal
    
    @State private var currentStep = 1
    
    @State private var profileCompletion = 0.20
    
    @State private var selectedCountryCode = "+33"
    
    @State private var isLoading = false
    
    @State private var navigateNext = false
    
    @State private var errorMessage = ""
    
    @State private var showError = false
    
    @State private var canContinue = false
    
    
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 28) {
                
                progressSection
                
                header
                
                photoSection
                
                basicInformations
                
                profileTypeSection
                
                nextStepPreview
                
                continueButton
                
                
                NavigationLink(
                    destination: MarketplaceLocationSetupView(),
                    isActive: $navigateNext
                ) {
                    EmptyView()
                }
                
            }
            .padding(.vertical,30)
            
        }
        .navigationTitle("Profil Marketplace")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadExistingProfile()
            }
        
        .onChange(of: selectedPhoto) { newItem in
            Task {
                guard let newItem else { return }

                do {
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {

                        await MainActor.run {
                            selectedPhotoData = data
                            profileImage = Image(uiImage: uiImage)
                        }
                    }
                } catch {
                    print("❌ Erreur chargement photo:", error.localizedDescription)
                }
            }
        }
        
    }
    private var profileTypeSection: some View {
        
        VStack(alignment: .leading, spacing: 22) {
            
            Text("Quel type de profil souhaitez-vous ?")
                .font(.title3.bold())
            
            Text("Vous pourrez toujours changer ou faire évoluer votre profil plus tard.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            ForEach(MarketplaceProfileType.allCases) { type in
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                        profileType = type
                    }
                } label: {
                    
                    HStack(alignment: .center, spacing: 14) {
                        
                        ZStack {
                            Circle()
                                .fill(
                                    profileType == type
                                    ? LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [.gray.opacity(0.20), .gray.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 58, height: 58)
                            
                            Image(systemName: type.icon)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(profileType == type ? .white : .primary)
                        }
                        .frame(width: 58)
                        
                        VStack(alignment: .leading, spacing: 7) {
                            
                            Text(type.title)
                                .font(.headline.bold())
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(type.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if type == .buyerSeller {
                                Text("RECOMMANDÉ")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(Color.green.opacity(0.15))
                                    .clipShape(Capsule())
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: profileType == type ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(profileType == type ? .blue : .gray)
                    }
                    .padding(18)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                profileType == type ? Color.blue : Color.gray.opacity(0.15),
                                lineWidth: profileType == type ? 3 : 1
                            )
                    )
                    .shadow(
                        color: profileType == type ? .blue.opacity(0.15) : .black.opacity(0.04),
                        radius: profileType == type ? 16 : 6
                    )
                    .scaleEffect(profileType == type ? 1.01 : 1)
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
    private var nextStepPreview: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            Label("Étape suivante", systemImage: "arrow.right.circle.fill")
                .font(.headline)
            
            Text("Pays • Ville • Langue • Devise")
                .foregroundStyle(.secondary)
            
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    private var header: some View {
        
        VStack(spacing: 14) {
            
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Créer votre profil Marketplace")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
            
            Text("""
    Complétez votre profil pour acheter et vendre partout dans le monde.
    
    Vous pourrez modifier toutes ces informations plus tard.
    """)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            
        }
        
    }
    private var photoSection: some View {
        
        VStack(spacing: 18) {
            
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images
            ) {
                
                ZStack {
                    
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 140, height: 140)
                    
                    if let profileImage {
                        
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                        
                    } else {
                        
                        VStack(spacing: 10) {
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(.blue)
                            
                            Text("Ajouter une photo")
                                .font(.caption.bold())
                            
                        }
                        
                    }
                    
                }
                .overlay(
                    Circle()
                        .stroke(Color.blue.opacity(0.35), lineWidth: 3)
                )
                .shadow(color: .blue.opacity(0.15), radius: 12)
                
            }
            
            Text("Cette photo sera visible par les acheteurs et les vendeurs.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
        }
        .padding(.horizontal)
        
    }
    private var basicInformations: some View {
        
        VStack(alignment: .leading, spacing: 22) {
            
            Text("Informations de base")
                .font(.title3.bold())
            
            // Nom
            VStack(alignment: .leading, spacing: 8) {
                
                Text("Nom affiché")
                    .font(.headline)
                
                TextField("Ex : Thierno Barry", text: $displayName)
                    .textInputAutocapitalization(.words)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                
            }
            
            // Email obligatoire
            VStack(alignment: .leading, spacing: 8) {
                Text("Adresse e-mail")
                    .font(.headline)

                TextField("Ex : exemple@email.com", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Text("Obligatoire pour recevoir les tickets, confirmations, PDF colis et codes Marketplace.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            
            
            
            // Téléphone
            VStack(alignment: .leading, spacing: 8) {
                
                Text("Téléphone")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    
                    Menu {
                        
                        Button("+33 🇫🇷 France") {
                            selectedCountryCode = "+33"
                        }
                        
                        Button("+224 🇬🇳 Guinée") {
                            selectedCountryCode = "+224"
                        }
                        
                        Button("+221 🇸🇳 Sénégal") {
                            selectedCountryCode = "+221"
                        }
                        
                        Button("+212 🇲🇦 Maroc") {
                            selectedCountryCode = "+212"
                        }
                        
                        Button("+225 🇨🇮 Côte d'Ivoire") {
                            selectedCountryCode = "+225"
                        }
                        
                    } label: {
                        
                        HStack {
                            
                            Text(selectedCountryCode)
                            
                            Image(systemName: "chevron.down")
                            
                        }
                        .padding(.horizontal,14)
                        .padding(.vertical,12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                    }
                    
                    TextField("Numéro de téléphone", text: $phone)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                }
                
            }
            
            // Adresse facultative
            VStack(alignment: .leading, spacing: 8) {
                Text("Adresse de livraison / expédition")
                    .font(.headline)

                TextField("Ex : 16 rue Victor Hugo", text: $addressLine)
                    .textInputAutocapitalization(.words)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                HStack(spacing: 12) {
                    TextField("Code postal", text: $postalCode)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    TextField("Ville", text: $city)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                Text("Facultatif, mais recommandé pour que les tickets colis soient complets.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            
            VStack(alignment: .leading, spacing: 6) {
                
                Label(
                    "Ces informations permettront aux acheteurs et vendeurs de vous reconnaître.",
                    systemImage: "info.circle.fill"
                )
                .font(.caption)
                
                Text("Votre numéro pourra également servir à la récupération de votre compte si vous l'autorisez.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
            }
            
        }
        .padding(22)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: .black.opacity(0.04), radius: 10)
        .padding(.horizontal)
        
    }
    private var continueButton: some View {
        
        VStack(spacing: 14) {
            
            Button {
                
                saveMarketplaceStepOne()
                
            } label: {
                
                HStack(spacing: 12) {
                    
                    if isLoading {
                        
                        ProgressView()
                            .tint(.white)
                        
                    } else {
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                        
                        Text("Continuer")
                            .font(.headline.bold())
                        
                    }
                    
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical,18)
                .background(
                    
                    LinearGradient(
                        colors: [.purple,.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))
                
            }
            .buttonStyle(.plain)
            
            Text("Étape suivante : localisation, langue et devise.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
        }
        .padding(.horizontal)
        
    }
    private func saveMarketplaceStepOne() {

        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAddress = addressLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPostalCode = postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCity = city.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            errorMessage = "Veuillez entrer votre nom."
            showError = true
            return
        }

        guard cleanEmail.contains("@"), cleanEmail.contains(".") else {
            errorMessage = "Veuillez entrer une adresse e-mail valide."
            showError = true
            return
        }

        guard !cleanPhone.isEmpty else {
            errorMessage = "Veuillez entrer votre numéro de téléphone."
            showError = true
            return
        }

        isLoading = true

        Task {
            do {
                try await MarketplaceProfileService.shared.saveStepOne(
                    displayName: cleanName,
                    email: cleanEmail,
                    phone: cleanPhone,
                    countryCode: selectedCountryCode,
                    addressLine: cleanAddress,
                    postalCode: cleanPostalCode,
                    city: cleanCity,
                    profileType: profileType
                )

                if let selectedPhotoData {
                    _ = try await MarketplaceProfileService.shared.uploadProfilePhoto(
                        imageData: selectedPhotoData
                    )
                }

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
    private func loadExistingProfile() {
        Task {
            do {
                if let profile = try await MarketplaceProfileService.shared.reloadProfile() {
                    await MainActor.run {
                        displayName = profile.displayName ?? ""
                        phone = profile.phone ?? ""
                        selectedCountryCode = profile.countryCode ?? "+33"
                        email = profile.email ?? Auth.auth().currentUser?.email ?? ""
                        addressLine = profile.addressLine ?? ""
                        postalCode = profile.postalCode ?? ""
                        city = profile.city ?? ""
                        

                        if let savedType = profile.profileType,
                           let type = MarketplaceProfileType(rawValue: savedType) {
                            profileType = type
                        }
                    }
                }
            } catch {
                print("❌ loadExistingProfile:", error.localizedDescription)
            }
        }
    }
    
    
    
    
    
    
}

enum MarketplaceProfileType: String, CaseIterable, Identifiable {

    case personal
    case buyerSeller
    case business

    var id: String { rawValue }

    var title: String {

        switch self {

        case .personal:
            return "Particulier"

        case .buyerSeller:
            return "Acheteur / Vendeur"

        case .business:
            return "Boutique professionnelle"
        }
    }

    var subtitle: String {

        switch self {

        case .personal:
            return "Acheter uniquement"

        case .buyerSeller:
            return "Acheter et vendre avec le même compte"

        case .business:
            return "Créer une boutique professionnelle"
        }
    }

    var icon: String {

        switch self {

        case .personal:
            return "person.fill"

        case .buyerSeller:
            return "cart.badge.plus"

        case .business:
            return "storefront.fill"
        }
    }
}
