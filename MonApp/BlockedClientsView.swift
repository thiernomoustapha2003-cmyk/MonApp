import SwiftUI

struct BlockedClientsView: View {
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text("Clients bloqués")
                .font(.title2)
                .fontWeight(.bold)

            Text("Les clients bloqués apparaîtront ici")
                .foregroundColor(.gray)
        }
        .padding()
        .navigationTitle("Blocage")
    }
}
