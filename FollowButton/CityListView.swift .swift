import SwiftUI

struct CityListView: View {
    
    var cityStats: [CityStat]
    
    var body: some View {
        
        VStack(spacing: 12) {
            
            ForEach(cityStats) { city in
                
                VStack(spacing: 6) {
                    
                    HStack {
                        
                        Text(city.city)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(Int(city.percentage))%")
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
                                    width: geo.size.width * CGFloat(city.percentage / 100),
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
