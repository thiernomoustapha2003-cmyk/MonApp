import SwiftUI

struct SimpleActionSheet: View {
    
    var title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 25) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Configuration disponible bientôt")
                .foregroundColor(.gray)
            
            Button("Fermer") {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
}
