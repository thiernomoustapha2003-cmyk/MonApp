//
//  LiveCoHostService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//

//
//  LiveCoHostService.swift
//  MonApp
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

final class LiveCoHostService: ObservableObject {
    
    static let shared = LiveCoHostService()
    
    @Published var coHosts: [LiveCoHost] = []
    @Published var activeGuests: [LiveCoHost] = []
    @Published var host: LiveCoHost?
    
    @Published var isMicMuted = false
    @Published var isCameraEnabled = false
    
    private let db = Firestore.firestore()
    private var coHostsListener: ListenerRegistration?
    
    private init() {}
}

// MARK: - LISTEN

extension LiveCoHostService {
    
    func startListening(liveId: String) {
        
        coHostsListener?.remove()
        
        coHostsListener = db.collection("lives")
            .document(liveId)
            .collection("cohosts")
            .whereField("status", isEqualTo: "active")
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("❌ CoHost listener:", error.localizedDescription)
                    return
                }
                
                let items = snapshot?.documents.map { doc in
                    LiveCoHost.fromFirestore(
                        id: doc.documentID,
                        data: doc.data()
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self.coHosts = items
                    self.host = items.first(where: { $0.role == .host })
                    self.activeGuests = items
                        .filter { $0.role == .guest || $0.role == .moderator }
                        .prefix(10)
                        .map { $0 }
                }
            }
    }
    
    func stopListening() {
        coHostsListener?.remove()
        coHostsListener = nil
    }
}

// MARK: - HOST

extension LiveCoHostService {
    
    func registerHost(liveId: String) {
        
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection("lives")
            .document(liveId)
            .collection("cohosts")
            .document(user.uid)
            .setData([
                "userId": user.uid,
                "username": user.displayName ?? "Créateur",
                "avatar": user.photoURL?.absoluteString ?? "",
                "role": "host",
                "status": "active",
                "cameraEnabled": true,
                "micEnabled": true,
                "mutedByHost": false,
                "canModerate": true,
                "timerSeconds": 0,
                "joinedAt": Timestamp()
            ], merge: true)
    }
    
    func acceptGuest(
        liveId: String,
        userId: String,
        username: String,
        avatar: String
    ) {
        
        db.collection("lives")
            .document(liveId)
            .collection("cohosts")
            .document(userId)
            .setData([
                "userId": userId,
                "username": username,
                "avatar": avatar,
                "role": "guest",
                "status": "active",
                "cameraEnabled": false,
                "micEnabled": true,
                "mutedByHost": false,
                "canModerate": false,
                "timerSeconds": 300,
                "joinedAt": Timestamp()
            ], merge: true)
    }
    
    func removeGuest(liveId: String, userId: String) {
        
        db.collection("lives")
            .document(liveId)
            .collection("cohosts")
            .document(userId)
            .updateData([
                "status": "removed",
                "removedAt": Timestamp()
            ])
    }
}

// MARK: - MICRO / CAMERA

extension LiveCoHostService {
    
    func toggleMyMic(liveId: String) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isMicMuted.toggle()
        
        db.collection("lives")
            .document(liveId)
            .collection("cohosts")
            .document(uid)
            .updateData([
                "micEnabled": !isMicMuted,
                "updatedAt": Timestamp()
            ])
    }
    
    func toggleMyCamera(liveId: String) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isCameraEnabled.toggle()
        
        db.collection("lives")
            .document(liveId)
            .collection("cohosts")
            .document(uid)
            .updateData([
                "cameraEnabled": isCameraEnabled,
                "updatedAt": Timestamp()
            ])
    }
    
    func hostMuteGuest(liveId: String, userId: String, muted: Bool) {
        
        db.collection("lives")
            .document(liveId)
            .collection("cohosts")
            .document(userId)
            .updateData([
                "mutedByHost": muted,
                "updatedAt": Timestamp()
            ])
    }
    
    func hostMuteAll(liveId: String, muted: Bool) {
        
        for guest in activeGuests {
            hostMuteGuest(
                liveId: liveId,
                userId: guest.userId,
                muted: muted
            )
        }
    }
}

// MARK: - MODERATION

extension LiveCoHostService {
    
    func promoteModerator(liveId: String, userId: String) {
        
        db.collection("lives")
            .document(liveId)
            .collection("cohosts")
            .document(userId)
            .updateData([
                "role": "moderator",
                "canModerate": true,
                "updatedAt": Timestamp()
            ])
    }
    
    func removeModerator(liveId: String, userId: String) {
        
        db.collection("lives")
            .document(liveId)
            .collection("cohosts")
            .document(userId)
            .updateData([
                "role": "guest",
                "canModerate": false,
                "updatedAt": Timestamp()
            ])
    }
}

// MARK: - TIMER

extension LiveCoHostService {
    
    func setSpeakingTimer(
        liveId: String,
        userId: String,
        seconds: Int
    ) {
        
        db.collection("lives")
            .document(liveId)
            .collection("cohosts")
            .document(userId)
            .updateData([
                "timerSeconds": seconds,
                "timerStartedAt": Timestamp(),
                "updatedAt": Timestamp()
            ])
    }
}
