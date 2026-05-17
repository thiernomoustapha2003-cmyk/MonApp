import SwiftUI
import Charts

struct AnalyticsFollowersCharts: View {

    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDate: Date?
    @State private var selectedValue: Int?
    
    @State private var scrollPosition: Date = Date()
    @State private var visibleDomain: Int = 7

    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Croissance des followers")
                .font(.headline)
            
            Text("\(viewModel.followersGrowth.reduce(0) { $0 + $1.value })")
                .font(.system(size: 34, weight: .bold))
                .contentTransition(.numericText())
            
            HStack(spacing: 20) {
                
                VStack(alignment: .leading) {
                    Text("Aujourd'hui")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("+\(todayFollowers())")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading) {
                    Text("Hier")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("+\(yesterdayFollowers())")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading) {
                    Text("7 jours")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("+\(weekFollowers())")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            
            
            Chart {
                
                ForEach(viewModel.followersGrowth) { item in
                    
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Followers", item.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .shadow(color: .green.opacity(0.6), radius: 6)
                    
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Followers", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .green.opacity(0.35),
                                .blue.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Followers", item.value)
                    )
                    .symbolSize(viewModel.followersGrowth.count > 0 ? 60 : 0)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                
                // POINT ACTIF + LIGNE VERTICALE (style TikTok)
                if let selectedDate,
                   let selectedValue {
                    
                    RuleMark(
                        x: .value("Date", selectedDate)
                    )
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    
                    PointMark(
                        x: .value("Date", selectedDate),
                        y: .value("Followers", selectedValue)
                    )
                    .symbolSize(120)
                    .foregroundStyle(.orange)
                }
            }
            .frame(height: 240)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: visibleDomain)
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        
                        if value > 1 {
                            visibleDomain = min(30, visibleDomain + 1)
                        } else {
                            visibleDomain = max(3, visibleDomain - 1)
                        }
                        
                    }
            )
            .chartScrollPosition(x: $scrollPosition)
            .chartScrollTargetBehavior(
                .valueAligned(
                    matching: .init(hour: 0),
                    majorAlignment: .matching(.init(day: 1))
                )
            )
            .chartXScale(domain: .automatic(includesZero: false))
            
            .animation(.easeInOut(duration: 0.6), value: viewModel.followersGrowth.count)
            
            // INTERACTION DOIGT (TikTok style)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                            
                                .onChanged { value in
                                    
                                    let x =
                                    value.location.x -
                                    geo[proxy.plotAreaFrame].origin.x
                                    
                                    if let date: Date =
                                        proxy.value(atX: x) {
                                        
                                        if let match =
                                            viewModel.followersGrowth.first(where: {
                                                
                                                Calendar.current.isDate(
                                                    $0.date,
                                                    inSameDayAs: date
                                                )
                                                
                                            }) {
                                            
                                            selectedDate = match.date
                                            selectedValue = match.value
                                        }
                                    }
                                }
                            
                                .onEnded { _ in
                                    
                                    selectedDate = nil
                                    selectedValue = nil
                                    
                                }
                        )
                }
            }
            
            // BULLE DE VALEUR (comme TikTok Analytics)
            if let selectedDate,
               let selectedValue {
                
                HStack {
                    
                    Text(
                        selectedDate.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                    )
                    
                    Spacer()
                    
                    Text("\(selectedValue) followers")
                        .bold()
                    
                }
                .padding(10)
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                
                ForEach(viewModel.followersGrowth) { item in
                    
                    HStack {
                        
                        Text(item.date.formatted(date: .abbreviated, time: .omitted))
                        
                        Spacer()
                        
                        Text("+\(item.value)")
                    }
                }
            }
        }
            .onAppear {
                viewModel.loadFollowersAnalytics()
            
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding()
    }
        func todayFollowers() -> Int {

            let today = Calendar.current.startOfDay(for: Date())

            return viewModel.followersGrowth
                .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
                .reduce(0) { $0 + $1.value }
        }

        func yesterdayFollowers() -> Int {

            guard let yesterday =
                Calendar.current.date(byAdding: .day, value: -1, to: Date())
            else { return 0 }

            return viewModel.followersGrowth
                .filter { Calendar.current.isDate($0.date, inSameDayAs: yesterday) }
                .reduce(0) { $0 + $1.value }
        }

        func weekFollowers() -> Int {

            guard let weekAgo =
                Calendar.current.date(byAdding: .day, value: -7, to: Date())
            else { return 0 }

            return viewModel.followersGrowth
                .filter { $0.date >= weekAgo }
                .reduce(0) { $0 + $1.value }
        }

        
    }

