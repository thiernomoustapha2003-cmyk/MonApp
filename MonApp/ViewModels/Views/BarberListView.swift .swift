import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct BarberListView: View {
    
    @StateObject var viewModel = BarberViewModel()
    @State private var searchText: String = ""
    @State private var showFavoritesOnly = false
    
    var filteredBarbers: [Barber] {
        let list = showFavoritesOnly
        ? viewModel.barbers.filter { $0.isFavorite }
        : viewModel.barbers
        
        if searchText.isEmpty {
            return list
        } else {
            return list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.city.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                
                // ==========================
                // 🔹 HEADER (tu voulais garder)
                // ==========================
                
                HStack {
                    Text("Coiffeurs")
                        .font(.largeTitle)
                        .bold()
                    
                    Spacer()
                    
                    Button(action: {
                        showFavoritesOnly.toggle()
                    }) {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundColor(showFavoritesOnly ? .red : .gray)
                    }
                }
                .padding(.horizontal)
                
                // 🔹 Barre de recherche (tu voulais garder)
                TextField("Rechercher un coiffeur...", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Divider()
                
                // ==========================
                // 🔹 LISTE DES COIFFEURS
                // ==========================
                
                if viewModel.isLoading {
                    ProgressView("Chargement des coiffeurs...")
                        .padding()
                }
                else if filteredBarbers.isEmpty {
                    Text("Aucun coiffeur trouvé")
                        .foregroundColor(.gray)
                        .padding()
                }
                else {
                    List {
                        ForEach(filteredBarbers) { barber in
                            
                            VStack(spacing: 12) {
                                
                                // ==========================
                                // ZONE PROFIL (CLIQUE → DÉTAIL)
                                // ==========================
                                
                                NavigationLink(
                                    destination: BarberDetailView(barber: barber)
                                ) {
                                    HStack(spacing: 12) {
                                        
                                        AsyncImage(url: URL(string: barber.imageUrl ?? "")) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            
                                            
                                            
                                            Image(systemName: "person.crop.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.gray)
                                        }
                                        
                                        
                                        
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            
                                            HStack {
                                                Text(barber.name)
                                                    .font(.headline)
                                                
                                                Text("Disponible")
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.green.opacity(0.2))
                                                    .foregroundColor(.green)
                                                    .cornerRadius(6)
                                            }
                                            
                                            Text(barber.city)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            
                                            Text("💰 \(barber.price, specifier: "%.2f") €")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            toggleFavorite(barber: barber)
                                        } label: {
                                            Image(systemName: barber.isFavorite ? "heart.fill" : "heart")
                                                .foregroundColor(barber.isFavorite ? .red : .gray)
                                                .font(.title3)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(PlainButtonStyle()) // empêche les conflits
                                
                                Divider()
                                
                                // ==========================
                                // ZONE ACTIONS (SÉPARÉES)
                                // ==========================
                                
                                HStack(spacing: 25) {
                                    
                                    // 📅 RÉSERVER
                                    Button {
                                        print("Réserver \(barber.name)")
                                    } label: {
                                        Label("Réserver", systemImage: "calendar")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    
                                    Spacer()
                                    
                                    // 📞 APPELER
                                    Button {
                                        let cleaned = barber.phone.replacingOccurrences(of: " ", with: "")
                                        if let url = URL(string: "tel://\(cleaned)") {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        Label("Appeler", systemImage: "phone")
                                            .foregroundColor(.orange)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 6)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Coiffeurs")
            .onAppear {
                viewModel.fetchBarbers()
            }
        }
    }
    func toggleFavorite(barber: Barber) {
        guard let clientId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let barberId = barber.authId.isEmpty ? (barber.id ?? "") : barber.authId

        guard !barberId.isEmpty else {
            print("❌ barberId vide")
            return
        }

        let clientFavRef = db.collection("users")
            .document(clientId)
            .collection("favoriteBarbers")
            .document(barberId)

        let barberFavRef = db.collection("users")
            .document(barberId)
            .collection("favoritedBy")
            .document(clientId)

        clientFavRef.getDocument { snap, _ in
            if snap?.exists == true {
                clientFavRef.delete()
                barberFavRef.delete()
            } else {
                clientFavRef.setData([
                    "barberId": barberId,
                    "barberName": barber.name,
                    "barberCity": barber.city,
                    "barberImageUrl": barber.imageUrl ?? "",
                    "createdAt": Timestamp()
                ])

                barberFavRef.setData([
                    "clientId": clientId,
                    "createdAt": Timestamp()
                ])
            }

            viewModel.fetchBarbers()
        }
    }
    
}
