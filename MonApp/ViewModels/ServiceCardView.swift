import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ServiceCardView: View {
    
    var service: Service
    var barberId: String
    var isOwner: Bool
    
    // 🔥 États locaux pour les toggles
    @State private var isActive: Bool = true
    @State private var isPremium: Bool = false
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            Text(service.name)
                .font(.headline)
            
            Text("\(service.price, specifier: "%.0f") € • \(service.duration) min")
                .foregroundColor(.gray)
            
            Text(service.description)
                .font(.subheadline)
            
            // 🔥 Slider images
            if !service.imageURLs.isEmpty {
                
                TabView {
                    ForEach(service.imageURLs.indices, id: \.self) { index in
                        
                        ZStack(alignment: .bottomTrailing) {
                            
                            if let url = URL(string: service.imageURLs[index]) {
                                
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    ZStack {
                                        Color.gray.opacity(0.2)
                                        ProgressView()
                                    }
                                }
                                .frame(height: 250)
                                .clipped()
                                .cornerRadius(20)
                            }
                            
                            Text("\(index + 1)/\(service.imageURLs.count)")
                                .font(.caption)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .padding(10)
                        }
                    }
                }
                .frame(height: 250)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            }
            
            // ❤️ Likes
            HStack {
                Button {
                    toggleLike()
                } label: {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
                
                Text("\(service.likesCount) likes")
                    .font(.subheadline)
            }
            
            // 🔐 Options propriétaire
            if isOwner {
                
                Divider()
                
                Toggle("Service actif", isOn: $isActive)
                    .onChange(of: isActive) { value in
                        updateActiveStatus(value)
                    }
                
                Toggle("Service Premium ⭐️", isOn: $isPremium)
                    .onChange(of: isPremium) { value in
                        updatePremiumStatus(value)
                    }
                
                Button(role: .destructive) {
                    deleteService()
                } label: {
                    Text("Supprimer le service")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
        .onAppear {
            isActive = service.isActive
            isPremium = service.isPremium
        }
    }
    
    // ❤️ Toggle Like
    private func toggleLike() {
        
        guard let uid = Auth.auth().currentUser?.uid,
              let serviceId = service.id else { return }
        
        let db = Firestore.firestore()
        
        let serviceRef = db
            .collection("barbers")
            .document(barberId)
            .collection("services")
            .document(serviceId)
        
        serviceRef.getDocument { snapshot, _ in
            guard let data = snapshot?.data(),
                  var likedBy = data["likedBy"] as? [String] else { return }
            
            if likedBy.contains(uid) {
                likedBy.removeAll { $0 == uid }
                serviceRef.updateData([
                    "likedBy": likedBy,
                    "likesCount": FieldValue.increment(Int64(-1))
                ])
            } else {
                likedBy.append(uid)
                serviceRef.updateData([
                    "likedBy": likedBy,
                    "likesCount": FieldValue.increment(Int64(1))
                ])
            }
        }
    }
    
    // 🟢 Actif / Inactif
    private func updateActiveStatus(_ value: Bool) {
        guard let serviceId = service.id else { return }
        
        Firestore.firestore()
            .collection("barbers")
            .document(barberId)
            .collection("services")
            .document(serviceId)
            .updateData([
                "isActive": value
            ])
    }
    
    // ⭐ Premium
    private func updatePremiumStatus(_ value: Bool) {
        guard let serviceId = service.id else { return }
        
        Firestore.firestore()
            .collection("barbers")
            .document(barberId)
            .collection("services")
            .document(serviceId)
            .updateData([
                "isPremium": value
            ])
    }
    
    // 🗑 Supprimer
    private func deleteService() {
        guard let serviceId = service.id else { return }

        Firestore.firestore()
            .collection("barbers")
            .document(barberId)
            .collection("services")
            .document(serviceId)
            .delete()
    }
}
