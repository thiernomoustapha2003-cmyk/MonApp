//
//  MarketplaceGalleryView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI
import AVKit
import Kingfisher



struct MarketplaceGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let mediaItems: [MarketplaceProductMedia]

    @State private var selectedIndex: Int
    @State private var showControls = true
    @State private var animateIn = false

    init(
        mediaItems: [MarketplaceProductMedia] = MarketplaceGalleryPreviewData.items,
        selectedIndex: Int = 0
    ) {
        self.mediaItems = mediaItems
        self._selectedIndex = State(initialValue: selectedIndex)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(Array(mediaItems.enumerated()), id: \.element.id) { index, item in
                    MarketplaceGalleryMediaPage(item: item)
                        .tag(index)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                showControls.toggle()
                            }
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .opacity(animateIn ? 1 : 0)
            .scaleEffect(animateIn ? 1 : 0.96)

            if showControls {
                galleryTopBar
                galleryBottomBar
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                animateIn = true
            }
        }
    }

    private var galleryTopBar: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.14))
                        .clipShape(Circle())
                }

                Spacer()

                Text("\(selectedIndex + 1) / \(mediaItems.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.14))
                    .clipShape(Capsule())

                Spacer()

                Button {
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.14))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer()
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var galleryBottomBar: some View {
        VStack {
            Spacer()

            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentMediaTitle)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)

                        Text(currentMediaSubtitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        MarketplaceGalleryActionButton(icon: "square.and.arrow.up", title: "Partager")
                        MarketplaceGalleryActionButton(icon: "arrow.down.circle", title: "Télécharger")
                        MarketplaceGalleryActionButton(icon: "heart", title: "Favori")
                        MarketplaceGalleryActionButton(icon: "exclamationmark.triangle", title: "Signaler")
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(mediaItems.enumerated()), id: \.element.id) { index, item in
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    selectedIndex = index
                                }
                            } label: {
                                MarketplaceGalleryThumbnail(
                                    item: item,
                                    isSelected: selectedIndex == index
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var currentMediaTitle: String {
        switch mediaItems[safe: selectedIndex]?.type {
        case .video: return "Vidéo produit"
        case .threeSixty: return "Vue 360°"
        case .thumbnail: return "Miniature"
        default: return "Photo HD"
        }
    }

    private var currentMediaSubtitle: String {
        "Touchez l’image pour masquer ou afficher les contrôles"
    }
}

// MARK: - Media Page

private struct MarketplaceGalleryMediaPage: View {
    let item: MarketplaceProductMedia

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            if item.type == .video {

                MarketplaceGalleryVideoPlaceholder()

            } else if item.type == .threeSixty {

                MarketplaceGallery360Placeholder()

            } else {
                MarketplaceGalleryRemoteImage(
                    item: item,
                    scale: scale,
                    offset: offset,
                    iconName: iconName,
                    title: title
                )
                .scaleEffect(scale)
                .offset(offset)
                .gesture(dragGesture)
                .simultaneousGesture(magnificationGesture)
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        if scale > 1 {
                            resetZoom()
                        } else {
                            scale = 2.25
                        }
                    }
                }
            }
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                scale = min(max(newScale, 1), 4)
            }
            .onEnded { _ in
                lastScale = scale

                if scale <= 1.02 {
                    resetZoom()
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }

                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                guard scale > 1 else {
                    offset = .zero
                    lastOffset = .zero
                    return
                }

                lastOffset = offset
            }
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }

    private var iconName: String {
        switch item.type {
        case .image: return "photo.fill"
        case .video: return "play.rectangle.fill"
        case .threeSixty: return "rotate.3d"
        case .thumbnail: return "photo"
        }
    }

    private var title: String {
        switch item.type {
        case .image: return "Photo HD"
        case .video: return "Vidéo produit"
        case .threeSixty: return "Vue 360°"
        case .thumbnail: return "Miniature"
        }
    }
}

// MARK: - Thumbnail

private struct MarketplaceGalleryThumbnail: View {
    let item: MarketplaceProductMedia
    let isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isSelected ? AnyShapeStyle(MarketplaceUITheme.primaryGradient) : AnyShapeStyle(.white.opacity(0.12)))
            .frame(width: 64, height: 64)
            .overlay(
                Image(systemName: thumbnailIcon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.12), lineWidth: 2)
            )
    }

    private var thumbnailIcon: String {
        switch item.type {
        case .image: return "photo"
        case .video: return "play.fill"
        case .threeSixty: return "rotate.3d"
        case .thumbnail: return "photo.fill"
        }
    }
}

// MARK: - Action Button

private struct MarketplaceGalleryActionButton: View {
    let icon: String
    let title: String

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                isPressed.toggle()
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .black))

                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(width: 54, height: 48)
            .background(.white.opacity(isPressed ? 0.24 : 0.14))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(isPressed ? 0.96 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview Data

enum MarketplaceGalleryPreviewData {
    static let items: [MarketplaceProductMedia] = [
        .init(url: "", type: .image, position: 0, isMain: true),
        .init(url: "", type: .video, position: 1),
        .init(url: "", type: .threeSixty, position: 2),
        .init(url: "", type: .image, position: 3),
        .init(url: "", type: .image, position: 4)
    ]
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
private struct MarketplaceGalleryVideoPlaceholder: View {
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(MarketplaceUITheme.primaryGradient)
                    .frame(width: 92, height: 92)
                    .shadow(color: .black.opacity(0.30), radius: 24, x: 0, y: 14)

                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(.white)
                    .offset(x: isPlaying ? 0 : 3)
            }

            Text(isPlaying ? "Lecture vidéo" : "Vidéo produit")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)

            Text("Lecteur premium prêt. On branchera les vraies vidéos Firebase Storage ensuite.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isPlaying.toggle()
                }
            } label: {
                Label(isPlaying ? "Mettre en pause" : "Lire la vidéo", systemImage: isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(MarketplacePremiumButtonStyle(isFullWidth: false))
        }
    }
}
private struct MarketplaceGallery360Placeholder: View {

    @State private var rotation: Double = 0
    @State private var autoRotate = true

    var body: some View {

        VStack(spacing: 24) {

            ZStack {

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 260, height: 260)

                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 90, weight: .black))
                    .foregroundStyle(.white)
                    .rotation3DEffect(
                        .degrees(rotation),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }

            Text("Vue 360°")
                .font(.system(.title2, design: .rounded).weight(.black))
                .foregroundStyle(.white)

            Text("Le produit pourra être tourné librement avec le doigt. Les vraies images 360° seront chargées depuis Firebase Storage.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.60))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 34)

            HStack(spacing: 14) {

                Button {

                    withAnimation(.linear(duration: 1)) {
                        rotation -= 45
                    }

                } label: {

                    Label("←", systemImage: "rotate.left.fill")

                }
                .buttonStyle(MarketplacePremiumButtonStyle(isFullWidth: false))

                Button {

                    autoRotate.toggle()

                } label: {

                    Label(
                        autoRotate ? "Pause rotation" : "Rotation auto",
                        systemImage: autoRotate ? "pause.fill" : "play.fill"
                    )

                }
                .buttonStyle(MarketplacePremiumButtonStyle(isFullWidth: false))

                Button {

                    withAnimation(.linear(duration: 1)) {
                        rotation += 45
                    }

                } label: {

                    Label("→", systemImage: "rotate.right.fill")

                }
                .buttonStyle(MarketplacePremiumButtonStyle(isFullWidth: false))
            }
        }
        .onAppear {

            guard autoRotate else { return }

            withAnimation(
                .linear(duration: 18)
                .repeatForever(autoreverses: false)
            ) {

                rotation = 360

            }
        }
    }
}
private struct MarketplaceGalleryRemoteImage: View {
    let item: MarketplaceProductMedia
    let scale: CGFloat
    let offset: CGSize
    let iconName: String
    let title: String

    var body: some View {
        Group {
            if let url = URL(string: item.url), !item.url.isEmpty {
                KFImage(url)
                    .placeholder {
                        MarketplaceGalleryLoadingPlaceholder(iconName: iconName, title: title)
                    }
                    .resizable()
                    .cacheMemoryOnly(false)
                    .fade(duration: 0.22)
                    .scaledToFit()
                    .padding(.horizontal, 10)
            } else {
                MarketplaceGalleryLoadingPlaceholder(iconName: iconName, title: title)
            }
        }
    }
}

private struct MarketplaceGalleryLoadingPlaceholder: View {
    let iconName: String
    let title: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: iconName)
                .font(.system(size: 92, weight: .black))
                .foregroundStyle(.white.opacity(0.92))

            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white.opacity(0.9))

            Text("Image Firebase Storage prête • cache et préchargement activables")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
}



#Preview {
    MarketplaceGalleryView()
}
