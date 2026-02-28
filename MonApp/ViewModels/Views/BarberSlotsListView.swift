import SwiftUI
import FirebaseFirestore

// MARK: - Slots List View (CORRIGÉE)
struct BarberSlotsListView: View {
    
    /// ⚠️ IMPORTANT : ICI ON REÇOIT L’AUTH ID DU BARBER (PAS le documentID)
    let barberId: String
    
    @State private var slots: [AvailabilitySlot] = []
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Chargement des créneaux...")
                    .padding()
            }
            else if slots.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Aucun créneau programmé")
                        .foregroundColor(.gray)
                }
                .padding()
            }
            else {

                List {
                    ForEach(groupSlotsByDate(), id: \.0) { (date, daySlots) in

                        Section(header: Text(date, style: .date)) {

                            ForEach(daySlots) { slot in

                                HStack(alignment: .top, spacing: 12) {

                                    // Indicateur couleur
                                    Circle()
                                        .fill(colorForStatus(slot.status))
                                        .frame(width: 12, height: 12)
                                        .padding(.top, 4)

                                    VStack(alignment: .leading, spacing: 6) {

                                        HStack {
                                            Text("De :")
                                            Text(slot.startTime, style: .time)
                                                .font(.subheadline)

                                            Text("à")
                                                .padding(.horizontal, 4)

                                            Text(slot.endTime, style: .time)
                                                .font(.subheadline)
                                        }

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

                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .refreshable {
                    loadSlots()
                }
            }
        }
        .navigationTitle("Mes créneaux")
        .onAppear {
            loadSlots()
        }
    }
    
    // ======================================================
    // 🔥 CHARGEMENT FIRESTORE (CORRIGÉ & ALIGNÉ)
    // ======================================================
    func loadSlots() {
        isLoading = true

        print("🟦 DEBUG — loadSlots() avec barberId :", barberId)

        db.collection("slots")
            .whereField("barberId", isEqualTo: barberId)   // ✅ BON FILTRE (AUTH ID)
            .order(by: "date", descending: false)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Erreur chargement slots:", error.localizedDescription)
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.slots = []
                    }
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("⚠️ Aucun slot trouvé pour ce barber (BarberSlotsListView)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.slots = []
                    }
                    return
                }

                print("✅ Slots trouvés :", documents.count)

                let loadedSlots = documents.compactMap { doc -> AvailabilitySlot? in
                    let data = doc.data()

                    guard
                        let dateTS = data["date"] as? Timestamp,
                        let startTS = data["startTime"] as? Timestamp,
                        let endTS = data["endTime"] as? Timestamp,
                        let statusRaw = data["status"] as? String
                    else {
                        print("⚠️ Données manquantes dans slot:", data)
                        return nil
                    }

                    return AvailabilitySlot(
                        id: doc.documentID,        // ✅ ON GARDE L’ID FIRESTORE
                        barberId: barberId,        // ✅ ON GARDE L’AUTH ID
                        date: dateTS.dateValue(),
                        startTime: startTS.dateValue(),
                        endTime: endTS.dateValue(),
                        status: SlotStatus(rawValue: statusRaw) ?? .available
                    )
                }

                DispatchQueue.main.async {
                    self.slots = loadedSlots
                    self.isLoading = false
                    print("🟢 Slots transformés :", loadedSlots.count)
                }
            }
    }

    // ======================================================
    // 🔥 REGROUPEMENT PAR JOUR (PROPRE)
    // ======================================================
    func groupSlotsByDate() -> [(Date, [AvailabilitySlot])] {
        let grouped = Dictionary(grouping: slots) { slot in
            Calendar.current.startOfDay(for: slot.date)
        }

        return grouped
            .map { ($0.key, $0.value.sorted { $0.startTime < $1.startTime }) }
            .sorted { $0.0 < $1.0 }
    }
    
    // ======================================================
    // 🔥 HELPERS (ALIGNÉS AVEC TON PROJET)
    // ======================================================
    
    func colorForStatus(_ status: SlotStatus) -> Color {
        switch status {
        case .available:
            return .green
        case .booked:
            return .red
        case .pending:
            return .orange
        case .notWorking:
            return .yellow
        }
    }
    
    func labelForStatus(_ status: SlotStatus) -> String {
        switch status {
        case .available:
            return "Libre"
        case .booked:
            return "Pris"
        case .pending:
            return "En attente"
        case .notWorking:
            return "Pause"
        }
    }
}
