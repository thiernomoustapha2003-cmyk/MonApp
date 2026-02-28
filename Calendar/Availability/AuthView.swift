import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthView: View {
    @State private var isLogin = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLogin {
                    LoginView()
                } else {
                    RegisterView()
                }
                
                Button(action: {
                    isLogin.toggle()
                }) {
                    Text(isLogin ? "Créer un compte" : "Déjà un compte ? Se connecter")
                        .foregroundColor(.blue)
                        .padding(.top)
                }
            }
            .navigationTitle("Cutly")
        }
    }
}
