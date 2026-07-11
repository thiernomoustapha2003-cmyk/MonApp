//
//  MarketplaceEditProductView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI
import PhotosUI
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct MarketplaceEditProductView: View {
    let productId: String
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var productTitle = "Perruque premium naturelle"
    @State private var productDescription = "Produit en très bon état, prêt pour livraison internationale."
    @State private var price = "49"
    @State private var stock = "12"
    
    @State private var selectedStatus: MarketplaceProductStatus = .active
    @State private var selectedCondition: MarketplaceProductCondition = .veryGood
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showDeleteAlert = false
    @State private var animateHeader = false
    
    @State private var hasPromotion = false
    @State private var promotionPercent = ""
    @State private var allowDelivery = true
    @State private var allowPickup = true
    @State private var aiRecheckEnabled = true
    @State private var hasUnsavedChanges = false
    
    
    @State private var productData: [String: Any] = [:]
    @State private var existingImageURLs: [String] = []
    @State private var isLoadingProduct = false
    @State private var isSavingProduct = false
    @State private var showPreview = false
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @State private var productListener: ListenerRegistration?
    
    
    
    
    
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        editHeroSection
                        statusSection
                        quickActionsSection
                        mediaEditSection
                        mainEditSection
                        promotionEditSection
                        deliveryEditSection
                        aiRecheckSection
                        savePanelSection
                        Spacer(minLength: 120)
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Modifier le produit")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadProduct()
            }
            .onDisappear {
                productListener?.remove()
            }
            
            
            
            
            .onChange(of: productTitle) { _, _ in hasUnsavedChanges = true }
            .onChange(of: productDescription) { _, _ in hasUnsavedChanges = true }
            .onChange(of: price) { _, _ in hasUnsavedChanges = true }
            .onChange(of: stock) { _, _ in hasUnsavedChanges = true }
            .onChange(of: selectedStatus) { _, _ in hasUnsavedChanges = true }
            .onChange(of: selectedCondition) { _, _ in hasUnsavedChanges = true }
            .onChange(of: hasPromotion) { _, _ in hasUnsavedChanges = true }
            .onChange(of: promotionPercent) { _, _ in hasUnsavedChanges = true }
            .onChange(of: allowDelivery) { _, _ in hasUnsavedChanges = true }
            .onChange(of: allowPickup) { _, _ in hasUnsavedChanges = true }
            
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(hasUnsavedChanges ? "Annuler" : "Fermer") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") {
                        saveProductChanges()
                    }
                    .disabled(isSavingProduct)
                    .fontWeight(.bold)
                }
            }
            .alert("Supprimer ce produit ?", isPresented: $showDeleteAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    deleteProduct()
                }
            } message: {
                Text("Cette action pourra être protégée plus tard par confirmation, historique admin et vérification sécurité.")
            }
        }
    }
    
    private var editHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Modifier l’annonce")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Mets à jour les photos, le prix, le stock, le statut et la visibilité.")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(3)
                }
                
                Spacer()
                
                MarketplaceIconBadge(icon: "pencil.and.outline", size: 62)
            }
            
            HStack(spacing: 10) {
                MarketplaceEditProductHeroChip(title: selectedStatus.title, icon: "checkmark.circle.fill")
                MarketplaceEditProductHeroChip(title: "Firestore prêt", icon: "flame.fill")
                MarketplaceEditProductHeroChip(title: "IA", icon: "brain.head.profile")
            }
        }
        .padding(22)
        .background(MarketplaceUITheme.darkLuxuryGradient)
        .clipShape(RoundedRectangle(cornerRadius: MarketplaceUITheme.cornerXL, style: .continuous))
        .overlay(MarketplaceUITheme.premiumStroke(colorScheme: colorScheme, cornerRadius: MarketplaceUITheme.cornerXL))
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 16)
        .padding(.horizontal, 16)
        .scaleEffect(animateHeader ? 1 : 0.97)
        .opacity(animateHeader ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                animateHeader = true
            }
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MarketplaceSectionHeader(
                title: "Statut de l’annonce",
                subtitle: "Contrôle la visibilité du produit",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)
            
            Picker("Statut", selection: $selectedStatus) {
                ForEach(MarketplaceProductStatus.allCases) { status in
                    Text(status.title).tag(status)
                }
            }
            .pickerStyle(.menu)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            Picker("État", selection: $selectedCondition) {
                ForEach(MarketplaceProductCondition.allCases) { condition in
                    Text(condition.title).tag(condition)
                }
            }
            .pickerStyle(.menu)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MarketplaceEditQuickActionCard(title: "Mettre en avant", icon: "arrow.up.circle.fill") {
                    promoteProduct()
                }
                
                MarketplaceEditQuickActionCard(title: "Partager", icon: "square.and.arrow.up") {
                    UIPasteboard.general.string = "cutly://product/\(productId)"
                }
            }
            
            HStack(spacing: 12) {
                MarketplaceEditQuickActionCard(title: "Dupliquer", icon: "plus.square.on.square") {
                    duplicateProduct()
                }
                
                MarketplaceEditQuickActionCard(
                    title: selectedStatus == .active ? "Mettre en pause" : "Réactiver",
                    icon: selectedStatus == .active ? "pause.circle.fill" : "play.circle.fill"
                ) {
                    togglePauseProduct()
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var mediaEditSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MarketplaceSectionHeader(
                title: "Photos & vidéos",
                subtitle: "Ajoute, remplace ou réorganise les médias",
                actionTitle: "Galerie",
                action: {}
            )
            .padding(.horizontal, 0)
            
            if !existingImageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(existingImageURLs, id: \.self) { imageURL in
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: URL(string: imageURL)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image.resizable().scaledToFill()
                                    default:
                                        Color.gray.opacity(0.2)
                                    }
                                }
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 18))

                                Button {
                                    removeImage(imageURL)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(.white, .red)
                                        .padding(6)
                                }
                            }
                        }
                    }
                }
            }
            
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.regularMaterial)
                .frame(height: 210)
                .overlay {
                    VStack(spacing: 16) {
                        MarketplaceIconBadge(icon: "photo.stack.fill", size: 58)
                        
                        Text("Modifier les médias")
                            .font(.headline.weight(.bold))
                        
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 20,
                            matching: .images
                        ) {
                            Text("Choisir des photos")
                        }
                        .buttonStyle(MarketplacePremiumButtonStyle(isFullWidth: false))
                    }
                }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var mainEditSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MarketplaceSectionHeader(
                title: "Informations principales",
                subtitle: "Titre, description, prix et stock",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)
            
            TextField("Titre", text: $productTitle)
                .marketplaceEditField()
            
            TextField("Description", text: $productDescription, axis: .vertical)
                .lineLimit(5)
                .marketplaceEditField()
            
            TextField("Prix", text: $price)
                .keyboardType(.decimalPad)
                .marketplaceEditField()
            
            TextField("Stock", text: $stock)
                .keyboardType(.numberPad)
                .marketplaceEditField()
            
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Supprimer le produit", systemImage: "trash.fill")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.bordered)
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    private var promotionEditSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MarketplaceSectionHeader(
                title: "Promotion",
                subtitle: "Active une remise visible dans la Marketplace",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)
            
            Toggle("Activer une promotion", isOn: $hasPromotion)
                .marketplaceEditField()
            
            if hasPromotion {
                TextField("Remise en %", text: $promotionPercent)
                    .keyboardType(.numberPad)
                    .marketplaceEditField()
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var deliveryEditSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MarketplaceSectionHeader(
                title: "Livraison",
                subtitle: "Modifier les options de retrait et d’expédition",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)
            
            Toggle("Livraison disponible", isOn: $allowDelivery)
                .marketplaceEditField()
            
            Toggle("Remise en main propre", isOn: $allowPickup)
                .marketplaceEditField()
            
            MarketplaceEditInfoRow(
                icon: "globe.europe.africa.fill",
                title: "International & Afrique",
                subtitle: "Domicile, relais, poste, agence locale, GPS, point de repère et téléphone obligatoire."
            )
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var aiRecheckSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MarketplaceSectionHeader(
                title: "Contrôle IA",
                subtitle: "Relancer une analyse avant sauvegarde",
                actionTitle: "Analyser",
                action: {
                    runAIRecheck()
                }
            )
            .padding(.horizontal, 0)
            
            Toggle("Relancer l’analyse IA", isOn: $aiRecheckEnabled)
                .marketplaceEditField()
            
            VStack(spacing: 10) {
                MarketplaceEditInfoRow(icon: "photo.fill", title: "Images", subtitle: "Flou, duplications, images volées ou qualité faible.")
                MarketplaceEditInfoRow(icon: "tag.fill", title: "Prix", subtitle: "Prix anormal, promotion suspecte ou incohérence devise.")
                MarketplaceEditInfoRow(icon: "shield.fill", title: "Sécurité", subtitle: "Contrefaçon, produit interdit ou vendeur à risque.")
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var savePanelSection: some View {
        VStack(spacing: 12) {
            Button {
                saveProductChanges()
            } label: {
                Label(isSavingProduct ? "Sauvegarde..." : "Sauvegarder les modifications", systemImage: "checkmark.circle.fill")
            }
            .disabled(isSavingProduct)
            .buttonStyle(MarketplacePremiumButtonStyle())
            
            NavigationLink {
                MarketplaceProductDetailView(
                    product: MarketplaceHomeProduct(
                        id: productId,
                        title: productTitle,
                        priceText: "\(price) €",
                        originalPriceText: MarketplacePriceFormatter.formatOptional(productData["originalPrice"] as? Double),
                        discountPercent: productData["discountPercent"] as? Int
                            ?? productData["discountPercentage"] as? Int
                            ?? productData["discount"] as? Int,
                        country: productData["country"] as? String
                            ?? productData["countryName"] as? String
                            ?? "",
                        city: productData["city"] as? String
                            ?? productData["sellerCity"] as? String
                            ?? "",
                        imageURL: existingImageURLs.first,
                        sellerId: productData["sellerId"] as? String ?? "",
                        sellerName: productData["sellerName"] as? String ?? "Vendeur Cutly Market",
                        sellerPhotoURL: productData["sellerPhotoURL"] as? String ?? "",
                        sellerVerified: productData["sellerVerified"] as? Bool ?? false,
                        rating: productData["rating"] as? Double
                            ?? productData["averageRating"] as? Double,
                        latitude: productData["latitude"] as? Double,
                        longitude: productData["longitude"] as? Double,
                        isFavorite: false,
                        variants: [],
                    )
                )
            } label: {
                Label("Prévisualiser l’annonce", systemImage: "eye.fill")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.primary)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            
            Text("Vos modifications sont enregistrées en toute sécurité et vérifiées automatiquement par notre système de contrôle intelligent.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 16)
    }
    
    private func loadProduct() {
        
        isLoadingProduct = true
        
        productListener?.remove()

        productListener = db.collection("marketplace_products")
            .document(productId)
            .addSnapshotListener { snapshot, error in
                
                isLoadingProduct = false
                
                guard
                    error == nil,
                    let data = snapshot?.data()
                else {
                    print("❌ Impossible de charger le produit :", error?.localizedDescription ?? "")
                    return
                }
                
                productData = data
                
                productTitle = data["title"] as? String ?? ""
                productDescription = data["description"] as? String ?? ""
                
                if let amount = data["price"] as? Double {
                    price = String(format: "%.2f", amount)
                }
                
                stock = "\(data["stock"] as? Int ?? data["quantity"] as? Int ?? 1)"
                
                existingImageURLs = data["imageURLs"] as? [String] ?? []
                
                hasPromotion = data["hasPromotion"] as? Bool ?? false
                
                if let promo = data["promotionPercent"] as? Int,
                   promo > 0 {
                    promotionPercent = "\(promo)"
                }
                
                allowDelivery = data["allowsDelivery"] as? Bool
                ?? data["deliveryAvailable"] as? Bool
                ?? true
                
                allowPickup = data["allowsPickup"] as? Bool
                ?? data["pickupAvailable"] as? Bool
                ?? true
                
                if let status = data["status"] as? String,
                   let value = MarketplaceProductStatus(rawValue: status) {
                    selectedStatus = value
                }
                
                if let condition = data["condition"] as? String {
                    
                    if let value = MarketplaceProductCondition
                        .allCases
                        .first(where: { $0.title == condition }) {
                        
                        selectedCondition = value
                    }
                }
                hasUnsavedChanges = false
            }
    }
    private func togglePauseProduct() {
        
        let newStatus: MarketplaceProductStatus =
        selectedStatus == .active ? .paused : .active
        
        db.collection("marketplace_products")
            .document(productId)
            .updateData([
                "status": newStatus.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ]) { error in
                
                if error == nil {
                    selectedStatus = newStatus
                }
            }
    }
    
    private func promoteProduct() {
        
        db.collection("marketplace_products")
            .document(productId)
            .updateData([
                "isPromoted": true,
                "promotionStartedAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    private func duplicateProduct() {
        
        db.collection("marketplace_products")
            .document(productId)
            .getDocument { snapshot, error in
                
                guard
                    error == nil,
                    var data = snapshot?.data()
                else {
                    return
                }
                
                let newId = UUID().uuidString
                
                data["id"] = newId
                data["status"] = MarketplaceProductStatus.draft.rawValue
                data["createdAt"] = FieldValue.serverTimestamp()
                data["updatedAt"] = FieldValue.serverTimestamp()
                
                self.db
                    .collection("marketplace_products")
                    .document(newId)
                    .setData(data)
            }
    }
    private func saveProductChanges() {
        let cleanTitle = productTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDescription = productDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedPrice = Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0
        let parsedStock = Int(stock) ?? 0
        
        guard !cleanTitle.isEmpty else { return }
        guard cleanDescription.count >= 10 else { return }
        guard parsedPrice > 0 else { return }
        
        isSavingProduct = true

        Task {
            await saveProductWithImages()
        }
        return

      
    }
    private func saveProductWithImages() async {
        do {
            var finalImageURLs = existingImageURLs

            if !selectedPhotos.isEmpty {
                for (index, item) in selectedPhotos.enumerated() {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { continue }

                    guard let uid = Auth.auth().currentUser?.uid else { return }

                    let ref = storage.reference()
                        .child("marketplaceProducts")
                        .child(uid)
                        .child(productId)
                        .child("edit_\(UUID().uuidString)_\(index).jpg")

                    guard let jpegData = image.jpegData(compressionQuality: 0.78) else { continue }

                    _ = try await ref.putDataAsync(jpegData)
                    let url = try await ref.downloadURL()
                    finalImageURLs.append(url.absoluteString)
                }
            }

            let parsedPrice = Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0
            let parsedStock = Int(stock) ?? 0

            try await db.collection("marketplace_products")
                .document(productId)
                .setData([
                    "title": productTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    "description": productDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    "price": parsedPrice,
                    "priceText": "\(String(format: "%.2f", parsedPrice)) €",
                    "stock": parsedStock,
                    "quantity": parsedStock,
                    "status": selectedStatus.rawValue,
                    "condition": selectedCondition.title,
                    "hasPromotion": hasPromotion,
                    "promotionPercent": Int(promotionPercent) ?? 0,
                    "allowsDelivery": allowDelivery,
                    "allowsPickup": allowPickup,
                    "deliveryAvailable": allowDelivery,
                    "pickupAvailable": allowPickup,
                    "imageURLs": finalImageURLs,
                    "mainImageURL": finalImageURLs.first ?? "",
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)

            await MainActor.run {
                existingImageURLs = finalImageURLs
                selectedPhotos = []
                isSavingProduct = false
                hasUnsavedChanges = false
                dismiss()
            }

        } catch {
            await MainActor.run {
                isSavingProduct = false
            }
            print("❌ saveProductWithImages:", error.localizedDescription)
        }
    }
    private func removeImage(_ imageURL: String) {
        existingImageURLs.removeAll { $0 == imageURL }
        hasUnsavedChanges = true

        db.collection("marketplace_products")
            .document(productId)
            .setData([
                "imageURLs": existingImageURLs,
                "mainImageURL": existingImageURLs.first ?? "",
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)

        Storage.storage()
            .reference(forURL: imageURL)
            .delete { error in
                if let error {
                    print("⚠️ Image retirée de Firestore mais pas supprimée du Storage :", error.localizedDescription)
                }
            }
    }
    
    
    private func deleteProduct() {
        db.collection("marketplace_products")
            .document(productId)
            .setData([
                "status": "deleted",
                "deletedAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if error == nil {
                    dismiss()
                }
            }
    }
    private func runAIRecheck() {
        db.collection("marketplace_ai_moderation_results")
            .document(productId)
            .setData([
                "productId": productId,
                "title": productTitle,
                "description": productDescription,
                "price": Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0,
                "imageURLs": existingImageURLs,
                "status": "pending",
                "requestedAt": FieldValue.serverTimestamp()
            ], merge: true)

        db.collection("marketplace_products")
            .document(productId)
            .setData([
                "aiReviewStatus": "pending",
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }
    
    
    
    
    
    
    
    
    
}



// MARK: - Components

private struct MarketplaceEditProductHeroChip: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.14))
        .clipShape(Capsule())
    }
}

private struct MarketplaceEditQuickActionCard: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                MarketplaceIconBadge(icon: icon, size: 38)

                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func marketplaceEditField() -> some View {
        self
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
private struct MarketplaceEditInfoRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}



#Preview {
    MarketplaceEditProductView(productId: "preview_product")
}
