import SwiftUI
import FirebaseFirestore

struct CreatorFeedView: View {

    @State private var posts: [Post] = []

    var body: some View {

        GeometryReader { proxy in

            ScrollView(.vertical, showsIndicators: false) {

                LazyVStack(spacing: 0) {

                    ForEach(posts) { post in

                        PostCardView(post: post)
                            .frame(
                                width: proxy.size.width,
                                height: proxy.size.height
                            )
                            .id(post.id)
                    }
                }
            }
            .scrollTargetBehavior(.paging) // TikTok snap
        }
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

                print("📦 POSTS COUNT:", posts.count)
            }
    }
}
