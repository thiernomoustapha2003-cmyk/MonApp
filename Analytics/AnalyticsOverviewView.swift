import SwiftUI
import Charts
import FirebaseFirestore

struct DailyViewData: Identifiable {
    let id = UUID()
    let date: String
    let views: Int
}

struct AnalyticsOverviewView: View {
    
    @State private var startDate = Date()
    @State private var endDate = Date()

    @State private var showCustomPicker = false
    @State private var appliedStartDate = Date()
    @State private var appliedEndDate = Date()
    
    @State private var selectedPeriod: AnalyticsPeriod = .twentyEight
    @StateObject var viewModel = AnalyticsViewModel()
    @StateObject var engine = AnalyticsEngine()
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 24) {
                
                // =========================
                // SÉLECTEUR DE PÉRIODE
                // =========================
                
                AnalyticsPeriodSelector(selectedPeriod: $selectedPeriod)
                
                    .onChange(of: selectedPeriod) { value in
                        if value == .custom {
                            showCustomPicker = true
                        }
                    }
                // =========================
                // INDICATEURS CLÉS
                // =========================
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    HStack {
                        Text("Indicateurs clés")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 16) {
                        
                        AnalyticsMetricCard(
                            title: "Vues de publication",
                            value: "\(viewModel.totalViews)",
                            variation: "",
                            isPositive: true
                        )
                        
                        AnalyticsMetricCard(
                            title: "Vues du profil",
                            value: "\(viewModel.profileViews)",
                            variation: "",
                            isPositive: true
                        )
                        
                        AnalyticsMetricCard(
                            title: "Likes",
                            value: "\(viewModel.totalLikes)",
                            variation: "",
                            isPositive: true
                        )
                        
                        AnalyticsMetricCard(
                            title: "Commentaires",
                            value: "\(viewModel.totalComments)",
                            variation: "",
                            isPositive: true
                        )
                        
                        AnalyticsMetricCard(
                            title: "Partages",
                            value: "\(viewModel.totalShares)",
                            variation: "",
                            isPositive: true
                        )
                        
                    }
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.2))
                .cornerRadius(16)
                
                
                // =========================
                // GRAPHIQUE VUES
                // =========================
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text("Vues")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Chart(viewModel.dailyViews) { item in
                        
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Vues", item.views)
                        )
                        
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Vues", item.views)
                        )
                        .opacity(0.3)
                        
                    }
                    .frame(height: 200)
                    
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.2))
                .cornerRadius(16)
                
                
                // =========================
                // SOURCES DE TRAFIC
                // =========================
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text("Sources de trafic")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    TrafficRow(title: "Pour toi", value: viewModel.forYou)
                    TrafficRow(title: "Profil personnel", value: viewModel.profile)
                    TrafficRow(title: "Recherche", value: viewModel.search)
                    TrafficRow(title: "Son", value: viewModel.sound)
                    TrafficRow(title: "Suivi(e)s", value: viewModel.following)
                    
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.2))
                .cornerRadius(16)
                
                
                // =========================
                // ANALYSE SPECTATEURS
                // =========================
                
                AnalyticsAudienceCharts(engine: engine)
                
                
                // =========================
                // CROISSANCE FOLLOWERS
                // =========================

                FollowersAnalyticsView()
                
                
                // =========================
                // TOP VIDÉOS
                // =========================
                
                AnalyticsTopVideosView(engine: engine)
                
                
                // =========================
                // TRAFIC AVANCÉ
                // =========================
                
                AnalyticsTrafficSources(engine: engine)
                
            }
            .padding()
            
        }
        .sheet(isPresented: $showCustomPicker) {

            VStack(spacing: 20) {

                Text("Période personnalisée")
                    .font(.title3)

                DatePicker(
                    "Date début",
                    selection: $startDate,
                    displayedComponents: .date
                )

                DatePicker(
                    "Date fin",
                    selection: $endDate,
                    displayedComponents: .date
                )

                Button("Appliquer") {

                    appliedStartDate = startDate
                    appliedEndDate = endDate

                    viewModel.loadAnalytics(
                        startDate: appliedStartDate,
                        endDate: appliedEndDate
                    )

                    showCustomPicker = false
                }

            }
            .padding()
        }
        .background(Color.black)
        .onAppear {
            viewModel.loadAnalytics()
            viewModel.loadFollowersAnalytics()
        
            engine.loadDailyViews()
            engine.loadHourlyAudience()
            engine.loadTrafficSources()
            engine.loadFollowersGrowth()
            engine.loadTopVideos()

        }
    }
}
