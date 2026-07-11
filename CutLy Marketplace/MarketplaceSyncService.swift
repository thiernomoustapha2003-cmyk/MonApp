//
//  MarketplaceSyncService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 01/07/2026.
//

import Foundation
import FirebaseFirestore
import Network

final class MarketplaceSyncService {
    
    static let shared = MarketplaceSyncService()
    
    private let db = Firestore.firestore()
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "marketplace.sync.monitor")
    
    private(set) var isOnline: Bool = true
    private(set) var lastSyncAt: Date?
    
    private init() {}
    
    // MARK: - Network Monitoring
    
    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isOnline = path.status == .satisfied
        }
        
        monitor.start(queue: monitorQueue)
    }
    
    func stopNetworkMonitoring() {
        monitor.cancel()
    }
    
    // MARK: - Firestore Offline
    
    func configureFirestoreOfflinePersistence() {
        let settings = Firestore.firestore().settings
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
        Firestore.firestore().settings = settings
    }
    
    // MARK: - Sync Bootstrap
    
    func bootstrapMarketplaceIfNeeded() async throws {
        try await MarketplaceFirestoreService.shared.bootstrapMarketplaceCollections()
        lastSyncAt = Date()
    }
    
    // MARK: - Refresh Core Data
    
    func refreshMarketplaceCore() async throws {
        async let products = MarketplaceFirestoreService.shared.fetchProducts(limit: 30)
        async let notifications: [MarketplaceNotificationDraft] = {
            if let userId = MarketplaceFirestoreService.shared.currentUserId {
                return try await MarketplaceNotificationService.shared.fetchUserNotifications(userId: userId, limit: 20)
            }
            return []
        }()
        
        _ = try await (products, notifications)
        lastSyncAt = Date()
    }
    
    // MARK: - Safe Sync
    
    func runSafeSync() async {
        do {
            try await bootstrapMarketplaceIfNeeded()
            try await refreshMarketplaceCore()
        } catch {
            print("Marketplace sync error: \(error.localizedDescription)")
        }
    }
    // MARK: - Offline Queue

    private var pendingActions: [MarketplaceSyncAction] = []

    func enqueueAction(_ action: MarketplaceSyncAction) {
        guard !pendingActions.contains(where: { $0.deduplicationKey == action.deduplicationKey }) else {
            return
        }

        pendingActions.append(action)
    }

    func clearPendingActions() {
        pendingActions.removeAll()
    }

    func pendingActionsCount() -> Int {
        pendingActions.count
    }

    // MARK: - Retry Sync

    func retryPendingActions() async {
        guard isOnline else { return }

        var completedIds: Set<String> = []

        for action in pendingActions {
            do {
                try await executeSyncAction(action)
                completedIds.insert(action.id)
            } catch {
                print("Marketplace pending action failed: \(error.localizedDescription)")
            }
        }

        pendingActions.removeAll { completedIds.contains($0.id) }
        lastSyncAt = Date()
    }

    private func executeSyncAction(_ action: MarketplaceSyncAction) async throws {
        switch action.type {
        case .userAction:
            try await Firestore.firestore()
                .collection(MarketplaceFirestoreService.Collection.userActions)
                .document(action.id)
                .setData(action.payload, merge: true)

        case .notification:
            try await Firestore.firestore()
                .collection(MarketplaceFirestoreService.Collection.notifications)
                .document(action.id)
                .setData(action.payload, merge: true)

        case .favorite:
            try await Firestore.firestore()
                .collection(MarketplaceFirestoreService.Collection.favorites)
                .document(action.id)
                .setData(action.payload, merge: true)

        case .search:
            try await Firestore.firestore()
                .collection(MarketplaceFirestoreService.Collection.searchHistory)
                .document(action.id)
                .setData(action.payload, merge: true)

        case .supportTicket:
            try await Firestore.firestore()
                .collection(MarketplaceFirestoreService.Collection.supportTickets)
                .document(action.id)
                .setData(action.payload, merge: true)
        }
    }
    
    
    
    
    
    
    
    
}
struct MarketplaceSyncAction: Identifiable {
    var id: String
    var type: MarketplaceSyncActionType
    var payload: [String: Any]
    var deduplicationKey: String
    var createdAt: Date
}

enum MarketplaceSyncActionType: String, Codable, CaseIterable, Identifiable {
    case userAction
    case notification
    case favorite
    case search
    case supportTicket

    var id: String { rawValue }
}
