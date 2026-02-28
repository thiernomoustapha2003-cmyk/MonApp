import SwiftUI
import FirebaseFirestore

struct CreatorFeedView: View {

    @State private var posts: [Post] = []

    var body: some View {

        TabView {
            ForEach(posts) { post in
                PostCardView(post: post)
                    .tag(post.id ?? "")
           
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .rotationEffect(.degrees(-90))
        .ignoresSafeArea()
        .onAppear {
            loadPosts()
        }
    }

    // MARK: - LOAD POSTS
    func loadPosts() {
        Firestore.firestore()
            .collection("posts")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in

                guard let docs = snapshot?.documents else { return }

                self.posts = docs.compactMap { try? $0.data(as: Post.self) }
            }
    }
}
