import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct BarberRegistrationView: View {

    @State private var goToProfile = false
    @State private var message = ""

    private let db = Firestore.firestore()
    private let barberId = Auth.auth().currentUser?.uid ?? ""

    var body: some View {
        NavigationStack {

            VStack(spacing: 20) {

                Text("Bienvenue, futur coiffeur ✂️")
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)

                Text("""
                Avant d’accéder à votre espace,
                merci de compléter votre profil :
                photo, adresse, description,
                services et paiement.
                """)
                .multilineTextAlignment(.center)
                .padding()

                Button("Compléter mon profil") {
                    goToProfile = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(12)

                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(.blue)
                        .font(.footnote)
                }

                NavigationLink(
                    destination: BarberProfileView(),
                    isActive: $goToProfile
                ) {
                    EmptyView()
                }
            }
            .padding()
            .navigationTitle("Inscription Coiffeur")
        }
    }
}
