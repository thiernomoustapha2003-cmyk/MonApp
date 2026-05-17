import SwiftUI

struct DonatorRow: View {
    
    let name: String
    let coins: String
    
    var body: some View {
        
        HStack {
            
            Circle()
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(name)
                Text("🪙 \(coins)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button("Suivre") {}
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}
