import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI

struct BusinessSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    
    @State private var selectedPhotosPickerItems: [PhotosPickerItem] = []
    
    
    @State private var likedImages: [String: Set<Int>] = [:]
    
    // MARK: - STATES BUSINESS
    
    @State private var salonName: String = ""
    @State private var city: String = ""
    @State private var houseNumber: String = ""
    @State private var price: String = ""
    @State private var isLoading = false
    
    
    // MARK: - SERVICES
    
    @State private var services: [Service] = []
    @State private var showAddServiceSheet = false
    
    @State private var newServiceName = ""
    @State private var newServicePrice = ""
    @State private var newServiceDuration = ""
    @State private var newServiceDescription = ""
    
    @State private var selectedImages: [UIImage] = []
    
    // MARK: - STATES SHEETS
    
    @State private var showNameSheet = false
    @State private var showAddressSheet = false
    @State private var showPriceSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                Text("🏢 Paramètres Business")
                    .font(.title2)
                    .bold()
                
                Button("Modifier nom du salon") {
                    showNameSheet = true
                }
                
                Button("Changer adresse") {
                    showAddressSheet = true
                }
                
                Button("Gérer les services") {
                    showAddServiceSheet = true
                }
                
                Button("Fermer") {
                    dismiss()
                }
                .padding(.top, 20)
                
            }
            .padding()
            .onAppear {
                loadBusinessInfo()
                loadServices()
            }
        }
        
        // =====================================================
        // MARK: - SHEET MODIFIER NOM
        // =====================================================
        
        .sheet(isPresented: $showNameSheet) {
            VStack(spacing: 20) {
                
                Text("Modifier nom du salon")
                    .font(.headline)
                
                TextField("Nom du salon", text: $salonName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Enregistrer") {
                    saveSalonName()
                    showNameSheet = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        
        // =====================================================
        // MARK: - SHEET MODIFIER ADRESSE
        // =====================================================
        
        .sheet(isPresented: $showAddressSheet) {
            VStack(spacing: 20) {
                
                Text("Changer adresse")
                    .font(.headline)
                Button("Modifier prix global") {
                    showPriceSheet = true
                }
                TextField("Ville", text: $city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                TextField("Numéro de rue", text: $houseNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Enregistrer") {
                    saveAddress()
                    showAddressSheet = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        
        // =====================================================
        // MARK: - SHEET MODIFIER PRIX
        // =====================================================
        
        .sheet(isPresented: $showPriceSheet) {
            VStack(spacing: 20) {
                
                Text("Paramétrer prix")
                    .font(.headline)
                
                TextField("Prix (€)", text: $price)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Enregistrer") {
                    savePrice()
                    showPriceSheet = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        
        
        
        // MARK: - SHEET SERVICES
        
        .sheet(isPresented: $showAddServiceSheet) {
            
            NavigationStack {
                
                VStack(spacing: 20) {
                    
                    Text("Mes Services")
                        .font(.title2)
                        .bold()

                    // 🔥 MINI TABLEAU STATS
                    HStack(spacing: 20) {

                        VStack {
                            Text("\(services.count)")
                                .font(.title3)
                                .bold()
                            Text("Services")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        VStack {
                            Text("\(services.reduce(0) { $0 + $1.likesCount })")
                                .font(.title3)
                                .bold()
                            Text("Likes")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        VStack {
                            let totalValue = services.reduce(0) { $0 + $1.price }
                            Text("\(Int(totalValue)) €")
                                .font(.title3)
                                .bold()
                            Text("Valeur")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(16)

                    
                    ScrollView {
                        if services.isEmpty {
                            Text("Aucun service pour le moment")
                                .foregroundColor(.gray)
                        }
                       
                        ForEach(services) { service in
                            if let barberId = Auth.auth().currentUser?.uid {
                                ServiceCardView(service: service,
                                                barberId: barberId,
                                                isOwner: true)
                            }
                        }
                        
                    }
                    
                    Divider()
                    
                    Text("Ajouter un service")
                        .font(.headline)
                    
                    TextField("Nom du service", text: $newServiceName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Prix (€)", text: $newServicePrice)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Durée (minutes)", text: $newServiceDuration)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description", text: $newServiceDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    PhotosPicker(
                        selection: $selectedPhotosPickerItems,
                        maxSelectionCount: 3,
                        matching: .images
                    ) {
                        Text("Ajouter des photos (max 3 gratuites)")
                            .foregroundColor(.blue)
                    }
                    
                    .onChange(of: selectedPhotosPickerItems) { newItems in
                        selectedImages.removeAll()
                        
                        for item in newItems {
                            Task {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImages.append(uiImage)
                                }
                            }
                        }
                    }
                    
                    Button("Ajouter") {
                        saveService()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                }
                .padding()
                .onAppear {
                    loadServices()
                }
            }
        }
        
    }
    // =====================================================
    // MARK: - CHARGEMENT DES DONNÉES FIRESTORE
    // =====================================================
    
    private func loadBusinessInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        db.collection("barbers").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                
                salonName = data["salonName"] as? String ?? ""
                city = data["city"] as? String ?? ""
                houseNumber = data["houseNumber"] as? String ?? ""
                
                if let priceValue = data["price"] as? Int {
                    price = "\(priceValue)"
                }
            }
        }
    }
    
    // =====================================================
    // MARK: - FONCTIONS SAUVEGARDE FIRESTORE
    // =====================================================
    
    private func saveSalonName() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("barbers")
            .document(uid)
            .updateData([
                "salonName": salonName
            ])
    }
    
    private func saveAddress() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("barbers")
            .document(uid)
            .updateData([
                "city": city,
                "houseNumber": houseNumber
            ])
    }
    
    private func savePrice() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if let priceInt = Int(price) {
            Firestore.firestore()
                .collection("barbers")
                .document(uid)
                .updateData([
                    "price": priceInt
                ])
        }
    }
    
    // MARK: - LOAD SERVICES
    private func saveService() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        guard
            let price = Double(newServicePrice),
            let duration = Int(newServiceDuration)
        else { return }
        
        if selectedImages.count > 3 {
            print("⚠️ Limite gratuite atteinte")
            return
        }
        
        let db = Firestore.firestore()
        
        // 1️⃣ Créer document vide d'abord pour obtenir ID
        let serviceRef = db
            .collection("barbers")
            .document(uid)
            .collection("services")
            .document()
        
        let serviceId = serviceRef.documentID
        
        // 2️⃣ Upload images
        uploadImages(uid: uid, serviceId: serviceId) { urls in
            
            let service = Service(
                id: serviceId,
                name: newServiceName,
                price: price,
                duration: duration,
                description: newServiceDescription,
                imageURLs: urls,
                isPremium: false,
                isActive: true,
                likesCount: 0,
                likedBy: []
            )
            
            do {
                try serviceRef.setData(from: service)
                
                DispatchQueue.main.async {
                    newServiceName = ""
                    newServicePrice = ""
                    newServiceDuration = ""
                    newServiceDescription = ""
                    selectedImages = []
                    loadServices()
                }
                
            } catch {
                print("Erreur ajout service:", error)
            }
        }
    }
    
    
    // =====================================================
    // MARK: - LOAD SERVICES
    // =====================================================
    
    private func loadServices() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ Aucun utilisateur connecté")
            return
        }

        print("✅ UID connecté:", uid)

        Firestore.firestore()
            .collection("barbers")
            .document(uid)
            .collection("services")
            .getDocuments { snapshot, error in

                if let error = error {
                    print("❌ Erreur chargement services:", error)
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("❌ Aucun document trouvé")
                    return
                }

                print("📦 Nombre de services trouvés:", documents.count)

                var loadedServices: [Service] = []

                for doc in documents {
                    let data = doc.data()

                    let service = Service(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        price: data["price"] as? Double ?? 0,
                        duration: data["duration"] as? Int ?? 0,
                        description: data["description"] as? String ?? "",
                        imageURLs: data["imageURLs"] as? [String] ?? [],
                        isPremium: data["isPremium"] as? Bool ?? false,
                        isActive: data["isActive"] as? Bool ?? true,   // ✅ AJOUTE ÇA
                        likesCount: data["likesCount"] as? Int ?? 0,
                        likedBy: data["likedBy"] as? [String] ?? []
                    )

                    loadedServices.append(service)
                }

                DispatchQueue.main.async {
                    self.services = loadedServices
                    
                    print("🔥 Services chargés :", loadedServices.count)
                    print("✅ Services chargés dans la vue:", loadedServices.count)
                }
            }
    }
    
    private func uploadImages(uid: String, serviceId: String, completion: @escaping ([String]) -> Void) {
        
        print("🚀 Upload lancé")
        print("Nombre images:", selectedImages.count)
        print("Service ID:", serviceId)
        print("UID:", uid)
        
        let storage = Storage.storage()
        let group = DispatchGroup()
        
        var urls: [String] = []
        let lock = NSLock()   // 🔐 protège l'accès concurrent
        
        for (index, image) in selectedImages.enumerated() {
            
            group.enter()
            
            let imageRef = storage.reference()
                .child("serviceImages/(uid)/(serviceId)/image(index).jpg")
            
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                print("❌ Impossible de convertir l'image en data")
                group.leave()
                continue
            }
            
            // 🔥 IMPORTANT : metadata obligatoire sinon downloadURL peut être nil
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            imageRef.putData(imageData, metadata: metadata) { _, error in
                
                if let error = error {
                    print("❌ Upload error:", error.localizedDescription)
                    group.leave()
                    return
                }
                
                // attendre que Firebase indexe vraiment le fichier
                imageRef.downloadURL { url, error in
                    
                    if let error = error {
                        print("❌ URL error:", error.localizedDescription)
                        group.leave()
                        return
                    }
                    
                    if let url = url {
                        print("📸 URL récupérée:", url.absoluteString)
                        lock.lock()
                        urls.append(url.absoluteString)
                        lock.unlock()
                    } else {
                        print("❌ URL nil")
                    }
                    
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            print("✅ Upload terminé, URLs:", urls)
            completion(urls)
        }
    }
    private func toggleLike(for serviceId: String, imageIndex: Int) {
        if likedImages[serviceId]?.contains(imageIndex) == true {
            likedImages[serviceId]?.remove(imageIndex)
        } else {
            likedImages[serviceId, default: []].insert(imageIndex)
        }
    }
    
    private func isLiked(_ serviceId: String, _ imageIndex: Int) -> Bool {
        likedImages[serviceId]?.contains(imageIndex) ?? false
    }
    
    
    private func toggleLike(service: Service, barberId: String) {
        guard let uid = Auth.auth().currentUser?.uid,
              let serviceId = service.id else { return }
        
        let db = Firestore.firestore()
        
        let serviceRef = db
            .collection("barbers")
            .document(barberId)
            .collection("services")
            .document(serviceId)
        
        serviceRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  var likedBy = data["likedBy"] as? [String] else { return }
            
            if likedBy.contains(uid) {
                // 👎 UNLIKE
                likedBy.removeAll { $0 == uid }
                serviceRef.updateData([
                    "likedBy": likedBy,
                    "likesCount": FieldValue.increment(Int64(-1))
                ])
            } else {
                // ❤️ LIKE
                likedBy.append(uid)
                serviceRef.updateData([
                    "likedBy": likedBy,
                    "likesCount": FieldValue.increment(Int64(1))
                ])
            }
        }
    }
}
