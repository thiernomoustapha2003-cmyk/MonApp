import SwiftUI
import Charts

struct FollowersActivityHours: View {
    
    @State private var selectedHour: String?
    @State private var selectedValue: Int?
    
    @Binding var selectedActivityDay: Date
    
    var viewModel: FollowersAnalyticsViewModel
    
    
    // HEATMAP JOURS
    let days = ["Lun","Mar","Mer","Jeu","Ven","Sam","Dim"]
    
    // HEURES
    let hours = Array(0..<24)
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {

            Text("Heures d'activité élevée")
                .font(.headline)

            Text("Ces 7 derniers jours, la plupart de tes followers ont été actifs à \(viewModel.bestHour).")
                .font(.subheadline)
                .foregroundColor(.gray)

            // EXPLICATION SIMPLE POUR COMPRENDRE LE GRAPHIQUE

            Text("Chaque barre représente une heure de la journée.")
                .font(.caption)
                .foregroundColor(.gray)

            Text("Plus la barre est haute, plus il y a de followers actifs à cette heure.")
                .font(.caption)
                .foregroundColor(.gray)

            // =========================
            // BEST POSTING TIME CARD
            // =========================

            VStack(alignment: .leading, spacing: 8) {
                
                HStack {
                    Text("🔥 Meilleur moment pour publier")
                        .font(.headline)
                    
                    Spacer()
                }
                
                Text("\(viewModel.bestPostingDay) • \(viewModel.bestPostingHour)")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Ton audience est la plus active à ce moment.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            
            // SELECTEUR DE JOUR
            
            HStack {
                
                Button {
                    selectedActivityDay =
                    Calendar.current.date(
                        byAdding: .day,
                        value: -1,
                        to: selectedActivityDay
                    ) ?? selectedActivityDay
                } label: {
                    Image(systemName: "chevron.left")
                }
                
                if viewModel.activityHours.isEmpty {
                    
                    Text("Pas encore assez de données d'activité")
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    
                } else {
                }
                
                
                
                Spacer()
                
                
                Text(
                    selectedActivityDay
                        .formatted(date: .abbreviated, time: .omitted)
                )
                
                Spacer()
                
                Button {
                    selectedActivityDay =
                    Calendar.current.date(
                        byAdding: .day,
                        value: 1,
                        to: selectedActivityDay
                    ) ?? selectedActivityDay
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            
            
            // GRAPHIQUE
            
            Chart(viewModel.activityHours) { item in

                BarMark(
                    x: .value("Heure", item.hour),
                    y: .value("Activité", item.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)

                .annotation(position: .top) {
                    Text("\(item.value)")
                        .font(.caption2)
                        .foregroundColor(.white)
                }

            }
            .chartYScale(domain: 0...max(1, viewModel.activityHours.map{$0.value}.max() ?? 1))
            .chartXAxis {
                AxisMarks(values: .automatic)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 220)
            .padding(.vertical, 10)
            
            
            // AXE Y
            
            .chartYAxis {
                
                AxisMarks(position: .leading) { value in
                    
                    AxisGridLine()
                    AxisTick()
                    
                    if let v = value.as(Int.self) {
                        
                        AxisValueLabel {
                            
                            if v >= 1000 {
                                Text("\(v/1000)K")
                            } else {
                                Text("\(v)")
                            }
                        }
                    }
                }
            }
            
            
            // AXE X
            
            .chartXAxis {
                AxisMarks(values: .stride(by: 3)) { value in
                    
                    AxisGridLine()
                    AxisTick()
                    
                    if let hour = value.as(Int.self) {
                        
                        AxisValueLabel {
                            Text(String(format: "%02dh", hour))
                        }
                    }
                }
            }
            
            
            .frame(height: 220)
            .chartOverlay { proxy in
                
                GeometryReader { geo in
                    
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            
                            DragGesture()
                                .onChanged { value in
                                    
                                    let x = value.location.x
                                    - geo[proxy.plotAreaFrame].origin.x
                                    
                                    if let hour: String = proxy.value(atX: x) {
                                        
                                        print("Heure touchée :", hour)
                                    }
                                }
                        )
                }
            }
            
            .animation(.easeInOut(duration: 0.2), value: viewModel.activityHours.count)
            
            
            // =========================
            // HEATMAP JOUR + HEURE
            // =========================
            
            VStack(alignment: .leading, spacing: 10) {

                Text("Activité des followers par jour et heure")
                    .font(.headline)

                Text("Heure de la journée")
                    .font(.caption)
                    .foregroundColor(.gray)

                // HEURES
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    VStack(alignment: .leading, spacing: 6) {
                        
                        HStack(spacing: 4) {
                            
                            Text("")
                                .frame(width: 40)
                            
                            ForEach(hours, id: \.self) { hour in
                                
                                if hour % 3 == 0 {
                                    
                                    Text(String(format: "%02dh", hour))
                                        .font(.system(size: 10, weight: .medium))
                                        .frame(width: 18, alignment: .center)
                                    
                                } else {
                                    
                                    Text("")
                                        .frame(width: 18)
                                }
                                
                            }
                        }
                        
                        
                        // LIGNES JOURS
                        
                        ForEach(days, id: \.self) { day in
                            
                            HStack(spacing: 4) {
                                
                                Text(day)
                                    .font(.caption)
                                    .frame(width: 40)
                                
                                ForEach(hours, id: \.self) { hour in
                                    
                                    Rectangle()
                                        .fill(
                                            heatColor(
                                                value: heatmapValue(day: day, hour: hour)
                                            )
                                        )
                                        .frame(width: 18, height: 14)
                                        .cornerRadius(3)
                                }
                            }
                        }
                    }
                    .frame(minWidth: 600)
                }
                // =========================
                // LEGENDE HEATMAP
                // =========================

                VStack(alignment: .leading, spacing: 8) {

                    Text("Légende")
                        .font(.caption)
                        .foregroundColor(.gray)

                    HStack(spacing: 16) {

                        legend(color: Color.gray.opacity(0.2), text: "Activité faible")

                        legend(color: Color.blue.opacity(0.3), text: "Activité moyenne")

                        legend(color: Color.blue.opacity(0.6), text: "Activité élevée")

                        legend(color: Color.blue, text: "Activité très élevée")
                    }
                }

                // =========================
                // EXPLICATION SIMPLE
                // =========================

                Text("Plus la couleur est bleue, plus tes followers sont connectés à ce moment.")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("💡 Publie quand les cases sont les plus bleues pour toucher plus de followers.")
                    .font(.caption)
                    .foregroundColor(.gray)            }
        }
    }
    func heatmapValue(day: String, hour: Int) -> Int {
        
        if let item = viewModel.activityHeatmap.first(
            where: { $0.day == day && $0.hour == hour }
        ) {
            return item.value
        }
        
        return 0
    }
}
// =========================
// LEGENDE VISUELLE
// =========================

func legend(color: Color, text: String) -> some View {

    HStack(spacing: 4) {

        Rectangle()
            .fill(color)
            .frame(width: 12, height: 12)
            .cornerRadius(2)

        Text(text)
            .font(.caption)
    }
}
// =========================
// COULEUR HEATMAP
// =========================

func heatColor(value: Int) -> Color {
    
    if value == 0 {
        return Color.gray.opacity(0.2)
    }
    
    if value < 5 {
        return Color.blue.opacity(0.3)
    }
    
    if value < 15 {
        return Color.blue.opacity(0.6)
    }
    
    return Color.blue
}


// =========================
// VALEUR DEMO (TEST)
// =========================

