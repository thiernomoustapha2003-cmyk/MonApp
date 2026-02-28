import SwiftUI
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore

struct SecurityAccessView: View {

    @State private var info = ""
    @State private var showDelete = false

    var body: some View {

        List {

            Section("Compte") {

                NavigationLink {
                    ChangePasswordView()
                } label: {
                    Text("Changer mot de passe")
                }

                Button("Déconnecter cet appareil") {
                    logout()
                }

                NavigationLink("Activer double authentification") {
                    TwoFactorSetupView()
                }
                
                Button(role: .destructive) {
                    Task {
                        try? await SessionManager.shared.forceLogoutAllDevices()
                    }
                } label: {
                    Label("Se déconnecter de tous les appareils", systemImage: "lock.slash")
                }
                
                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    Text("Supprimer mon compte")
                }
            }

            Section("Protection") {
                
                NavigationLink("Clients bloqués") {
                    BlockedClientsView()
                }
                
                NavigationLink("Journal de connexion") {
                    LoginHistoryView()
                }
                NavigationLink {
                    ConnectedDevicesView()
                } label: {
                    Label("Appareils connectés", systemImage: "iphone.gen3")
                }
            }

            
            if !info.isEmpty {
                Text(info)
                    .foregroundColor(.green)
            }
        }
        
        .onAppear {
            recordLoginIfNeeded()
        }
        
        .navigationTitle("Sécurité & accès")
        .alert("Supprimer le compte ?", isPresented: $showDelete) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Action irréversible")
        }
    }
}

extension SecurityAccessView {
    
    func sendReset() {
        guard let email = Auth.auth().currentUser?.email else { return }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if error == nil {
                info = "Email de réinitialisation envoyé"
            } else {
                info = "Erreur: (error!.localizedDescription)"
            }
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            info = "Erreur déconnexion"
        }
    }
    
    func deleteAccount() {
        
        guard let user = Auth.auth().currentUser else {
            print("❌ Aucun utilisateur connecté")
            return
        }
        
        print("🧨 Tentative suppression...")
        
        user.delete { error in
            
            if let error = error as NSError? {
                
                print("❌ Erreur suppression:", error.code, error.localizedDescription)
                
                // 🔐 Cas le plus courant : session trop vieille
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    print("⚠️ Reconnexion requise")
                }
                
                return
            }
            
            print("✅ Compte supprimé avec succès")
            
            do {
                try Auth.auth().signOut()
            } catch {
                print("Erreur signout:", error)
            }
        }
    }
    
    func logoutAllDevices() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = Firestore.firestore().collection("users").document(uid)
        
        ref.updateData([
            "sessionVersion": FieldValue.increment(Int64(1))
        ]) { error in
            
            if let error = error {
                print("❌ Erreur logout all:", error)
                return
            }
            
            print("✅ Tous les appareils seront déconnectés")
            
            do {
                try Auth.auth().signOut()
            } catch {
                print("Erreur signout:", error)
            }
        }
    }
}
func recordLoginIfNeeded() {

    guard let user = Auth.auth().currentUser else { return }

    let db = Firestore.firestore()

    let data: [String: Any] = [
        "uid": user.uid,
        "email": user.email ?? "unknown",
        "date": Timestamp(date: Date()),
        "device": UIDevice.current.name,
        "platform": "iOS",
        "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    ]

    db.collection("login_history")
        .document(user.uid)
        .collection("events")
        .addDocument(data: data) { error in

            if let error = error {
                print("❌ Erreur enregistrement login:", error)
            } else {
                print("✅ Login enregistré")
            }
        }
}
