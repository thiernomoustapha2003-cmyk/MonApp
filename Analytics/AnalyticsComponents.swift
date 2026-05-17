import SwiftUI

struct AnalyticsComponents: View {
    
    let title: String
    let value: String
    let variation: String
    let isPositive: Bool
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 6) {
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            HStack {
                
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                
                Spacer()
                
                if variation != "" {
                    
                    HStack(spacing: 4) {
                        
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        
                        Text(variation)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(isPositive ? .blue : .gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}



