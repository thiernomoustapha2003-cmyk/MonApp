import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct BarberRegisterView: View {

    @State private var name = ""
    @State private var city = ""
    @State private var price = ""
    @State private var description = ""

    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false

    @State private var isLoading = false
    @State private var message = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                Text("Créer mon profil coiffeur ✂️")
                    .font(.title2)
                    .bold()

                // PHOTO DE PROFIL
                Button(action: {
                    showImagePicker = true
                }) {
                    if let image = selectedImage {
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

                TextField("Nom", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Ville", text: $city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Prix (€)", text: $price)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Description", text: $description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if isLoading {
                    ProgressView()
                }

                Button(action: createBarberProfile) {
                    Text("Créer mon profil")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    // ✅ FONCTION PRINCIPALE
    func createBarberProfile() {
        guard let user = Auth.auth().currentUser else {
            message = "Utilisateur non connecté"
            return
        }

        guard let image = selectedImage else {
            message = "Ajoute une photo de profil"
            return
        }

        isLoading = true

        uploadImage(image: image, userId: user.uid) { url in
            guard let url = url else {
                isLoading = false
                message = "Erreur upload photo"
                return
            }

            let db = Firestore.firestore()

            let data: [String: Any] = [
                "name": name,
                "city": city,
                "price": Int(price) ?? 0,
                "description": description,
                "photoUrl": url,
                "createdAt": Timestamp()
            ]

            db.collection("barbers").document(user.uid).setData(data) { error in
                isLoading = false
                if let error = error {
                    message = "Erreur Firestore: \(error.localizedDescription)"
                } else {
                    message = "Profil créé avec succès ✅"
                }
            }
        }
    }

    // ✅ UPLOAD IMAGE FIREBASE STORAGE
    func uploadImage(image: UIImage, userId: String, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("barbers/\(userId).jpg")

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }

        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Upload error:", error)
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let url = url {
                    completion(url.absoluteString)
                } else {
                    completion(nil)
                }
            }
        }
    }
}

