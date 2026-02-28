import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct BarberProfileView: View {

    @Environment(\.dismiss) var dismiss

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    let barberId = Auth.auth().currentUser?.uid ?? ""

    // =========================
    // INFORMATIONS PROFIL
    // =========================

    @State private var fullName = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var houseNumber = ""
    @State private var postalCode = ""
    @State private var city = ""
    @State private var description = ""
    @State private var servicesText = ""
    @State private var price = ""

    @State private var profileImage: UIImage? = nil
    @State private var imageUrl: String = ""
    @State private var showImagePicker = false

    // =========================
    // PAIEMENT / STRIPE
    // =========================

    @State private var isPro = false
    @State private var acceptsOnlinePayment = false
    @State private var commissionRate = "15"
    @State private var stripeAccountId = ""
    @State private var payoutEnabled = false

    // =========================
    // UI STATES
    // =========================

    @State private var isLoading = false
    @State private var message = ""
    @State private var goToDashboard = false

    var body: some View {
        NavigationStack {

            ScrollView {
                VStack(spacing: 18) {

                    Text("📸 Profil du Coiffeur")
                        .font(.title)
                        .bold()

                    // =========================
                    // PHOTO DE PROFIL
                    // =========================

                    Button {
                        showImagePicker = true
                    } label: {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                .shadow(radius: 6)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .foregroundColor(.gray)
                        }
                    }

                    Text("Changer photo de profil")
                        .font(.footnote)
                        .foregroundColor(.blue)

                    Divider()

                    // =========================
                    // INFORMATIONS PERSONNELLES
                    // =========================

                    Group {
                        TextField("Nom complet", text: $fullName)
                        TextField("Téléphone", text: $phone)
                            .keyboardType(.phonePad)

                        TextField("Rue", text: $street)
                        TextField("Numéro de maison", text: $houseNumber)
                        TextField("Code postal", text: $postalCode)
                            .keyboardType(.numberPad)
                        TextField("Ville", text: $city)

                        TextField("Prix (€)", text: $price)
                            .keyboardType(.decimalPad)

                        TextField("Services (séparés par des virgules)", text: $servicesText)

                        TextEditor(text: $description)
                            .frame(height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5))
                            )
                            .padding(.top, 5)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)

                    Divider()

                    // =========================
                    // SECTION PAIEMENT (STRIPE)
                    // =========================

                    VStack(alignment: .leading, spacing: 10) {

                        Text("💳 Paiement en ligne (Stripe)")
                            .font(.headline)

                        Toggle("Je suis un coiffeur PRO", isOn: $isPro)

                        Toggle("Autoriser paiement en ligne", isOn: $acceptsOnlinePayment)
                            .disabled(!isPro)

                        TextField("Commission plateforme (%)", text: $commissionRate)
                            .keyboardType(.numberPad)

                        TextField("Stripe Account ID (si déjà créé)", text: $stripeAccountId)

                        Toggle("Paiement automatique activé", isOn: $payoutEnabled)

                        Text("""
                        ⚠️ Note :
                        - Seuls les coiffeurs PRO peuvent recevoir des paiements en ligne.
                        - L’argent sera BLOQUÉ jusqu’à validation de la prestation.
                        """)
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(12)

                    Divider()

                    if isLoading {
                        ProgressView()
                    }

                    Button("Enregistrer mon profil") {
                        saveProfile()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                    if !message.isEmpty {
                        Text(message)
                            .foregroundColor(.blue)
                            .font(.footnote)
                    }

                    NavigationLink(
                        destination: BarberDashboardView(),
                        isActive: $goToDashboard
                    ) {
                        EmptyView()
                    }

                }
                .padding()
            }
            .navigationTitle("Profil Coiffeur")
            .sheet(isPresented: $showImagePicker) {
                BarberPhotoPicker(image: $profileImage)   // ✅ RENOMMÉ ICI
            }
        }
    }

    // =========================
    // SAUVEGARDE FIRESTORE
    // =========================

    func saveProfile() {

        guard let priceDouble = Double(price) else {
            message = "❌ Prix invalide"
            return
        }

        isLoading = true

        uploadProfileImage { url in

            let commission = Double(commissionRate) ?? 15.0
            let commissionDecimal = commission / 100

            let data: [String: Any] = [
                "name": fullName,
                "phone": phone,
                "street": street,
                "houseNumber": houseNumber,
                "postalCode": postalCode,
                "city": city,
                "description": description,
                "price": priceDouble,
                "services": servicesText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                "imageUrl": url ?? "",
                "isPro": isPro,
                "acceptsOnlinePayment": acceptsOnlinePayment,
                "platformCommissionRate": commissionDecimal,
                "stripeAccountId": stripeAccountId,
                "payoutEnabled": payoutEnabled,
                "updatedAt": Timestamp()
            ]

            db.collection("barbers").document(barberId).setData(data, merge: true) { error in
                isLoading = false

                if let error = error {
                    message = "❌ Erreur : \(error.localizedDescription)"
                } else {
                    message = "✅ Profil enregistré avec succès"

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        goToDashboard = true
                    }
                }
            }
        }
    }

    // =========================
    // UPLOAD PHOTO
    // =========================

    func uploadProfileImage(completion: @escaping (String?) -> Void) {

        guard let image = profileImage,
              let data = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }

        let ref = storage.reference().child("barbers/\(barberId).jpg")

        ref.putData(data, metadata: nil) { _, error in
            if let error = error {
                print("❌ Upload erreur:", error)
                completion(nil)
                return
            }

            ref.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }
}

// =========================
// IMAGE PICKER (RENOMMÉ)
// =========================

struct BarberPhotoPicker: UIViewControllerRepresentable {

    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        let parent: BarberPhotoPicker

        init(_ parent: BarberPhotoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }

            picker.dismiss(animated: true)
        }
    }
}
