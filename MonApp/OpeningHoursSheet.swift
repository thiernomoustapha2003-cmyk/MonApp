import SwiftUI

struct OpeningHoursSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Horaires d'ouverture")
                .font(.title2)
            
            Text("Module en préparation")
                .foregroundColor(.gray)
            
            Button("Fermer") {
                dismiss()
            }
        }
        .padding()
    }
}
