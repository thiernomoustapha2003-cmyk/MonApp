import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CommentsView: View {

    let postId: String

    // AJOUT EN HAUT
    @State private var likedComments: Set<String> = []
    @State private var expandedComments: Set<String> = []
    @State private var sortByTop = false

    @State private var comments: [PostComment] = []
    @State private var text = ""
    @State private var replyingTo: PostComment? = nil

    var body: some View {

        VStack {

            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.4))
                .padding(.top, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {

                    // SORT TOGGLE
                    HStack {
                        Button(sortByTop ? "Top" : "Récent") {
                            sortByTop.toggle()
                        }
                        .font(.caption)
                        .foregroundColor(.gray)

                        Spacer()
                    }

                    ForEach(sortedRootComments) { comment in

                        commentRow(comment)

                        let replies = comments.filter { $0.parentCommentId == comment.id }

                        if !replies.isEmpty {

                            VStack(alignment: .leading, spacing: 18) {

                                Button {
                                    toggleReplies(comment.id ?? "")
                                } label: {
                                    Text(expandedComments.contains(comment.id ?? "")
                                         ? "Masquer réponses"
                                         : "Afficher \(replies.count) réponses")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                if expandedComments.contains(comment.id ?? "") {
                                    ForEach(replies) { reply in
                                        commentRow(reply, isReply: true)
                                            .padding(.leading, 50)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }

                    // TON ForEach ORIGINAL — réorganisé mais conservé
                    ForEach(comments) { comment in

                        HStack(alignment: .top) {

                            Circle()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.gray.opacity(0.3))

                            VStack(alignment: .leading, spacing: 6) {

                                // USER + TIME
                                HStack(spacing: 6) {
                                    Text(comment.userId.prefix(6))
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)

                                    Text("•")
                                        .foregroundColor(.gray)

                                    Text(timeAgoString(from: comment.createdAt))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }

                                // TEXT
                                Text(comment.text)
                                    .foregroundColor(.white)

                                // ACTION ROW
                                HStack(spacing: 16) {

                                    // LIKE BUTTON
                                    Button {
                                        CommentService.shared.toggleLike(comment: comment)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: comment.likesCount > 0 ? "heart.fill" : "heart")
                                                .foregroundColor(comment.likesCount > 0 ? .red : .gray)

                                            Text("\(comment.likesCount)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    // REPLY BUTTON
                                    Button {
                                        print("Reply tapped for:", comment.id ?? "")
                                    } label: {
                                        Text("Répondre")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }

                            Spacer()
                        }
                    }
                }
                .padding()
            }

            Divider()

            VStack(spacing: 8) {

                if let replyingTo {
                    HStack {
                        Text("Réponse à \(replyingTo.userId.prefix(6))")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Spacer()

                        Button("Annuler") {
                            self.replyingTo = nil
                        }
                        .font(.caption)
                    }
                }

                HStack {

                    TextField("Ajouter un commentaire...", text: $text)
                        .textFieldStyle(.roundedBorder)

                    Button("Envoyer") {
                        sendComment()
                    }
                }
            }
            .padding()
        }
        .background(Color.black)
        .onAppear {
            CommentService.shared.listenComments(postId: postId) {
                self.comments = $0
            }
        }
    }

    // MARK: - COMMENT ROW

    private func commentRow(_ comment: PostComment, isReply: Bool = false) -> some View {

        HStack(alignment: .top, spacing: 12) {

            Circle()
                .frame(width: 36, height: 36)
                .foregroundColor(.gray.opacity(0.3))

            VStack(alignment: .leading, spacing: 6) {

                HStack(spacing: 6) {

                    Text(comment.userId.prefix(6))
                        .font(.caption)
                        .bold()
                        .foregroundColor(.white)

                    if comment.userId == postCreatorId {
                        Text("Créateur")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }

                Text(comment.text)
                    .foregroundColor(.white)

                HStack(spacing: 14) {

                    Text(timeAgoString(from: comment.createdAt))
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Button("Répondre") {
                        replyingTo = comment
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
            }

            Spacer()

            VStack(spacing: 6) {

                Button {
                    toggleLike(comment)
                } label: {
                    Image(systemName: likedComments.contains(comment.id ?? "")
                          ? "heart.fill"
                          : "heart")
                        .foregroundColor(likedComments.contains(comment.id ?? "")
                                         ? .red
                                         : .gray)
                        .scaleEffect(likedComments.contains(comment.id ?? "") ? 1.2 : 1)
                        .animation(.spring(), value: likedComments)
                }

                Text("\(comment.likesCount)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .swipeActions(edge: .trailing) {
            if comment.userId == Auth.auth().currentUser?.uid {
                Button(role: .destructive) {
                    deleteComment(comment)
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - SEND COMMENT

    private func sendComment() {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        CommentService.shared.send(
            postId: postId,
            text: text,
            parentCommentId: replyingTo?.id
        )

        text = ""
        replyingTo = nil
    }

    // MARK: - COMPUTED PROPERTIES

    private var rootComments: [PostComment] {
        comments.filter { $0.parentCommentId == nil }
    }

    private var sortedRootComments: [PostComment] {
        sortByTop
        ? rootComments.sorted { $0.likesCount > $1.likesCount }
        : rootComments.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
    }

    private var postCreatorId: String {
        comments.first?.postId ?? ""
    }

    // MARK: - REPLIES TOGGLE

    private func toggleReplies(_ id: String) {
        if expandedComments.contains(id) {
            expandedComments.remove(id)
        } else {
            expandedComments.insert(id)
        }
    }

    // MARK: - LIKE LOGIC

    private func toggleLike(_ comment: PostComment) {
        guard let commentId = comment.id,
              let uid = Auth.auth().currentUser?.uid else { return }

        let likeId = "\(uid)_\(commentId)"
        let likeRef = Firestore.firestore().collection("commentLikes").document(likeId)

        likeRef.getDocument { snapshot, _ in

            if snapshot?.exists == true {
                likeRef.delete()
                likedComments.remove(commentId)
                decrementLike(commentId)
            } else {
                likeRef.setData([
                    "commentId": commentId,
                    "userId": uid,
                    "createdAt": Timestamp()
                ])
                likedComments.insert(commentId)
                incrementLike(commentId)
            }
        }
    }

    private func incrementLike(_ commentId: String) {
        Firestore.firestore()
            .collection("postComments")
            .document(commentId)
            .updateData([
                "likesCount": FieldValue.increment(Int64(1))
            ])
    }

    private func decrementLike(_ commentId: String) {
        Firestore.firestore()
            .collection("postComments")
            .document(commentId)
            .updateData([
                "likesCount": FieldValue.increment(Int64(-1))
            ])
    }

    private func deleteComment(_ comment: PostComment) {
        guard let id = comment.id else { return }

        Firestore.firestore()
            .collection("postComments")
            .document(id)
            .delete()
    }
}

// MARK: - TIME FORMATTER

private func timeAgoString(from timestamp: Date?) -> String {

    guard let date = timestamp else { return "" }

    let seconds = Int(Date().timeIntervalSince(date))

    if seconds < 60 {
        return "à l’instant"
    } else if seconds < 3600 {
        return "\(seconds / 60) min"
    } else if seconds < 86400 {
        return "\(seconds / 3600) h"
    } else {
        return "\(seconds / 86400) j"
    }
}
