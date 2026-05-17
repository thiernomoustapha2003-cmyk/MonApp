import SwiftUI
import Charts

enum FollowersPeriod: String, CaseIterable, Identifiable {

    case seven = "7 jours"
    case twentyEight = "28 jours"
    case sixty = "60 jours"
    case year = "365 jours"
    case custom = "Personnalisé"

    var id: String { rawValue }
}

enum AudienceTab: String, CaseIterable, Identifiable {
    
    case gender = "Sexe"
    case age = "Âge"
    case location = "Emplacements"
    
    var id: String { rawValue }
}

struct FollowersAnalyticsView: View {
    
    @StateObject var viewModel = FollowersAnalyticsViewModel()
    
    @State private var selectedPeriod: FollowersPeriod = .seven
    @State private var selectedAudienceTab: AudienceTab = .gender
    
    @State private var selectedDate: Date?
    @State private var selectedValue: Int?
    
    @State private var selectedActivityDay = Date()
    
    
    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading, spacing: 24) {
                
                // SELECTEUR PERIODE
                FollowersPeriodSelector(selectedPeriod: $selectedPeriod)
                
                
                // CARDS METRICS
                FollowersMetricsSection(viewModel: viewModel)
                
                
                // GRAPH FOLLOWERS
                
                VStack(alignment: .leading, spacing: 12) {
                    
                    if viewModel.followersHistory.isEmpty {
                        
                        Text("Chargement des données...")
                            .foregroundColor(.gray)
                        
                    } else {
                        
                        FollowersGrowthChart(
                            viewModel: viewModel,
                            selectedDate: $selectedDate,
                            selectedValue: $selectedValue
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 500) // graph plus compact
                        .clipped() // empêche tout débordement
                        .padding(.horizontal, 2)
                    }
                }
                
                
                // SECTION AUDIENCE
                
                FollowersAudienceSection(
                    selectedAudienceTab: $selectedAudienceTab,
                    selectedActivityDay: $selectedActivityDay,
                    viewModel: viewModel
                )
                
                
                Spacer(minLength: 40)
                
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .onAppear {
            
            print("FollowersAnalyticsView loaded")
            
            viewModel.loadFollowersAnalytics()
        }
    }
}
