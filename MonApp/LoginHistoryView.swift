import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginHistoryView: View {

    @State private var logs: [LoginLog] = []
    @State private var loading = true

    var body: some View {

        Group {
            if loading {
                ProgressView("Chargement...")
            } else if logs.isEmpty {
                Text("Aucune connexion enregistrée")
                    .foregroundColor(.gray)
            } else {
                List(logs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.device)
                            .font(.headline)

                        Text(log.platform)
                            .font(.subheadline)

                        Text(log.email)
                            .font(.caption)

                        Text(log.dateFormatted)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Journal de connexion")
        .onAppear(perform: loadLogs)
    }

    func loadLogs() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("login_history")
            .document(uid)
            .collection("events")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in

                loading = false

                guard let docs = snapshot?.documents else { return }

                logs = docs.compactMap { LoginLog(doc: $0) }
            }
    }
}

struct LoginLog: Identifiable {

    var id: String
    var device: String
    var platform: String
    var email: String
    var date: Date

    var dateFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    init?(doc: QueryDocumentSnapshot) {

        let data = doc.data()

        guard
            let device = data["device"] as? String,
            let platform = data["platform"] as? String,
            let email = data["email"] as? String,
            let timestamp = data["date"] as? Timestamp
        else { return nil }

        self.id = doc.documentID
        self.device = device
        self.platform = platform
        self.email = email
        self.date = timestamp.dateValue()
    }
}
