import FirebaseAuth

extension Auth {

    func signOutCurrentUserEverywhere() {

        guard let user = self.currentUser else { return }

        user.reload { _ in
            do {
                try self.signOut()
                print("Utilisateur déconnecté partout")
            } catch {
                print("Erreur déconnexion:", error)
            }
        }
    }
}
