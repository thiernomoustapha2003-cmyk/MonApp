import SwiftUI
import FirebaseFirestore

struct BarberListView: View {
    
    @StateObject var viewModel = BarberViewModel()

    var body: some View {
        NavigationView {
            
            VStack {
                if viewModel.isLoading {
                    ProgressView("Chargement des coiffeurs...")
                        .padding()
                }
                else if viewModel.barbers.isEmpty {
                    Text("Aucun coiffeur trouvé")
                        .foregroundColor(.gray)
                        .padding()
                }
                else {
                    List {
                        ForEach(viewModel.barbers) { barber in
                            NavigationLink(destination: BarberDetailView(barber: barber)) {
                                
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
                                            
                                            // 🟢 Badge disponible (TU L’AS GARDÉ)
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
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Coiffeurs")
            .onAppear {
                // ✅ CLÉ DU PROBLÈME : ON APPELLE LA FONCTION ICI
                viewModel.fetchBarbers()
            }
        }
    }
}
