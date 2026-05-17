import SwiftUI

struct InfoRow: View {
    
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 12) {
            
            Image(systemName: icon)
                .font(.system(size: 18))
                .frame(width: 24)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}
