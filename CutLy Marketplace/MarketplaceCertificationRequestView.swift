//
//  MarketplaceCertificationRequestView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 02/07/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

struct MarketplaceCertificationView: View {

    enum CertificationPlan: String, CaseIterable, Identifiable {
        case essential, plus, business, premium

        var id: String { rawValue }

        var title: String {
            switch self {
            case .essential: return "Essentiel"
            case .plus: return "Plus"
            case .business: return "Business"
            case .premium: return "Premium"
            }
        }

        var price: String {
            switch self {
            case .essential: return "4,99 €/mois"
            case .plus: return "9,99 €/mois"
            case .business: return "19,99 €/mois"
            case .premium: return "49,99 €/mois"
            }
        }

        var icon: String {
            switch self {
            case .essential: return "checkmark.seal.fill"
            case .plus: return "star.circle.fill"
            case .business: return "storefront.fill"
            case .premium: return "crown.fill"
            }
        }

        var benefits: [String] {
            switch self {
            case .essential:
                return [
                    "Badge vérifié visible à côté du nom",
                    "Vérification du profil",
                    "Meilleure confiance acheteurs-vendeurs",
                    "Protection contre l’usurpation"
                ]
            case .plus:
                return [
                    "Tous les avantages Essentiel",
                    "Visibilité renforcée dans la Marketplace",
                    "Priorité dans certains résultats",
                    "Support plus rapide"
                ]
            case .business:
                return [
                    "Tous les avantages Plus",
                    "Badge boutique professionnelle",
                    "Outils vendeur avancés",
                    "Profil boutique renforcé"
                ]
            case .premium:
                return [
                    "Tous les avantages Business",
                    "Visibilité maximale",
                    "Support prioritaire",
                    "Protection IA renforcée"
                ]
            }
        }
    }

    @Environment(\.openURL) private var openURL

    @State private var selectedPlan: CertificationPlan = .essential
    @State private var acceptedTerms = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    
    @State private var showPaymentSuccess = false
    @State private var showPaymentCancel = false
    

    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "us-central1")

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header

                ForEach(CertificationPlan.allCases) { plan in
                    planCard(plan)
                }

                termsSection
                paymentButton
            }
            .padding(.vertical, 24)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MarketplaceCertificationPaymentSuccess"))) { _ in
            showPaymentSuccess = true
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MarketplaceCertificationPaymentCancel"))) { _ in
            showPaymentCancel = true
        }
        .navigationTitle("Certification Cutly")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Demande envoyée", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Votre demande de certification a été créée. Le badge sera activé automatiquement après paiement confirmé.")
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 68, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            Text("Obtenir le badge vérifié")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("Le badge Cutly apparaît à côté de votre nom dans la Marketplace. Il augmente la confiance, protège votre identité et améliore votre visibilité.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private func planCard(_ plan: CertificationPlan) -> some View {
        Button {
            selectedPlan = plan
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: plan.icon)
                        .font(.title2)
                        .foregroundStyle(selectedPlan == plan ? .white : .blue)
                        .frame(width: 48, height: 48)
                        .background(selectedPlan == plan ? Color.blue : Color.blue.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Certification \(plan.title)")
                            .font(.headline.bold())

                        Text(plan.price)
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    Image(systemName: selectedPlan == plan ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedPlan == plan ? .blue : .gray)
                }

                ForEach(plan.benefits, id: \.self) { benefit in
                    Label(benefit, systemImage: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(selectedPlan == plan ? Color.blue : Color.gray.opacity(0.15), lineWidth: selectedPlan == plan ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private var termsSection: some View {
        Toggle(isOn: $acceptedTerms) {
            Text("J’accepte que la certification soit un abonnement mensuel renouvelable. Si le paiement échoue, Cutly pourra suspendre ou retirer le badge après notification.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var paymentButton: some View {
        Button {
            startCertificationPayment()
        } label: {
            HStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "creditcard.fill")
                    Text("Choisir \(selectedPlan.title) et payer")
                        .font(.headline.bold())
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .disabled(isLoading || !acceptedTerms)
        .opacity(acceptedTerms ? 1 : 0.45)
        .padding(.horizontal)
    }

    private func startCertificationPayment() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Vous devez être connecté pour demander la certification."
            showError = true
            return
        }

        isLoading = true

        Task {
            do {
                let requestRef = db.collection("marketplace_certification_requests").document()

                try await requestRef.setData([
                    "id": requestRef.documentID,
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "plan": selectedPlan.rawValue,
                    "planTitle": selectedPlan.title,
                    "priceLabel": selectedPlan.price,
                    "status": "pending_payment",
                    "badgeVisible": false,
                    "renewal": "monthly",
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ])

                let result = try await functions
                    .httpsCallable("createMarketplaceCertificationCheckout")
                    .call([
                        "requestId": requestRef.documentID,
                        "plan": selectedPlan.rawValue
                    ])

                guard
                    let data = result.data as? [String: Any],
                    let urlString = data["checkoutUrl"] as? String,
                    let url = URL(string: urlString)
                else {
                    throw NSError(domain: "Certification", code: 500, userInfo: [
                        NSLocalizedDescriptionKey: "Lien de paiement introuvable."
                    ])
                }

                await MainActor.run {
                    isLoading = false
                    openURL(url)
                    showSuccess = true
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
}
