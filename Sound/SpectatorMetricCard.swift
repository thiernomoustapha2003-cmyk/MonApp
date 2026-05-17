import SwiftUI

struct SpectatorMetricCard: View {
    
    let title: String
    let value: String
    let change: Double
    let percentage: Double
    let isActive: Bool
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.black)
            
            HStack(spacing: 4) {
                
                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(change >= 0 ? .green : .red)
                
                Text("\(Int(change)) (\(String(format: "%.1f", percentage))%)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(change >= 0 ? .green : .red)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 95, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isActive ? Color.blue.opacity(0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActive ? Color.blue : Color(.systemGray5), lineWidth: 1)
        )
    }
}
