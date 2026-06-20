import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FavoriteClient: Identifiable {
    let id: String
    let name: String
    let email: String
    let imageUrl: String
    let city: String
    let addedAt: Date?
}

struct FavoritedByClientsView: View {

    @State private var clients: [FavoriteClient] = []
    @State private var isLoading = true

    private let db = Firestore.firestore()
    private let barberId = Auth.auth().currentUser?.uid ?? ""

    var body: some View {
        VStack {

            if isLoading {
                ProgressView("Chargement...")
            }

            else if clients.isEmpty {
                Text("Aucun client ne vous a encore ajouté en favori")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            else {
                List(clients) { client in
                    HStack(spacing: 12) {

                        AsyncImage(url: URL(string: client.imageUrl)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                        }
                        .frame(width: 55, height: 55)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 5) {
                            Text(client.name.isEmpty ? "Sans nom" : client.name)
                                .font(.headline)

                            Text(client.email)
                                .font(.caption)
                                .foregroundColor(.gray)

                            if !client.city.isEmpty {
                                Text("📍 \(client.city)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            if let addedAt = client.addedAt {
                                Text("Ajouté le \(formatDate(addedAt))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button {
                            openConversation(with: client.id, clientName: client.name)
                        } label: {
                            Image(systemName: "message.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Favoris clients")
        .onAppear {
            loadFavoritedByClients()
        }
    }

    func loadFavoritedByClients() {
        guard !barberId.isEmpty else {
            isLoading = false
            return
        }

        db.collection("users")
            .document(barberId)
            .collection("favoritedBy")
            .getDocuments { snapshot, _ in

                let docs = snapshot?.documents ?? []

                if docs.isEmpty {
                    DispatchQueue.main.async {
                        self.clients = []
                        self.isLoading = false
                    }
                    return
                }

                fetchClientsDetails(favoriteDocs: docs)
            }
    }

    func fetchClientsDetails(favoriteDocs: [QueryDocumentSnapshot]) {

        var loadedClients: [FavoriteClient] = []
        let group = DispatchGroup()

        for favDoc in favoriteDocs {
            let clientId = favDoc.documentID
            let addedAt = (favDoc.data()["createdAt"] as? Timestamp)?.dateValue()

            group.enter()

            db.collection("users")
                .document(clientId)
                .getDocument { snapshot, _ in

                    if let data = snapshot?.data() {
                        let client = FavoriteClient(
                            id: snapshot?.documentID ?? clientId,
                            name: data["name"] as? String ?? data["fullName"] as? String ?? "Sans nom",
                            email: data["email"] as? String ?? "",
                            imageUrl: data["imageUrl"] as? String ?? data["avatarUrl"] as? String ?? "",
                            city: data["city"] as? String ?? "",
                            addedAt: addedAt
                        )

                        loadedClients.append(client)
                    }

                    group.leave()
                }
        }

        group.notify(queue: .main) {
            self.clients = loadedClients.sorted {
                ($0.addedAt ?? Date.distantPast) > ($1.addedAt ?? Date.distantPast)
            }
            self.isLoading = false
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd/MM/yyyy à HH:mm"
        return formatter.string(from: date)
    }

    func openConversation(with clientId: String, clientName: String) {
        print("💬 Ouvrir conversation avec:", clientName, clientId)

        // On branchera la vraie ouverture de ChatView juste après.
        // Là, le bouton est prêt et ne casse rien.
    }
}
