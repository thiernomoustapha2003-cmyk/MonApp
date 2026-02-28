import SwiftUI
import FirebaseFirestore
import CoreLocation
import Combine

// MARK: - Model Barber
struct Barber: Identifiable {
    var id: String
    var name: String
    var city: String
    var style: String
    var price: String
    var description: String
    var photoUrl: String
    var whatsapp: String
    var latitude: Double
    var longitude: Double
    var isFavorite: Bool = false
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation? = nil

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
}

// MARK: - Barber List View
struct BarberListView: View {
    @State private var barbers: [Barber] = []
    @State private var searchText: String = ""
    @StateObject private var locationManager = LocationManager()

    var filteredBarbers: [Barber] {
        if searchText.isEmpty {
            return barbers
        } else {
            return barbers.filter { $0.city.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("Rechercher par ville (ex: Vitré)", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                List(filteredBarbers) { barber in
                    NavigationLink(destination: BarberDetailView(barber: barber)) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: barber.photoUrl)) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(barber.name).font(.headline)
                                Text("📍 Ville : \(barber.city)")
                                Text("💇 Style : \(barber.style)")
                                Text("💰 Prix : \(barber.price) €")
                                Text(barber.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Coiffeurs")
            .onAppear {
                fetchBarbers()
            }
        }
    }

    func fetchBarbers() {
        let db = Firestore.firestore()
        db.collection("barbers").getDocuments { snapshot, error in
            if let error = error {
                print("Erreur Firestore : \(error)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            self.barbers = documents.map { doc in
                let data = doc.data()

                return Barber(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    city: data["city"] as? String ?? "",
                    style: data["style"] as? String ?? "",
                    price: data["price"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    photoUrl: data["photoUrl"] as? String ?? "",
                    whatsapp: data["whatsapp"] as? String ?? "",
                    latitude: data["latitude"] as? Double ?? 0.0,
                    longitude: data["longitude"] as? Double ?? 0.0,
                    isFavorite: false
                )
            }
        }
    }
}
