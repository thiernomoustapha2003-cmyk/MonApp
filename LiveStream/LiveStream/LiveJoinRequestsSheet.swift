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
        db.collection("lives")
            .document(liveId)
            .collection("joinRequests")
            .document(request.userId)
            .updateData([
                "status": status,
                "updatedAt": Timestamp()
            ])
    }
    
    func acceptRequest(_ request: LiveJoinRequest) {
        let cohostRef = db.collection("lives")
            .document(liveId)
            .collection("cohosts")
            .document(request.userId)
        
        cohostRef.setData([
            "userId": request.userId,
            "username": request.username,
            "avatar": request.avatar,
            "role": "guest",
            "status": "active",
            "cameraEnabled": false,
            "micEnabled": true,
            "mutedByHost": false,
            "timerSeconds": 300,
            "joinedAt": Timestamp()
        ])
        
        updateRequest(request, status: "accepted")
    }
}
