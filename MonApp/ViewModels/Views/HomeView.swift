import SwiftUI

struct HomeView: View {

    @State private var animate = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                // ✂️ Icône ciseaux
                Image(systemName: "scissors")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundColor(.black)
                    .padding(.top, 60)
                    .scaleEffect(animate ? 1 : 0.6)
                    .opacity(animate ? 1 : 0)

                // 🖤 Titre
                Text("Bienvenue sur Cutly")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .offset(y: animate ? 0 : 30)
                    .opacity(animate ? 1 : 0)

                Spacer().frame(height: 40)

                // 🔵 Je suis client (PAS de login)
                NavigationLink(destination: BarberListView()) {
                    Text("Je suis client")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                .padding(.horizontal)
                .offset(y: animate ? 0 : 40)
                .opacity(animate ? 1 : 0)

                // 🟢 Je suis coiffeur (login / inscription)
                NavigationLink(destination: LoginView()) {
                    Text("Je suis coiffeur")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(14)
                }
                .padding(.horizontal)
                .offset(y: animate ? 0 : 60)
                .opacity(animate ? 1 : 0)

                Spacer()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animate = true
                }
            }
        }
    }
}
