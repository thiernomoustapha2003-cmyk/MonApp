import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct BarberListView: View {
    
    @State private var barbers: [Barber] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Chargement des coiffeurs...")
                } else if barbers.isEmpty {
                    Text("Aucun coiffeur trouvé 😢")
                        .font(.headline)
                        .foregroundColor(.gray)
                } else {
                    List(barbers) { barber in
                        NavigationLink(destination: BarberDetailView(barber: barber)) {
                            BarberRowView(barber: barber)
                        }
                    }
                }
            }
            .navigationTitle("Coiffeurs")
        }
        .onAppear {
            fetchBarbers()
        }
    }
    
    // 🔥 Récupération des coiffeurs depuis Firestore
    func fetchBarbers() {
        let db = Firestore.firestore()
        
        db.collection("Barber").getDocuments { snapshot, error in
            if let error = error {
                print("Erreur Firestore: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                isLoading = false
                return
            }
            
            self.barbers = documents.compactMap { doc in
                try? doc.data(as: Barber.self)
            }
            
            isLoading = false
        }
    }
}


// ✅ UI d’un coiffeur dans la liste
struct BarberRowView: View {
    let barber: Barber
    
    var body: some View {
        HStack(spacing: 12) {
            
            // Photo de profil
            AsyncImage(url: URL(string: barber.photoURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(barber.name)
                    .font(.headline)
                
                Text(barber.city)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(barber.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                Text("À partir de \(barber.minPrice, specifier: "%.0f") €")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 6)
    }
}
