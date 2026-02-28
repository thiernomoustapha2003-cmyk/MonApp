import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct BarberAvailabilityView: View {

    let barberId: String
    private let availabilityService = AvailabilityService()
    private let db = Firestore.firestore()

    @State private var slots: [AvailabilitySlot] = []
    @State private var isLoading = true
    @State private var currentWeekStart = Calendar.current.startOfDay(for: Date())

    // ======= États pour l’édition des heures =======
    @State private var selectedSlot: AvailabilitySlot?
    @State private var showTimeEditor = false
    @State private var editedStartTime = Date()
    @State private var editedEndTime = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                Text("Mes disponibilités")
                    .font(.title)
                    .bold()
                    .padding(.top)

                // ======= NAVIGATION SEMAINE =======
                HStack {
                    Button(action: previousWeek) {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text("Semaine du \(formattedWeekRange())")
                        .font(.headline)

                    Spacer()

                    Button(action: nextWeek) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                Divider()

                // ======= GRILLE CALENDRIER =======
                VStack(spacing: 8) {

                    HStack {
                        ForEach(["Lun","Mar","Mer","Jeu","Ven","Sam","Dim"], id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {

                        ForEach(0..<7) { dayIndex in

                            let day = Calendar.current.date(
                                byAdding: .day,
                                value: dayIndex,
                                to: currentWeekStart
                            ) ?? Date()

                            VStack(spacing: 6) {

                                Text(formattedDay(day))
                                    .font(.subheadline)

                                let daySlots = slotsForDay(day)

                                if daySlots.isEmpty {
                                    Text("—")
                                        .foregroundColor(.gray)
                                        .onTapGesture {
                                            createDefaultSlot(for: day)
                                        }
                                } else {

                                    ForEach(daySlots) { slot in
                                        Text(slot.startTime, style: .time)
                                            .font(.caption2)
                                            .padding(6)
                                            .frame(maxWidth: .infinity)
                                            .background(colorForStatus(slot.status).opacity(0.2))
                                            .foregroundColor(colorForStatus(slot.status))
                                            .cornerRadius(6)
                                            .onTapGesture {
                                                openTimeEditor(for: slot)
                                            }
                                            .onLongPressGesture {
                                                cycleSlotStatus(slot)
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Divider()

                // ======= LISTE DES CRÉNEAUX =======
                VStack(alignment: .leading) {
                    Text("📅 Tous mes créneaux")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)

                    if isLoading {
                        ProgressView("Chargement...")
                            .padding()
                    }
                    else if slots.isEmpty {
                        Text("Aucun créneau enregistré")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    else {
                        ForEach(slots) { slot in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(slot.date, style: .date)
                                        .font(.headline)
                                    Text("\(slot.startTime, style: .time) → \(slot.endTime, style: .time)")
                                        .font(.subheadline)
                                }

                                Spacer()

                                Text(labelForStatus(slot.status))
                                    .font(.caption)
                                    .padding(6)
                                    .background(colorForStatus(slot.status).opacity(0.2))
                                    .foregroundColor(colorForStatus(slot.status))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            .onTapGesture {
                                openTimeEditor(for: slot)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            loadSlots()
        }
        .sheet(isPresented: $showTimeEditor) {
            TimeEditorSheet(
                startTime: $editedStartTime,
                endTime: $editedEndTime,
                onSave: {
                    if let slot = selectedSlot {
                        updateSlotTime(slot)
                    }
                }
            )
        }
    }
}

// =====================================================
// MARK: - LOGIQUE
// =====================================================
extension BarberAvailabilityView {

    func loadSlots() {
        isLoading = true

        db.collection("barbers")
            .document(barberId)
            .collection("availability")
            .order(by: "date", descending: false)
            .getDocuments { snapshot, error in

                isLoading = false

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

    func createDefaultSlot(for day: Date) {

        let start = Calendar.current.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: day
        )!

        let end = Calendar.current.date(
            bySettingHour: 12,
            minute: 0,
            second: 0,
            of: day
        )!

        let newSlot = AvailabilitySlot(
            id: UUID().uuidString,
            barberId: barberId,
            date: day,
            startTime: start,
            endTime: end,
            isBooked: false,
            status: .available
        )

        availabilityService.createSlots(
            barberId: barberId,
            slots: [newSlot]
        ) { success in
            if success {
                loadSlots()
            }
        }
    }

    func cycleSlotStatus(_ slot: AvailabilitySlot) {

        guard let slotId = slot.id else { return }

        let nextStatus: SlotStatus

        switch slot.status {
        case .available:
            nextStatus = .notWorking
        case .notWorking:
            nextStatus = .booked
        case .booked:
            nextStatus = .available
        }

        let ref = db
            .collection("barbers")
            .document(barberId)
            .collection("availability")
            .document(slotId)

        ref.updateData(["status": nextStatus.rawValue]) { _ in
            loadSlots()
        }
    }

    func openTimeEditor(for slot: AvailabilitySlot) {
        selectedSlot = slot
        editedStartTime = slot.startTime
        editedEndTime = slot.endTime
        showTimeEditor = true
    }

    func updateSlotTime(_ slot: AvailabilitySlot) {

        guard let slotId = slot.id else { return }

        let ref = db
            .collection("barbers")
            .document(barberId)
            .collection("availability")
            .document(slotId)

        ref.updateData([
            "startTime": Timestamp(date: editedStartTime),
            "endTime": Timestamp(date: editedEndTime)
        ]) { error in
            if error == nil {
                loadSlots()
            }
        }
    }

    func previousWeek() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart) {
            currentWeekStart = newDate
        }
    }

    func nextWeek() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) {
            currentWeekStart = newDate
        }
    }

    func formattedWeekRange() -> String {
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: endOfWeek))"
    }

    func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    func slotsForDay(_ day: Date) -> [AvailabilitySlot] {
        let calendar = Calendar.current
        return slots.filter { calendar.isDate($0.date, inSameDayAs: day) }
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
        case .available: return "Disponible"
        case .booked: return "Réservé"
        case .notWorking: return "Fermé"
        }
    }
}

// =====================================================
// ✅ TIME EDITOR SHEET (AJOUTÉ ICI POUR SUPPRIMER L’ERREUR)
// =====================================================
struct TimeEditorSheet: View {

    @Binding var startTime: Date
    @Binding var endTime: Date
    let onSave: () -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                Text("Modifier les heures")
                    .font(.title2)
                    .bold()

                DatePicker("Heure de début", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("Heure de fin", selection: $endTime, displayedComponents: .hourAndMinute)

                Spacer()

                Button(action: {
                    onSave()
                    dismiss()
                }) {
                    Text("Enregistrer")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
}
