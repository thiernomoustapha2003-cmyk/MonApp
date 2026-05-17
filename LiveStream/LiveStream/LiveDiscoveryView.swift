//
//  LiveDiscoveryView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 16/05/2026.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

struct LiveDiscoveryView: View {
    
    @StateObject private var viewModel = LiveDiscoveryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Chargement des lives...")
                    .foregroundColor(.white)
            } else if viewModel.lives.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Aucun live actif")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("Reviens bientôt pour découvrir les coiffeurs en direct.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                TabView {
                    ForEach(viewModel.lives) { live in
                        LivePreviewPage(live: live)
                            .ignoresSafeArea()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .rotationEffect(.degrees(90))
                .ignoresSafeArea()
            }
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("CUTLY LIVE")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .onAppear {
            viewModel.listenLives()
        }
    }
}

// MARK: - PAGE LIVE STYLE TIKTOK

struct LivePreviewPage: View {
    
    let live: LivePreviewModel
    @State private var goToLive = false
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                colors: [
                    Color.black,
                    Color.red.opacity(0.65),
                    Color.purple.opacity(0.55),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 18) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.25))
                        .frame(width: 150, height: 150)
                        .blur(radius: 12)
                    
                    AsyncImage(url: URL(string: live.creatorImageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .frame(width: 115, height: 115)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.9), lineWidth: 3)
                    )
                }
                
                HStack(spacing: 8) {
                    Text("LIVE")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    
                    Text("\(live.viewersCount) spectateurs")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Text(live.creatorName)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                
                Text(live.title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                
                Button {
                    goToLive = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Entrer dans le live")
                            .bold()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(28)
                    .padding(.horizontal, 32)
                }
                .padding(.top, 12)
                
                Spacer()
            }
            
            VStack {
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("✂️ Coiffure en direct")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Like, commente, partage et envoie des cadeaux.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 18) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.title2)
                        
                        Image(systemName: "gift.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        
                        Image(systemName: "arrowshape.turn.up.right.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 35)
            }
        }
        .rotationEffect(.degrees(-90))
        .fullScreenCover(isPresented: $goToLive) {
            LiveViewerView(live: live)
        }
    }
}

// MARK: - VUE SPECTATEUR



// MARK: - MODEL

struct LivePreviewModel: Identifiable {
    let id: String
    let creatorId: String
    let creatorName: String
    let creatorImageUrl: String
    let title: String
    let viewersCount: Int
    let isLive: Bool
}

// MARK: - VIEWMODEL

final class LiveDiscoveryViewModel: ObservableObject {
    
    @Published var lives: [LivePreviewModel] = []
    @Published var isLoading = true
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func listenLives() {
        listener?.remove()
        isLoading = true
        
        listener = db.collection("lives")
            .whereField("isLive", isEqualTo: true)
            .addSnapshotListener { snapshot, error in
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                
                if let error = error {
                    print("❌ Erreur chargement lives:", error.localizedDescription)
                    return
                }
                
                let items = snapshot?.documents.map { doc -> LivePreviewModel in
                    let data = doc.data()
                    
                    return LivePreviewModel(
                        id: doc.documentID,
                        creatorId: data["creatorId"] as? String ?? "",
                        creatorName: data["creatorName"] as? String ?? "Créateur",
                        creatorImageUrl: data["creatorImageUrl"] as? String ?? "",
                        title: data["title"] as? String ?? "Live coiffure en direct",
                        viewersCount: data["viewersCount"] as? Int ?? 0,
                        isLive: data["isLive"] as? Bool ?? false
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self.lives = items
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
}
