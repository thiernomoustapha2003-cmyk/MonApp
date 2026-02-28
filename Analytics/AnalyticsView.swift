import SwiftUI
import Charts

struct AnalyticsView: View {
    
    let postId: String
   
    
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var dailyStats = AnalyticsDataService.shared.getDailyViews()
    @State private var countryStats = AnalyticsDataService.shared.getCountryStats()
    @State private var audienceStats = AnalyticsDataService.shared.getAudienceStats()
    
    var totalViews: Int {
        dailyStats.reduce(0) { $0 + $1.views }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // MARK: - INDICATEURS CLÉS
                    
                    Text("Indicateurs clés")
                        .font(.title2)
                        .bold()
                    
                    KeyMetricCard(title: "Vues totales", value: "\(totalViews)", color: .blue)
                    
                    KeyMetricCard(title: "Followers", value: "\(audienceStats.followersPercentage)%", color: .purple)
                    
                    KeyMetricCard(title: "Non-followers", value: "\(audienceStats.nonFollowersPercentage)%", color: .gray)
                    
                    // MARK: - GRAPHIQUE VUES
                    
                    Text("Évolution des vues (30 jours)")
                        .font(.headline)
                    
                    Chart(dailyStats) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Views", item.views)
                        )
                    }
                    .frame(height: 250)
                    
                    // MARK: - PAYS DU MONDE
                    
                    Text("Pays qui vous regardent")
                        .font(.headline)
                    
                    ForEach(countryStats) { country in
                        HStack {
                            Text(country.country) // Accéder à la propriété `country` de l'élément individuel
                            Spacer()
                            Text("\(country.percentage, specifier: "%.1f")%")
                        }
                        Divider()
                    }
                            .onAppear {
                                viewModel.fetchAnalytics(for: postId)
                            }
                    
                    
                    // MARK: - GENRE
                    
                    Text("Audience (Genre)")
                        .font(.headline)
                    
                    KeyMetricCard(title: "Femmes", value: "\(audienceStats.femalePercentage)%", color: .pink)
                    
                    KeyMetricCard(title: "Hommes", value: "\(audienceStats.malePercentage)%", color: .blue)
                }
                .padding()
            }
            .navigationTitle("Données Analytiques")
        }
    }
}

// MARK: - CARD UI

struct KeyMetricCard: View {
    
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title)
                    .bold()
            }
            
            Spacer()
            
            Circle()
                .fill(color)
                .frame(width: 18, height: 18)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
