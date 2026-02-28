import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI

struct BarberProfileView: View {
    
    // =============================
    // INFOS PRINCIPALES
    // =============================
    
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
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
                    } else {
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
    
    // =============================
    // SAUVEGARDE
    // =============================
    
    func saveProfile() {

        guard !barberId.isEmpty else {
            print("❌ barberId vide")
            return
        }

        let data: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "streetAddress": streetAddress,
            "buildingNumber": buildingNumber,
            "city": city,
            "postalCode": postalCode,
            "description": description,
            "services": services,
            "isProfessional": isProfessional,
            "stripeEnabled": stripeEnabled,
            "onlyByAppointment": onlyByAppointment,
            "profileCompleted": true,

            // 🔥 IMPORTANT POUR STRIPE
            "role": "barber",
            "acceptsOnlinePayment": stripeEnabled,
            "platformCommissionRate": 0.15,
            "payoutEnabled": false
        ]

        db.collection("users").document(barberId).setData(data, merge: true) { error in

            if let error = error {
                print("❌ Erreur sauvegarde profil:", error.localizedDescription)
                return
            }

            print("✅ Profil barber sauvegardé dans users")

            showSuccessMessage = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                goToAvailability = true
            }
        }
    }
    
}
