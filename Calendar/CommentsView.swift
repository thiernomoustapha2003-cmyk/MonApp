import SwiftUI

struct CommentsView: View {

    let postId: String

    @State private var comments: [PostComment] = []
    @State private var text = ""

    var body: some View {

        VStack {

            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.4))
                .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(comments) { comment in
                        HStack(alignment: .top) {

                            Circle()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.gray.opacity(0.3))

                            VStack(alignment: .leading) {
                                Text(comment.userId)
                                    .font(.caption)
                                    .bold()

                                Text(comment.text)
                            }
                        }
                    }
                }
                .padding()
            }

            HStack {

                TextField("Ajouter un commentaire...", text: $text)
                    .textFieldStyle(.roundedBorder)

                Button("Envoyer") {
                    guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    CommentService.shared.send(postId: postId, text: text)
                    text = ""
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .onAppear {
            CommentService.shared.listenComments(postId: postId) {
                self.comments = $0
            }
        }
    }
}
