import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AcceptedCallRoute: Identifiable, Hashable {
    let id = UUID()
    let callId: String
    let conversationId: String
    let type: String
    let callerName: String
}

struct ContentView: View {

    @State private var isLoggedIn: Bool = Auth.auth().currentUser != nil
    @State private var acceptedCallRoute: AcceptedCallRoute?

    var body: some View {

        NavigationStack {
            RootRouterView()
                .navigationDestination(item: $acceptedCallRoute) { route in
                    CallScreenView(
                        name: route.callerName,
                        avatarURL: nil,
                        mode: route.type == "video" ? .video : .audio,
                        callId: route.callId,
                        conversationId: route.conversationId,
                        onEndCall: { _ in }
                    )
                }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { _, user in
                self.isLoggedIn = (user != nil)
            }

            startSessionListener()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenAcceptedCall"))) { notification in
            let info = notification.userInfo ?? [:]

            let callId = info["callId"] as? String ?? ""
            let conversationId = info["conversationId"] as? String ?? ""
            let type = info["type"] as? String ?? "audio"
            let callerName = info["callerName"] as? String ?? "Appel Cutly"

            guard !callId.isEmpty else {
                print("❌ OpenAcceptedCall sans callId")
                return
            }

            print("📲 Ouverture écran appel accepté:", callId)

            acceptedCallRoute = AcceptedCallRoute(
                callId: callId,
                conversationId: conversationId,
                type: type,
                callerName: callerName
            )
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

        if Auth.auth().currentUser == nil {
            LoginView()
        } else {
            Group {
                if role == nil {
                    ProgressView("Chargement du compte...")
                } else if role == "chooseRole" {
                    ChooseRoleView()
                } else if role == "coiffeur" {
                    if hasCompletedProfile == true {
                        BarberDashboardView()
                    } else {
                        BarberProfileView()
                    }
                } else {
                    ClientHomeView()
                }
            }
            .onAppear {
                loadUserData()
                IncomingCallListener.shared.startListening()
                print("📞 IncomingCallListener lancé")
            }
        }
    }

    func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let ref = db.collection("users").document(uid)

        ref.getDocument { snapshot, _ in
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
