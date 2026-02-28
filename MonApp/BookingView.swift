import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import StripePaymentSheet

struct BookingView: View {

    let barber: Barber
    @Environment(\.dismiss) var dismiss

    private let db = Firestore.firestore()
    
    
    @State private var currentBookingId: String?
    
    
    @State private var availableSlots: [AvailabilitySlot] = []
    @State private var selectedSlot: AvailabilitySlot?

    @State private var isLoading = true
    @State private var showLoginSheet = false
    @State private var showEscrowInfo = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    // STRIPE
    @State private var paymentSheet: PaymentSheet?
    @State private var showPaymentSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {

                Text("📅 Réservation")
                    .font(.title)
                    .bold()

                Text(barber.name)
                Text(barber.city)
                Text(String(format: "%.2f €", barber.price))

                Divider()

                if isLoading {
                    ProgressView("Chargement des créneaux...")
                }
                else if availableSlots.isEmpty {
                    Text("Aucun créneau disponible")
                        .foregroundColor(.gray)
                }
                else {
                    ScrollView {
                        VStack(spacing: 12) {

                            ForEach(groupSlotsByDate(), id: \.0) { date, slots in

                                VStack(alignment: .leading) {

                                    Text(date, style: .date)
                                        .font(.headline)

                                    ForEach(slots) { slot in
                                        slotRow(slot)
                                    }
                                }
                            }
                        }
                    }
                }

                Button("Payer et confirmer") {
                    guard let slot = selectedSlot else { return }

                    if Auth.auth().currentUser == nil {
                        showLoginSheet = true
                    } else {
                        showEscrowInfo = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedSlot == nil)

                Button("Fermer") { dismiss() }

                Spacer()
            }
            .padding()
            .navigationTitle("Réservation")
            .onAppear { loadAvailableSlots() }
            .alert("Info", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showLoginSheet) {
                ClientAuthView {
                    showLoginSheet = false
                    showEscrowInfo = true
                }
            }
            .sheet(isPresented: $showEscrowInfo) {
                EscrowInfoView(hasAccepted: .constant(true)) {
                    showEscrowInfo = false
                    startPaymentFlow()
                }
            }
            .sheet(isPresented: $showPaymentSheet) {
                if let sheet = paymentSheet {
                    PaymentSheetView(paymentSheet: sheet) { result in
                        handlePaymentResult(result)
                    }
                }
            }
        }
    }
}

// MARK: UI SLOT
extension BookingView {

    func slotRow(_ slot: AvailabilitySlot) -> some View {
        HStack {
            Text("\(slot.startTime.formatted(date: .omitted, time: .shortened)) - \(slot.endTime.formatted(date: .omitted, time: .shortened))")

            Spacer()

            Text(slot.status.rawValue)
                .foregroundColor(slot.status == .available ? .green : .red)
        }
        .padding()
        .background(selectedSlot?.id == slot.id ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(10)
        .onTapGesture {
            if slot.status == .available {
                selectedSlot = slot
            }
        }
    }

    func groupSlotsByDate() -> [(Date, [AvailabilitySlot])] {
        let grouped = Dictionary(grouping: availableSlots) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return grouped
            .map { ($0.key, $0.value.sorted { $0.startTime < $1.startTime }) }
            .sorted { $0.0 < $1.0 }
    }
}

// MARK: FIRESTORE
extension BookingView {

    func loadAvailableSlots() {

        isLoading = true

        db.collection("slots")
            .whereField("barberId", isEqualTo: barber.authId)
            .getDocuments { snapshot, error in

                isLoading = false

                if let error = error {
                    alertMessage = error.localizedDescription
                    showAlert = true
                    return
                }

                availableSlots = snapshot?.documents.compactMap { doc in
                    let data = doc.data()

                    guard
                        let date = data["date"] as? Timestamp,
                        let start = data["startTime"] as? Timestamp,
                        let end = data["endTime"] as? Timestamp,
                        let status = data["status"] as? String
                    else { return nil }

                    return AvailabilitySlot(
                        id: doc.documentID,
                        barberId: barber.authId,
                        date: date.dateValue(),
                        startTime: start.dateValue(),
                        endTime: end.dateValue(),
                        status: SlotStatus(rawValue: status) ?? .available
                    )
                } ?? []
            }
    }
}

// MARK: PAYMENT
extension BookingView {
    
    func startPaymentFlow() {
        
        guard let slot = selectedSlot else { return }
        
        PaymentFlowManager.shared.startPayment(barber: barber, slot: slot) { clientSecret, bookingId in
            
            guard let clientSecret = clientSecret,
                  let bookingId = bookingId else {
                alertMessage = "Impossible de créer le paiement"
                showAlert = true
                return
            }
            
            currentBookingId = bookingId
            
            DispatchQueue.main.async {
                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "Cutly"
                
                paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
                showPaymentSheet = true
            }
        }
    }
    func handlePaymentResult(_ result: PaymentSheetResult) {
        
        switch result {
            
        case .completed:
            print("✅ paiement confirmé")
            listenBookingAfterPayment()
            
        case .canceled:
            print("❌ paiement annulé")
            
        case .failed(let error):
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    func listenBookingAfterPayment() {

        guard let bookingId = currentBookingId else { return }

        BookingService.shared.listenToBooking(bookingId: bookingId) { booking in

            guard let booking = booking else { return }

            print("📡 UPDATE UI:", booking.status, booking.escrowStatus)

            // quand l'argent est libéré → réservation terminée
            if booking.escrowStatus == "released" {

                alertMessage = "🎉 Réservation terminée et payée !"
                showAlert = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
}










