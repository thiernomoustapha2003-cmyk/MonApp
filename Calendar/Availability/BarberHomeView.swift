import SwiftUI

struct BarberHomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("✂️ Espace Coiffeur")
                .font(.largeTitle)
                .bold()
            
            Text("Bienvenue dans l'espace coiffeur")
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    BarberHomeView()
}
