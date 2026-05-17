import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ClientHomeView: View {

    @StateObject var viewModel = BarberViewModel()

    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    @State private var showLoginSheet = false
    @State private var selectedBarberForAction: Barber? = nil
    @State private var pendingAction: PendingAction? = nil

    enum PendingAction {
        case call
        case whatsapp
        case book
    }

    var filteredBarbers: [Barber] {
        viewModel.barbers.filter { barber in
            let matchesSearch = searchText.isEmpty ||
                barber.name.lowercased().contains(searchText.lowercased()) ||
                barber.city.lowercased().contains(searchText.lowercased())

            let matchesFavorite = !showFavoritesOnly || barber.isFavorite

            return matchesSearch && matchesFavorite
        }
    }

    var body: some View {
        NavigationStack {
            
            VStack(alignment: .leading, spacing: 12) {
                
                NavigationLink("💬 Mes messages") {
                    ChatListView()
                }
                .padding(.horizontal)
                
                NavigationLink("📅 Mes réservations") {
                    ClientBookingsView()
                }
                
                NavigationLink {
                    LiveDiscoveryView()
                } label: {
                    CutlyLiveCard()
                }
                .buttonStyle(PlainButtonStyle())
                
                
                TextField("Rechercher un coiffeur...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Toggle("Afficher mes favoris", isOn: $showFavoritesOnly)
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Chargement des coiffeurs...")
                    Spacer()
                }
                else if filteredBarbers.isEmpty {
                    Spacer()
                    Text("Aucun coiffeur trouvé")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
                else {
                    
                    List(filteredBarbers) { barber in
                        
                        
                        
                        VStack(alignment: .leading, spacing: 10) {
                            
                            // ============================
                            // 🔹 ZONE PROFIL (SEULEMENT ÇA EST NAVIGABLE)
                            // ============================
                            
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
                                    .frame(width: 50, height: 50)
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
                                    
                                    Image(systemName: barber.isFavorite ? "heart.fill" : "heart")
                                        .foregroundColor(barber.isFavorite ? .red : .gray)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(PlainButtonStyle()) // 🔥 CLÉ : empêche les conflits
                            .contentShape(Rectangle())       // 🔥 CLÉ : zone de clic propre
                            
                            Divider()
                            
                            // ============================
                            // 🔹 ZONE ACTIONS (TOTALMENT INDÉPENDANTE)
                            // ============================
                            
                            HStack {
                                
                                Button("📅 Réserver") {
                                    handleAction(barber: barber, action: .book)
                                }
                                .foregroundColor(.blue)
                                .buttonStyle(BorderlessButtonStyle())
                                
                                Spacer()
                                
                                Button("📞 Appeler") {
                                    handleAction(barber: barber, action: .call)
                                }
                                .foregroundColor(.orange)
                                .buttonStyle(BorderlessButtonStyle())
                                
                                Spacer()
                                
                                Button("💬 WhatsApp") {
                                    handleAction(barber: barber, action: .whatsapp)
                                }
                                .foregroundColor(.green)
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowInsets(EdgeInsets())      // 🔥 CLÉ : évite les zones “fantômes”
                        .listRowBackground(Color.clear)   // 🔥 CLÉ : évite les superpositions
                    }
                }
            }
            .navigationTitle("Coiffeurs")
            .onAppear {
                viewModel.fetchBarbers()
            }
            .sheet(isPresented: $showLoginSheet, onDismiss: {
                if Auth.auth().currentUser != nil {
                    performPendingAction()
                }
            }) {
                LoginView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Logout") {
                    try? Auth.auth().signOut()
                    print("🔴 Déconnecté")
                }
            }
        }
    }

    func handleAction(barber: Barber, action: PendingAction) {

        selectedBarberForAction = barber
        pendingAction = action

        if Auth.auth().currentUser == nil {
            showLoginSheet = true
        } else {
            performPendingAction()
        }
    }

    func performPendingAction() {

        guard let barber = selectedBarberForAction,
              let action = pendingAction else { return }

        switch action {

        case .call:
            let cleaned = barber.phone.replacingOccurrences(of: " ", with: "")
            if let url = URL(string: "tel://\(cleaned)") {
                UIApplication.shared.open(url)
            }

        case .whatsapp:
            let cleaned = barber.phone.replacingOccurrences(of: " ", with: "")
            let whatsappURL = "https://wa.me/\(cleaned)"
            if let url = URL(string: whatsappURL) {
                UIApplication.shared.open(url)
            }

        case .book:
            print("👉 Réserver avec \(barber.name)")
        }
    }
}
struct CutlyLiveCard: View {
    var body: some View {
        HStack(spacing: 14) {
            
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 54, height: 54)
                
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("CUTLY LIVE")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                
                Text("Découvre les coiffeurs en direct")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.black,
                    Color.red.opacity(0.85),
                    Color.purple.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .red.opacity(0.35), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }
}
