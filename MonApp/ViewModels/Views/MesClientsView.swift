import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MesClientsView: View {
    
    @State private var clients: [AppUser] = []
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    private let uid = Auth.auth().currentUser?.uid ?? ""
    
    var body: some View {
        
        VStack {
            
            if isLoading {
                ProgressView("Chargement des clients...")
            }
            
            else if clients.isEmpty {
                Text("Aucun client pour le moment")
                    .foregroundColor(.gray)
            }
            
            else {
                List(clients) { client in
                    VStack(alignment: .leading) {
                        Text(client.name)
                            .font(.headline)
                        Text(client.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("Mes Clients")
        .onAppear {
            loadClients()
        }
    }
    
    private func loadClients() {
        
        db.collection("bookings")
            .whereField("barberId", isEqualTo: uid)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    isLoading = false
                    return
                }
                
                let clientIds = Set(documents.compactMap {
                    $0["clientId"] as? String
                })
                
                fetchClientsDetails(clientIds: Array(clientIds))
            }
    }
    
    private func fetchClientsDetails(clientIds: [String]) {
        
        var loadedClients: [AppUser] = []
        let group = DispatchGroup()
        
        for clientId in clientIds {
            
            group.enter()
            
            db.collection("users")
                .document(clientId)
                .getDocument { snapshot, _ in
                    
                    if let data = snapshot?.data() {
                        
                        let user = AppUser(
                            id: snapshot?.documentID ?? "",
                            name: data["name"] as? String ?? "Sans nom",
                            email: data["email"] as? String ?? ""
                        )
                        
                        loadedClients.append(user)
                    }
                    
                    group.leave()
                }
        }
        
        group.notify(queue: .main) {
            self.clients = loadedClients
            self.isLoading = false
        }
    }
}
