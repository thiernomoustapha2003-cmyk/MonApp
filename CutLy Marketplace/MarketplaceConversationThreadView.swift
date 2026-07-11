//
//  MarketplaceConversationThreadView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 03/07/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MarketplaceConversationThreadView: View {
    let conversationId: String
    let productId: String
    let sellerId: String
    let productTitle: String

    @Environment(\.colorScheme) private var colorScheme

    @State private var messageText = ""
    @State private var messages: [MarketplaceThreadMessage] = []
    @State private var listener: ListenerRegistration?

    @State private var conversationTitle = "Conversation Marketplace"
    @State private var subtitle = ""
    @State private var avatarURL = ""
    
    @State private var receiverId = ""
    @State private var unreadCount = 0
    @State private var supportAvatarURL = ""
    
    @State private var conversationType = "buyerSeller"
    @State private var isVerified = false

    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation(.spring()) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            inputBar
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .background(MarketplaceUITheme.softBackgroundGradient.ignoresSafeArea())
        .onAppear {
            loadConversationInfo()
            listenMessages()
            markConversationAsRead()
            setPresence(isViewing: true)
        }
        .onChange(of: messages.count) { _ in
            markConversationAsRead()
        }
        .onDisappear {
            listener?.remove()
            clearPresence()
            
        }
    }

    private var headerSection: some View {
        HStack(spacing: 14) {
            avatarView

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(conversationTitle)
                        .font(.headline.bold())
                        .lineLimit(1)

                    if isVerified || conversationType == "support" {
                        CutlyVerifiedBadge(size: 16)
                    }
                }

                Text(subtitle.isEmpty ? productTitle : subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .frame(minWidth: 24, minHeight: 24)
                    .padding(.horizontal, unreadCount > 9 ? 6 : 0)
                    .background(
                        LinearGradient(
                            colors: [.teal, .cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
    }

    private var avatarView: some View {
        ZStack {
            if let url = URL(string: avatarURL), !avatarURL.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange, .pink, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: avatarIcon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var avatarIcon: String {
        switch conversationType {
        case "support":
            return "headset"
        case "store":
            return "storefront.fill"
        case "dispute":
            return "exclamationmark.shield.fill"
        default:
            return "person.fill"
        }
    }

    private func messageBubble(_ message: MarketplaceThreadMessage) -> some View {
        let isMe = message.senderId == Auth.auth().currentUser?.uid

        return HStack {
            if isMe { Spacer(minLength: 50) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 5) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(isMe ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background {
                        if isMe {
                            MarketplaceUITheme.primaryGradient
                        } else {
                            Color.primary.opacity(0.07)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text(message.timeText)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 290, alignment: isMe ? .trailing : .leading)

            if !isMe { Spacer(minLength: 50) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Écrire un message...", text: $messageText, axis: .vertical)
                .lineLimit(1...4)
                .padding(14)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(MarketplaceUITheme.primaryGradient)
                    .clipShape(Circle())
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func loadConversationInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("marketplace_conversations")
            .document(conversationId)
            .getDocument { snapshot, _ in
                let data = snapshot?.data() ?? [:]

                conversationType = data["type"] as? String ?? "buyerSeller"

                let participants = data["participantIds"] as? [String] ?? []
                receiverId = participants.first(where: { $0 != uid }) ?? sellerId

                unreadCount = data["unreadCount_\(uid)"] as? Int ?? 0

                if conversationType == "support" {
                    conversationTitle = "Support Cutly"
                    subtitle = "Support officiel Marketplace"
                    avatarURL = data["supportAvatarURL"] as? String ?? supportAvatarURL
                    isVerified = true
                    return
                }

                conversationTitle = data["title"] as? String
                    ?? data["sellerName"] as? String
                    ?? "Conversation Marketplace"

                subtitle = data["productTitle"] as? String ?? productTitle

                avatarURL = data["avatarURL"] as? String
                    ?? data["sellerPhotoURL"] as? String
                    ?? data["storeLogoURL"] as? String
                    ?? ""

                isVerified = data["isVerified"] as? Bool
                    ?? data["sellerVerified"] as? Bool
                    ?? false

                if avatarURL.isEmpty, !receiverId.isEmpty {
                    loadReceiverProfile(receiverId: receiverId)
                }
            }
    }
    
    private func loadReceiverProfile(receiverId: String) {
        db.collection("marketplaceUsers")
            .document(receiverId)
            .getDocument { snapshot, _ in
                let data = snapshot?.data() ?? [:]

                if avatarURL.isEmpty {
                    avatarURL = data["photoURL"] as? String ?? ""
                }

                if conversationTitle == "Conversation Marketplace" || conversationTitle.isEmpty {
                    conversationTitle = data["displayName"] as? String ?? "Utilisateur Marketplace"
                }

                isVerified =
                    data["marketplaceVerified"] as? Bool == true &&
                    data["badgeVisible"] as? Bool == true &&
                    data["certificationStatus"] as? String == "active"
            }
    }
    
    
    
    
    

    private func listenMessages() {
        listener?.remove()

        listener = db.collection("marketplace_messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    print("❌ listenMessages:", error.localizedDescription)
                    return
                }

                let firestoreMessages: [MarketplaceThreadMessage] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()

                    return MarketplaceThreadMessage(
                        id: doc.documentID,
                        senderId: data["senderId"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        createdAt: data["createdAt"] as? Timestamp,
                        isRead: data["isRead"] as? Bool ?? false
                    )
                } ?? []

                messages = firestoreMessages

                if !messages.isEmpty {
                    markConversationAsRead()
                }
            }
    }
    private func sendMessage() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let cleanText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }

        messageText = ""

        let finalReceiverId = receiverId.isEmpty ? sellerId : receiverId
        let messageRef = db.collection("marketplace_messages").document()
        let now = Timestamp(date: Date())

        

        messageRef.setData([
            "id": messageRef.documentID,
            "conversationId": conversationId,
            "senderId": uid,
            "receiverId": finalReceiverId,
            "productId": productId,
            "productTitle": productTitle,
            "text": cleanText,
            "type": "text",
            "isRead": false,
            "readAt": NSNull(),
            "createdAt": now
        ], merge: true) { error in
            if let error {
                print("❌ sendMessage:", error.localizedDescription)
            }
        }


        var updateData: [String: Any] = [
            "lastMessageText": cleanText,
            "lastMessageSenderId": uid,
            "lastMessageAt": now,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if !finalReceiverId.isEmpty {
            updateData["unreadFor"] = FieldValue.arrayUnion([finalReceiverId])
            updateData["unreadCount_\(finalReceiverId)"] = FieldValue.increment(Int64(1))
            updateData["hasUnread_\(finalReceiverId)"] = true
            updateData["unreadCount_\(uid)"] = 0
            updateData["lastReadAt_\(uid)"] = FieldValue.serverTimestamp()
        }

        db.collection("marketplace_conversations")
            .document(conversationId)
            .setData(updateData, merge: true)
    }
    private func setPresence(isViewing: Bool) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("marketplace_presence")
            .document(uid)
            .setData([

                "conversationId": conversationId,
                "isViewingConversation": isViewing,
                "updatedAt": FieldValue.serverTimestamp()

            ], merge: true)
    }
    private func clearPresence() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("marketplace_presence")
            .document(uid)
            .updateData([

                "isViewingConversation": false,
                "updatedAt": FieldValue.serverTimestamp()

            ])
    }
    
    
    
    
    
    private func markConversationAsRead() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("marketplace_conversations")
            .document(conversationId)
            .setData([
                    "unreadFor": FieldValue.arrayRemove([uid]),
                    "unreadCount_\(uid)": 0,
                    "hasUnread_\(uid)": false,
                    "lastReadAt_\(uid)": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                
                
                
            ], merge: true)
    

        db.collection("marketplace_messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .whereField("receiverId", isEqualTo: uid)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snapshot, _ in
                snapshot?.documents.forEach { document in
                    document.reference.setData([
                        "isRead": true,
                        "readAt": FieldValue.serverTimestamp()
                    ], merge: true)
                }
            }

        unreadCount = 0
    }
}

private struct MarketplaceThreadMessage: Identifiable, Hashable {
    let id: String
    let senderId: String
    let text: String
    let createdAt: Timestamp?
    let isRead: Bool

    var timeText: String {
        guard let date = createdAt?.dateValue() else { return "" }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
