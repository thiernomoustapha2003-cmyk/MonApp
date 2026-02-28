import SwiftUI

struct EscrowInfoView: View {
    @Binding var hasAccepted: Bool
    let onContinue: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                
                Text("Information importante sur votre paiement")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    Text("""
Lorsque vous payez votre réservation :

• Votre argent est bloqué temporairement
• Il ne va PAS directement au coiffeur
• Il reste sécurisé jusqu’à la fin de la prestation
• Après votre rendez-vous vous confirmez
• Ensuite seulement le coiffeur est payé
""")
                    .padding()
                }
                
                Toggle("J’ai lu et j’accepte", isOn: $hasAccepted)
                    .padding()
                
                Button("Continuer vers le paiement") {
                    if hasAccepted { onContinue() }
                }
                .disabled(!hasAccepted)
                .padding()
                .frame(maxWidth: .infinity)
                .background(hasAccepted ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Paiement sécurisé")
        }
    }
}
