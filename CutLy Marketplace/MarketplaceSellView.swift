//
//  MarketplaceSellView.swift
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
import FirebaseFunctions






struct MarketplaceSellView: View {

    @Environment(\.colorScheme) private var colorScheme
    
    
    @StateObject private var locationManager = MarketplaceLocationManager.shared

    
    
    @State private var productTitle = ""
    @State private var productDescription = ""
    @State private var selectedCategory = "Sélectionner"

    @State private var price = ""
    @State private var quantity = "1"

    @State private var animateHero = false
    

    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    @State private var selectedCondition: MarketplaceProductCondition = .new
    @State private var selectedCurrency: MarketplaceCurrency = .eur
    @State private var selectedCountry = "France"
    @State private var allowDelivery = true
    @State private var allowPickup = true
    @State private var allowNegotiation = false
    
    
    @State private var sku = ""
    @State private var barcode = ""
    @State private var brand = ""
    @State private var colors = ""
    @State private var sizes = ""
    @State private var weightKg = ""
    @State private var lengthCm = ""
    @State private var widthCm = ""
    @State private var heightCm = ""
    
    
    @State private var hasWarranty = false
    @State private var warrantyText = ""
    @State private var hasPromotion = false
    @State private var promotionPercent = ""
    @State private var aiCheckEnabled = true
    @State private var saveAsDraft = true
    
    
    
    @State private var isPublishing = false
    @State private var uploadProgress = 0.0
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var categories: [String] = []
    @State private var showCategorySheet = false
    @State private var marketplaceCategories: [MarketplaceDynamicCategory] = []
    @State private var selectedDynamicCategory: MarketplaceDynamicCategory?
    @State private var categoryFields: [MarketplaceDynamicField] = []
    @State private var dynamicAttributes: [String: String] = [:]
    @State private var isLoadingCategoryFields = false
    
    @State private var isSeedingCategories = false
    @State private var seedMessage = ""
    
    @State private var productVariants: [MarketplaceVariantEditorDraft] = []

    @State private var editingVariant: MarketplaceVariantEditorDraft?

    @State private var showVariantEditor = false
    
    
    @State private var currentStep = 1
    @State private var showPreviewBeforePublish = false
    
    @State private var normalPrice = ""
    @State private var promotionalPrice = ""
    @State private var promotionStartDate = Date()
    @State private var promotionEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var freeShippingFrom = ""
    @State private var fixedShippingFee = ""
    @State private var shippingPaidBy = "Acheteur"
    @State private var allowInternationalDelivery = false
    @State private var material = ""
    @State private var gender = "Homme"
    @State private var collarType = "Col rond"
    @State private var season = "Toutes saisons"
   
    
    @State private var publishedProductId = ""
    @State private var publishedMainImageURL = ""
    @State private var openPublishedProduct = false
    
    @State private var openMarketplaceHome = false
    
    
    
    
    
    @State private var publishedProduct: MarketplaceHomeProduct?
    
    
    
    
    

    private let totalSteps = 7

    private var stepProgress: Double {
        Double(currentStep) / Double(totalSteps)
    }

    private var stepTitle: String {
        switch currentStep {
        case 1: return "Informations principales"
        case 2: return "Détails du produit"
        case 3: return "Variantes"
        case 4: return "Livraison"
        case 5: return "Prix & promotion"
        case 6: return "Aperçu"
        case 7: return "Publication"
        default: return "Publier"
        }
    }
    
    
    
    
    
    
    
    
    

    var body: some View {

        NavigationStack {

            ZStack {

                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {

                    VStack(spacing: 22) {

                        sellStepHeader

                        switch currentStep {
                        case 1:
                            mediaSection
                            basicInformationSection

                        case 2:
                            stepTwoProductDetailsSection

                        case 3:
                            stepThreeVariantsSection

                        case 4:
                            stepFourShippingSection

                        case 5:
                            stepFivePricePromotionSection

                        case 6:
                            MarketplaceSellPreviewCard(
                                title: productTitle,
                                price: price,
                                normalPrice: normalPrice,
                                promotionalPrice: promotionalPrice,
                                category: selectedCategory,
                                brand: brand,
                                material: material,
                                condition: selectedCondition.title,
                                allowDelivery: allowDelivery,
                                allowPickup: allowPickup,
                                hasPromotion: hasPromotion,
                                promotionPercent: promotionPercent,
                                selectedPhotos: selectedPhotos,
                                variants: productVariants,
                                onPublish: {
                                    publishProduct(isDraft: false)
                                },
                                onEdit: {
                                    currentStep = 1
                                }
                            )

                        default:
                            publishedSuccessSection
                        }

                        sellStepButtons

                        Spacer(minLength: 120)
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Vendre")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                locationManager.requestLocation()
                locationManager.startLiveTracking()
                loadCategories()
            }
            .onDisappear {
                locationManager.stopLiveTracking()
            }
            .sheet(isPresented: $showVariantEditor) {

                MarketplaceVariantEditorView(

                    baseProductPrice: Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0,

                    existingVariant: editingVariant,

                    onSave: { variant in

                        if let index = productVariants.firstIndex(where: { $0.id == variant.id }) {

                            productVariants[index] = variant

                        } else {

                            productVariants.append(variant)

                        }

                    },

                    onDelete: {

                        guard let editingVariant else { return }

                        productVariants.removeAll { $0.id == editingVariant.id }

                    }

                )

            }
            
            
            .alert("Produit publié ✅", isPresented: $showSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Votre produit est maintenant enregistré dans Cutly Marketplace.")
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .navigationDestination(isPresented: $openPublishedProduct) {
                MarketplaceProductDetailView(productId: publishedProductId)
            }
            .navigationDestination(isPresented: $openMarketplaceHome) {
                MarketplacePremiumHomeView()
            }
            
            
            
            
        }
    }
}
private extension MarketplaceSellView {

    var sellStepHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Publier un produit")
                        .font(.system(size: 30, weight: .black, design: .rounded))

                    Text("Étape \(currentStep) sur \(totalSteps) • \(stepTitle)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                MarketplaceIconBadge(
                    icon: currentStep == 7 ? "checkmark.seal.fill" : "shippingbox.fill",
                    size: 58
                )
            }

            ProgressView(value: stepProgress)
                .tint(.purple)

            HStack(spacing: 8) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? .purple : Color.primary.opacity(0.15))
                        .frame(width: 9, height: 9)
                }
            }
        }
        .padding(22)
        .background(MarketplaceUITheme.darkLuxuryGradient)
        .clipShape(
            RoundedRectangle(
                cornerRadius: MarketplaceUITheme.cornerXL,
                style: .continuous
            )
        )
        .padding(.horizontal, 16)
    }

    var sellStepButtons: some View {
        Group {
            if currentStep < 7 {
                HStack(spacing: 12) {
                    if currentStep > 1 {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                currentStep -= 1
                            }
                        } label: {
                            Text("Retour")
                                .font(.headline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            currentStep += 1
                        }
                    } label: {
                        Label("Continuer", systemImage: "arrow.right")
                    }
                    .buttonStyle(MarketplacePremiumButtonStyle())
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    
    
    var sellHeroSection: some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Publier un produit")
                        .font(.system(size: 30, weight: .black, design: .rounded))

                    Text("Vends partout dans le monde avec Cutly Marketplace.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                MarketplaceIconBadge(
                    icon: "shippingbox.fill",
                    size: 62
                )
            }

            HStack(spacing: 12) {
                MarketplaceSellBadge(title: "IA", icon: "brain.head.profile")
                MarketplaceSellBadge(title: "International", icon: "globe.europe.africa.fill")
                MarketplaceSellBadge(title: "Paiement sécurisé", icon: "lock.fill")
            }

            Button {
                seedMarketplaceCategories()
            } label: {
                Label(
                    isSeedingCategories ? "Création des catégories..." : "Initialiser toutes les catégories Marketplace",
                    systemImage: "square.grid.2x2.fill"
                )
            }
            .disabled(isSeedingCategories)
            .buttonStyle(MarketplacePremiumButtonStyle())

            if !seedMessage.isEmpty {
                Text(seedMessage)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(22)
        .background(MarketplaceUITheme.darkLuxuryGradient)
        .clipShape(
            RoundedRectangle(
                cornerRadius: MarketplaceUITheme.cornerXL,
                style: .continuous
            )
        )
        .padding(.horizontal, 16)
    }

    var dynamicCategoryFieldsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            MarketplaceSectionHeader(
                title: "Détails spécifiques",
                subtitle: selectedCategory == "Sélectionner"
                ? "Choisis une catégorie pour afficher les bons champs."
                : "Champs adaptés à la catégorie : \(selectedCategory).",
                actionTitle: nil,
                action: nil
            )

            if isLoadingCategoryFields {
                MarketplaceSkeletonView(cornerRadius: 24)
                    .frame(height: 90)
            } else if selectedCategory == "Sélectionner" {
                MarketplaceSellInfoBox(
                    icon: "square.grid.2x2.fill",
                    title: "Champs automatiques",
                    subtitle: "Chaque catégorie affichera ses propres champs."
                )
            } else if categoryFields.isEmpty {
                MarketplaceSellInfoBox(
                    icon: "wand.and.stars",
                    title: "Aucun champ spécifique",
                    subtitle: "Cette catégorie utilise les champs généraux."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(categoryFields) { field in
                        MarketplaceDynamicFieldInput(
                            field: field,
                            value: Binding(
                                get: { dynamicAttributes[field.key] ?? "" },
                                set: { dynamicAttributes[field.key] = $0 }
                            )
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

private extension MarketplaceSellView {

    var mediaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Photos du produit")
                .font(.headline.bold())

            MarketplaceSellStepOnePhotoGrid(selectedPhotos: $selectedPhotos)

            Text("Ajoute au moins 1 photo")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
    }

}
private extension MarketplaceSellView {

    var basicInformationSection: some View {

        VStack(alignment:.leading,spacing:18){

            MarketplaceSectionHeader(
                title:"Informations",
                subtitle:"Les informations principales du produit.",
                actionTitle:nil,
                action:nil
            )

            TextField(
                "Titre du produit",
                text:$productTitle
            )
            .marketplaceField()

            TextField(
                "Description",
                text:$productDescription,
                axis:.vertical
            )
            .lineLimit(5)
            .marketplaceField()

            TextField(
                "Prix",
                text:$price
            )
            .keyboardType(.decimalPad)
            .marketplaceField()

            TextField(
                "Quantité",
                text:$quantity
            )
            .keyboardType(.numberPad)
            .marketplaceField()

        }
        .padding(.horizontal,16)

    }

}
private extension View {

    func marketplaceField() -> some View {

        self
            .padding(16)
            .background(.regularMaterial)
            .clipShape(
                RoundedRectangle(
                    cornerRadius:20,
                    style:.continuous
                )
            )

    }

}
private extension MarketplaceSellView {

    var stepTwoProductDetailsSection: some View {

        VStack(alignment: .leading, spacing: 22) {

            MarketplaceSectionHeader(
                title: "Détails du produit",
                subtitle: "Informations adaptées à la catégorie choisie.",
                actionTitle: nil,
                action: nil
            )

            Button {
                showCategorySheet = true
            } label: {
                MarketplaceSellSelectorRow(
                    title: "Catégorie",
                    value: selectedCategory,
                    icon: "square.grid.2x2.fill"
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showCategorySheet) {
                MarketplaceCategorySelectionSheet(
                    categories: categories,
                    selectedCategory: $selectedCategory
                ) { category in
                    loadFieldsForSelectedCategory(category)
                }
            }

            Picker("État", selection: $selectedCondition) {
                ForEach(MarketplaceProductCondition.allCases) { condition in
                    Text(condition.title)
                        .tag(condition)
                }
            }
            .pickerStyle(.menu)
            .marketplaceField()

            TextField("Marque", text: $brand)
                .marketplaceField()

            TextField("Matière", text: $material)
                .marketplaceField()

            Picker("Genre", selection: $gender) {
                Text("Homme").tag("Homme")
                Text("Femme").tag("Femme")
                Text("Mixte").tag("Mixte")
                Text("Enfant").tag("Enfant")
            }
            .pickerStyle(.menu)
            .marketplaceField()

            Picker("Type de col", selection: $collarType) {
                Text("Col rond").tag("Col rond")
                Text("Col V").tag("Col V")
                Text("Polo").tag("Polo")
                Text("Col roulé").tag("Col roulé")
            }
            .pickerStyle(.menu)
            .marketplaceField()

            Picker("Saison", selection: $season) {
                Text("Toutes saisons").tag("Toutes saisons")
                Text("Été").tag("Été")
                Text("Hiver").tag("Hiver")
                Text("Printemps").tag("Printemps")
                Text("Automne").tag("Automne")
            }
            .pickerStyle(.menu)
            .marketplaceField()

            TextField("Référence / Étiquette (optionnel)", text: $sku)
                .marketplaceField()

            dynamicCategoryFieldsSection

        }
        .padding(.horizontal,16)
    }
    
    
    
    
    
    
    
    
    
    
    
    var categoryConditionSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            MarketplaceSectionHeader(
                title: "Catégorie & état",
                subtitle: "Classe ton produit pour améliorer la visibilité.",
                actionTitle: nil,
                action: nil
            )

            Button {
                showCategorySheet = true
            } label: {
                MarketplaceSellSelectorRow(
                    title: "Catégorie",
                    value: selectedCategory,
                    icon: "square.grid.2x2.fill"
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showCategorySheet) {
                MarketplaceCategorySelectionSheet(
                    categories: categories,
                    selectedCategory: $selectedCategory,
                    onSelect: { category in
                        loadFieldsForSelectedCategory(category)
                    }
                )
            }

            Picker("État", selection: $selectedCondition) {
                ForEach(MarketplaceProductCondition.allCases) { condition in
                    Text(condition.title).tag(condition)
                }
            }
            .pickerStyle(.menu)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Picker("Devise", selection: $selectedCurrency) {
                ForEach(MarketplaceCurrency.allCases) { currency in
                    Text(currency.rawValue).tag(currency)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
    }

    var stepFourShippingSection: some View {

        VStack(alignment: .leading, spacing: 22) {

            MarketplaceSectionHeader(
                title: "Livraison",
                subtitle: "Choisis comment l’acheteur peut recevoir le produit.",
                actionTitle: nil,
                action: nil
            )

            VStack(spacing: 12) {

                Toggle("Remise en main propre", isOn: $allowPickup)
                    .marketplaceField()

                Toggle("Livraison à domicile", isOn: $allowDelivery)
                    .marketplaceField()

                Toggle("Point relais / Agence / Poste", isOn: $allowDelivery)
                    .marketplaceField()

                Toggle("Livraison internationale", isOn: $allowInternationalDelivery)
                    .marketplaceField()
            }

            MarketplaceSellInfoBox(
                icon: "shippingbox.fill",
                title: "Livraison flexible",
                subtitle: "Compatible domicile, point relais, poste, agence locale, remise en main propre et livraison internationale."
            )

            VStack(alignment: .leading, spacing: 14) {

                MarketplaceSectionHeader(
                    title: "Frais de livraison",
                    subtitle: "Définis qui paie et les frais appliqués.",
                    actionTitle: nil,
                    action: nil
                )

                Picker("À la charge de", selection: $shippingPaidBy) {
                    Text("Acheteur").tag("Acheteur")
                    Text("Vendeur").tag("Vendeur")
                }
                .pickerStyle(.segmented)
                .marketplaceField()

                TextField("Frais fixes ex : 4,50", text: $fixedShippingFee)
                    .keyboardType(.decimalPad)
                    .marketplaceField()

                TextField("Livraison gratuite à partir de ex : 50", text: $freeShippingFrom)
                    .keyboardType(.decimalPad)
                    .marketplaceField()
            }

            VStack(alignment: .leading, spacing: 10) {
                MarketplaceSellDeliveryOption(
                    icon: "house.fill",
                    title: "Domicile",
                    subtitle: "Livraison classique quand l’adresse existe."
                )

                MarketplaceSellDeliveryOption(
                    icon: "mappin.and.ellipse",
                    title: "Point relais / poste / agence",
                    subtitle: "Utile en Afrique, Europe et zones sans adresse précise."
                )

                MarketplaceSellDeliveryOption(
                    icon: "location.fill",
                    title: "GPS & point de repère",
                    subtitle: "Ex : marché, mairie, carrefour, station, agence locale."
                )
            }
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(.horizontal, 16)
    }
    
    
    var shippingOptionsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            MarketplaceSectionHeader(
                title: "Livraison",
                subtitle: "Adapté aux adresses Europe, Afrique et international.",
                actionTitle: nil,
                action: nil
            )

            MarketplaceSellSelectorRow(title: "Pays d’expédition", value: selectedCountry, icon: "globe.europe.africa.fill")

            Toggle("Livraison disponible", isOn: $allowDelivery)
                .marketplaceField()

            Toggle("Remise en main propre", isOn: $allowPickup)
                .marketplaceField()

            Toggle("Prix négociable", isOn: $allowNegotiation)
                .marketplaceField()

            VStack(alignment: .leading, spacing: 10) {
                MarketplaceSellDeliveryOption(icon: "house.fill", title: "Domicile", subtitle: "Livraison classique quand l’adresse existe.")
                MarketplaceSellDeliveryOption(icon: "mappin.and.ellipse", title: "Point relais / poste / agence", subtitle: "Pour les zones sans boîte aux lettres.")
                MarketplaceSellDeliveryOption(icon: "location.fill", title: "GPS & point de repère", subtitle: "Ex : près de la mairie, carrefour, marché.")
            }
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(.horizontal, 16)
    }
}
private extension MarketplaceSellView {

    
    
    
    
    
    
    var stepThreeVariantsSection: some View {

        VStack(alignment: .leading, spacing: 18) {

            MarketplaceSectionHeader(
                title: "Variantes",
                subtitle: "Ajoute couleurs, tailles, stock, prix, photos et promotions par variante.",
                actionTitle: nil,
                action: nil
            )

            MarketplaceSellInfoBox(
                icon: "paintpalette.fill",
                title: "Chaque couleur peut avoir son prix",
                subtitle: "Exemple : Noir M à 29,99 €, Rouge L en promotion à 19,99 €, Bleu XL avec stock différent."
            )

            Button {
                editingVariant = nil
                showVariantEditor = true
            } label: {
                Label("Ajouter une variante", systemImage: "plus.circle.fill")
            }
            .buttonStyle(MarketplacePremiumButtonStyle())

            if productVariants.isEmpty {

                MarketplaceSellInfoBox(
                    icon: "sparkles",
                    title: "Aucune variante ajoutée",
                    subtitle: "Ajoute une couleur, une taille, un prix, un stock et une promotion si besoin."
                )

            } else {

                VStack(spacing: 10) {
                    ForEach(productVariants) { variant in
                        MarketplaceVariantRow(
                            variant: variant,
                            onEdit: {
                                editingVariant = variant
                                showVariantEditor = true
                            },
                            onDelete: {
                                productVariants.removeAll { $0.id == variant.id }
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    var dimensionsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            MarketplaceSectionHeader(
                title: "Poids & dimensions",
                subtitle: "Utile pour calculer les frais de livraison.",
                actionTitle: nil,
                action: nil
            )

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                TextField("Poids kg", text: $weightKg)
                    .keyboardType(.decimalPad)
                    .marketplaceField()

                TextField("Longueur cm", text: $lengthCm)
                    .keyboardType(.decimalPad)
                    .marketplaceField()

                TextField("Largeur cm", text: $widthCm)
                    .keyboardType(.decimalPad)
                    .marketplaceField()

                TextField("Hauteur cm", text: $heightCm)
                    .keyboardType(.decimalPad)
                    .marketplaceField()
            }

            MarketplaceSellInfoBox(
                icon: "shippingbox.fill",
                title: "Transporteurs internationaux et locaux",
                subtitle: "Ces données prépareront DHL, UPS, FedEx, Colissimo, postes, agences locales, bus et coursiers."
            )
        }
        .padding(.horizontal, 16)
    }
}
private extension MarketplaceSellView {
    
    var stepFivePricePromotionSection: some View {

        VStack(alignment: .leading, spacing: 22) {

            MarketplaceSectionHeader(
                title: "Prix & Promotion",
                subtitle: "Prix normal, promotion automatique, dates, négociation et garantie.",
                actionTitle: nil,
                action: nil
            )

            MarketplaceSellInfoBox(
                icon: "tag.fill",
                title: "Prix principal du produit",
                subtitle: "Ce prix sert de base générale. Les variantes peuvent avoir leur propre prix et leur propre promotion."
            )

            TextField("Prix normal ex : 29,99", text: $normalPrice)
                .keyboardType(.decimalPad)
                .marketplaceField()
                .onChange(of: normalPrice) { _, newValue in
                    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        price = newValue
                    }
                }

            Toggle("Promotion générale du produit", isOn: $hasPromotion.animation(.spring(response: 0.3, dampingFraction: 0.85)))
                .marketplaceField()

            if hasPromotion {

                VStack(alignment: .leading, spacing: 14) {

                    TextField("Prix promotionnel ex : 19,99", text: $promotionalPrice)
                        .keyboardType(.decimalPad)
                        .marketplaceField()

                    HStack(spacing: 12) {

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Début")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            DatePicker(
                                "",
                                selection: $promotionStartDate,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fin")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            DatePicker(
                                "",
                                selection: $promotionEndDate,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    if promotionEndDate <= promotionStartDate {
                        MarketplaceSellInfoBox(
                            icon: "exclamationmark.triangle.fill",
                            title: "Dates incorrectes",
                            subtitle: "La date de fin doit être après la date de début."
                        )
                    } else {
                        MarketplaceSellInfoBox(
                            icon: "clock.badge.checkmark.fill",
                            title: "Promotion automatique",
                            subtitle: "Quand la date de fin arrive, le produit revient automatiquement au prix normal."
                        )
                    }

                    if let normal = Double(normalPrice.replacingOccurrences(of: ",", with: ".")),
                       let promo = Double(promotionalPrice.replacingOccurrences(of: ",", with: ".")),
                       normal > 0,
                       promo > 0,
                       promo < normal {

                        let percent = Int(((normal - promo) / normal * 100).rounded())

                        HStack {
                            Text("Réduction calculée")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("-\(percent)%")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(.red)
                                .clipShape(Capsule())
                        }
                        .padding(14)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .onAppear {
                            promotionPercent = "\(percent)"
                        }
                        .onChange(of: promotionalPrice) { _, _ in
                            promotionPercent = "\(percent)"
                        }
                    }
                }
            }

            Toggle("Prix négociable", isOn: $allowNegotiation)
                .marketplaceField()

            TextField("Quantité / Stock total", text: $quantity)
                .keyboardType(.numberPad)
                .marketplaceField()

            Toggle("Garantie vendeur", isOn: $hasWarranty.animation(.spring(response: 0.3, dampingFraction: 0.85)))
                .marketplaceField()

            if hasWarranty {

                TextField(
                    "Détails de la garantie ex : retour accepté sous 14 jours",
                    text: $warrantyText,
                    axis: .vertical
                )
                .lineLimit(4)
                .marketplaceField()
            }

            if !productVariants.isEmpty {
                MarketplaceSellInfoBox(
                    icon: "paintpalette.fill",
                    title: "Promotions par variante déjà disponibles",
                    subtitle: "Pour réduire seulement une couleur ou une taille, retourne à l’étape 3 et modifie la variante concernée."
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    var aiModerationSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            MarketplaceSectionHeader(
                title: "Contrôle IA",
                subtitle: "Sécurité avant publication.",
                actionTitle: nil,
                action: nil
            )
            
            Toggle("Analyser le produit avant publication", isOn: $aiCheckEnabled)
                .marketplaceField()
            
            VStack(spacing: 10) {
                MarketplaceSellAIWarningRow(icon: "photo.fill", title: "Images", subtitle: "Détection flou, doublons, images volées.")
                MarketplaceSellAIWarningRow(icon: "checkmark.shield.fill", title: "Produit", subtitle: "Contrefaçons, produits interdits, prix anormal.")
                MarketplaceSellAIWarningRow(icon: "person.crop.circle.badge.exclamationmark", title: "Vendeur", subtitle: "Faux vendeur, comportement suspect, comptes multiples.")
            }
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(.horizontal, 16)
    }
    
    var publishedSuccessSection: some View {
        VStack(spacing: 22) {

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(MarketplaceUITheme.primaryGradient)
                        .frame(width: 96, height: 96)

                    Image(systemName: "checkmark")
                        .font(.system(size: 42, weight: .black))
                        .foregroundStyle(.white)
                }

                Text("Produit publié !")
                    .font(.system(size: 28, weight: .black, design: .rounded))

                VStack(alignment: .leading, spacing: 8) {

                    Label(productTitle.isEmpty ? "Produit" : productTitle,
                          systemImage: "shippingbox.fill")

                    Label(selectedCategory,
                          systemImage: "square.grid.2x2.fill")

                    Label(
                        normalPrice.isEmpty ? price + " €" : normalPrice + " €",
                        systemImage: "eurosign.circle.fill"
                    )

                }
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                
                
                
                
                Text("Ton produit est maintenant en ligne sur Cutly Marketplace.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if !publishedMainImageURL.isEmpty,
                   let url = URL(string: publishedMainImageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            MarketplaceIconBadge(icon: "bag.fill", size: 90)
                        }
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }

                Button {
                    openPublishedProduct = true
                } label: {
                    Label("Voir mon produit", systemImage: "eye.fill")
                }
                .buttonStyle(MarketplacePremiumButtonStyle())
                .disabled(publishedProductId.isEmpty)

                Button {

                    openMarketplaceHome = true
                } label: {

                    Label(
                        "Aller sur Cutly Marketplace",
                        systemImage: "storefront.fill"
                    )
                    .font(.headline.bold())

                }
                .buttonStyle(MarketplacePremiumButtonStyle())
                
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        resetSellForm()
                    }
                } label: {
                    Label("Publier un autre produit", systemImage: "plus.circle.fill")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
        .padding(.horizontal, 16)
    }
    
    
    
    
    var publishActionSection: some View {
        VStack(spacing: 12) {
            Button {
                publishProduct(isDraft: false)
            } label: {
                if isPublishing {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Publication... \(Int(uploadProgress * 100))%")
                    }
                } else {
                    Label("Publier le produit", systemImage: "paperplane.fill")
                }
            }
            .disabled(isPublishing)
            .buttonStyle(MarketplacePremiumButtonStyle())

            Button {
                publishProduct(isDraft: true)
            } label: {
                Text("Enregistrer en brouillon")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.primary)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(isPublishing)

            Text("Votre produit sera publié avec ses photos, son prix, son stock, ses options de livraison et un contrôle de sécurité intelligent.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 16)
    }

    private func resetSellForm() {
        productTitle = ""
        productDescription = ""
        selectedCategory = "Sélectionner"
        price = ""
        quantity = "1"
        selectedPhotos = []
        selectedCondition = .new
        brand = ""
        material = ""
        sku = ""
        barcode = ""
        productVariants = []
        normalPrice = ""
        promotionalPrice = ""
        hasPromotion = false
        promotionPercent = ""
        hasWarranty = false
        warrantyText = ""
        publishedProductId = ""
        publishedMainImageURL = ""
        currentStep = 1
    }
    
    
    
    private func publishProduct(isDraft: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Utilisateur non connecté."
            showError = true
            return
        }

        let cleanTitle = productTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDescription = productDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCategory = selectedCategory.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty else {
            errorMessage = "Ajoute un titre au produit."
            showError = true
            return
        }

        guard cleanDescription.count >= 10 else {
            errorMessage = "Ajoute une description plus détaillée."
            showError = true
            return
        }

        guard cleanCategory != "Sélectionner", !cleanCategory.isEmpty else {
            errorMessage = "Choisis une catégorie."
            showError = true
            return
        }

        let parsedPrice = Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0

        guard parsedPrice > 0 else {
            errorMessage = "Ajoute un prix valide."
            showError = true
            return
        }

        isPublishing = true
        uploadProgress = 0

        Task {
            do {
                let productId = UUID().uuidString

                let imageURLs = try await uploadSelectedImages(
                    uid: uid,
                    productId: productId
                )

                let media = imageURLs.enumerated().map { index, url in
                    MarketplaceProductMedia(
                        url: url,
                        type: .image,
                        position: index,
                        isMain: index == 0
                    )
                }

                let moderation = MarketplaceModerationService.shared.moderateProduct(
                    productId: productId,
                    sellerId: uid,
                    title: cleanTitle,
                    description: cleanDescription,
                    categoryId: cleanCategory,
                    price: parsedPrice,
                    imageURLs: imageURLs,
                    sellerIsVerified: false
                )

                let finalStatus: MarketplaceProductStatus

                if isDraft {
                    finalStatus = .draft
                } else if moderation.decision == .block {
                    finalStatus = .rejected
                } else if moderation.decision == .review || moderation.decision == .restrict {
                    finalStatus = .underReview
                } else {
                    finalStatus = .active
                }

                let product = MarketplaceProduct(
                    id: productId,
                    sellerId: uid,
                    title: cleanTitle,
                    description: cleanDescription,
                    categoryId: cleanCategory,
                    categoryName: cleanCategory,
                    price: MarketplacePrice(
                        amount: parsedPrice,
                        currency: selectedCurrency,
                        discountPercent: hasPromotion ? Double(promotionPercent) : nil,
                        isNegotiable: allowNegotiation
                    ),
                    condition: selectedCondition,
                    status: finalStatus,
                    media: media,
                    dimensions: MarketplaceProductDimensions(
                        weightKg: Double(weightKg.replacingOccurrences(of: ",", with: ".")),
                        lengthCm: Double(lengthCm.replacingOccurrences(of: ",", with: ".")),
                        widthCm: Double(widthCm.replacingOccurrences(of: ",", with: ".")),
                        heightCm: Double(heightCm.replacingOccurrences(of: ",", with: "."))
                    ),
                    stock: Int(quantity) ?? 1,
                    sku: sku.isEmpty ? nil : sku,
                    barcode: barcode.isEmpty ? nil : barcode,
                    brand: brand.isEmpty ? nil : brand,
                    colors: splitList(colors),
                    sizes: splitList(sizes),
                    tags: buildSearchKeywords(),
                    countryName: selectedCountry,
                    city: locationManager.city,
                    latitude: locationManager.latitude,
                    longitude: locationManager.longitude,
                    allowsPickup: allowPickup,
                    allowsDelivery: allowDelivery,
                    allowsNegotiation: allowNegotiation,
                    viewCount: 0,
                    favoriteCount: 0,
                    soldCount: 0,
                    shareCount: 0,
                    aiScore: moderation.riskScore,
                    aiRiskLevel: convertModerationRisk(moderation.riskLevel),
                    aiWarnings: moderation.reasons,
                    createdAt: Timestamp(),
                    updatedAt: Timestamp(),
                    publishedAt: isDraft ? nil : Timestamp()
                )

                try await Firestore.firestore()
                    .collection(MarketplaceFirestoreService.Collection.products)
                    .document(productId)
                    .setData(from: product, merge: true)
                var variantsToSave: [MarketplaceVariantEditorDraft] = []

                for variant in productVariants {

                    var updatedVariant = variant

                    let uploadedURLs = try await uploadVariantImages(
                        uid: uid,
                        productId: productId,
                        variant: variant
                    )

                    updatedVariant.existingImageURLs = uploadedURLs
                    updatedVariant.selectedImageData = []

                    variantsToSave.append(updatedVariant)
                }
                
                
                
                let productFirestoreData: [String: Any] = [
                    "id": productId,
                    "sellerId": uid,
                    "title": cleanTitle,
                    "description": cleanDescription,
                    "category": cleanCategory,
                    "categoryId": cleanCategory,
                    "categoryName": cleanCategory,
                    "price": parsedPrice,
                    "priceText": "\(String(format: "%.2f", parsedPrice)) \(selectedCurrency.rawValue)",
                    "currency": selectedCurrency.rawValue,
                    "quantity": productVariants.isEmpty ? (Int(quantity) ?? 1) : productVariants.reduce(0) { $0 + $1.stock },
                    "stock": productVariants.isEmpty ? (Int(quantity) ?? 1) : productVariants.reduce(0) { $0 + $1.stock },
                    "status": finalStatus.rawValue,
                    "condition": selectedCondition.title,
                    "brand": brand,
                    "colors": productVariants.isEmpty ? splitList(colors) : Array(Set(productVariants.map { $0.colorName })),
                    "sizes": productVariants.isEmpty ? splitList(sizes) : Array(Set(productVariants.map { $0.size }.filter { !$0.isEmpty })),
                    "variants": variantsToSave.map {
                        $0.firestoreData(baseProductPrice: parsedPrice)
                    },
                    "hasVariants": !productVariants.isEmpty,
                    "availableColors": Array(Set(productVariants.map { $0.colorName })),
                    "availableSizes": Array(Set(productVariants.map { $0.size }.filter { !$0.isEmpty })),
                    "variantColors": Array(Set(productVariants.map { $0.colorName })),
                    "variantSizes": Array(Set(productVariants.map { $0.size }.filter { !$0.isEmpty })),
                    "totalVariantStock": productVariants.reduce(0) { $0 + $1.stock },
                    "minVariantPrice": productVariants.map { $0.effectivePrice }.min() ?? parsedPrice,
                    "maxVariantPrice": productVariants.map { $0.effectivePrice }.max() ?? parsedPrice,
                    "isSoldOut": productVariants.isEmpty
                        ? ((Int(quantity) ?? 1) <= 0)
                        : productVariants.reduce(0) { $0 + $1.stock } <= 0,
                    "availableVariantCount": productVariants.filter { $0.stock > 0 }.count,
                    "soldOutVariantCount": productVariants.filter { $0.stock <= 0 }.count,
                    "sku": sku,
                    "barcode": barcode,
                    "imageURLs": imageURLs,
                    "mainImageURL": imageURLs.first ?? "",
                    "country": selectedCountry,
                    "countryName": selectedCountry,
                    "city": locationManager.city,
                    "latitude": locationManager.latitude as Any,
                    "longitude": locationManager.longitude as Any,
                    "allowsPickup": allowPickup,
                    "allowsDelivery": allowDelivery,
                    "deliveryAvailable": allowDelivery,
                    "pickupAvailable": allowPickup,
                    "allowsNegotiation": allowNegotiation,
                    "hasPromotion": hasPromotion,
                    "promotionPercent": Int(promotionPercent) ?? 0,
                    "hasWarranty": hasWarranty,
                    "warrantyText": warrantyText,
                    "dynamicAttributes": dynamicAttributes,
                    "dynamicCategoryId": selectedDynamicCategory?.id ?? cleanCategory,
                    "searchKeywords": buildSearchKeywords(),
                    "sellerName": Auth.auth().currentUser?.displayName ?? "Vendeur Marketplace",
                    "sellerVerified": false,
                    "viewsCount": 0,
                    "favoritesCount": 0,
                    "salesCount": 0,
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp(),
                    "publishedAt": isDraft ? NSNull() : FieldValue.serverTimestamp()
                ]

                try await Firestore.firestore()
                    .collection("marketplace_products")
                    .document(productId)
                    .setData(productFirestoreData, merge: true)
                
                

                try await MarketplaceModerationService.shared.saveModerationResult(moderation)

                try await MarketplaceAnalyticsService.shared.trackEvent(
                    userId: uid,
                    eventType: isDraft ? .productView : .conversion,
                    targetId: productId,
                    targetType: "product",
                    metadata: [
                        "action": isDraft ? "draft_created" : "product_published",
                        "status": finalStatus.rawValue
                    ]
                )

                await MainActor.run {
                    isPublishing = false
                    uploadProgress = 1
                    publishedProductId = productId
                    publishedMainImageURL = imageURLs.first ?? ""
                    currentStep = 7
                    showSuccess = true
                }

            } catch {
                await MainActor.run {
                    isPublishing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func uploadSelectedImages(uid: String, productId: String) async throws -> [String] {
        guard !selectedPhotos.isEmpty else { return [] }

        var urls: [String] = []

        for (index, item) in selectedPhotos.enumerated() {
            guard let rawData = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: rawData) else {
                continue
            }

            let url = try await MarketplaceStorageService.shared.uploadImage(
                uiImage,
                folder: "marketplaceProducts/\(uid)/\(productId)",
                fileName: "image_\(index)",
                compressionQuality: 0.78
            )

            urls.append(url)

            await MainActor.run {
                uploadProgress = Double(index + 1) / Double(selectedPhotos.count)
            }
        }

        return urls
    }
    private func uploadVariantImages(
        uid: String,
        productId: String,
        variant: MarketplaceVariantEditorDraft
    ) async throws -> [String] {

        guard !variant.selectedImageData.isEmpty else {
            return variant.existingImageURLs
        }

        var uploadedURLs = variant.existingImageURLs

        for (index, imageData) in variant.selectedImageData.enumerated() {

            guard let image = UIImage(data: imageData) else {
                continue
            }

            let url = try await MarketplaceStorageService.shared.uploadImage(
                image,
                folder: "marketplaceProducts/\(uid)/\(productId)/variants/\(variant.id)",
                fileName: "variant_\(index)",
                compressionQuality: 0.8
            )

            uploadedURLs.append(url)
        }

        return uploadedURLs
    }
    
    
    
    
    
    private func buildSearchKeywords() -> [String] {
        let rawText = [
            productTitle,
            productDescription,
            selectedCategory,
            brand,
            colors,
            sizes,
            productVariants.map { $0.colorName }.joined(separator: " "),
            productVariants.map { $0.size }.joined(separator: " "),
            selectedCountry,
            locationManager.city,
            locationManager.country
        ].joined(separator: " ")
        return Array(Set(
            rawText
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .lowercased()
                .replacingOccurrences(of: ",", with: " ")
                .split(separator: " ")
                .map { String($0) }
                .filter { $0.count >= 2 }
        ))
    }

    private func splitList(_ text: String) -> [String] {
        text
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func convertModerationRisk(_ risk: MarketplaceModerationRiskLevel) -> MarketplaceRiskLevel {
        switch risk {
        case .low:
            return .low
        case .medium:
            return .medium
        case .high:
            return .high
        case .critical:
            return .critical
        }
    }
    private func loadCategories() {
        Firestore.firestore()
            .collection("marketplace_categories")
            .order(by: "title")
            .getDocuments { snapshot, _ in

                let loadedCategories: [MarketplaceDynamicCategory] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()

                    return MarketplaceDynamicCategory(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "Catégorie",
                        icon: data["icon"] as? String ?? "square.grid.2x2.fill"
                    )
                } ?? []

                marketplaceCategories = loadedCategories
                categories = loadedCategories.map { $0.title }

                if categories.isEmpty {
                    categories = [
                        "Mode", "Chaussures", "Sacs", "Bijoux", "Montres",
                        "Beauté", "Cheveux", "Perruques", "Maquillage", "Parfums",
                        "Téléphone", "Électronique", "Informatique", "Jeux vidéo",
                        "Maison", "Meubles", "Décoration", "Électroménager",
                        "Immobilier", "Maison à vendre", "Appartement", "Villa", "Terrain",
                        "Voiture", "Moto", "Vélo", "Pièces auto",
                        "Bébé", "Enfants", "Sport", "Santé", "Livres",
                        "Animaux", "Alimentation", "Services", "Accessoires"
                    ]
                }
            }
    }
    private func seedMarketplaceCategories() {
        isSeedingCategories = true
        seedMessage = ""

        let functions = Functions.functions(region: "us-central1")

        functions.httpsCallable("seedMarketplaceCategories").call { result, error in
            isSeedingCategories = false

            if let error {
                seedMessage = "Erreur : \(error.localizedDescription)"
                return
            }

            seedMessage = "Catégories créées avec succès ✅"
            loadCategories()
        }
    }
    
    
    
    
    
    private func loadFieldsForSelectedCategory(_ categoryTitle: String) {
        isLoadingCategoryFields = true
        categoryFields = []
        dynamicAttributes = [:]

        let matchedCategory = marketplaceCategories.first {
            $0.title.lowercased() == categoryTitle.lowercased()
        }

        selectedDynamicCategory = matchedCategory

        let categoryId = matchedCategory?.id ?? categoryTitle
            .lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "_")

        Firestore.firestore()
            .collection("marketplace_category_fields")
            .whereField("categoryId", isEqualTo: categoryId)
            .order(by: "position")
            .getDocuments { snapshot, _ in

                let firestoreFields: [MarketplaceDynamicField] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()

                    return MarketplaceDynamicField(
                        id: doc.documentID,
                        key: data["key"] as? String ?? doc.documentID,
                        title: data["title"] as? String ?? "Champ",
                        placeholder: data["placeholder"] as? String ?? "",
                        type: data["type"] as? String ?? "text",
                        isRequired: data["isRequired"] as? Bool ?? false,
                        options: data["options"] as? [String] ?? []
                    )
                } ?? []

                if firestoreFields.isEmpty {
                    categoryFields = fallbackFields(for: categoryTitle)
                } else {
                    categoryFields = firestoreFields
                }

                isLoadingCategoryFields = false
            }
    }
    private func fallbackFields(for category: String) -> [MarketplaceDynamicField] {
        let name = category.lowercased()

        if name.contains("immobilier") || name.contains("maison") || name.contains("villa") || name.contains("appartement") || name.contains("terrain") {
            return [
                MarketplaceDynamicField(id: "surface", key: "surface", title: "Surface m²", placeholder: "Ex : 120", type: "number", isRequired: true, options: []),
                MarketplaceDynamicField(id: "pieces", key: "pieces", title: "Nombre de pièces", placeholder: "Ex : 5", type: "number", isRequired: false, options: []),
                MarketplaceDynamicField(id: "chambres", key: "chambres", title: "Chambres", placeholder: "Ex : 3", type: "number", isRequired: false, options: []),
                MarketplaceDynamicField(id: "piscine", key: "piscine", title: "Piscine", placeholder: "", type: "select", isRequired: false, options: ["Oui", "Non"]),
                MarketplaceDynamicField(id: "adresse", key: "adresse", title: "Adresse / quartier", placeholder: "Ex : Vitré centre", type: "text", isRequired: false, options: [])
            ]
        }

        if name.contains("voiture") || name.contains("moto") || name.contains("vélo") {
            return [
                MarketplaceDynamicField(id: "marque", key: "marque", title: "Marque", placeholder: "Ex : Volkswagen", type: "text", isRequired: true, options: []),
                MarketplaceDynamicField(id: "modele", key: "modele", title: "Modèle", placeholder: "Ex : Polo", type: "text", isRequired: false, options: []),
                MarketplaceDynamicField(id: "annee", key: "annee", title: "Année", placeholder: "Ex : 2019", type: "number", isRequired: false, options: []),
                MarketplaceDynamicField(id: "kilometrage", key: "kilometrage", title: "Kilométrage", placeholder: "Ex : 85000", type: "number", isRequired: false, options: []),
                MarketplaceDynamicField(id: "carburant", key: "carburant", title: "Carburant", placeholder: "", type: "select", isRequired: false, options: ["Essence", "Diesel", "Hybride", "Électrique"])
            ]
        }

        if name.contains("mode") || name.contains("t-shirt") || name.contains("chaussure") || name.contains("vêtement") {
            return [
                MarketplaceDynamicField(id: "marque", key: "marque", title: "Marque", placeholder: "Ex : Nike", type: "text", isRequired: false, options: []),
                MarketplaceDynamicField(id: "taille", key: "taille", title: "Taille", placeholder: "", type: "select", isRequired: false, options: ["XS", "S", "M", "L", "XL", "XXL", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45"]),
                MarketplaceDynamicField(id: "couleur", key: "couleur", title: "Couleur", placeholder: "Ex : Noir", type: "text", isRequired: false, options: [])
            ]
        }

        return [
            MarketplaceDynamicField(id: "marque", key: "marque", title: "Marque", placeholder: "Optionnel", type: "text", isRequired: false, options: []),
            MarketplaceDynamicField(id: "etat_detail", key: "etat_detail", title: "Détail de l’état", placeholder: "Décris l’état réel du produit", type: "longText", isRequired: false, options: [])
        ]
    }
    

    

    func addProductVariant() {

        editingVariant = nil
        showVariantEditor = true

    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}

private struct MarketplaceSellPreviewCard: View {
    let title: String
    let price: String
    let normalPrice: String
    let promotionalPrice: String
    let category: String
    let brand: String
    let material: String
    let condition: String
    let allowDelivery: Bool
    let allowPickup: Bool
    let hasPromotion: Bool
    let promotionPercent: String
    let selectedPhotos: [PhotosPickerItem]
    let variants: [MarketplaceVariantEditorDraft]
    let onPublish: () -> Void
    let onEdit: () -> Void

    @State private var selectedImageData: Data?
    @State private var selectedVariant: MarketplaceVariantEditorDraft?
    @State private var previewPhotoData: [Data] = []

    private var displayPrice: String {
        if let variant = selectedVariant {
            if variant.isPromotionCurrentlyActive, let promo = variant.promotionalPrice {
                return String(format: "%.2f €", promo)
            }
            return String(format: "%.2f €", variant.normalPrice)
        }

        if hasPromotion, !promotionalPrice.isEmpty {
            return "\(promotionalPrice) €"
        }

        if !price.isEmpty {
            return "\(price) €"
        }

        return "Prix à confirmer"
    }

    private var oldPriceText: String? {
        if let variant = selectedVariant,
           variant.isPromotionCurrentlyActive,
           variant.promotionalPrice != nil {
            return String(format: "%.2f €", variant.normalPrice)
        }

        if hasPromotion, !normalPrice.isEmpty {
            return "\(normalPrice) €"
        }

        return nil
    }

    private var discountText: String? {
        if let variant = selectedVariant, variant.discountPercent > 0 {
            return "-\(variant.discountPercent)%"
        }

        if hasPromotion, !promotionPercent.isEmpty {
            return "-\(promotionPercent)%"
        }

        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MarketplaceSectionHeader(
                title: "Aperçu avant publication",
                subtitle: "Vérifie exactement comment le produit va sortir côté acheteur.",
                actionTitle: nil,
                action: nil
            )
            
            VStack(alignment: .leading, spacing: 16) {
                previewImage
                
                if !previewPhotoData.isEmpty || !variants.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(previewPhotoData.indices, id: \.self) { index in
                                Button {
                                    selectedImageData = previewPhotoData[index]
                                    selectedVariant = nil
                                } label: {
                                    Image(uiImage: UIImage(data: previewPhotoData[index]) ?? UIImage())
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 54, height: 54)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                            
                            ForEach(variants) { variant in
                                Button {
                                    selectedVariant = variant
                                    selectedImageData = variant.selectedImageData.first
                                } label: {
                                    Circle()
                                        .fill(Color(hex: variant.colorHex))
                                        .frame(width: 42, height: 42)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedVariant?.id == variant.id ? Color.orange : Color.white.opacity(0.2), lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title.isEmpty ? "Titre du produit" : title)
                            .font(.title3.bold())
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            Text(displayPrice)
                                .font(.system(size: 25, weight: .black, design: .rounded))
                                .foregroundStyle(.red)
                            
                            if let oldPriceText {
                                Text(oldPriceText)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .strikethrough()
                            }
                            
                            if let discountText {
                                Text(discountText)
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    if allowDelivery {
                        Label("Livraison", systemImage: "shippingbox.fill")
                    }
                    
                    if allowPickup {
                        Label("Retrait", systemImage: "hand.raised.fill")
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                
                Divider()
                
                Text("État : \(condition)")
                    .font(.subheadline.bold())
                
                if !brand.isEmpty {
                    Text("Marque : \(brand)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if !material.isEmpty {
                    Text("Matière : \(material)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let selectedVariant {
                    Text("Variante : \(selectedVariant.colorName)\(selectedVariant.size.isEmpty ? "" : " • \(selectedVariant.size)")")
                        .font(.caption.bold())
                        .foregroundStyle(.purple)
                    
                    Text(selectedVariant.stock > 0 ? "\(selectedVariant.stock) disponible(s)" : "Rupture de stock")
                        .font(.caption.bold())
                        .foregroundStyle(selectedVariant.stock > 0 ? .green : .red)
                }
                
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Text("Modifier")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    
                    Button(action: onPublish) {
                        Text("Publier")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(MarketplaceUITheme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .padding(.horizontal, 16)
        .task {
            previewPhotoData.removeAll()
            
            for item in selectedPhotos.prefix(8) {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    previewPhotoData.append(data)
                }
            }
            
            if selectedImageData == nil {
                selectedImageData = previewPhotoData.first ?? variants.first?.selectedImageData.first
            }
            
            if selectedVariant == nil, let firstVariant = variants.first {
                selectedVariant = firstVariant
                
                if let firstVariantImage = firstVariant.selectedImageData.first {
                    selectedImageData = firstVariantImage
                }
            }
        }
        .onChange(of: selectedPhotos.count) { _, _ in
            Task {
                previewPhotoData.removeAll()

                for item in selectedPhotos.prefix(8) {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        previewPhotoData.append(data)
                    }
                }

                selectedImageData = previewPhotoData.first ?? variants.first?.selectedImageData.first
                selectedVariant = variants.first
            }
        }
        .onChange(of: variants.count) { _, _ in
            if selectedVariant == nil {
                selectedVariant = variants.first
            }

            if selectedImageData == nil {
                selectedImageData = previewPhotoData.first ?? variants.first?.selectedImageData.first
            }
        }
        
    }

    private var previewImage: some View {
        Group {
            if let selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(MarketplaceUITheme.primaryGradient)
                    .overlay {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

private struct MarketplaceSellStepOnePhotoGrid: View {
    @Binding var selectedPhotos: [PhotosPickerItem]

    @State private var imageData: [Data] = []

    var body: some View {
        HStack(spacing: 10) {
            mainPhoto

            VStack(spacing: 10) {
                smallPhoto(index: 1)
                smallPhoto(index: 2)
            }

            addPhotoButton
        }
        .frame(height: 150)
        .task {
            await loadImages()
        }
        .onChange(of: selectedPhotos.count) { _, _ in
            Task {
                await loadImages()
            }
        }
    }

    private var mainPhoto: some View {
        photoBox(index: 0)
            .frame(maxWidth: .infinity)
            .frame(height: 150)
    }

    private func smallPhoto(index: Int) -> some View {
        photoBox(index: index)
            .frame(width: 70, height: 70)
    }

    private var addPhotoButton: some View {
        PhotosPicker(
            selection: $selectedPhotos,
            maxSelectionCount: 20,
            matching: .images
        ) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .frame(width: 70, height: 150)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(.primary)
                }
        }
        .buttonStyle(.plain)
    }

    private func photoBox(index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if imageData.indices.contains(index),
                   let uiImage = UIImage(data: imageData[index]) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay {
                            Image(systemName: "photo.fill")
                                .font(.system(size: index == 0 ? 34 : 22, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if imageData.indices.contains(index) {
                Button {
                    removePhoto(at: index)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.black.opacity(0.45))
                        .clipShape(Circle())
                }
                .padding(6)
            }
        }
        .clipped()
    }

    @MainActor
    private func removePhoto(at index: Int) {
        guard selectedPhotos.indices.contains(index) else { return }
        selectedPhotos.remove(at: index)
        imageData.removeAll()
    }

    private func loadImages() async {
        var loaded: [Data] = []

        for item in selectedPhotos.prefix(20) {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }

        await MainActor.run {
            imageData = loaded
        }
    }
}




private struct MarketplaceSellBadge: View {

    let title:String
    let icon:String

    var body: some View{

        HStack(spacing:6){

            Image(systemName:icon)

            Text(title)

        }
        .font(.caption.bold())
        .padding(.horizontal,12)
        .padding(.vertical,8)
        .background(.white.opacity(0.14))
        .foregroundStyle(.white)
        .clipShape(Capsule())

    }

}

private struct MarketplaceSellSelectorRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))

                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct MarketplaceSellDeliveryOption: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}
private struct MarketplaceSellInfoBox: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MarketplaceIconBadge(icon: icon, size: 40)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.bold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            Spacer()
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
private struct MarketplaceSellAIWarningRow: View {
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
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}
private struct MarketplaceCategorySelectionSheet: View {
    let categories: [String]
    @Binding var selectedCategory: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredCategories: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if query.isEmpty {
            return categories
        }

        return categories.filter {
            $0.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("Rechercher une catégorie...", text: $searchText)
                    .padding(14)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 16)

                List(filteredCategories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                        onSelect(category)
                        dismiss()
                    } label: {
                        HStack {
                            Text(category)
                                .font(.headline)

                            Spacer()

                            if selectedCategory == category {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Catégorie")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
private struct MarketplaceSelectedPhotoPreview: View {
    let item: PhotosPickerItem
    let index: Int

    @State private var imageData: Data?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(MarketplaceUITheme.primaryGradient)
                        .overlay(
                            Image(systemName: "photo.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
            }
            .frame(width: 82, height: 82)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text("\(index + 1)")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(6)
                .background(.black.opacity(0.35))
                .clipShape(Circle())
                .padding(6)
        }
        .task {
            imageData = try? await item.loadTransferable(type: Data.self)
        }
    }
}
private struct MarketplaceDynamicCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
}

private struct MarketplaceDynamicField: Identifiable, Hashable {
    let id: String
    let key: String
    let title: String
    let placeholder: String
    let type: String
    let isRequired: Bool
    let options: [String]
}
private struct MarketplaceDynamicFieldInput: View {
    let field: MarketplaceDynamicField
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(field.title)
                    .font(.subheadline.weight(.bold))

                if field.isRequired {
                    Text("*")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
            }

            if field.type == "select", !field.options.isEmpty {
                Picker(field.title, selection: $value) {
                    Text("Sélectionner").tag("")
                    ForEach(field.options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .padding(14)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            } else if field.type == "number" || field.type == "decimal" {
                TextField(field.placeholder.isEmpty ? field.title : field.placeholder, text: $value)
                    .keyboardType(.decimalPad)
                    .marketplaceField()

            } else if field.type == "longText" {
                TextField(field.placeholder.isEmpty ? field.title : field.placeholder, text: $value, axis: .vertical)
                    .lineLimit(3...6)
                    .marketplaceField()

            } else {
                TextField(field.placeholder.isEmpty ? field.title : field.placeholder, text: $value)
                    .marketplaceField()
            }
        }
    }
}
private struct MarketplaceProductVariantDraft: Identifiable, Hashable {

    let id = UUID()

    let colorName: String
    let colorHex: String

    let size: String

    let price: Double

    let stock: Int

    let sku: String

    let barcode: String?

    let imageURLs: [String]
    let promotionalPrice: Double?
    let promotionPercent: Int?
    let promotionStartDate: Date?
    let promotionEndDate: Date?
    
    var isAvailable: Bool {
        stock > 0
    }

    var firestoreData: [String: Any] {
        [
            "id": id.uuidString,

            "name": "Couleur",
            "value": colorName,

            "colorName": colorName,
            "colorHex": colorHex,

            "size": size,

            "price": price,
            "priceAdjustment": price,

            "stock": stock,

            "sku": sku,
            "barcode": barcode ?? "",

            "imageURL": imageURLs.first ?? "",
            "imageURLs": imageURLs,

            "isAvailable": stock > 0
        ]
    }
    var firestoreVariants: [[String: Any]] {
        var items: [[String: Any]] = []

        items.append([
            "id": "\(id.uuidString)_color",
            "name": "Couleur",
            "value": colorName,
            "colorName": colorName,
            "colorHex": colorHex,
            "size": size,
            "price": price,
            "priceAdjustment": price,
            "stock": stock,
            "sku": sku,
            "barcode": barcode ?? "",
            "imageURL": imageURLs.first ?? "",
            "imageURLs": imageURLs,
            "isAvailable": stock > 0
        ])

        if !size.isEmpty {
            items.append([
                "id": "\(id.uuidString)_size",
                "name": "Taille",
                "value": size,
                "colorName": colorName,
                "colorHex": colorHex,
                "size": size,
                "price": price,
                "priceAdjustment": price,
                "stock": stock,
                "sku": sku,
                "barcode": barcode ?? "",
                "imageURL": imageURLs.first ?? "",
                "imageURLs": imageURLs,
                "isAvailable": stock > 0
            ])
        }

        return items
    }
    
    
    
}

private struct MarketplaceVariantRow: View {

    let variant: MarketplaceVariantEditorDraft

    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {

        HStack(spacing: 14) {

            Circle()
                .fill(Color(hex: variant.colorHex))
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 5) {

                Text("\(variant.colorName)\(variant.size.isEmpty ? "" : " • \(variant.size)")")
                    .font(.headline)

                HStack(spacing: 8) {

                    if variant.isPromotionCurrentlyActive,
                       let promo = variant.promotionalPrice {

                        Text(String(format: "%.2f €", promo))
                            .font(.headline.bold())
                            .foregroundStyle(.red)

                        Text(String(format: "%.2f €", variant.normalPrice))
                            .font(.caption)
                            .strikethrough()
                            .foregroundStyle(.secondary)

                    } else {

                        Text(String(format: "%.2f €", variant.normalPrice))
                            .font(.headline.bold())
                            .foregroundStyle(.purple)

                    }

                }

                HStack(spacing: 12) {

                    Label(
                        "\(variant.stock)",
                        systemImage: "shippingbox.fill"
                    )

                    if variant.stock > 0 {

                        Text("Disponible")
                            .foregroundStyle(.green)

                    } else {

                        Text("Épuisé")
                            .foregroundStyle(.red)

                    }

                }
                .font(.caption.bold())

            }

            Spacer()

            HStack(spacing: 18) {

                Button(action: onEdit) {

                    Image(systemName: "pencil")

                }

                Button(action: onDelete) {

                    Image(systemName: "trash.fill")
                        .foregroundStyle(.red)

                }

            }

        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )

    }

}

private extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
