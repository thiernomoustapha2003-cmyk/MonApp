import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TwoFactorSetupView: View {

    @State private var phone = ""
    @State private var code = ""
    @State private var verificationID: String?
    @State private var message = ""

    var body: some View {
        Form {

            Section(header: Text("Téléphone")) {

                TextField("+33...", text: $phone)

                Button("Envoyer le code") {
                    sendCode()
                }
            }

            if verificationID != nil {

                Section(header: Text("Vérification")) {

                    TextField("Code SMS", text: $code)

                    Button("Activer 2FA") {
                        verifyCode()
                    }
                }
            }

            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Double authentification")
    }

    func sendCode() {

        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { id, error in
            if let error = error {
                message = error.localizedDescription
                return
            }

            verificationID = id
            message = "Code envoyé 📩"
        }
    }

    func verifyCode() {

        guard let verificationID = verificationID else {
            message = "Verification ID manquant"
            return
        }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )

        guard let user = Auth.auth().currentUser else {
            message = "Utilisateur non connecté"
            return
        }

        // 🔥 LA LIGNE LA PLUS IMPORTANTE
        user.link(with: credential) { result, error in

            if let error = error as NSError? {

                // déjà lié → on considère que c’est OK
                if error.code == AuthErrorCode.providerAlreadyLinked.rawValue {
                    message = "2FA déjà activé ✅"
                    return
                }

                message = error.localizedDescription
                return
            }

            message = "2FA activé ✅"

            // optionnel : flag firestore
            Firestore.firestore()
                .collection("users")
                .document(user.uid)
                .setData([
                    "phone2FA": true,
                    "phoneNumber": user.phoneNumber ?? ""
                ], merge: true)
        }
    }
    }

