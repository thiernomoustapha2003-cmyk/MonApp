import SwiftUI

struct StatItem: View {
    
    let value: String
    let title: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
