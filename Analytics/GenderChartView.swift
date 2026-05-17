import SwiftUI
import Charts
import MapKit

// MARK: - MODELS

struct FollowerGainLoss: Identifiable {
    let id = UUID()
    let date: Date
    let gained: Int
    let lost: Int
}

struct ActivityDay: Identifiable {
    let id = UUID()
    let day: String
    let value: Int
}

struct AudienceCountry: Identifiable {
    let id = UUID()
    let country: String
    let percentage: Double
    let coordinate: CLLocationCoordinate2D
}

struct CityAudience: Identifiable {
    let id = UUID()
    let city: String
    let percentage: Double
}

// MARK: - MAIN VIEW

struct GenderChartView: View {

    @ObservedObject var viewModel: FollowersAnalyticsViewModel
    
    // demo data (sera remplacé par Firestore)
    
    var gains: [FollowerGainLoss] = [
        .init(date: .now.addingTimeInterval(-86400*5), gained: 20, lost: 2),
        .init(date: .now.addingTimeInterval(-86400*4), gained: 40, lost: 5),
        .init(date: .now.addingTimeInterval(-86400*3), gained: 30, lost: 3),
        .init(date: .now.addingTimeInterval(-86400*2), gained: 50, lost: 8),
        .init(date: .now.addingTimeInterval(-86400), gained: 70, lost: 10)
    ]
    
    var heatmap: [ActivityDay] = [
        .init(day: "L", value: 40),
        .init(day: "M", value: 60),
        .init(day: "M", value: 20),
        .init(day: "J", value: 70),
        .init(day: "V", value: 90),
        .init(day: "S", value: 30),
        .init(day: "D", value: 50)
    ]
    
    var countries: [AudienceCountry] = [
        .init(country: "France", percentage: 35,
              coordinate: CLLocationCoordinate2D(latitude:48.85,longitude:2.35)),
        .init(country: "USA", percentage: 25,
              coordinate: CLLocationCoordinate2D(latitude:37.77,longitude:-122.41)),
        .init(country: "Canada", percentage: 15,
              coordinate: CLLocationCoordinate2D(latitude:45.50,longitude:-73.56))
    ]
    
    var cities: [CityAudience] = [
        .init(city: "Paris", percentage: 20),
        .init(city: "Marseille", percentage: 8),
        .init(city: "New York", percentage: 12),
        .init(city: "Toronto", percentage: 10)
    ]
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 30) {
                
                // MARK: GENDER DONUT
                                
                VStack(spacing: 16) {
                                    
                    Text("Répartition par genre")
                        .font(.headline)
                                    
                    // CERCLE
                                    
                    ZStack {

                        if viewModel.genderStats.isEmpty {

                            ProgressView()
                                .padding(.top, 40)

                        } else {

                            Chart {

                                ForEach(viewModel.genderStats) { stat in
                                    SectorMark(
                                        angle: .value("Percent", max(stat.percentage, 0.01)),
                                        innerRadius: .ratio(0.6)
                                    )
                                    .foregroundStyle(color(for: stat.gender))
                                    .cornerRadius(6)
                                    
                                    .annotation(position: .overlay) {

                                        Text("\(Int(stat.percentage))%")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .frame(height: 200)
                            .id(viewModel.genderStats.map { $0.count }.reduce(0,+))   // ⭐ AJOUTE CETTE LIGNE

                            // centre donut

                            Circle()
                                .fill(Color.black)
                                .frame(width: 90, height: 90)
                        }
                    }
                    .id(viewModel.genderStats.map{$0.count}.reduce(0,+))
                                    
                    // LEGENDE SOUS LE CERCLE (comme TikTok)
                                    
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
                    .padding(.horizontal)
                }
                
                // MARK: FOLLOWERS GAIN / LOSS
                
                VStack(alignment:.leading) {
                    
                    Text("Followers gagnés / perdus")
                        .font(.headline)
                    
                    Chart(gains) { item in
                        
                        BarMark(
                            x:.value("Date",item.date),
                            y:.value("Gained",item.gained)
                        )
                        .foregroundStyle(.green)
                        
                        BarMark(
                            x:.value("Date",item.date),
                            y:.value("Lost",-item.lost)
                        )
                        .foregroundStyle(.red)
                    }
                    .frame(height:220)
                }
                
                
                // MARK: HEATMAP ACTIVITY
                
                VStack(alignment:.leading) {
                    
                    Text("Activité des followers")
                        .font(.headline)
                    
                    HStack {
                        
                        ForEach(heatmap) { item in
                            
                            VStack {
                                
                                Text(item.day)
                                    .font(.caption)
                                
                                Rectangle()
                                    .fill(
                                        Color.blue.opacity(
                                            Double(item.value)/100
                                        )
                                    )
                                    .frame(width:30,height:30)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                
                
                // MARK: MAP COUNTRIES
                
                VStack(alignment:.leading) {
                    
                    Text("Répartition mondiale")
                        .font(.headline)
                    
                    Map(
                        coordinateRegion:.constant(
                            MKCoordinateRegion(
                                center:CLLocationCoordinate2D(latitude:20,longitude:0),
                                span:MKCoordinateSpan(latitudeDelta:120,longitudeDelta:120)
                            )
                        ),
                        annotationItems:countries
                    ){country in
                        
                        MapAnnotation(coordinate:country.coordinate){
                            
                            VStack{
                                
                                Circle()
                                    .fill(Color.red)
                                    .frame(width:16,height:16)
                                
                                Text("\(Int(country.percentage))%")
                                    .font(.caption2)
                            }
                        }
                    }
                    .frame(height:300)
                }
                
                
                // MARK: CITY LIST
                
                VStack(alignment:.leading){
                    
                    Text("Top villes")
                        .font(.headline)
                    
                    ForEach(cities){city in
                        
                        HStack{
                            
                            Text(city.city)
                            
                            Spacer()
                            
                            Text("\(Int(city.percentage))%")
                                .bold()
                        }
                    }
                }
                
            }
            .padding()
        }
    }
    
    
    func color(for gender:String)->Color{
        
        switch gender{
            
        case "Hommes":
            return .blue
            
        case "Femmes":
            return .green
            
        default:
            return .orange
        }
    }
}
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
