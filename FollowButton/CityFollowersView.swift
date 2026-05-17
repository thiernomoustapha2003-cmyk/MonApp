import SwiftUI

struct CityFollowersView: View {
    
    var country: CountryStat?
    var cityStats: [CityStat]
    
    var body: some View {
        
        NavigationStack {
            
            List(cityStats) { city in
                
                HStack(spacing: 12) {
                    
                    VStack(alignment: .leading, spacing: 4) {
                        
                        Text(city.city)
                            .font(.headline)
                        
                        Text("\(Int(city.percentage))% des followers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        
                        Text("\(Int(city.percentage))%")
                            .fontWeight(.bold)
                        
                        // barre visuelle (style analytics)
                        GeometryReader { geo in
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.2))
                                .frame(height: 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue)
                                        .frame(
                                            width: geo.size.width * CGFloat(city.percentage / 100),
                                            height: 6
                                        ),
                                    alignment: .leading
                                )
                        }
                        .frame(width: 120, height: 6)
                    }
                }
                .padding(.vertical, 6)
            }
            .navigationTitle(country?.country ?? "Villes")
        }
    }
}
