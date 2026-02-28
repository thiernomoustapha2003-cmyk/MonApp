import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FinanceMonthlyView: View {

    @State private var totalEarned: Double = 0
    @State private var totalBookings: Int = 0
    @State private var averageTicket: Double = 0
    @State private var loading: Bool = true

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            ScrollView {

                if loading {
                    ProgressView("Calcul de ton business du mois...")
                        .padding(.top, 80)
                }
                else {

                    VStack(spacing: 22) {

                        // REVENUS
                        financeCard(
                            title: "Revenus du mois",
                            value: totalEarned,
                            color: .green
                        )

                        // CE QUE TU TOUCHES
                        financeCard(
                            title: "Tu recevras (85%)",
                            value: totalEarned,
                            color: .blue
                        )

                        // PANIER MOYEN
                        financeCard(
                            title: "Panier moyen",
                            value: averageTicket,
                            color: .orange
                        )

                        // BOOKINGS COUNT
                        VStack(spacing: 6) {
                            Text("\(totalBookings)")
                                .font(.system(size: 44, weight: .bold))

                            Text("Réservations payées")
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)

                        // MESSAGE BONUS
                        if totalEarned == 0 {
                            Text("Aucune coupe ce mois-ci… 🔕\nActive ta visibilité !")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        } else if totalEarned < 200 {
                            Text("Bon début 💪 Continue comme ça !")
                                .foregroundColor(.orange)
                                .padding(.top, 20)
                        } else if totalEarned < 600 {
                            Text("Tu tournes bien 🔥")
                                .foregroundColor(.green)
                                .padding(.top, 20)
                        } else {
                            Text("Barber rentable 💸 excellent mois !")
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                                .padding(.top, 20)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Revenus du mois")
            .onAppear {
                loadFinance()
            }
        }
    }
}

// UI
extension FinanceMonthlyView {

    func financeCard(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .foregroundColor(.gray)

            Text("\(value, specifier: "%.2f") €")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(18)
    }
}

// FIRESTORE
extension FinanceMonthlyView {

    func loadFinance() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        loading = true

        let calendar = Calendar.current
        let now = Date()

        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        db.collection("bookings")
            .whereField("barberId", isEqualTo: uid)
            .getDocuments { snapshot, error in

                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async { loading = false }
                    return
                }

                var total: Double = 0
                var count: Int = 0

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"

                for doc in documents {

                    let data = doc.data()

                    // paiement validé uniquement
                    guard let paymentStatus = data["paymentStatus"] as? String,
                          paymentStatus == "paid" else { continue }

                    // escrow réellement libéré
                    guard let escrow = data["escrowStatus"] as? String,
                          escrow == "released" else { continue }

                    // conversion de la date STRING -> Date
                    guard let dateString = data["date"] as? String,
                          let bookingDate = formatter.date(from: dateString) else { continue }

                    let month = calendar.component(.month, from: bookingDate)
                    let year = calendar.component(.year, from: bookingDate)

                    // uniquement ce mois
                    guard month == currentMonth && year == currentYear else { continue }

                    // montant réel barber
                    let earned = data["barberPaidAmount"] as? Double ?? 0

                    total += earned
                    count += 1
                }

                DispatchQueue.main.async {

                    self.totalEarned = total
                    self.totalBookings = count
                    self.averageTicket = count > 0 ? total / Double(count) : 0
                    self.loading = false
                }
            }
    }
}
