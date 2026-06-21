//
//  StyleCommentsView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 20/06/2026.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct StyleComment: Identifiable {
    let id: String
    let userId: String
    let text: String
    let createdAt: Date
}

struct StyleCommentsView: View {

    let style: Style

    @State private var comment = ""
    @State private var comments: [StyleComment] = []
    @State private var isLoading = true

    var body: some View {

        NavigationStack {

            VStack(spacing: 12) {

                if isLoading {
                    ProgressView()
                        .padding()
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {

                        ForEach(comments) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.text)
                                    .font(.body)

                                Text(formatDate(item.createdAt))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.10))
                            .cornerRadius(14)
                        }
                    }
                    .padding()
                }

                HStack {
                    TextField("Écrire un commentaire...", text: $comment)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        sendComment()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                    }
                    .disabled(comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Commentaires")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                listenComments()
            }
        }
    }

    func listenComments() {
        guard let styleId = style.id else { return }

        Firestore.firestore()
            .collection("styles")
            .document(styleId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in

                let docs = snapshot?.documents ?? []

                self.comments = docs.map { doc in
                    let data = doc.data()

                    return StyleComment(
                        id: doc.documentID,
                        userId: data["userId"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }

                self.isLoading = false
            }
    }

    func sendComment() {
        let clean = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        StylesService.shared.addComment(
            style: style,
            text: clean
        )

        comment = ""
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
