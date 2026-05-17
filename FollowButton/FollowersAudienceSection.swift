import SwiftUI

struct FollowersAudienceSection: View {
    
    @Binding var selectedAudienceTab: AudienceTab
    @Binding var selectedActivityDay: Date
    
    var viewModel: FollowersAnalyticsViewModel
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            
            Divider()
                .padding(.vertical, 8)
            
            
            Text("Données relatives aux followers")
                .font(.headline)
            
            
            // TABS
            
            ScrollView(.horizontal, showsIndicators: false) {
                
                HStack(spacing: 10) {
                    
                    ForEach(AudienceTab.allCases) { tab in
                        
                        AudienceTabButton(
                            tab: tab,
                            selectedAudienceTab: $selectedAudienceTab
                        )
                    }
                }
            }
            
            
            // CONTENU SELON LE TAB
            
            Group {
                
                if selectedAudienceTab == .gender {
                    
                    GenderChartView(
                        viewModel: viewModel
                    )
                }
                
                else if selectedAudienceTab == .age {
                    
                    AgeChartView(
                        ageStats: viewModel.ageStats
                    )
                }
                
                else if selectedAudienceTab == .location {

                    VStack(spacing: 16) {

                        // 🌍 Carte avec les pays Firestore
                        CountryMapView(
                            countryStats: viewModel.countryStats
                        )

                        // 📊 Liste des pays
                        CountryListView(
                            countryStats: viewModel.countryStats
                        )
                    }
                }
                
            }
            .padding(.top, 8)
            .animation(.easeInOut(duration: 0.25), value: selectedAudienceTab)
            
            
            // HEURES D'ACTIVITÉ
            
            FollowersActivityHours(
                selectedActivityDay: $selectedActivityDay,
                viewModel: viewModel
            )
            .padding(.top, 12)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
