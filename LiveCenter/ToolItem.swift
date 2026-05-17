import SwiftUI

struct ToolItem: View {
    
    let icon: String
    let title: String
    
    var body: some View {
        
        VStack {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
    }
}
