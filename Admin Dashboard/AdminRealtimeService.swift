//
//  AdminRealtimeService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class AdminRealtimeService: ObservableObject {

    static let shared = AdminRealtimeService()

    private let db = Firestore.firestore()

    @Published var usersCount: Int = 0
    @Published var reportsCount: Int = 0
    @Published var bookingsCount: Int = 0
    @Published var transactionsCount: Int = 0
    @Published var activeLivesCount: Int = 0

    @Published var liveRevenue: Double = 0
    @Published var bookingRevenue: Double = 0
    @Published var marketplaceRevenue: Double = 0
    @Published var adsRevenue: Double = 0

    @Published var isLive = false
    @Published var lastUpdate = Date()

    private var listeners: [ListenerRegistration] = []

    var totalRevenue: Double {
        liveRevenue + bookingRevenue + marketplaceRevenue + adsRevenue
    }

    private init() {}

    func start() {
        stop()

        listenUsers()
        listenReports()
        listenBookings()
        listenGiftTransactions()
        listenMarketplace()
        listenLives()

        isLive = true
        lastUpdate = Date()
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        isLive = false
    }

    private func listenUsers() {
        let listener = db.collection("users")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("❌ Realtime users:", error.localizedDescription)
                    return
                }

                Task { @MainActor in
                    self.usersCount = snapshot?.documents.count ?? 0
                    self.lastUpdate = Date()
                }
            }

        listeners.append(listener)
    }

    private func listenReports() {
        let listener = db.collection("reports")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("❌ Realtime reports:", error.localizedDescription)
                    return
                }

                Task { @MainActor in
                    self.reportsCount = snapshot?.documents.count ?? 0
                    self.lastUpdate = Date()
                }
            }

        listeners.append(listener)
    }

    private func listenBookings() {
        let listener = db.collection("bookings")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("❌ Realtime bookings:", error.localizedDescription)
                    return
                }

                var commission: Double = 0

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    let status = data["status"] as? String ?? ""
                    let paymentStatus = data["paymentStatus"] as? String ?? ""

                    let amount = data["amount"] as? Double
                        ?? data["totalPrice"] as? Double
                        ?? data["price"] as? Double
                        ?? 0

                    let platformCommission = data["platformCommission"] as? Double
                        ?? data["commission"] as? Double
                        ?? amount * 0.15

                    if paymentStatus == "paid" || status == "completed" || status == "confirmed" {
                        commission += platformCommission
                    }
                }

                Task { @MainActor in
                    self.bookingsCount = snapshot?.documents.count ?? 0
                    self.bookingRevenue = commission
                    self.lastUpdate = Date()
                }
            }

        listeners.append(listener)
    }

    private func listenGiftTransactions() {
        let listener = db.collection("giftTransactions")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("❌ Realtime gifts:", error.localizedDescription)
                    return
                }

                var total: Double = 0

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    let platformCoins = data["platformCoins"] as? Int ?? 0
                    total += Double(platformCoins) * 0.10
                }

                Task { @MainActor in
                    self.transactionsCount = snapshot?.documents.count ?? 0
                    self.liveRevenue = total
                    self.lastUpdate = Date()
                }
            }

        listeners.append(listener)
    }

    private func listenMarketplace() {
        let listener = db.collection("orders")
            .whereField("status", in: ["paid", "completed", "delivered"])
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("❌ Realtime marketplace:", error.localizedDescription)
                    return
                }

                var total: Double = 0

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    total += data["platformCommission"] as? Double ?? 0
                }

                Task { @MainActor in
                    self.marketplaceRevenue = total
                    self.lastUpdate = Date()
                }
            }

        listeners.append(listener)
    }

    private func listenLives() {
        let listener = db.collection("lives")
            .whereField("status", isEqualTo: "active")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("❌ Realtime lives:", error.localizedDescription)
                    return
                }

                Task { @MainActor in
                    self.activeLivesCount = snapshot?.documents.count ?? 0
                    self.lastUpdate = Date()
                }
            }

        listeners.append(listener)
    }

    func formatEUR(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) €"
    }
}
