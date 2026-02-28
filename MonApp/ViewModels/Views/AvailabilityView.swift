import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AvailabilityView: View {

    @State private var selectedSlot: AvailabilitySlot?

    let db = Firestore.firestore()

    var barberProfileId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    // ===== ÉTATS PRINCIPAUX =====
    @State private var currentWeekStart: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var message = ""
    @State private var showSuccessIcon = false
    @State private var goToBarberDashboard = false

    @State private var mySlots: [AvailabilitySlot] = []
    @State private var selectedDays: Set<Int> = []
    @State private var repeatWeeks: Int = 1

    // ===== SHEETS (FENÊTRES MODALES) =====
    @State private var showAddSingleSheet = false
    @State private var showMultiDaySheet = false
    @State private var showDuplicateWeekSheet = false
    @State private var showDuplicateWeeksSheet = false
    @State private var showBlockSheet = false
    @State private var showDeleteSheet = false
    @State private var showExpertSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    Text("📅 Gestion avancée des créneaux (PRO)")
                        .font(.title2)
                        .bold()

                    Divider()

                    // ===== SÉLECTION DATE =====
                    VStack(alignment: .leading, spacing: 6) {
                        Text("📆 Date de référence")
                            .font(.headline)

                        DatePicker(
                            "Choisir une date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                    }

                    Divider()

                    calendarHeader
                    weekCalendarGrid

                    Divider()

                    // ===== HEURES =====
                    VStack(alignment: .leading, spacing: 6) {
                        Text("⏰ Heures du créneau")
                            .font(.headline)

                        DatePicker("Heure de début",
                                   selection: $startTime,
                                   displayedComponents: .hourAndMinute)

                        DatePicker("Heure de fin",
                                   selection: $endTime,
                                   displayedComponents: .hourAndMinute)
                    }

                    Divider()

                    // =========================
                    // 🔥 7 OPTIONS PRINCIPALES
                    // =========================

                    VStack(spacing: 12) {

                        Button("1️⃣ Ajouter un créneau (jour unique)") {
                            showAddSingleSheet = true
                        }
                        .buttonStyle(MainButtonStyle(color: .green))

                        Button("2️⃣ Appliquer aux jours sélectionnés") {
                            showMultiDaySheet = true
                        }
                        .buttonStyle(MainButtonStyle(color: .blue))

                        Button("3️⃣ Dupliquer sur toute la semaine") {
                            showDuplicateWeekSheet = true
                        }
                        .buttonStyle(MainButtonStyle(color: .purple))

                        Button("4️⃣ Dupliquer sur X semaines") {
                            showDuplicateWeeksSheet = true
                        }
                        .buttonStyle(MainButtonStyle(color: .orange))

                        Button("5️⃣ Bloquer / Débloquer jours") {
                            showBlockSheet = true
                        }
                        .buttonStyle(MainButtonStyle(color: .red))

                        Button("6️⃣ Supprimer / Remplacer créneaux") {
                            showDeleteSheet = true
                        }
                        .buttonStyle(MainButtonStyle(color: .gray))

                        Button("7️⃣ Mode expert (avancé)") {
                            showExpertSheet = true
                        }
                        .buttonStyle(MainButtonStyle(color: .black))
                    }

                    if showSuccessIcon {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                            .transition(.scale)
                    }

                    NavigationLink(
                        destination: BarberDashboardView(),
                        isActive: $goToBarberDashboard
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
                .padding()
            }
            .onAppear {
                fetchMySlots()
            }
        }
        // ===== FENÊTRES MODALES =====
        .sheet(isPresented: $showAddSingleSheet) {
            AddSingleSlotSheet(
                selectedDate: $selectedDate,
                startTime: $startTime,
                endTime: $endTime,
                onSave: saveAvailability
            )
        }
        .sheet(isPresented: $showMultiDaySheet) {
            MultiDaySheet(
                selectedDays: $selectedDays,
                repeatWeeks: $repeatWeeks,
                onSave: saveMultipleAvailability
            )
        }
        .sheet(isPresented: $showDuplicateWeekSheet) {
            DuplicateWeekSheet(onSave: duplicateWholeWeek)
        }
        .sheet(isPresented: $showDuplicateWeeksSheet) {
            DuplicateWeeksSheet(
                repeatWeeks: $repeatWeeks,
                onSave: duplicateForWeeks
            )
        }
        
        .sheet(isPresented: $showDeleteSheet) {
            DeleteReplaceSheet(
                selectedDate: $selectedDate,
                onDelete: deleteSlotsForSelectedDate,
                onReplace: replaceSlotsForDay
            )
        }
        .sheet(isPresented: $showExpertSheet) {
            ExpertSheet(
                selectedDate: $selectedDate,
                startTime: $startTime,
                endTime: $endTime,
                onSave: saveAvailability
            )
        }
    }

    // ========== CALENDRIER (IDENTIQUE À AVANT) ==========
    var calendarHeader: some View {
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
    }

    var weekCalendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(0..<7) { dayIndex in

                let isSelected = selectedDays.contains(dayIndex)

                Text(isSelected ? "✓" : "•")
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(isSelected ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .cornerRadius(8)
                    .onTapGesture {
                        if selectedDays.contains(dayIndex) {
                            selectedDays.remove(dayIndex)
                        } else {
                            selectedDays.insert(dayIndex)
                        }
                    }
            }
        }
        .padding(.horizontal)
    }

    func previousWeek() {
        currentWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart) ?? currentWeekStart
    }

    func nextWeek() {
        currentWeekStart = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
    }

    func formattedWeekRange() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM"

        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart

        return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: endDate))"
    }

    // ========== FIRESTORE ACTIONS ==========

    func saveAvailability() {
        let calendar = Calendar.current
        let correctedDate = calendar.startOfDay(for: selectedDate)

        let finalStart = calendar.date(
            bySettingHour: calendar.component(.hour, from: startTime),
            minute: calendar.component(.minute, from: startTime),
            second: 0,
            of: correctedDate
        )!

        let finalEnd = calendar.date(
            bySettingHour: calendar.component(.hour, from: endTime),
            minute: calendar.component(.minute, from: endTime),
            second: 0,
            of: correctedDate
        )!

        let slotData: [String: Any] = [
            "barberId": barberProfileId,
            "date": Timestamp(date: correctedDate),
            "startTime": Timestamp(date: finalStart),
            "endTime": Timestamp(date: finalEnd),
            "status": "available",
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("slots").addDocument(data: slotData) { _ in
            showSuccess()
            fetchMySlots()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                goToBarberDashboard = true
            }
        }
    }

    func saveMultipleAvailability() {
        let batch = db.batch()
        let calendar = Calendar.current

        for week in 0..<repeatWeeks {
            for dayIndex in selectedDays {

                let targetDate = calendar.date(
                    byAdding: .day,
                    value: dayIndex + (7 * week),
                    to: currentWeekStart
                ) ?? selectedDate

                let finalStart = calendar.date(
                    bySettingHour: calendar.component(.hour, from: startTime),
                    minute: calendar.component(.minute, from: startTime),
                    second: 0,
                    of: targetDate
                )!

                let finalEnd = calendar.date(
                    bySettingHour: calendar.component(.hour, from: endTime),
                    minute: calendar.component(.minute, from: endTime),
                    second: 0,
                    of: targetDate
                )!

                let ref = db.collection("slots").document()

                let slotData: [String: Any] = [
                    "barberId": barberProfileId,
                    "date": Timestamp(date: targetDate),
                    "startTime": Timestamp(date: finalStart),
                    "endTime": Timestamp(date: finalEnd),
                    "status": "available",
                    "createdAt": Timestamp(date: Date())
                ]

                batch.setData(slotData, forDocument: ref)
            }
        }

        batch.commit { _ in
            showSuccess()
            fetchMySlots()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                goToBarberDashboard = true
            }
        }
    }

    func duplicateWholeWeek() {
        selectedDays = Set(0..<7)
        saveMultipleAvailability()
    }

    func duplicateForWeeks() {
        saveMultipleAvailability()
    }

    func updateStatusForSelectedDays(to status: String) {
        db.collection("slots")
            .whereField("barberId", isEqualTo: barberProfileId)
            .getDocuments { snapshot, _ in

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    if let ts = data["date"] as? Timestamp {
                        let day = Calendar.current.component(.weekday, from: ts.dateValue()) - 2
                        if selectedDays.contains(day) {
                            doc.reference.updateData(["status": status])
                        }
                    }
                }
                showSuccess()
                fetchMySlots()
            }
    }

    func deleteSlotsForSelectedDate() {
        db.collection("slots")
            .whereField("barberId", isEqualTo: barberProfileId)
            .getDocuments { snapshot, _ in

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    if let ts = data["date"] as? Timestamp,
                       Calendar.current.isDate(ts.dateValue(), inSameDayAs: selectedDate) {
                        doc.reference.delete()
                    }
                }
                showSuccess()
                fetchMySlots()
            }
    }

    func replaceSlotsForDay() {
        deleteSlotsForSelectedDate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            saveAvailability()
        }
    }

    func fetchMySlots() {
        db.collection("slots")
            .whereField("barberId", isEqualTo: barberProfileId)
            .order(by: "date", descending: false)
            .getDocuments { snapshot, error in

                if let error = error {
                    print("❌ Erreur Firestore slots:", error.localizedDescription)
                    self.mySlots = []
                    return
                }

                self.mySlots = snapshot?.documents.compactMap { doc in
                    let data = doc.data()

                    guard
                        let date = data["date"] as? Timestamp,
                        let start = data["startTime"] as? Timestamp,
                        let end = data["endTime"] as? Timestamp
                    else {
                        return nil
                    }

                    let statusRaw = data["status"] as? String ?? "available"

                    return AvailabilitySlot(
                        barberId: barberProfileId,
                        date: date.dateValue(),
                        startTime: start.dateValue(),
                        endTime: end.dateValue(),
                        status: SlotStatus(rawValue: statusRaw) ?? .available
                    )
                } ?? []
            }
    }

    func showSuccess() {
        withAnimation {
            showSuccessIcon = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showSuccessIcon = false
        }
    }
}

// =========================
// STYLES + SHEETS (FENÊTRES)
// =========================

struct MainButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// === SHEET 1 : Ajouter un créneau ===
struct AddSingleSlotSheet: View {
    @Binding var selectedDate: Date
    @Binding var startTime: Date
    @Binding var endTime: Date
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Ajouter un créneau (Jour unique)")
                    .font(.headline)

                Button("Option A : Ajouter normalement") { }
                Button("Option B : Ajouter + notifier clients") { }
                Button("Option C : Ajouter + répéter demain") { }

                Button("💾 Enregistrer cette étape") { }
                Button("✅ Enregistrer FINAL") { onSave() }
            }
            .padding()
        }
    }
}

// === SHEET 2 : Jours multiples ===
struct MultiDaySheet: View {
    @Binding var selectedDays: Set<Int>
    @Binding var repeatWeeks: Int
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Appliquer aux jours sélectionnés")

                Button("Option A : Même horaire") { }
                Button("Option B : Horaires différents") { }
                Button("Option C : Répéter X semaines") { }

                Button("💾 Enregistrer cette étape") { }
                Button("✅ Enregistrer FINAL") { onSave() }
            }
            .padding()
        }
    }
}

// === SHEET 3 : Dupliquer semaine ===
struct DuplicateWeekSheet: View {
    var onSave: () -> Void
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Dupliquer toute la semaine")

                Button("Option A : Même horaires") { }
                Button("Option B : Décaler d’1 heure") { }
                Button("Option C : Personnaliser") { }

                Button("💾 Enregistrer cette étape") { }
                Button("✅ Enregistrer FINAL") { onSave() }
            }
            .padding()
        }
    }
}

// === SHEET 4 : X semaines ===
struct DuplicateWeeksSheet: View {
    @Binding var repeatWeeks: Int
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Dupliquer sur plusieurs semaines")

                Stepper("Répéter \(repeatWeeks) semaines", value: $repeatWeeks, in: 1...12)

                Button("Option A : Copier exactement") { }
                Button("Option B : Décaler horaires") { }
                Button("Option C : Ajuster selon jour") { }

                Button("💾 Enregistrer cette étape") { }
                Button("✅ Enregistrer FINAL") { onSave() }
            }
            .padding()
        }
    }
}



// === SHEET 6 : Supprimer / Remplacer ===
struct DeleteReplaceSheet: View {
    @Binding var selectedDate: Date
    var onDelete: () -> Void
    var onReplace: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Supprimer / Remplacer créneaux")

                Button("Option A : Supprimer tout") { }
                Button("Option B : Remplacer par nouveau") { }
                Button("Option C : Archiver") { }

                Button("💾 Enregistrer cette étape") { }
                Button("🗑 Supprimer FINAL") { onDelete() }
                Button("🔄 Remplacer FINAL") { onReplace() }
            }
            .padding()
        }
    }
}

// === SHEET 7 : Mode expert ===
struct ExpertSheet: View {
    @Binding var selectedDate: Date
    @Binding var startTime: Date
    @Binding var endTime: Date
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Mode expert — paramètres avancés")

                Button("Option A : Créer créneaux fractionnés") { }
                Button("Option B : Créer en masse") { }
                Button("Option C : Importer modèle") { }

                Button("💾 Enregistrer cette étape") { }
                Button("✅ Enregistrer FINAL") { onSave() }
            }
            .padding()
        }
    }
}
