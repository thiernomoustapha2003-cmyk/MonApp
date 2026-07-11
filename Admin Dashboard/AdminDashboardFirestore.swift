//
//  AdminDashboardFirestore.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

extension AdminDashboardView {
    
    func loadAll() {
        loadUsers()
        loadReports()
        loadBookings()
        loadGiftTransactions()
        loadShopRevenue()
        loadAdsRevenue()
        loadLiveStats()
        loadMessagesStats()
        loadCallsStats()
    }
    
    func loadUsers() {
        db.collection("users")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Admin loadUsers:", error.localizedDescription)
                    return
                }
                
                let items = snapshot?.documents.map { doc -> AdminUserItem in
                    let data = doc.data()
                    
                    return AdminUserItem(
                        id: doc.documentID,
                        name: data["name"] as? String
                        ?? data["fullName"] as? String
                        ?? data["displayName"] as? String
                        ?? "Utilisateur",
                        email: data["email"] as? String ?? "",
                        role: data["role"] as? String ?? "client",
                        isBanned: data["isBanned"] as? Bool ?? false,
                        isRestricted: data["isRestricted"] as? Bool ?? false
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self.users = items
                }
            }
    }
    
    func loadReports() {
        db.collection("reports")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Admin loadReports:", error.localizedDescription)
                    return
                }
                
                let items = snapshot?.documents.map { doc -> AdminReportItem in
                    let data = doc.data()
                    
                    return AdminReportItem(
                        id: doc.documentID,
                        reason: data["reason"] as? String ?? "Signalement",
                        details: data["details"] as? String
                        ?? data["messageText"] as? String
                        ?? "",
                        reportedUserId: data["reportedUserId"] as? String ?? "",
                        reportedBy: data["reportedBy"] as? String ?? "",
                        status: data["status"] as? String ?? "pending",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self.reports = items
                }
            }
    }
    
    func loadBookings() {
        db.collection("bookings")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Admin loadBookings:", error.localizedDescription)
                    return
                }
                
                var totalCommission: Double = 0
                
                let items = snapshot?.documents.map { doc -> AdminBookingItem in
                    let data = doc.data()
                    
                    let status = data["status"] as? String ?? ""
                    let paymentStatus = data["paymentStatus"] as? String ?? ""
                    let amount = data["amount"] as? Double
                    ?? data["totalPrice"] as? Double
                    ?? data["price"] as? Double
                    ?? 0
                    
                    let commission = data["platformCommission"] as? Double
                    ?? data["commission"] as? Double
                    ?? amount * 0.15
                    
                    if paymentStatus == "paid" || status == "completed" || status == "confirmed" {
                        totalCommission += commission
                    }
                    
                    return AdminBookingItem(
                        id: doc.documentID,
                        status: status,
                        paymentStatus: paymentStatus,
                        amount: amount,
                        commission: commission,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self.bookings = items
                    self.bookingRevenue = totalCommission
                }
            }
    }
    
    func loadGiftTransactions() {
        db.collection("giftTransactions")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Admin loadGiftTransactions:", error.localizedDescription)
                    return
                }
                
                var total: Double = 0
                
                let items = snapshot?.documents.map { doc -> AdminTransactionItem in
                    let data = doc.data()
                    
                    let platformCoins = data["platformCoins"] as? Int ?? 0
                    let amountEUR = Double(platformCoins) * 0.10
                    total += amountEUR
                    
                    return AdminTransactionItem(
                        id: doc.documentID,
                        title: data["giftName"] as? String ?? "Cadeau live",
                        senderName: data["senderName"] as? String ?? "Utilisateur",
                        category: "Lives",
                        amount: amountEUR,
                        commission: data["platformCommissionEUR"] as? Double ?? 0,
                        status: data["status"] as? String ?? "completed",
                        date: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self.transactions = items
                    self.liveRevenue = total
                }
            }
    }
    
    func loadShopRevenue() {
        db.collection("orders")
            .whereField("status", in: ["paid", "completed", "delivered"])
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Admin loadShopRevenue:", error.localizedDescription)
                    return
                }
                
                var total: Double = 0
                
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    let commission = data["platformCommission"] as? Double ?? 0
                    total += commission
                }
                
                DispatchQueue.main.async {
                    self.shopRevenue = total
                }
            }
    }
    
    func loadAdsRevenue() {
        db.collection("adRevenue")
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Admin loadAdsRevenue:", error.localizedDescription)
                    return
                }
                
                var total: Double = 0
                
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    total += data["amountEUR"] as? Double ?? 0
                }
                
                DispatchQueue.main.async {
                    self.adsRevenue = total
                }
            }
    }
    
    func warnUser(_ report: AdminReportItem) {
        guard !report.reportedUserId.isEmpty else { return }
        
        db.collection("users").document(report.reportedUserId).setData([
            "warningsCount": FieldValue.increment(Int64(1)),
            "lastWarningAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        db.collection("reports").document(report.id).setData([
            "status": "warned",
            "handledAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        loadAll()
    }
    
    func restrictUser(_ report: AdminReportItem) {
        guard !report.reportedUserId.isEmpty else { return }
        
        db.collection("users").document(report.reportedUserId).setData([
            "isRestricted": true,
            "restrictedAt": FieldValue.serverTimestamp(),
            "restrictionReason": report.reason
        ], merge: true)
        
        db.collection("reports").document(report.id).setData([
            "status": "restricted",
            "handledAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        loadAll()
    }
    
    func banUser(_ report: AdminReportItem) {
        guard !report.reportedUserId.isEmpty else { return }
        
        db.collection("users").document(report.reportedUserId).setData([
            "isBanned": true,
            "bannedAt": FieldValue.serverTimestamp(),
            "banReason": report.reason
        ], merge: true)
        
        db.collection("reports").document(report.id).setData([
            "status": "banned",
            "handledAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        loadAll()
    }
    
    func createWithdrawRequest() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("platformWithdrawRequests").addDocument(data: [
            "adminId": uid,
            "amountEUR": totalRevenue,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
    
    func loadLiveStats() {
        db.collection("lives")
            .whereField("status", isEqualTo: "active")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Admin loadLiveStats:", error.localizedDescription)
                    return
                }
                
                print("📺 Lives actifs:", snapshot?.documents.count ?? 0)
            }
    }
    
    func loadMessagesStats() {
        db.collection("messages")
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Admin loadMessagesStats:", error.localizedDescription)
                    return
                }
                
                print("💬 Messages collection OK:", snapshot?.documents.count ?? 0)
            }
    }
    
    func loadCallsStats() {
        db.collection("calls")
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Admin loadCallsStats:", error.localizedDescription)
                    return
                }
                
                print("📞 Calls collection OK:", snapshot?.documents.count ?? 0)
            }
    }
    
    func formatEUR(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) €"
    }
    func startReportsRealtimeListener() {
        stopReportsRealtimeListener()

        reportsListener = db.collection("reports")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in

                if let error = error {
                    print("❌ Reports realtime error:", error.localizedDescription)
                    return
                }

                let items = snapshot?.documents.map { doc -> AdminReportItem in
                    let data = doc.data()

                    return AdminReportItem(
                        id: doc.documentID,
                        reason: data["reason"] as? String ?? "Signalement",
                        details: data["details"] as? String
                            ?? data["messageText"] as? String
                            ?? "",
                        reportedUserId: data["reportedUserId"] as? String ?? "",
                        reportedBy: data["reportedBy"] as? String ?? "",
                        status: data["status"] as? String ?? "pending",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.reports = items
                }
            }
    }

    func stopReportsRealtimeListener() {
        reportsListener?.remove()
        reportsListener = nil
    }
    func startUsersRealtimeListener() {
        stopUsersRealtimeListener()

        usersListener = db.collection("users")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in

                if let error = error {
                    print("❌ Users realtime error:", error.localizedDescription)
                    return
                }

                let items = snapshot?.documents.map { doc -> AdminUserItem in
                    let data = doc.data()

                    return AdminUserItem(
                        id: doc.documentID,
                        name: data["name"] as? String
                            ?? data["fullName"] as? String
                            ?? data["displayName"] as? String
                            ?? "Utilisateur",
                        email: data["email"] as? String ?? "",
                        role: data["role"] as? String ?? "client",
                        isBanned: data["isBanned"] as? Bool ?? false,
                        isRestricted: data["isRestricted"] as? Bool ?? false
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.users = items
                }
            }
    }

    func stopUsersRealtimeListener() {
        usersListener?.remove()
        usersListener = nil
    }
    func startBookingsRealtimeListener() {
        stopBookingsRealtimeListener()

        bookingsListener = db.collection("bookings")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in

                if let error = error {
                    print("❌ Bookings realtime error:", error.localizedDescription)
                    return
                }

                var totalCommission: Double = 0

                let items = snapshot?.documents.map { doc -> AdminBookingItem in
                    let data = doc.data()

                    let status = data["status"] as? String ?? ""
                    let paymentStatus = data["paymentStatus"] as? String ?? ""

                    let amount = data["amount"] as? Double
                        ?? data["totalPrice"] as? Double
                        ?? data["price"] as? Double
                        ?? 0

                    let commission = data["platformCommission"] as? Double
                        ?? data["commission"] as? Double
                        ?? amount * 0.15

                    if paymentStatus == "paid" || status == "completed" || status == "confirmed" {
                        totalCommission += commission
                    }

                    return AdminBookingItem(
                        id: doc.documentID,
                        status: status,
                        paymentStatus: paymentStatus,
                        amount: amount,
                        commission: commission,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.bookings = items
                    self.bookingRevenue = totalCommission
                }
            }
    }

    func stopBookingsRealtimeListener() {
        bookingsListener?.remove()
        bookingsListener = nil
    }
    func startTransactionsRealtimeListener() {

        stopTransactionsRealtimeListener()

        transactionsListener = db.collection("giftTransactions")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in

                if let error = error {
                    print("❌ Transactions realtime:", error.localizedDescription)
                    return
                }

                var total: Double = 0

                let items = snapshot?.documents.map { doc -> AdminTransactionItem in

                    let data = doc.data()

                    let platformCoins = data["platformCoins"] as? Int ?? 0
                    let amountEUR = Double(platformCoins) * 0.10

                    total += amountEUR

                    return AdminTransactionItem(
                        id: doc.documentID,
                        title: data["giftName"] as? String ?? "Cadeau Live",
                        senderName: data["senderName"] as? String ?? "Utilisateur",
                        category: "Lives",
                        amount: amountEUR,
                        commission: data["platformCommissionEUR"] as? Double ?? 0,
                        status: data["status"] as? String ?? "completed",
                        date: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.transactions = items
                    self.liveRevenue = total
                }
            }
    }

    func stopTransactionsRealtimeListener() {

        transactionsListener?.remove()
        transactionsListener = nil
    }
    func startMarketplaceRealtimeListener() {

        stopMarketplaceRealtimeListener()

        marketplaceListener = db.collection("orders")
            .whereField("status", in: ["paid", "completed", "delivered"])
            .addSnapshotListener { snapshot, error in

                if let error = error {
                    print("❌ Marketplace realtime:", error.localizedDescription)
                    return
                }

                var total: Double = 0

                snapshot?.documents.forEach { doc in
                    let data = doc.data()

                    total += data["platformCommission"] as? Double ?? 0
                }

                DispatchQueue.main.async {
                    self.shopRevenue = total
                }
            }
    }

    func stopMarketplaceRealtimeListener() {

        marketplaceListener?.remove()
        marketplaceListener = nil
    }
    
    
    
}
