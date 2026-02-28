import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine


@MainActor
class AutoConfirmBookingViewModel: ObservableObject {

    @Published var enabled = false
    @Published var message = "Votre rendez-vous est confirmé ✅ Merci pour votre réservation !"

    private var db = Firestore.firestore()

    func load() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("automation")
            .document(uid)
            .collection("settings")
            .document("autoConfirm")
            .getDocument { snap, _ in

                guard let data = snap?.data() else { return }

                self.enabled = data["enabled"] as? Bool ?? false
                self.message = data["message"] as? String ?? self.message
            }
    }

    func save() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("automation")
            .document(uid)
            .collection("settings")
            .document("autoConfirm")
            .setData([
                "enabled": enabled,
                "message": message
            ])
    }
}
