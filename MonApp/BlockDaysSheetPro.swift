import SwiftUI

struct BlockDaysSheetPro: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Blocage de jours")
                .font(.title2)
            
            Text("Module avancé bientôt disponible")
                .foregroundColor(.gray)
            
            Button("Fermer") {
                dismiss()
            }
        }
        .padding()
    }
}
 
