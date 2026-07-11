//
//  MarketplaceSupportTicketView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 02/07/2026.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct MarketplaceSupportTicketView: View {

    enum SupportCategory: String, CaseIterable, Identifiable {
        case order = "Commande"
        case payment = "Paiement"
        case delivery = "Livraison"
        case dispute = "Litige"
        case account = "Compte"
        case verification = "Vérification"
        case seller = "Vendeur"
        case other = "Autre"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .order: return "shippingbox.fill"
            case .payment: return "creditcard.fill"
            case .delivery: return "truck.box.fill"
            case .dispute: return "exclamationmark.triangle.fill"
            case .account: return "person.crop.circle.fill"
            case .verification: return "checkmark.shield.fill"
            case .seller: return "bag.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: SupportCategory = .order
    @State private var subject = ""
    @State private var message = ""

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImagesData: [Data] = []

    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var showError = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                headerSection
                categorySection
                subjectSection
                messageSection
                attachmentSection
                sendButton
            }
            .padding(.vertical, 24)
        }
        .navigationTitle("Contacter le support")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Demande envoyée", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Votre demande a bien été envoyée au support Cutly Marketplace.")
        }
        .onChange(of: selectedPhotos) { newItems in
            loadSelectedImages(newItems)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "headset")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            Text("Support Cutly Marketplace")
                .font(.title2.bold())

            Text("Expliquez votre problème avec le maximum de détails. Plus votre demande est claire, plus le support pourra vous aider rapidement.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Catégorie")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(SupportCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                                .font(.caption.bold())
                        }
                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            selectedCategory == category
                            ? AnyView(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                            : AnyView(Color(.secondarySystemBackground))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sujet")
                .font(.headline)

            TextField("Ex : Problème avec ma commande", text: $subject)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Message")
                .font(.headline)

            TextEditor(text: $message)
                .frame(minHeight: 180)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

            Text("Ajoutez les détails utiles : numéro de commande, nom du vendeur, date, montant, capture d’écran, pays, méthode de paiement ou livraison concernée.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }

    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pièces jointes")
                .font(.headline)

            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Label("Ajouter des captures ou photos", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            if !selectedImagesData.isEmpty {
                Text("\(selectedImagesData.count) pièce(s) jointe(s) sélectionnée(s)")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }

    private var sendButton: some View {
        Button {
            submitTicket()
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Envoyer ma demande")
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
        .disabled(isLoading)
        .padding(.horizontal)
    }

    private func loadSelectedImages(_ items: [PhotosPickerItem]) {
        selectedImagesData.removeAll()

        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        selectedImagesData.append(data)
                    }
                }
            }
        }
    }

    private func submitTicket() {
        let cleanSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let user = Auth.auth().currentUser else {
            errorMessage = "Vous devez être connecté pour contacter le support."
            showError = true
            return
        }

        guard cleanSubject.count >= 3 else {
            errorMessage = "Veuillez ajouter un sujet clair."
            showError = true
            return
        }

        guard cleanMessage.count >= 15 else {
            errorMessage = "Veuillez expliquer votre problème avec plus de détails."
            showError = true
            return
        }

        isLoading = true

        Task {
            do {
                let ticketRef = db.collection("marketplace_support_tickets").document()
                let ticketId = ticketRef.documentID

                var attachmentURLs: [String] = []

                for (index, data) in selectedImagesData.enumerated() {
                    let ref = storage.reference()
                        .child("marketplaceSupportTickets")
                        .child(user.uid)
                        .child(ticketId)
                        .child("attachment_\(index).jpg")

                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"

                    _ = try await ref.putDataAsync(data, metadata: metadata)
                    let url = try await ref.downloadURL()
                    attachmentURLs.append(url.absoluteString)
                }

                try await ticketRef.setData([
                    "id": ticketId,
                    "uid": user.uid,
                    "userEmail": user.email ?? "",
                    "category": selectedCategory.rawValue,
                    "subject": cleanSubject,
                    "message": cleanMessage,
                    "attachments": attachmentURLs,
                    "status": "open",
                    "priority": selectedCategory == .dispute ? "high" : "normal",
                    "source": "ios_marketplace",
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ])

                await MainActor.run {
                    isLoading = false
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
