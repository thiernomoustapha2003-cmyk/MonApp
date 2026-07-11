//
//  MarketplaceLocationSetupView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import SwiftUI

struct MarketplaceLocationSetupView: View {
    
    @State private var selectedCountry = ""
    
    @State private var selectedCity = ""
    
    @State private var selectedLanguage = "Français"
    
    @State private var selectedCurrency = "EUR (€)"
    
    @State private var currentStep = 2
    
    @State private var profileCompletion = 0.40
    
    @State private var navigateNext = false
    
    @State private var isLoading = false
    
    
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 28) {
                
                progressSection
                
                headerSection
                
                countrySection
                
                citySection
                
                languageSection
                
                currencySection
                
                nextStepPreview
                
                continueButton
                
                NavigationLink(
                    destination: MarketplacePaymentSetupView(),
                    isActive: $navigateNext
                ) {
                    EmptyView()
                }
            }
            .padding(.vertical,30)
            
        }
        .navigationTitle("Localisation")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadExistingLocation()
        }
        
        
    }
    private var progressSection: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                
                Text("Étape \(currentStep) / 5")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(profileCompletion * 100)) %")
                    .foregroundStyle(.blue)
                    .font(.headline)
                
            }
            
            ProgressView(value: profileCompletion)
                .tint(.blue)
            
        }
        .padding(.horizontal)
        
    }
    
    private var headerSection: some View {
        
        VStack(spacing: 8) {
            
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 52))
                .foregroundStyle(.blue)
            
            Text("Votre localisation")
            
                .font(.title2.bold())
            
            Text("Ces informations permettront d'adapter automatiquement votre devise, vos paiements et votre expérience Marketplace.")
            
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
        }
        .padding(.horizontal)
        
    }
    private var countrySection: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Label("Pays", systemImage: "globe.europe.africa.fill")
                .font(.headline)
            
            Menu {
                
                ForEach(MarketplaceCountries.all) { country in
                    
                    Button {
                        
                        selectedCountry = country.name
                        selectedLanguage = country.defaultLanguage
                        selectedCurrency = country.defaultCurrency
                        
                    } label: {
                        
                        Label(
                            "\(country.flag) \(country.name)",
                            systemImage: "checkmark"
                        )
                        
                    }
                    
                }
                
            } label: {
                
                HStack {
                    
                    if selectedCountry.isEmpty {
                        
                        Text("Choisir votre pays")
                            .foregroundStyle(.secondary)
                        
                    } else {
                        
                        Text(selectedCountry)
                        
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                    
                }
                .padding()
                
                .background(Color(.secondarySystemBackground))
                
                .clipShape(RoundedRectangle(cornerRadius: 18))
                
            }
            
        }
        .padding(.horizontal)
        
    }
    
    private var citySection: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Label("Ville", systemImage: "building.2.fill")
                .font(.headline)
            
            Menu {
                
                if let country = MarketplaceCountries.all.first(where: { $0.name == selectedCountry }) {
                    
                    ForEach(country.mainCities, id: \.self) { city in
                        
                        Button {
                            selectedCity = city
                        } label: {
                            Text(city)
                        }
                    }
                    
                } else {
                    
                    Button("Choisissez d’abord un pays") { }
                    
                }
                
            } label: {
                
                HStack {
                    
                    Text(selectedCity.isEmpty ? "Choisir votre ville" : selectedCity)
                        .foregroundStyle(selectedCity.isEmpty ? .secondary : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            
        }
        .padding(.horizontal)
    }
    private var languageSection: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Label("Langue", systemImage: "text.bubble.fill")
                .font(.headline)
            
            Menu {
                
                ForEach(["Français", "English", "Español", "Português", "العربية"], id: \.self) { language in
                    Button(language) {
                        selectedLanguage = language
                    }
                }
                
            } label: {
                
                HStack {
                    Text(selectedLanguage)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .padding(.horizontal)
    }
    private var currencySection: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Label("Devise", systemImage: "coloncurrencysign.circle.fill")
                .font(.headline)
            
            Menu {
                
                ForEach(["EUR (€)", "GNF", "XOF", "XAF", "USD ($)", "CAD ($)", "MAD"], id: \.self) { currency in
                    Button(currency) {
                        selectedCurrency = currency
                    }
                }
                
            } label: {
                
                HStack {
                    Text(selectedCurrency)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .padding(.horizontal)
    }
    private var nextStepPreview: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Label("Étape suivante", systemImage: "creditcard.fill")
            
            Text("Choix du moyen de paiement")
            
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
                
                guard !selectedCountry.isEmpty else { return }
                guard !selectedCity.isEmpty else { return }
                
                saveMarketplaceLocation()
                
            } label: {
                
                HStack(spacing: 12) {
                    
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Continuer")
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
            
            Text("Étape suivante : moyens de paiement adaptés à votre pays.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
    private func saveMarketplaceLocation() {
        
        guard !selectedCountry.isEmpty else { return }
        guard !selectedCity.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                try await MarketplaceProfileService.shared.saveLocation(
                    country: selectedCountry,
                    city: selectedCity,
                    language: selectedLanguage,
                    currency: selectedCurrency
                )
                
                await MainActor.run {
                    isLoading = false
                    navigateNext = true
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    private func loadExistingLocation() {
        Task {
            do {
                if let profile = try await MarketplaceProfileService.shared.reloadProfile() {
                    await MainActor.run {
                        selectedCountry = profile.country ?? ""
                        selectedCity = profile.city ?? ""
                        selectedLanguage = profile.language ?? "Français"
                        selectedCurrency = profile.currency ?? "EUR (€)"
                    }
                }
            } catch {
                print("❌ loadExistingLocation:", error.localizedDescription)
            }
        }
    }
    
    
    
    
}
