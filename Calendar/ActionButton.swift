import SwiftUI

struct ActionButton: View {
    
    let systemName: String
    let count: Int
    
    var body: some View {
        VStack(spacing: 6) {
            
            Image(systemName: systemName)
                .font(.system(size: 28))
                .foregroundColor(.white)
            
            Text(formatNumber(count))
                .font(.caption)
                .foregroundColor(.white)
        }
    }
    
    private func formatNumber(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value)/1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value)/1_000)
        }
        return "\(value)"
    }
}
