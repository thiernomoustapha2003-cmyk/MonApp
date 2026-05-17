import SwiftUI
import Charts

struct FollowersGrowthChart: View {
    
    var viewModel: FollowersAnalyticsViewModel
    
    @Binding var selectedDate: Date?
    @Binding var selectedValue: Int?
    
    @State private var animateGraph = false
    
    var maxFollowers: Int {
        viewModel.followersHistory.map { $0.total }.max() ?? 100
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
        

            Text("Croissance des followers")
                .font(.headline)
                .padding(.top, 8)
                .padding(.bottom, 6)

            Spacer().frame(height: 6)
            
            // GRAPH
            
            Chart(viewModel.followersHistory) { item in
                
                // BARRES GAINS / PERTES
                
                ForEach(viewModel.followersHistory) { item in
                    
                    BarMark(
                        x: .value("Date", item.date),
                        y: .value("Gain", item.gained)
                    )
                    .foregroundStyle(Color.green.opacity(0.4))
                    
                    if item.lost > 0 {
                        
                        BarMark(
                            x: .value("Date", item.date),
                            y: .value("Perte", -item.lost)
                        )
                        .foregroundStyle(Color.red.opacity(0.4))
                    }
                }
                
                
                // COURBE PRINCIPALE
                
                ForEach(viewModel.followersHistory) { item in
                    
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Followers", animateGraph ? item.total : 0)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(.blue)
                    .lineStyle(.init(lineWidth: 3))
                    
                    
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Followers", animateGraph ? item.total : 0)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.6),
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Followers", animateGraph ? item.total : 0)
                    )
                    .symbol(Circle())
                    .symbolSize(60)
                    .foregroundStyle(.white)
                }
                
                
                // POINT INTERACTIF
                
                if let selectedDate,
                   let selectedValue {
                    
                    RuleMark(x: .value("Selected", selectedDate))
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(.init(lineWidth: 1, dash: [4]))
                    
                    
                    PointMark(
                        x: .value("Selected", selectedDate),
                        y: .value("Value", selectedValue)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(120)
                }
            }
            
            
            // AXES
            
            .chartYScale(domain: (maxFollowers - 40)...(maxFollowers + 20))
            
            
            .chartYAxis {
                
                AxisMarks(position: .leading) { value in
                    
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.15))
                    
                    AxisTick()
                        .foregroundStyle(.white)
                    
                    if let v = value.as(Int.self) {
                        
                        AxisValueLabel {
                            
                            if v >= 1000 {
                                Text("\(v/1000)K")
                            } else {
                                Text("\(v)")
                            }
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            
            
            .chartXAxis {
                
                AxisMarks { value in
                    
                    AxisGridLine()
                        .foregroundStyle(.gray.opacity(0.2))
                    
                    AxisTick()
                        .foregroundStyle(.gray)
                    
                    AxisValueLabel()
                        .foregroundStyle(.primary)
                }
            }
            
            
            // SCROLL HORIZONTAL
            
            .chartScrollableAxes(.horizontal)
            
            
            // TAILLE (IMPORTANT)
            
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .padding(.vertical, 12)
            
            
            // ANIMATION
            
            .onAppear {
                
                if !viewModel.followersHistory.isEmpty {
                    
                    withAnimation(.easeOut(duration: 1.2)) {
                        animateGraph = true
                    }
                }
            }
            
            
            // DRAG INTERACTIF
            
            .chartOverlay { proxy in
                
                GeometryReader { geo in
                    
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            
                            DragGesture()
                            
                                .onChanged { value in
                                    
                                    let x = value.location.x - geo[proxy.plotAreaFrame].origin.x
                                    
                                    if let date: Date = proxy.value(atX: x) {
                                        
                                        let closest = viewModel.followersHistory.min(by: {
                                            abs($0.date.timeIntervalSince(date)) <
                                            abs($1.date.timeIntervalSince(date))
                                        })
                                        
                                        selectedDate = closest?.date
                                        selectedValue = closest?.total
                                    }
                                }
                            
                                .onEnded { _ in
                                    
                                    selectedDate = nil
                                    selectedValue = nil
                                }
                        )
                }
            }
            
            
            // BULLE INFO
            
            if let selectedDate,
               let selectedValue {
                
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                    
                    Text("\(selectedValue)")
                        .font(.headline)
                        .bold()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.black.opacity(0.9))
                )
                .foregroundColor(.white)
            }
            
            
            // LEGENDE GENRE (comme TikTok)
            
            VStack(spacing: 12) {
                
                ForEach(viewModel.genderStats) { stat in
                    
                    HStack {
                        
                        Circle()
                            .fill(color(for: stat.gender))
                            .frame(width: 10, height: 10)
                        
                        Text(stat.gender)
                        
                        Spacer()
                        
                        Text("\(Int(stat.percentage))%")
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                }
            }
            .padding(.top, 10)
        }
    }
    
    
    // MARK: - Couleur genre
    
    func color(for gender: String) -> Color {
        
        switch gender {
            
        case "Hommes":
            return .blue
            
        case "Femmes":
            return .green
            
        default:
            return .orange
        }
    }
}
