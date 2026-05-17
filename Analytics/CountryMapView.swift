import SwiftUI
import MapKit

struct CountryMapView: View {
    
    var countryStats: [CountryStat]
    var cityStats: [CityStat] = []
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
    )
    
    @State private var selectedCountry: CountryStat?
    @State private var showCities = false
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            
            Text("Répartition mondiale des followers")
                .font(.headline)
            
            
            Map(coordinateRegion: $region,
                annotationItems: countryStats) { country in
                
                MapAnnotation(coordinate: country.coordinate) {
                    
                    VStack(spacing: 4) {
                        
                        Circle()
                            .fill(color(for: country.percentage))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        Text("\(Int(country.percentage))%")
                            .font(.caption2)
                            .padding(4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(6)
                    }
                    .onTapGesture {
                        
                        withAnimation(.easeInOut(duration: 0.4)) {
                            
                            selectedCountry = country
                            
                            // zoom sur le pays
                            region.center = country.coordinate
                            region.span = MKCoordinateSpan(
                                latitudeDelta: 25,
                                longitudeDelta: 25
                            )
                        }
                        
                        showCities = true
                    }
                }
            }
            .frame(height: 300)
            .cornerRadius(14)
            
            
            if let country = selectedCountry {
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    Text("Pays sélectionné")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(country.country)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("\(Int(country.percentage))% des followers")
                        .font(.subheadline)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showCities) {
            CityFollowersView(
                country: selectedCountry,
                cityStats: cityStats
            )
        }
    }
    
    
    func color(for value: Double) -> Color {
        
        if value > 40 {
            return .red
        }
        else if value > 20 {
            return .orange
        }
        else if value > 10 {
            return .yellow
        }
        else {
            return .blue
        }
    }
}
