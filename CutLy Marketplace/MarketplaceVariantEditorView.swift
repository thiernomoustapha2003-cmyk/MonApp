//
//  MarketplaceVariantEditorView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 09/07/2026.
//

//
//  MarketplaceVariantEditorView.swift
//  Cutly / AfroConnect
//
//  Éditeur de variante produit Marketplace (couleur, taille, stock, prix,
//  promotion, images, infos avancées). Utilisable en sheet depuis
//  MarketplaceSellView.swift, en mode création ou édition.
//

import SwiftUI
import PhotosUI
import UIKit
import FirebaseFirestore

// MARK: - Color(hex:) helper

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            r = (value >> 16) & 0xFF
            g = (value >> 8) & 0xFF
            b = value & 0xFF
        default:
            r = 255; g = 255; b = 255
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: - Design tokens

private enum VariantTheme {
    static let background = Color(hex: "0B0B10")
    static let cardBackground = Color(hex: "16161F")
    static let cardStroke = Color.white.opacity(0.06)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.55)
    static let gradient = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let danger = Color(hex: "FF4D4D")
    static let success = Color(hex: "34D399")
}

// MARK: - Color palette option

struct MarketplaceColorOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let hex: String
}

private let marketplaceColorPalette: [MarketplaceColorOption] = [
    .init(name: "Noir", hex: "1A1A1A"),
    .init(name: "Blanc", hex: "F5F5F5"),
    .init(name: "Rouge", hex: "E11D2E"),
    .init(name: "Bleu marine", hex: "1E2A4A"),
    .init(name: "Vert", hex: "1F8A4C"),
    .init(name: "Gris", hex: "8A8A8A"),
    .init(name: "Beige", hex: "D8C3A5"),
    .init(name: "Jaune", hex: "F2C230"),
    .init(name: "Rose", hex: "F06292"),
    .init(name: "Orange", hex: "F2872A"),
    .init(name: "Violet", hex: "7C4DFF"),
    .init(name: "Marron", hex: "5B3A29")
]

private let marketplaceQuickSizes = ["XS", "S", "M", "L", "XL", "XXL", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45"]

// MARK: - Variant image (existing remote or freshly picked local)

private enum MarketplaceVariantImage: Identifiable, Hashable {
    case remote(String)
    case local(Data)

    var id: String {
        switch self {
        case .remote(let url): return "remote-\(url)"
        case .local(let data): return "local-\(data.hashValue)"
        }
    }
}

// MARK: - Draft model

struct MarketplaceVariantEditorDraft: Identifiable, Hashable {
    var id: String
    var colorName: String
    var colorHex: String
    var size: String
    var normalPrice: Double
    var promotionalPrice: Double?
    var promotionEnabled: Bool
    var promotionStartDate: Date
    var promotionEndDate: Date
    var stock: Int
    var sku: String
    var barcode: String
    var material: String
    var model: String
    var privateNote: String
    var existingImageURLs: [String]
    var selectedImageData: [Data]

    init(
        id: String = UUID().uuidString,
        colorName: String = "",
        colorHex: String = "1A1A1A",
        size: String = "",
        normalPrice: Double = 0,
        promotionalPrice: Double? = nil,
        promotionEnabled: Bool = false,
        promotionStartDate: Date = Date(),
        promotionEndDate: Date = Date().addingTimeInterval(86_400 * 7),
        stock: Int = 0,
        sku: String = "",
        barcode: String = "",
        material: String = "",
        model: String = "",
        privateNote: String = "",
        existingImageURLs: [String] = [],
        selectedImageData: [Data] = []
    ) {
        self.id = id
        self.colorName = colorName
        self.colorHex = colorHex
        self.size = size
        self.normalPrice = normalPrice
        self.promotionalPrice = promotionalPrice
        self.promotionEnabled = promotionEnabled
        self.promotionStartDate = promotionStartDate
        self.promotionEndDate = promotionEndDate
        self.stock = stock
        self.sku = sku
        self.barcode = barcode
        self.material = material
        self.model = model
        self.privateNote = privateNote
        self.existingImageURLs = existingImageURLs
        self.selectedImageData = selectedImageData
    }

    var isAvailable: Bool {
        stock > 0
    }

    var isPromotionCurrentlyActive: Bool {
        guard promotionEnabled, promotionalPrice != nil else { return false }
        let now = Date()
        return now >= promotionStartDate && now <= promotionEndDate
    }

    var discountPercent: Int {
        guard let promo = promotionalPrice, normalPrice > 0, promo < normalPrice else { return 0 }
        return Int(((normalPrice - promo) / normalPrice * 100).rounded())
    }

    var effectivePrice: Double {
        if isPromotionCurrentlyActive, let promo = promotionalPrice {
            return promo
        }
        return normalPrice
    }

    func firestoreData(baseProductPrice: Double) -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "name": "\(colorName) - \(size)",
            "value": "\(colorName)|\(size)",
            "colorName": colorName,
            "colorHex": colorHex,
            "size": size,
            "price": effectivePrice,
            "normalPrice": normalPrice,
            "promotionEnabled": promotionEnabled,
            "promotionStartDate": Timestamp(date: promotionStartDate),
            "promotionEndDate": Timestamp(date: promotionEndDate),
            "discountPercent": discountPercent,
            "priceAdjustment": normalPrice - baseProductPrice,
            "stock": stock,
            "sku": sku,
            "barcode": barcode,
            "imageURL": existingImageURLs.first ?? "",
            "imageURLs": existingImageURLs,
            "isAvailable": isAvailable,
            "isPromotionCurrentlyActive": isPromotionCurrentlyActive,
            "material": material,
            "model": model,
            "privateNote": privateNote
        ]
        if let promo = promotionalPrice {
            data["promotionalPrice"] = promo
        } else {
            data["promotionalPrice"] = NSNull()
        }
        return data
    }
}

// MARK: - Main view

struct MarketplaceVariantEditorView: View {
    let baseProductPrice: Double
    let existingVariant: MarketplaceVariantEditorDraft?
    let onSave: (MarketplaceVariantEditorDraft) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var colorName: String
    @State private var colorHex: String
    @State private var colorSearchText: String = ""
    @State private var size: String
    @State private var stock: Int
    @State private var normalPriceText: String
    @State private var promotionalPriceText: String
    @State private var promotionEnabled: Bool
    @State private var promotionStartDate: Date
    @State private var promotionEndDate: Date
    @State private var sku: String
    @State private var barcode: String
    @State private var material: String
    @State private var model: String
    @State private var privateNote: String
    @State private var existingImageURLs: [String]
    @State private var selectedImageData: [Data]

    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showDeleteConfirmation = false

    private var isEditMode: Bool {
        existingVariant != nil
    }

    init(
        baseProductPrice: Double,
        existingVariant: MarketplaceVariantEditorDraft?,
        onSave: @escaping (MarketplaceVariantEditorDraft) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.baseProductPrice = baseProductPrice
        self.existingVariant = existingVariant
        self.onSave = onSave
        self.onDelete = onDelete

        let base = existingVariant ?? MarketplaceVariantEditorDraft(normalPrice: baseProductPrice)
        _colorName = State(initialValue: base.colorName)
        _colorHex = State(initialValue: base.colorHex)
        _size = State(initialValue: base.size)
        _stock = State(initialValue: base.stock)
        _normalPriceText = State(initialValue: base.normalPrice > 0 ? String(format: "%.2f", base.normalPrice) : "")
        _promotionalPriceText = State(initialValue: base.promotionalPrice.map { String(format: "%.2f", $0) } ?? "")
        _promotionEnabled = State(initialValue: base.promotionEnabled)
        _promotionStartDate = State(initialValue: base.promotionStartDate)
        _promotionEndDate = State(initialValue: base.promotionEndDate)
        _sku = State(initialValue: base.sku)
        _barcode = State(initialValue: base.barcode)
        _material = State(initialValue: base.material)
        _model = State(initialValue: base.model)
        _privateNote = State(initialValue: base.privateNote)
        _existingImageURLs = State(initialValue: base.existingImageURLs)
        _selectedImageData = State(initialValue: base.selectedImageData)
    }

    private var normalPrice: Double {
        Double(normalPriceText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var promotionalPrice: Double? {
        let trimmed = promotionalPriceText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    private var isPromotionDateRangeValid: Bool {
        promotionEndDate > promotionStartDate
    }

    private var discountPercent: Int {
        guard let promo = promotionalPrice, normalPrice > 0, promo < normalPrice else { return 0 }
        return Int(((normalPrice - promo) / normalPrice * 100).rounded())
    }

    private var isPromotionCurrentlyActive: Bool {
        guard promotionEnabled, promotionalPrice != nil, isPromotionDateRangeValid else { return false }
        let now = Date()
        return now >= promotionStartDate && now <= promotionEndDate
    }

    private var isSaveEnabled: Bool {
        guard !colorName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard !size.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard normalPrice > 0 else { return false }
        if promotionEnabled && promotionalPrice != nil {
            return isPromotionDateRangeValid
        }
        return true
    }

    private var combinedImages: [MarketplaceVariantImage] {
        existingImageURLs.map { .remote($0) } + selectedImageData.map { .local($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VariantTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        colorSection
                        sizeSection
                        stockSection
                        priceSection
                        imagesSection
                        advancedSection

                        if isEditMode, onDelete != nil {
                            deleteButton
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(isEditMode ? "Modifier la variante" : "Nouvelle variante")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(VariantTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundStyle(VariantTheme.secondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveDraft()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(isSaveEnabled ? Color(hex: "EC4899") : VariantTheme.secondaryText)
                    .disabled(!isSaveEnabled)
                }
            }
            .confirmationDialog(
                "Supprimer cette variante ?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("Annuler", role: .cancel) {}
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Save

    private func saveDraft() {
        var draft = existingVariant ?? MarketplaceVariantEditorDraft()
        draft.colorName = colorName.trimmingCharacters(in: .whitespaces)
        draft.colorHex = colorHex
        draft.size = size.trimmingCharacters(in: .whitespaces)
        draft.stock = stock
        draft.normalPrice = normalPrice
        draft.promotionalPrice = promotionEnabled ? promotionalPrice : nil
        draft.promotionEnabled = promotionEnabled
        draft.promotionStartDate = promotionStartDate
        draft.promotionEndDate = promotionEndDate
        draft.sku = sku.trimmingCharacters(in: .whitespaces)
        draft.barcode = barcode.trimmingCharacters(in: .whitespaces)
        draft.material = material.trimmingCharacters(in: .whitespaces)
        draft.model = model.trimmingCharacters(in: .whitespaces)
        draft.privateNote = privateNote
        draft.existingImageURLs = existingImageURLs
        draft.selectedImageData = selectedImageData
        onSave(draft)
        dismiss()
    }

    // MARK: - Color section

    private var filteredColors: [MarketplaceColorOption] {
        guard !colorSearchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return marketplaceColorPalette
        }
        return marketplaceColorPalette.filter {
            $0.name.localizedCaseInsensitiveContains(colorSearchText)
        }
    }

    private var colorSection: some View {
        MarketplaceSectionCard(title: "Couleur", systemImage: "paintpalette.fill") {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Nom de la couleur", text: $colorName)
                        .textFieldStyle(.plain)
                        .foregroundStyle(VariantTheme.primaryText)
                        .font(.system(size: 16, weight: .medium))

                    TextField("Code hex (ex: FF0000)", text: $colorHex)
                        .textFieldStyle(.plain)
                        .foregroundStyle(VariantTheme.secondaryText)
                        .font(.system(size: 13))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))

            MarketplaceSearchField(placeholder: "Rechercher une couleur", text: $colorSearchText)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 12)], spacing: 12) {
                ForEach(filteredColors) { option in
                    MarketplaceColorSwatch(
                        option: option,
                        isSelected: option.hex.uppercased() == colorHex.uppercased()
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            colorHex = option.hex
                            if colorName.isEmpty {
                                colorName = option.name
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Size section

    private var sizeSection: some View {
        MarketplaceSectionCard(title: "Taille", systemImage: "ruler.fill") {
            TextField("Taille (ex: M, 42...)", text: $size)
                .textFieldStyle(.plain)
                .foregroundStyle(VariantTheme.primaryText)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 10)], spacing: 10) {
                ForEach(marketplaceQuickSizes, id: \.self) { quickSize in
                    MarketplaceChip(
                        label: quickSize,
                        isSelected: size.uppercased() == quickSize.uppercased()
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            size = quickSize
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stock section

    private var stockSection: some View {
        MarketplaceSectionCard(title: "Stock", systemImage: "shippingbox.fill") {
            HStack(spacing: 16) {
                Button {
                    if stock > 0 { stock -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }

                Text("\(stock)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(VariantTheme.primaryText)
                    .frame(minWidth: 60)

                Button {
                    stock += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(VariantTheme.gradient))
                }

                Spacer()

                MarketplaceStatusBadge(isAvailable: stock > 0)
            }
        }
    }

    // MARK: - Price + promotion section

    private var priceSection: some View {
        MarketplaceSectionCard(title: "Prix & Promotion", systemImage: "tag.fill") {
            HStack(spacing: 12) {
                MarketplaceLabeledField(label: "Prix normal", text: $normalPriceText, keyboard: .decimalPad, suffix: "€")
            }

            Toggle(isOn: $promotionEnabled.animation(.easeInOut(duration: 0.2))) {
                Text("Promotion active")
                    .foregroundStyle(VariantTheme.primaryText)
                    .font(.system(size: 15, weight: .medium))
            }
            .tint(Color(hex: "EC4899"))
            .padding(.top, 4)

            if promotionEnabled {
                MarketplaceLabeledField(label: "Prix promotionnel", text: $promotionalPriceText, keyboard: .decimalPad, suffix: "€")

                VStack(spacing: 10) {
                    DatePicker("Début promotion", selection: $promotionStartDate, displayedComponents: .date)
                        .foregroundStyle(VariantTheme.primaryText)
                    DatePicker("Fin promotion", selection: $promotionEndDate, displayedComponents: .date)
                        .foregroundStyle(VariantTheme.primaryText)
                }
                .tint(Color(hex: "8B5CF6"))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))

                if !isPromotionDateRangeValid {
                    Label("La date de fin doit être postérieure à la date de début", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(VariantTheme.danger)
                } else {
                    HStack {
                        if discountPercent > 0 {
                            Text("-\(discountPercent)%")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 8).fill(VariantTheme.danger))
                        }

                        Text(isPromotionCurrentlyActive ? "Promotion active aujourd'hui" : "Promotion programmée")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(isPromotionCurrentlyActive ? VariantTheme.success : VariantTheme.secondaryText)
                    }
                }
            }
        }
    }

    // MARK: - Images section

    private var imagesSection: some View {
        MarketplaceSectionCard(title: "Photos de la variante", systemImage: "photo.on.rectangle.angled") {
            PhotosPicker(
                selection: $photoPickerItems,
                maxSelectionCount: 8,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Ajouter des photos")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(VariantTheme.gradient))
            }
            .onChange(of: photoPickerItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            selectedImageData.append(data)
                        }
                    }
                    photoPickerItems = []
                }
            }

            if combinedImages.isEmpty {
                Text("Aucune photo ajoutée pour cette variante")
                    .font(.system(size: 13))
                    .foregroundStyle(VariantTheme.secondaryText)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(combinedImages) { image in
                            MarketplaceImageThumbnail(image: image) {
                                removeImage(image)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func removeImage(_ image: MarketplaceVariantImage) {
        switch image {
        case .remote(let url):
            existingImageURLs.removeAll { $0 == url }
        case .local(let data):
            selectedImageData.removeAll { $0 == data }
        }
    }

    // MARK: - Advanced section

    private var advancedSection: some View {
        MarketplaceSectionCard(title: "Informations avancées", systemImage: "info.circle.fill") {
            MarketplaceLabeledField(label: "SKU", text: $sku, keyboard: .default)
            MarketplaceLabeledField(label: "Code-barres", text: $barcode, keyboard: .default)
            MarketplaceLabeledField(label: "Matière", text: $material, keyboard: .default)
            MarketplaceLabeledField(label: "Modèle", text: $model, keyboard: .default)

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes vendeur privées")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(VariantTheme.secondaryText)

                TextEditor(text: $privateNote)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(VariantTheme.primaryText)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
            }
        }
    }

    // MARK: - Delete button

    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("Supprimer la variante")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(VariantTheme.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(VariantTheme.danger.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(VariantTheme.danger.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Private components

private struct MarketplaceSectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(Color(hex: "EC4899"))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(VariantTheme.primaryText)
            }

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(VariantTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(VariantTheme.cardStroke, lineWidth: 1)
                )
        )
    }
}

private struct MarketplaceSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(VariantTheme.secondaryText)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .foregroundStyle(VariantTheme.primaryText)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(VariantTheme.secondaryText)
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
    }
}

private struct MarketplaceColorSwatch: View {
    let option: MarketplaceColorOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: option.hex))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color(hex: "EC4899") : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                    )
                    .overlay(
                        Group {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(option.hex.uppercased() == "F5F5F5" ? .black : .white)
                            }
                        }
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

private struct MarketplaceChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : VariantTheme.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            Capsule().fill(VariantTheme.gradient)
                        } else {
                            Capsule().fill(Color.white.opacity(0.05))
                        }
                    }
                )
                .overlay(
                    Capsule().stroke(isSelected ? .clear : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct MarketplaceStatusBadge: View {
    let isAvailable: Bool

    var body: some View {
        Text(isAvailable ? "Disponible" : "Épuisé")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isAvailable ? VariantTheme.success.opacity(0.85) : VariantTheme.danger.opacity(0.85))
            )
    }
}

private struct MarketplaceLabeledField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var suffix: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(VariantTheme.secondaryText)

            HStack {
                TextField("", text: $text)
                    .keyboardType(keyboard)
                    .textFieldStyle(.plain)
                    .foregroundStyle(VariantTheme.primaryText)

                if let suffix {
                    Text(suffix)
                        .foregroundStyle(VariantTheme.secondaryText)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
        }
    }
}

private struct MarketplaceImageThumbnail: View {
    let image: MarketplaceVariantImage
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch image {
                case .remote(let urlString):
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            case .failure:
                                Color.white.opacity(0.05)
                            default:
                                ProgressView()
                            }
                        }
                    } else {
                        Color.white.opacity(0.05)
                    }
                case .local(let data):
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.white.opacity(0.05)
                    }
                }
            }
            .frame(width: 84, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1)
            )

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white, VariantTheme.danger)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Previews

#Preview("Création") {
    MarketplaceVariantEditorView(
        baseProductPrice: 29.99,
        existingVariant: nil,
        onSave: { _ in },
        onDelete: nil
    )
}

#Preview("Édition") {
    MarketplaceVariantEditorView(
        baseProductPrice: 29.99,
        existingVariant: MarketplaceVariantEditorDraft(
            colorName: "Noir",
            colorHex: "1A1A1A",
            size: "M",
            normalPrice: 29.99,
            promotionalPrice: 19.99,
            promotionEnabled: true,
            promotionStartDate: Date().addingTimeInterval(-86_400),
            promotionEndDate: Date().addingTimeInterval(86_400 * 5),
            stock: 8,
            sku: "CUT-BLK-M-001",
            barcode: "3701234567890",
            material: "100% coton",
            model: "T-shirt Premium",
            privateNote: "Fournisseur habituel, réassort rapide.",
            existingImageURLs: [],
            selectedImageData: []
        ),
        onSave: { _ in },
        onDelete: {}
    )
}

