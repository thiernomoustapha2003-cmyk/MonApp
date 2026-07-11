//
//  MarketplacePaymentSetupView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import SwiftUI

struct MarketplacePaymentSetupView: View {
    
    @State private var currentStep = 3
    
    @State private var profileCompletion = 0.60
    
    @State private var selectedPaymentMethod = ""
    
    @State private var navigateNext = false
    
    @State private var isLoading = false
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 28) {
                
                progressSection
                
                headerSection
                
                paymentMethodsSection
                
                paymentInformationSection
                
                nextStepPreview
                
                continueButton
                
                NavigationLink(
                    destination: MarketplaceVerificationView(),
                    isActive: $navigateNext
                ) {
                    EmptyView()
                }
                
                
            }
            .padding(.vertical,30)
            
        }
        .navigationTitle("Paiements Marketplace")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExistingPayment()
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
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Moyens de paiement")
                .font(.title2.bold())

            Text("Choisissez comment payer et recevoir vos revenus Marketplace. Les options Mobile Money seront proposées selon votre pays.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choisir une méthode")
                .font(.title3.bold())

            paymentMethodCard("Carte bancaire", "creditcard.fill")
            paymentMethodCard("PayPal", "p.circle.fill")
            paymentMethodCard("IBAN / Compte bancaire", "building.columns.fill")
            paymentMethodCard("Apple Pay", "apple.logo")
            paymentMethodCard("Wallet Cutly", "wallet.pass.fill")

            Divider()
                .padding(.vertical, 4)

            Text("Mobile Money")
                .font(.headline)

            paymentMethodCard("Orange Money", "iphone.gen1.radiowaves.left.and.right")
            paymentMethodCard("Wave", "wave.3.right.circle.fill")
            paymentMethodCard("MTN Money", "simcard.fill")
            paymentMethodCard("Moov Money", "antenna.radiowaves.left.and.right")
            paymentMethodCard("Airtel Money", "phone.fill")
            paymentMethodCard("M-Pesa", "banknote.fill")
        }
        .padding(22)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.04), radius: 10)
        .padding(.horizontal)
    }

    private func paymentMethodCard(_ title: String, _ icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                selectedPaymentMethod = title
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(
                        selectedPaymentMethod == title
                        ? Color.blue.opacity(0.18)
                        : Color.gray.opacity(0.12)
                    )
                    .clipShape(Circle())

                Text(title)
                    .font(.headline)

                Spacer()

                Image(systemName: selectedPaymentMethod == title ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selectedPaymentMethod == title ? .blue : .gray)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(selectedPaymentMethod == title ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    private var paymentInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Informations nécessaires")
                .font(.title3.bold())

            if selectedPaymentMethod.isEmpty {
                Text("Choisissez d’abord un moyen de paiement.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                paymentFields(for: selectedPaymentMethod)
            }
        }
        .padding(22)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.04), radius: 10)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func paymentFields(for method: String) -> some View {
        switch method {
        case "IBAN / Compte bancaire":
            paymentTextField("Nom du titulaire", systemImage: "person.fill")
            paymentTextField("IBAN", systemImage: "number")
            paymentTextField("BIC / SWIFT", systemImage: "building.columns.fill")

        case "PayPal":
            paymentTextField("Email PayPal", systemImage: "envelope.fill")

        case "Orange Money", "Wave", "MTN Money", "Moov Money", "Airtel Money", "M-Pesa":
            paymentTextField("Numéro lié au compte", systemImage: "phone.fill")
            paymentTextField("Nom du titulaire", systemImage: "person.fill")

        case "Carte bancaire":
            Text("Le paiement par carte sera sécurisé via Stripe / Apple Pay.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

        case "Apple Pay":
            Text("Apple Pay sera proposé automatiquement si l’appareil le permet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

        case "Wallet Cutly":
            Text("Votre Wallet Cutly sera créé automatiquement après validation du profil.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

        default:
            EmptyView()
        }
    }

    private func paymentTextField(_ placeholder: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)

            TextField(placeholder, text: .constant(""))
                .textInputAutocapitalization(.never)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    private var nextStepPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Étape suivante", systemImage: "checkmark.shield.fill")
                .font(.headline)

            Text("Vérification du compte par e-mail ou SMS.")
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
                guard !selectedPaymentMethod.isEmpty else { return }

                saveMarketplacePayment()

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

            Text("Vous pourrez ajouter d’autres moyens de paiement plus tard.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
    private func saveMarketplacePayment() {

        guard !selectedPaymentMethod.isEmpty else { return }

        isLoading = true

        Task {
            do {
                try await MarketplaceProfileService.shared.savePaymentMethod(
                    method: selectedPaymentMethod
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
    private func loadExistingPayment() {
        Task {
            do {
                if let profile = try await MarketplaceProfileService.shared.reloadProfile() {
                    await MainActor.run {
                        selectedPaymentMethod = profile.paymentMethod ?? ""
                    }
                }
            } catch {
                print("❌ loadExistingPayment:", error.localizedDescription)
            }
        }
    }
    
    
    
    
}
