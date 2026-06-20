import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import PhotosUI

struct BarberProfileView: View {
    
    // =============================
    // INFOS PRINCIPALES
    // =============================
    
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    
    @State private var existingImageUrl = ""
    
    @State private var phone = ""
    @State private var price = ""
    
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var streetAddress = ""
    @State private var buildingNumber = ""
    @State private var city = ""
    @State private var postalCode = ""
    @State private var description = ""
    
    // SERVICES DYNAMIQUES
    @State private var services: [String] = [""]
    
    // OPTIONS
    @State private var isProfessional = false
    @State private var stripeEnabled = false
    @State private var onlyByAppointment = true
    
    @State private var profileProgress: Double = 0
    @State private var showSuccessMessage = false
    @State private var goToAvailability = false
    
    private let db = Firestore.firestore()
    private let barberId = Auth.auth().currentUser?.uid ?? ""
    
    var body: some View {
        
        ScrollView {
            VStack(spacing: 20) {
                
                Text("Compléter votre profil")
                    .font(.title)
                    .bold()
                
                // =============================
                // PHOTO
                // =============================
                
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    }
                    else if let url = URL(string: existingImageUrl),
                            !existingImageUrl.isEmpty {

                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    }
                    else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(Text("Ajouter photo"))
                    }
                }
                .onChange(of: selectedImage) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            profileImage = uiImage
                            calculateProgress()
                        }
                    }
                }
                
                // =============================
                // INFOS TEXTE
                // =============================
                
                Group {
                    TextField("Nom & Prénom", text: $fullName)
                    TextField("Email", text: $email)
                    TextField("Adresse (rue)", text: $streetAddress)
                    TextField("Numéro bâtiment", text: $buildingNumber)
                    TextField("Ville", text: $city)
                    TextField("Code postal", text: $postalCode)
                        .keyboardType(.numberPad)
                    TextField("Description", text: $description)
                    TextField("Téléphone", text: $phone)
                        .keyboardType(.phonePad)
                    
                    TextField("Prix moyen (€)", text: $price)
                        .keyboardType(.decimalPad)
                    
                    
                }
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .onChange(of: fullName) { _ in calculateProgress() }
                .onChange(of: email) { _ in calculateProgress() }
                .onChange(of: streetAddress) { _ in calculateProgress() }
                .onChange(of: city) { _ in calculateProgress() }
                .onChange(of: postalCode) { _ in calculateProgress() }
                
                // =============================
                // SERVICES DYNAMIQUES
                // =============================
                
                VStack(alignment: .leading) {
                    Text("Services proposés")
                        .font(.headline)
                    
                    ForEach(services.indices, id: \.self) { index in
                        TextField("Service \(index + 1)", text: $services[index])
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button("➕ Ajouter un service") {
                        services.append("")
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // =============================
                // OPTIONS
                // =============================
                
                Toggle("Disponible uniquement sur rendez-vous", isOn: $onlyByAppointment)
                Toggle("Profil professionnel", isOn: $isProfessional)
                Toggle("Activer paiement en ligne (Stripe)", isOn: $stripeEnabled)
                
                // =============================
                // PROGRESSION
                // =============================
                
                VStack(alignment: .leading) {
                    Text("Profil complété à \(Int(profileProgress))%")
                    ProgressView(value: profileProgress, total: 100)
                        .tint(.blue)
                        .animation(.easeInOut, value: profileProgress)
                }
                .padding(.horizontal)
                
                // =============================
                // BOUTON VALIDER
                // =============================
                
                Button("Valider mon profil") {
                    saveProfile()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(profileProgress >= 80 ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(profileProgress < 80)
                .padding(.horizontal)
                
                if showSuccessMessage {
                    Text("✅ Profil validé avec succès")
                        .foregroundColor(.green)
                        .bold()
                }
                
                NavigationLink(
                    destination: AvailabilityView(),
                    isActive: $goToAvailability
                ) {
                    EmptyView()
                }
            }
            .padding(.top)
        }
        .navigationTitle("Profil Coiffeur")
        .onAppear {
            loadExistingProfile()
        }
    }
    
    // =============================
    // CALCUL PROGRESSION
    // =============================
    
    func calculateProgress() {
        var score = 0
        
        if profileImage != nil { score += 10 }
        if !fullName.isEmpty { score += 15 }
        if !email.isEmpty { score += 15 }
        if !streetAddress.isEmpty { score += 10 }
        if !city.isEmpty { score += 10 }
        if !postalCode.isEmpty { score += 10 }
        if !description.isEmpty { score += 10 }
        if services.contains(where: { !$0.isEmpty }) { score += 10 }
        
        profileProgress = Double(score)
    }
    
    func loadExistingProfile() {
        guard !barberId.isEmpty else { return }

        db.collection("users").document(barberId).getDocument { snapshot, error in
            if let error = error {
                print("❌ Erreur chargement profil:", error.localizedDescription)
                return
            }

            let data = snapshot?.data() ?? [:]

            DispatchQueue.main.async {
                self.fullName = data["fullName"] as? String ?? data["name"] as? String ?? ""
                self.email = data["email"] as? String ?? ""
                self.phone = data["phone"] as? String ?? ""
                self.price = String(format: "%.2f", data["price"] as? Double ?? 0.0)
                self.streetAddress = data["streetAddress"] as? String ?? data["street"] as? String ?? ""
                self.buildingNumber = data["buildingNumber"] as? String ?? data["houseNumber"] as? String ?? ""
                self.city = data["city"] as? String ?? ""
                self.postalCode = data["postalCode"] as? String ?? ""
                self.description = data["description"] as? String ?? ""
                self.services = data["services"] as? [String] ?? [""]
                if self.services.isEmpty { self.services = [""] }

                self.isProfessional = data["isProfessional"] as? Bool ?? false
                self.stripeEnabled = data["acceptsOnlinePayment"] as? Bool ?? false
                self.onlyByAppointment = data["onlyByAppointment"] as? Bool ?? true
                self.existingImageUrl = data["imageUrl"] as? String ?? ""

                self.calculateProgress()
            }
        }
    }
    
    
    // =============================
    // SAUVEGARDE
    // =============================
    
    func saveProfile() {
        
        guard !barberId.isEmpty else {
            print("❌ barberId vide")
            return
        }
        
        uploadProfileImage { uploadedImageUrl in
            
            let data: [String: Any] = [
                "imageUrl": uploadedImageUrl ?? "",
                "name": fullName,
                "fullName": fullName,
                "email": email,
                "phone": phone,
                "price": Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                
                "streetAddress": streetAddress,
                "street": streetAddress,
                "buildingNumber": buildingNumber,
                "houseNumber": buildingNumber,
                "city": city,
                "postalCode": postalCode,
                "description": description,
                "services": services.filter { !$0.isEmpty },
                
                "profileCompleted": true,
                "role": "coiffeur",
                "acceptsOnlinePayment": stripeEnabled,
                "platformCommissionRate": 0.15,
                "payoutEnabled": false
            ]
            
            db.collection("users").document(barberId).setData(data, merge: true) { error in
                
                if let error = error {
                    print("❌ Erreur sauvegarde profil:", error.localizedDescription)
                    return
                }
                
                print("✅ Profil barber sauvegardé dans users avec image")
                
                DispatchQueue.main.async {
                    showSuccessMessage = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        goToAvailability = true
                    }
                }
            }
        }
    }
    
    func uploadProfileImage(completion: @escaping (String?) -> Void) {
        guard let image = profileImage,
              let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }

        let ref = Storage.storage().reference()
            .child("barber_profiles/\(barberId).jpg")

        ref.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("❌ Upload image:", error.localizedDescription)
                completion(nil)
                return
            }

            ref.downloadURL { url, error in
                if let error = error {
                    print("❌ URL image:", error.localizedDescription)
                    completion(nil)
                    return
                }

                completion(url?.absoluteString)
            }
        }
    }
    
}
