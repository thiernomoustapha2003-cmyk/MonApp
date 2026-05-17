//
//  LiveGuestRequestStatusView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//

//
//  LiveGuestRequestStatusView.swift
//  MonApp
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LiveGuestRequestStatusView: View {
    
    let liveId: String
    
    @State private var status: String?
    @State private var isLoading = false
    @State private var showAcceptedAlert = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 10) {
            
            Button {
                handleRequest()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: iconName())
                    Text(buttonTitle())
                        .font(.caption.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(buttonColor().opacity(0.9))
                )
            }
            .disabled(isLoading || status == "pending" || status == "accepted")
            
            if let status = status {
                Text(statusText(status))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .onAppear {
            listenMyRequest()
        }
        .alert("Demande acceptée 🎉", isPresented: $showAcceptedAlert) {
            Button("Activer caméra/micro") {
                LiveCoHostService.shared.toggleMyCamera(liveId: liveId)
            }
            
            Button("Plus tard", role: .cancel) {}
        } message: {
            Text("Le créateur t’a accepté dans le live. Tu peux activer ta caméra et ton micro.")
        }
    }
}

extension LiveGuestRequestStatusView {
    
    func handleRequest() {
        if status == "rejected" || status == "cancelled" || status == nil {
            sendRequest()
        }
    }
    
    func sendRequest() {
        isLoading = true
        LiveChatService().requestToJoinLive(liveId: liveId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
        }
    }
    
    func listenMyRequest() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("lives")
            .document(liveId)
            .collection("joinRequests")
            .document(uid)
            .addSnapshotListener { snapshot, _ in
                
                let newStatus = snapshot?.data()?["status"] as? String
                
                DispatchQueue.main.async {
                    if self.status != "accepted" && newStatus == "accepted" {
                        self.showAcceptedAlert = true
                    }
                    
                    self.status = newStatus
                }
            }
    }
    
    func buttonTitle() -> String {
        switch status {
        case "pending":
            return "Demande envoyée"
        case "accepted":
            return "Accepté"
        case "rejected":
            return "Redemander"
        case "cancelled":
            return "Demander à monter"
        default:
            return isLoading ? "Envoi..." : "Monter"
        }
    }
    
    func iconName() -> String {
        switch status {
        case "pending":
            return "hourglass"
        case "accepted":
            return "checkmark.circle.fill"
        case "rejected":
            return "arrow.clockwise"
        default:
            return "person.crop.circle.badge.plus"
        }
    }
    
    func buttonColor() -> Color {
        switch status {
        case "pending":
            return .orange
        case "accepted":
            return .green
        case "rejected":
            return .blue
        default:
            return .purple
        }
    }
    
    func statusText(_ value: String) -> String {
        switch value {
        case "pending":
            return "En attente de validation"
        case "accepted":
            return "Tu peux monter dans le live"
        case "rejected":
            return "Demande refusée"
        case "cancelled":
            return "Demande annulée"
        default:
            return ""
        }
    }
}
