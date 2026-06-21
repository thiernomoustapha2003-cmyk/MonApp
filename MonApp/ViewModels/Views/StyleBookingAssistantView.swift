//
//  StyleBookingAssistantView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 20/06/2026.
//

import SwiftUI

struct StyleBookingAssistantView: View {

    let imageUrl: String
    var preferredStyleId: String? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var styles: [Style] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Recherche du style...")
                            .foregroundColor(.gray)
                    }

                } else if styles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))

                        Text("Aucun style trouvé")
                            .font(.headline)

                        Text("Ce style n’est pas encore disponible à la réservation.")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(styles) { style in
                                StyleCardView(style: style)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Réserver ce style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadStyles()
        }
    }

    func loadStyles() {
        isLoading = true

        StylesService.shared.loadStyles { result in
            DispatchQueue.main.async {
                if let preferredStyleId = preferredStyleId,
                   !preferredStyleId.isEmpty {
                    self.styles = result.filter { $0.id == preferredStyleId }
                } else {
                    self.styles = result
                }

                self.isLoading = false
            }
        }
    }
}
