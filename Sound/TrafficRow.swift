import SwiftUI

struct TrafficRow: View {
    
    let title: String
    let value: Double
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 6) {
            
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.1f%%", value))
                    .font(.system(size: 14, weight: .semibold))
            }
            
            GeometryReader { geo in
                
                ZStack(alignment: .leading) {
                    
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * (value / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
