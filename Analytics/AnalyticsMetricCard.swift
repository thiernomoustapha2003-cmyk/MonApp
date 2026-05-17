import SwiftUI

struct AnalyticsMetricCard: View {
    
    let title: String
    let value: String
    let variation: String
    let isPositive: Bool
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
            
            if !variation.isEmpty {
                HStack(spacing: 4) {
                    
                    Image(systemName: isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(isPositive ? .blue : .gray)
                    
                    Text(variation)
                        .font(.system(size: 12))
                        .foregroundColor(isPositive ? .blue : .gray)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2))
        )
        .cornerRadius(12)
    }
}
