import SwiftUI
import FirebaseFirestore

struct BookingView: View {

    let barber: Barber
    @Environment(\.dismiss) var dismiss

    @State private var selectedDate = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                Text("📅 Réservation")
                    .font(.title)
                    .bold()

                Text("Coiffeur : \(barber.name)")
                Text("Ville : \(barber.city)")
                Text("Prix : \(String(format: "%.2f", barber.price)) €")

                DatePicker(
                    "Choisir la date et l'heure",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()

                Button(action: {
                    BookingService().addBooking(
                        barber: barber,
                        date: selectedDate,
                        clientName: "Client Test"
                    ) { success in
                        if success {
                            alertMessage = "✅ Réservation enregistrée dans Firestore"
                        } else {
                            alertMessage = "❌ Erreur : réservation non enregistrée"
                        }
                        showAlert = true
                    }
                }) {
                    Text("Confirmer le rendez-vous")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button("❌ Fermer") {
                    dismiss()
                }
                .padding(.top)

                Spacer()
            }
            .padding()
            .navigationTitle("Réservation")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Info"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
        }
    }
}
