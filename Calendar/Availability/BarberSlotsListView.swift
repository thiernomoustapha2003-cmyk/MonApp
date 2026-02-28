import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Slots List View
struct BarberSlotsListView: View {

    let barberId: String

    @State private var slots: [AvailabilitySlot] = []   // ✅ <-- IMPORTANT
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Chargement des créneaux...")
                    .padding()
            }
            else if slots.isEmpty {
                Text("Aucun créneau disponible")
                    .foregroundColor(.gray)
                    .padding()
            }
            else {
                List(slots) { slot in
                    VStack(alignment: .leading, spacing: 6) {

                        Text(slot.date, style: .date)
                            .font(.headline)

                        HStack {
                            Text("De :")
                            Text(slot.startTime, style: .time)
                                .font(.subheadline)

                            Text("à")
                                .padding(.horizontal, 4)

                            Text(slot.endTime, style: .time)
                                .font(.subheadline)
                        }

                        HStack {
                            Spacer()

                            Text(labelForStatus(slot.status))
                                .font(.caption)
                                .padding(6)
                                .background(
                                    colorForStatus(slot.status).opacity(0.2)
                                )
                                .foregroundColor(
                                    colorForStatus(slot.status)
                                )
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Mes créneaux")
        .onAppear {
            loadSlots()
        }
    }

    // MARK: - Firestore
    func loadSlots() {
        isLoading = true

        db.collection("barbers")
            .document(barberId)
            .collection("availability")
            .order(by: "date", descending: false)
            .getDocuments { snapshot, error in

                isLoading = false

                if let error = error {
                    print("❌ Erreur chargement slots:", error.localizedDescription)
                    return
                }

                guard let documents = snapshot?.documents else {
                    slots = []
                    return
                }

                slots = documents.compactMap { doc in
                    let data = doc.data()

                    guard
                        let dateTS = data["date"] as? Timestamp,
                        let startTS = data["startTime"] as? Timestamp,
                        let endTS = data["endTime"] as? Timestamp,
                        let statusRaw = data["status"] as? String
                    else {
                        return nil
                    }

                    return AvailabilitySlot(
                        id: doc.documentID,
                        barberId: barberId,
                        date: dateTS.dateValue(),
                        startTime: startTS.dateValue(),
                        endTime: endTS.dateValue(),
                        isBooked: data["isBooked"] as? Bool ?? false,
                        status: SlotStatus(rawValue: statusRaw) ?? .available
                    )
                }
            }
    }

    func colorForStatus(_ status: SlotStatus) -> Color {
        switch status {
        case .available: return .green
        case .booked: return .red
        case .notWorking: return .yellow
        }
    }

    func labelForStatus(_ status: SlotStatus) -> String {
        switch status {
        case .available: return "Libre"
        case .booked: return "Pris"
        case .notWorking: return "Pause"
        }
    }
}
