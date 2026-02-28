import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AvailabilityView: View {

    // 🔥 FIRESTORE
    let db = Firestore.firestore()

    // 🧑‍✂️ COIFFEUR
    let barberId = Auth.auth().currentUser?.uid ?? ""

    // 📅 ÉTATS
    @State private var selectedDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var message = ""

    // ✅ NOUVEAU (SANS SUPPRIMER RIEN)
    @State private var goToBarberDashboard = false

    var body: some View {
        NavigationStack {

            VStack(spacing: 20) {

                Text("📅 Mes créneaux disponibles")
                    .font(.title)
                    .fontWeight(.bold)

                // 📆 DATE
                DatePicker(
                    "Jour",
                    selection: $selectedDate,
                    displayedComponents: .date
                )

                // ⏰ HEURE DÉBUT
                DatePicker(
                    "Heure de début",
                    selection: $startTime,
                    displayedComponents: .hourAndMinute
                )

                // ⏰ HEURE FIN
                DatePicker(
                    "Heure de fin",
                    selection: $endTime,
                    displayedComponents: .hourAndMinute
                )

                // 💾 ENREGISTRER
                Button("Ajouter ce créneau") {
                    saveAvailability()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)

                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(.blue)
                        .font(.footnote)
                }

                Spacer()

                // ✅ NOUVEAU : Navigation automatique vers l’espace coiffeur
                NavigationLink(
                    destination: BarberDashboardView(),
                    isActive: $goToBarberDashboard
                ) {
                    EmptyView()
                }
            }
            .padding()
        }
    }

    // MARK: - FIRESTORE
    func saveAvailability() {
        guard !barberId.isEmpty else { return }

        let availabilityData: [String: Any] = [
            "barberId": barberId,
            "date": Timestamp(date: selectedDate),
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "isBooked": false,
            "createdAt": Timestamp(date: Date())
        ]

        // 1️⃣ — Sauvegarde dans "availabilities" (TON EXISTANT — GARDÉ)
        db.collection("availabilities").addDocument(data: availabilityData) { error in
            if let error = error {
                message = "❌ Erreur : \(error.localizedDescription)"
            } else {
                message = "✅ Créneau ajouté avec succès"

                // 2️⃣ — NOUVEAU : ON DUPLIQUE AUSSI DANS "slots"
                // (pour que BarberDetailView les lise correctement)
                let slotData: [String: Any] = [
                    "barberId": barberId,
                    "date": Timestamp(date: selectedDate),
                    "startTime": Timestamp(date: startTime),
                    "endTime": Timestamp(date: endTime),
                    "isBooked": false,
                    "status": "available",
                    "createdAt": Timestamp(date: Date())
                ]

                db.collection("slots").addDocument(data: slotData)

                // 3️⃣ — NOUVEAU : après succès → direction TON espace coiffeur
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    goToBarberDashboard = true
                }
            }
        }
    }
}
