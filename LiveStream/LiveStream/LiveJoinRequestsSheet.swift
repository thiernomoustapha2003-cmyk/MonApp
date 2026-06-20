//
//  LiveJoinRequestsSheet.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//

import SwiftUI
import FirebaseFirestore

struct LiveJoinRequest: Identifiable {
    let id: String
    let userId: String
    let username: String
    let avatar: String
    let status: String
}

struct LiveJoinRequestsSheet: View {
    
    let liveId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var requests: [LiveJoinRequest] = []
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack {
                if requests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 55))
                            .foregroundColor(.gray)
                        
                        Text("Aucune demande")
                            .font(.headline)
                        
                        Text("Les spectateurs qui veulent monter dans le live apparaîtront ici.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(requests) { request in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(String(request.username.prefix(1)).uppercased())
                                        .bold()
                                )
                            
                            VStack(alignment: .leading) {
                                Text(request.username)
                                    .font(.headline)
                                
                                Text("Demande à monter dans le live")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button("Refuser") {
                                updateRequest(request, status: "rejected")
                            }
                            .foregroundColor(.red)
                            
                            Button("Accepter") {
                                acceptRequest(request)
                            }
                            .foregroundColor(.green)
                            
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Demandes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                listenRequests()
            }
        }
    }
    
    func listenRequests() {
        db.collection("lives")
            .document(liveId)
            .collection("joinRequests")
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { snapshot, _ in
                
                var items: [LiveJoinRequest] = []
                
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    
                    let request = LiveJoinRequest(
                        id: doc.documentID,
                        userId: data["userId"] as? String ?? "",
                        username: data["username"] as? String ?? "Spectateur",
                        avatar: data["avatar"] as? String ?? "",
                        status: data["status"] as? String ?? "pending"
                    )
                    
                    items.append(request)
                }
                
                DispatchQueue.main.async {
                    self.requests = items
                }
            }
    }
    
    func updateRequest(_ request: LiveJoinRequest, status: String) {
        
        print("🔥 UPDATE STATUS =", status)
        
        db.collection("lives")
            .document(liveId)
            .collection("joinRequests")
            .document(request.userId)
            .updateData([
                "status": status,
                "updatedAt": Timestamp()
            ]) { error in
                
                if let error = error {
                    print("❌ UPDATE ERROR =", error.localizedDescription)
                } else {
                    print("✅ STATUS UPDATED =", status)
                }
            }
    }
    
    func acceptRequest(_ request: LiveJoinRequest) {
        
        print("✅ ACCEPT REQUEST =", request.username)
        
        let db = Firestore.firestore()
        
        let liveRef = db.collection("lives").document(liveId)
        
        liveRef.collection("cohosts")
            .whereField("status", isEqualTo: "active")
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Erreur lecture cohosts:", error.localizedDescription)
                    return
                }
                
                let activeGuestsCount = snapshot?.documents.filter { doc in
                    let role = doc.data()["role"] as? String ?? ""
                    return role == "guest" || role == "moderator"
                }.count ?? 0
                
                if activeGuestsCount >= 10 {
                    print("❌ Maximum 10 invités atteint")
                    return
                }
                
                let agoraUid = 2001 + UInt(activeGuestsCount)
                
                let requestRef = liveRef
                    .collection("joinRequests")
                    .document(request.userId)
                
                let cohostRef = liveRef
                    .collection("cohosts")
                    .document(request.userId)
                
                let batch = db.batch()
                
                batch.setData([
                    "userId": request.userId,
                    "username": request.username,
                    "avatar": request.avatar,
                    "role": "guest",
                    "status": "active",
                    "agoraUid": Int(agoraUid),
                    "cameraEnabled": true,
                    "micEnabled": true,
                    "mutedByHost": false,
                    "canModerate": false,
                    "timerSeconds": 300,
                    "joinedAt": Timestamp(),
                    "updatedAt": Timestamp()
                ], forDocument: cohostRef, merge: true)
                
                batch.updateData([
                    "status": "accepted",
                    "agoraUid": Int(agoraUid),
                    "updatedAt": Timestamp()
                ], forDocument: requestRef)
                
                batch.commit { error in
                    if let error = error {
                        print("❌ ACCEPT ERROR =", error.localizedDescription)
                    } else {
                        print("✅ INVITÉ ACCEPTÉ + COHOST CRÉÉ agoraUid =", agoraUid)
                    }
                }
            }
    }
}
