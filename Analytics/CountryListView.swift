import SwiftUI

struct CountryListView: View {
    
    var countryStats: [CountryStat]
    
    var body: some View {
        
        VStack(spacing: 12) {
            
            ForEach(countryStats) { country in
                
                VStack(spacing: 6) {
                    
                    HStack {
                        
                        Text(country.country)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(Int(country.percentage))%")
                            .fontWeight(.bold)
                    }
                    
                    GeometryReader { geo in
                        
                        ZStack(alignment: .leading) {
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(
                                    width: geo.size.width * CGFloat(country.percentage / 100),
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)
                    
                }
                .padding(.vertical, 4)
            }
        }
    }
}
