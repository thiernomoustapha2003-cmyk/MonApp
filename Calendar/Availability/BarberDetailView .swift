import SwiftUI
import MapKit
import FirebaseFirestore

struct BarberDetailView: View {
    
    let barber: Barber
    
    @State private var selectedDate = Date()
    @State private var clientName = ""
    @State private var clientPhone = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Photo de profil
                AsyncImage(url: URL(string: barber.photoURL ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.crop.square")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(height: 220)
                .clipped()
                .cornerRadius(12)
                
                // Infos coiffeur
                Text(barber.name)
                    .font(.title)
                    .bold()
                
                Text("📍 \(barber.city)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(barber.description)
                    .font(.body)
                
                // Prix
                VStack(alignment: .leading) {
                    Text("💰 Tarifs")
                        .font(.headline)
                    
                    Text("À partir de \(barber.minPrice, specifier: "%.0f") €")
                    Text("Jusqu’à \(barber.maxPrice, specifier: "%.0f") €")
                }
                
                Divider()
                
                // 📅 Calendrier
                VStack(alignment: .leading) {
                    Text("📅 Choisir un rendez-vous")
                        .font(.headline)
                    
                    DatePicker("Date & heure", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
                
                Divider()
                
                // 👤 Infos client
                VStack(alignment: .leading, spacing: 10) {
                    Text("👤 Vos informations")
                        .font(.headline)
                    
                    TextField("Votre nom", text: $clientName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Votre numéro", text: $clientPhone)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.phonePad)
                }
                
                // ✅ Bouton confirmer RDV
                Button(action: saveAppointment) {
                    Text("Confirmer le rendez-vous")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                }
                
                // 💬 WhatsApp
                Button(action: openWhatsApp) {
                    Text("Discuter sur WhatsApp")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                
                // 🗺️ Map
                if let lat = barber.latitude, let lon = barber.longitude {
                    MapView(latitude: lat, longitude: lon)
                        .frame(height: 200)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 🔥 Enregistrer rendez-vous Firestore
    func saveAppointment() {
        guard !clientName.isEmpty, !clientPhone.isEmpty else {
            print("❌ Infos client manquantes")
            return
        }
        
        let db = Firestore.firestore()
        
        let data: [String: Any] = [
            "barberId": barber.id ?? "",
            "barberName": barber.name,
            "clientName": clientName,
            "clientPhone": clientPhone,
            "date": selectedDate,
            "status": "confirmé"
        ]
        
        db.collection("Appointments").addDocument(data: data) { error in
            if let error = error {
                print("Erreur RDV: \(error.localizedDescription)")
            } else {
                print("✅ Rendez-vous enregistré")
            }
        }
    }
    
    // 💬 WhatsApp
    func openWhatsApp() {
        let phone = barber.phone ?? ""
        let urlString = "https://wa.me/\(phone)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}


// 🗺️ MapKit
struct MapView: UIViewRepresentable {
    
    let latitude: Double
    let longitude: Double
    
    func makeUIView(context: Context) -> MKMapView {
        MKMapView()
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
}
