import SwiftUI

struct ExpertStudioView: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {

                    // HEADER
                    VStack(spacing: 8) {
                        Text("Mode Expert")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Ton espace créateur")
                            .foregroundColor(.gray)
                    }
                    .padding(.top)

                    // STAT RAPIDE
                    HStack(spacing: 12) {
                        StatCard(title: "Vues", value: "0")
                        StatCard(title: "Likes", value: "0")
                        StatCard(title: "Revenus", value: "0€")
                    }

                    // ACTIONS PRINCIPALES
                    VStack(spacing: 14) {
                        
                        NavigationLink(destination: ExpertFeedView()) {
                            StudioButton(icon: "play.rectangle.fill",
                                         title: "Explorer le feed",
                                         color: .purple)
                        }
                        
                        NavigationLink(destination: UploadContentView()) {
                            StudioButton(icon: "plus.app.fill",
                                         title: "Publier",
                                         color: .blue)
                        }
                        
                        NavigationLink(destination: MonetizationView()) {
                            StudioButton(icon: "eurosign.circle.fill",
                                         title: "Monétisation",
                                         color: .green)
                        }
                        
                        NavigationLink(destination: LiveStreamView()) {
                            StudioButton(icon: "dot.radiowaves.left.and.right",
                                         title: "Lancer un live",
                                         color: .red)
                        }
                        
                        NavigationLink(destination: ShopManagerView()) {
                            StudioButton(icon: "bag.fill",
                                         title: "Ma boutique",
                                         color: .orange)
                        }
                        
                        NavigationLink(destination: ShopManagerView()) {
                            StudioButton(icon: "chart.line.uptrend.xyaxis",
                                         title: "Données Analytiques",
                                         color: .yellow)
                        }
                        
                        NavigationLink(destination: AnalyticsRootView()) {
                            StudioButton(
                                icon: "chart.bar.fill",
                                title: "Statistiques",
                                color: .pink
                            )
                        }
                    }
                    .padding(.top, 10)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color.black.opacity(0.05))
        }
    }
}
