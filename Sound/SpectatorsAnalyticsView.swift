import SwiftUI
import Charts
import AVFoundation


struct SpectatorsAnalyticsView: View {
    
    @StateObject var viewModel = AnalyticsViewModel()
    
    @State private var selectedRange = "7J"
    @State private var showDatePicker = false
    
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var audienceTab = "sexe"
    
    
    
    
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 28) {
                
                // ===============================
                // INDICATEURS CLÉS
                // ===============================
                
                VStack(alignment: .leading, spacing: 6) {
                    
                    HStack {
                        
                        Text("Indicateurs clés")
                            .font(.system(size: 18, weight: .bold))
                        
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    
                    Text(viewModel.currentRangeText)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                }
                
                HStack(spacing: 16) {
                    
                    SpectatorMetricCard(
                        title: "Total des spectateurs",
                        value: "\(viewModel.totalSpectators)",
                        change: -208000,
                        percentage: -40.6,
                        isActive: true
                    )
                    
                    SpectatorMetricCard(
                        title: "Nouveaux spectateurs",
                        value: "\(viewModel.newSpectators)",
                        change: -217000,
                        percentage: -68.4,
                        isActive: false
                    )
                }
                
                
                
                // ===============================
                // BOUTONS PÉRIODE (TikTok)
                // ===============================
                
                VStack(spacing: 12) {
                    
                    Text("Période")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        
                        HStack(spacing: 12) {
                            
                            RangeButton(title: "7J", selected: selectedRange == "7J") {
                                selectedRange = "7J"
                                viewModel.updateRange("7J")
                            }
                            
                            RangeButton(title: "28J", selected: selectedRange == "28J") {
                                selectedRange = "28J"
                                viewModel.updateRange("28J")
                            }
                            
                            RangeButton(title: "60J", selected: selectedRange == "60J") {
                                selectedRange = "60J"
                                viewModel.updateRange("60J")
                            }
                            
                            RangeButton(title: "365J", selected: selectedRange == "365J") {
                                selectedRange = "365J"
                                viewModel.updateRange("365J")
                            }
                            
                            RangeButton(title: "Personnaliser", selected: selectedRange == "custom") {
                                selectedRange = "custom"
                                showDatePicker = true
                            }
                            
                        }
                        .padding(.horizontal)
                    }
                    
                }
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                // ===============================
                // GRAPHIQUE
                // ===============================
                
                Chart(viewModel.spectatorsChart) { item in
                    
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Spectateurs", item.value)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol(Circle())
                    .symbolSize(40)
                    
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Spectateurs", item.value)
                    )
                    
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.35), Color.blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                }
                .chartXAxis {
                    AxisMarks {
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.35))
                        AxisTick()
                            .foregroundStyle(Color.gray)
                        AxisValueLabel()
                            .foregroundStyle(Color.black)
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .chartYAxis {
                    AxisMarks {
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.35))
                        AxisTick()
                            .foregroundStyle(Color.gray)
                        AxisValueLabel()
                            .foregroundStyle(Color.black)
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .frame(height: 220)
            }
            
            
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            
            /// ===============================
            // DONNÉES DES SPECTATEURS
            // ===============================
            
            VStack(alignment: .leading, spacing: 18) {
                
                // TITRE
                HStack {
                    
                    Text("Données des spectateurs")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                }
                
                // BOUTONS FILTRE (comme TikTok)
                HStack(spacing: 10) {
                    
                    AudienceFilterButton(
                        title: "Sexe",
                        selected: audienceTab == "sexe"
                    ) {
                        audienceTab = "sexe"
                    }
                    
                    AudienceFilterButton(
                        title: "Âge",
                        selected: audienceTab == "age"
                    ) {
                        audienceTab = "age"
                    }
                    
                    AudienceFilterButton(
                        title: "Emplacements",
                        selected: audienceTab == "location"
                    ) {
                        audienceTab = "location"
                    }
                    
                }
                
                // CONTENU
                if audienceTab == "sexe" {
                    
                    SpectatorDonutChart(
                        male: viewModel.maleAudience,
                        female: viewModel.femaleAudience,
                        other: viewModel.otherAudience
                    )
                    
                } else if audienceTab == "age" {
                    
                    Text("Graphique âge ici")
                        .foregroundColor(.gray)
                    
                } else {
                    
                    Text("Graphique emplacement ici")
                        .foregroundColor(.gray)
                }
                
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
            
            
            // ============================
            // PAYS DES SPECTATEURS
            // ============================
            
            VStack(alignment: .leading, spacing: 18) {
                
                // TITRE
                Text("Pays des spectateurs")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                // GRAPHIQUE
                Chart(viewModel.audienceCountries) { item in
                    
                    BarMark(
                        x: .value("Pays", item.country),
                        y: .value("Spectateurs", item.value)
                    )
                    .cornerRadius(3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.blue,
                                Color.blue.opacity(0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                }
                .chartXScale(range: .plotDimension(padding: 30))
                
                .chartXAxis {
                    AxisMarks {
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.35))
                        
                        AxisTick()
                            .foregroundStyle(Color.gray)
                        
                        AxisValueLabel()
                            .foregroundStyle(Color.black)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                
                .chartYAxis {
                    AxisMarks {
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.35))
                        
                        AxisTick()
                            .foregroundStyle(Color.gray)
                        
                        AxisValueLabel()
                            .foregroundStyle(Color.black)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                
                .frame(height: 220)
                
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
            
            // ============================
            // SPECTATEURS FIDÈLES
            // ============================
            
            VStack(alignment: .leading, spacing: 14) {
                
                // TITRE
                HStack {
                    
                    Text("Spectateurs fidèles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                }
                
                // NOMBRE
                Text("\(viewModel.returningViewers)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                
                // DESCRIPTION
                Text("personnes sont revenues voir vos vidéos")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
            
            // ===============================
            // HEURES ACTIVITÉ
            // ===============================
            
            VStack(alignment: .leading, spacing: 18) {
                
                // TITRE
                Text("Heures d'activité élevée")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                // GRAPHIQUE
                Chart(viewModel.activityHours) { item in
                    
                    BarMark(
                        x: .value("Heure", item.hour),
                        y: .value("Spectateurs", item.value)
                    )
                    .cornerRadius(3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.blue,
                                Color.blue.opacity(0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // espace comme TikTok
                .chartXScale(range: .plotDimension(padding: 40))
                
                // AXE HORIZONTAL
                .chartXAxis {
                    AxisMarks(position: .bottom) {
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.25))
                        
                        AxisTick()
                            .foregroundStyle(Color.gray)
                        
                        AxisValueLabel()
                            .foregroundStyle(Color.black)
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                
                // AXE VERTICAL (les chiffres 0 1 2 etc)
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.25))
                        
                        AxisTick()
                            .foregroundStyle(Color.gray)
                        
                        AxisValueLabel()
                            .foregroundStyle(Color.black)
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                
                .frame(height: 240)
                
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
            // ======================
            // SOURCE DU TRAFIC
            // ======================
            
            VStack(alignment: .leading, spacing: 18) {
                
                // TITRE
                Text("Source du trafic")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                // GRAPHIQUE
                Chart(viewModel.trafficSources) { item in
                    
                    BarMark(
                        x: .value("Source", item.source),
                        y: .value("Vues", item.value)
                    )
                    .cornerRadius(3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.blue,
                                Color.blue.opacity(0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                .chartXScale(range: .plotDimension(padding: 40))
                
                // AXE HORIZONTAL
                .chartXAxis {
                    AxisMarks(position: .bottom) {
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.25))
                        
                        AxisTick()
                            .foregroundStyle(Color.gray)
                        
                        AxisValueLabel()
                            .foregroundStyle(Color.black)
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                
                // AXE VERTICAL (0 1 2 etc)
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.25))
                        
                        AxisTick()
                            .foregroundStyle(Color.gray)
                        
                        AxisValueLabel()
                            .foregroundStyle(Color.black)
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                
                .frame(height: 220)
                
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        
            // ===============================
            // POSTS REGARDÉS
            // ===============================

            VStack(alignment: .leading, spacing: 18) {
                
                Text("Publications que tes spectateurs ont également vues")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                ForEach(Array(viewModel.relatedPosts.enumerated()), id: \.offset) { _, post in
                    
                    HStack(spacing: 12) {
                        
                        ZStack {

                            if let image = generateThumbnail(from: post.mediaURL) {

                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()

                            } else {

                                Color.gray.opacity(0.2)

                            }

                            Image(systemName: "play.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)

                        }
                        .frame(width: 80, height: 80)
                        .cornerRadius(10)
                        .clipped()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            
                            Text(post.caption)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black)
                                .lineLimit(2)
                            
                            Text("\(formatViews(post.viewsCount)) vues")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                        }
                        
                        Spacer()
                        
                    }
                    .padding(.vertical, 6)
                    
                }
                
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        
        .padding()
        .background(Color(.systemGray6))
        .sheet(isPresented: $showDatePicker) {
            VStack(spacing: 20) {
                
                Text("Choisir une période")
                    .font(.headline)
                
                DatePicker(
                    "Date début",
                    selection: $customStartDate,
                    displayedComponents: .date
                )
                
                DatePicker(
                    "Date fin",
                    selection: $customEndDate,
                    displayedComponents: .date
                )
                
                Button("Appliquer") {
                    
                    viewModel.startDate = customStartDate
                    viewModel.endDate = customEndDate
                    
                    viewModel.loadSpectatorsAnalytics()
                    
                    showDatePicker = false
                }
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
                
            }
            .padding()
            
        }
        
        .onAppear {
            
            viewModel.updateRange("7J")
            
        }
    }
    
    struct RangeButton: View {
        
        let title: String
        let selected: Bool
        let action: () -> Void
        
        var body: some View {
            
            Button(action: action) {
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1) // empêche le retour à la ligne
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        selected
                        ? Color.black
                        : Color(.systemGray5)
                    )
                    .foregroundColor(
                        selected
                        ? .white
                        : .black
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selected
                                ? Color.black
                                : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: selected)
                
            }
            
        }
    }
    struct AudienceFilterButton: View {
        
        let title: String
        let selected: Bool
        let action: () -> Void
        
        var body: some View {
            
            Button(action: action) {
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        selected
                        ? Color.blue.opacity(0.15)
                        : Color(.systemGray5)
                    )
                    .foregroundColor(
                        selected
                        ? Color.blue
                        : Color.gray
                    )
                    .cornerRadius(8)
                
            }
            
        }
    }
    func formatFollowers(_ value: Int) -> String {

        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }

        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }

        return "\(value)"
    }


    func formatViews(_ views: Int) -> String {

        if views >= 1_000_000 {
            return String(format: "%.1fM", Double(views) / 1_000_000)
        }

        if views >= 1_000 {
            return String(format: "%.1fK", Double(views) / 1_000)
        }

        return "\(views)"
    }
}
func generateThumbnail(from url: String) -> UIImage? {
    
    guard let videoURL = URL(string: url) else { return nil }
    
    let asset = AVAsset(url: videoURL)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    
    let time = CMTime(seconds: 1, preferredTimescale: 600)
    
    do {
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: cgImage)
    } catch {
        return nil
    }
}
