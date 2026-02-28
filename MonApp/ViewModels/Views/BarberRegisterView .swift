import SwiftUI
import FirebaseAuth
import MapKit
import CoreLocation
import FirebaseStorage
import FirebaseFirestore
import PhotosUI

// MARK: - Image Picker
struct BarberImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: BarberImagePicker

        init(_ parent: BarberImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Main View
struct BarberRegisterView: View {
    
    struct MapPoint: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
    
    // MARK: - Form
    @State private var name = ""
    @State private var description = ""
    @State private var price = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var houseNumber = ""
    @State private var postalCode = ""
    @State private var city = ""
    
    // MARK: - Image
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    // MARK: - Alert & Navigation
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var goToAvailability = false
    
    // MARK: - Map
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var markerPoint: MapPoint?
    @State private var route: MKRoute?
    @State private var distanceText = ""
    @State private var durationText = ""
    
    @StateObject private var locationManager = LocationManager()
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Photo
                    VStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(Text("Photo").foregroundColor(.gray))
                        }
                        
                        Button("Ajouter une photo") {
                            showImagePicker = true
                        }
                        .padding(.top, 8)
                    }
                    
                    Text("✂️ Compléter mon profil coiffeur")
                        .font(.title)
                        .bold()
                    
                    Group {
                        TextField("Nom", text: $name)
                        TextField("Description", text: $description)
                        TextField("Prix (€)", text: $price)
                            .keyboardType(.decimalPad)
                        TextField("Téléphone", text: $phone)
                        TextField("Rue", text: $street)
                        TextField("Numéro", text: $houseNumber)
                        TextField("Code postal", text: $postalCode)
                            .keyboardType(.numberPad)
                        TextField("Ville", text: $city)
                    }
                    .textFieldStyle(.roundedBorder)
                    
                    Button("📍 Vérifier l’adresse") {
                        openMap()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    if let point = markerPoint {
                        Map(coordinateRegion: $region, annotationItems: [point]) { item in
                            MapMarker(coordinate: item.coordinate)
                        }
                        .frame(height: 220)
                        .cornerRadius(12)
                    }
                    
                    if route != nil {
                        VStack(alignment: .leading) {
                            Text("🚗 Distance : \(distanceText)")
                            Text("⏱️ Durée : \(durationText)")
                        }
                    }
                    
                    Button("Enregistrer mon profil") {
                        addBarber()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
            .sheet(isPresented: $showImagePicker) {
                BarberImagePicker(image: $selectedImage)
            }
            .alert("Info", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            // ✅ REDIRECTION CORRIGÉE VERS LA GESTION DES CRÉNEAUX
            .navigationDestination(isPresented: $goToAvailability) {
                AvailabilityView()
            }
        }
    }
    
    // MARK: - Map Logic
    func openMap() {
        let address = "\(street) \(houseNumber), \(postalCode) \(city), France"
        
        CLGeocoder().geocodeAddressString(address) { placemarks, _ in
            guard let location = placemarks?.first?.location else {
                alertMessage = "❌ Adresse introuvable"
                showAlert = true
                return
            }
            
            let coord = location.coordinate
            markerPoint = MapPoint(coordinate: coord)
            region.center = coord
            
            if let userCoord = locationManager.location {
                calculateRoute(from: userCoord, to: coord)
            }
        }
    }
    
    func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .automobile
        
        MKDirections(request: request).calculate { response, _ in
            guard let route = response?.routes.first else { return }
            self.route = route
            
            distanceText = String(format: "%.1f km", route.distance / 1000)
            durationText = String(format: "%.0f min", route.expectedTravelTime / 60)
        }
    }
    
    // MARK: - Firebase
    func addBarber() {
        guard let image = selectedImage else {
            alertMessage = "❌ Ajoute une photo"
            showAlert = true
            return
        }
        
        uploadImage(image: image) { url in
            guard let url = url else {
                alertMessage = "❌ Erreur image"
                showAlert = true
                return
            }
            
            let address = "\(street) \(houseNumber), \(postalCode) \(city), France"
            
            CLGeocoder().geocodeAddressString(address) { placemarks, _ in
                guard let location = placemarks?.first?.location else {
                    alertMessage = "❌ Adresse introuvable"
                    showAlert = true
                    return
                }
                
                let coord = location.coordinate
                
                let data: [String: Any] = [
                    "name": name,
                    "description": description,
                    "price": Double(price) ?? 0,
                    "phone": phone,
                    "street": street,
                    "houseNumber": houseNumber,
                    "postalCode": postalCode,
                    "city": city,
                    "latitude": coord.latitude,
                    "longitude": coord.longitude,
                    "imageUrl": url,
                    "services": []
                ]
                
                guard let uid = Auth.auth().currentUser?.uid else { return }

                db.collection("barbers")
                    .document(uid) // 🔥 DOCUMENT ID = AUTH UID
                    .setData(data, merge: true) { error in
                        
                        DispatchQueue.main.async {
                            if let error = error {
                                alertMessage = error.localizedDescription
                            } else {
                                alertMessage = "✅ Profil enregistré !\nPassons aux créneaux."
                                goToAvailability = true
                            }
                            
                            showAlert = true
                        }
                    }
            }
        }
    }

    func uploadImage(image: UIImage, completion: @escaping (String?) -> Void) {
        let ref = Storage.storage().reference().child("barbers/\(UUID().uuidString).jpg")
        
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }
        
        ref.putData(data, metadata: nil) { _, error in
            if let error = error {
                print("❌ Erreur upload:", error.localizedDescription)
                completion(nil)
                return
            }
            
            ref.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }
}
