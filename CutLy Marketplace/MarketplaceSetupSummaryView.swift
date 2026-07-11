//
//  MarketplaceSetupSummaryView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import SwiftUI

struct MarketplaceSetupSummaryView: View {
    
    @State private var currentStep = 5
    @State private var profileCompletion = 1.0
    @State private var isLoading = false
    @State private var navigateToProfile = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                progressSection
                headerSection
                summarySection
                securitySection
                finishButton
                
                NavigationLink(
                    destination: MarketplacePremiumHomeView()
                        .navigationBarBackButtonHidden(true),
                    isActive: $navigateToProfile
                ) {
                    EmptyView()
                }
            }
            .padding(.vertical, 30)
        }
        .navigationTitle("Finalisation")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Étape \(currentStep) / 5")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(profileCompletion * 100)) %")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
            
            ProgressView(value: profileCompletion)
                .tint(.green)
        }
        .padding(.horizontal)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Votre profil Marketplace est prêt")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            
            Text("Vous pouvez maintenant acheter, vendre, gérer vos commandes, vos paiements et vos informations Marketplace.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Résumé")
                .font(.title3.bold())
            
            summaryRow("Profil Marketplace", "Créé", "person.fill", .green)
            summaryRow("Paiement", "En attente de vérification", "creditcard.fill", .orange)
            summaryRow("Compte", "Vérifié", "checkmark.shield.fill", .green)
            summaryRow("Boutique", "Optionnelle", "storefront.fill", .blue)
        }
        .padding(22)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.04), radius: 10)
        .padding(.horizontal)
    }
    
    private func summaryRow(_ title: String, _ status: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Sécurité Marketplace", systemImage: "lock.shield.fill")
                .font(.headline)
            
            Text("Certaines actions comme les retraits, remboursements, gros paiements ou certifications pourront demander une vérification supplémentaire.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    private var finishButton: some View {
        Button {
            completeMarketplaceProfile()
        } label: {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Entrer dans mon profil")
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
        .padding(.horizontal)
    }
    private func completeMarketplaceProfile() {

        isLoading = true

        Task {
            do {
                try await MarketplaceProfileService.shared.completeProfile()

                await MainActor.run {
                    isLoading = false
                    navigateToProfile = true
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    
    
    
    
    
}
