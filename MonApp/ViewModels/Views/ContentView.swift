import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct ContentView: View {

    @State private var isLoggedIn: Bool = Auth.auth().currentUser != nil

    var body: some View {

        NavigationStack {
            RootRouterView()
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { _, user in
                self.isLoggedIn = (user != nil)
            }
       
        }
        .onAppear {
            startSessionListener()
        }
    }
}
    


// ==========================
// 🔥 ROUTEUR PRINCIPAL CLEAN
// ==========================

struct RootRouterView: View {

    @State private var role: String? = nil
    @State private var hasCompletedProfile: Bool? = nil

    private let db = Firestore.firestore()
    private var userId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var body: some View {

        // 🔥 PAS CONNECTÉ → on renvoie vers login
        if Auth.auth().currentUser == nil {
            LoginView()
        }

        // 🔥 CONNECTÉ → on peut router
        else {
            Group {

                if role == nil {
                    ProgressView("Chargement du compte...")
                }

                else if role == "chooseRole" {
                    ChooseRoleView()
                }

                else if role == "coiffeur" {

                    if hasCompletedProfile == true {
                        BarberDashboardView()
                    } else {
                        BarberProfileView()
                    }
                }

                else {
                    ClientHomeView()
                }
            }
            .onAppear {
                loadUserData()
            }
        }
    }

    // ===========================
    // 🔥 LOGIQUE SIMPLE ET PROPRE
    // ===========================

    func loadUserData() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        let ref = db.collection("users").document(uid)

        ref.getDocument { snapshot, _ in

            // 🔥 PREMIÈRE CONNEXION → on crée le compte
            if snapshot?.exists == false {

                print("🆕 Création du document utilisateur")

                ref.setData([
                    "role": "chooseRole",
                    "profileCompleted": false,
                    "createdAt": Timestamp()
                ]) { _ in

                    DispatchQueue.main.async {
                        self.role = "chooseRole"
                        self.hasCompletedProfile = false
                    }
                }

                return
            }

            // 🔥 COMPTE EXISTE
            let data = snapshot?.data() ?? [:]

            DispatchQueue.main.async {
                self.role = data["role"] as? String ?? "chooseRole"
                self.hasCompletedProfile = data["profileCompleted"] as? Bool ?? false
            }
        }
    }
}
func startSessionListener() {

    guard let uid = Auth.auth().currentUser?.uid else { return }

    Firestore.firestore()
        .collection("users")
        .document(uid)
        .addSnapshotListener { snapshot, _ in

            guard let data = snapshot?.data(),
                  let serverVersion = data["sessionVersion"] as? Int else { return }

            let localVersion = UserDefaults.standard.integer(forKey: "sessionVersion")

            if serverVersion != localVersion {

                print("🔐 Déconnecté car session invalidée")

                try? Auth.auth().signOut()
                UserDefaults.standard.set(serverVersion, forKey: "sessionVersion")
            }
        }
}
