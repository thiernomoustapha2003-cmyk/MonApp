import SwiftUI
import Firebase
import FirebaseAuth


struct FavoritesView: View {
    
    @State private var favoriteServices: [Service] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(favoriteServices) { service in
                    
                    VStack(alignment: .leading) {
                        Text(service.name)
                            .font(.headline)
                        
                        Text("\(service.price, specifier: "%.2f") €")
                        
                        Text(service.description)
                            .font(.caption)
                    }
                    .padding()
                }
            }
            .navigationTitle("Mes Favoris")
            .onAppear {
                loadFavorites()
            }
        }
    }
    
    private func loadFavorites() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        db.collection("users")
            .document(uid)
            .collection("favorites")
            .getDocuments { snapshot, _ in
                
                guard let documents = snapshot?.documents else { return }
                
                for doc in documents {
                    
                    let serviceId = doc.documentID
                    let barberId = doc["barberId"] as? String ?? ""
                    
                    db.collection("barbers")
                        .document(barberId)
                        .collection("services")
                        .document(serviceId)
                        .getDocument { serviceDoc, _ in
                            
                            if let data = serviceDoc?.data() {

                                let service = Service(
                                    id: serviceDoc?.documentID,
                                    name: data["name"] as? String ?? "",
                                    price: data["price"] as? Double ?? 0,
                                    duration: data["duration"] as? Int ?? 0,
                                    description: data["description"] as? String ?? "",
                                    imageURLs: data["imageURLs"] as? [String] ?? [],
                                    isPremium: data["isPremium"] as? Bool ?? false,
                                    isActive: data["isActive"] as? Bool ?? true,
                                    likesCount: data["likesCount"] as? Int ?? 0,
                                    likedBy: data["likedBy"] as? [String] ?? []
                                )

                                favoriteServices.append(service)
                            }                        }
                }
            }
    }
}
