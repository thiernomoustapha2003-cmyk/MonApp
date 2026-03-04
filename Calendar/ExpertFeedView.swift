import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ExpertFeedView: View {

    @State private var posts: [Post] = []
    @State private var loading = true
    @State private var currentPostId: String?
    @State private var showUpload = false
    
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if loading {
                ProgressView()
                    .tint(.white)
            } else {
                
                GeometryReader { geo in
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        
                        LazyVStack(spacing: 0) {
                            
                            ForEach(posts) { post in
                                
                                PostCardView(post: post)
                                    .frame(width: geo.size.width,
                                           height: geo.size.height)
                                    .background(Color.black)
                                    .ignoresSafeArea()
                                    .id(post.id)
                                    .onAppear {
                                        if let id = post.id {
                                            currentPostId = id
                                            trackView(postId: id)
                                            FeedPlaybackManager.shared.setCurrent(postId: id)
                                        }
                                    }
                            }
                        }
                    }
                    .scrollTargetBehavior(.paging)
                    .frame(width: geo.size.width,
                           height: geo.size.height)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { fetchPosts() }
        
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenUpload"))) { _ in
            showUpload = true
        }
        .sheet(isPresented: $showUpload) {
            UploadContentView()
        }
    }

    // MARK: FETCH POSTS
    private func fetchPosts() {

        Firestore.firestore()
            .collection("posts")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in

                guard let documents = snapshot?.documents else {
                    print("❌ No posts:", error?.localizedDescription ?? "")
                    return
                }

                print("📦 POSTS COUNT:", documents.count)

                self.posts = documents.compactMap { doc in
                    do {
                        return try doc.data(as: Post.self)
                    } catch {
                        print("❌ Decode error:", error)
                        return nil
                    }
                }

                print("POSTS ARRAY:", self.posts.count)
                self.loading = false
            }
    }

    // MARK: TRACK VIEW
    private func trackView(postId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let viewId = "\(uid)_\(postId)"
        Firestore.firestore()
            .collection("postViews")
            .document(viewId)
            .setData([
                "postId": postId,
                "userId": uid,
                "createdAt": Timestamp(date: Date())
            ], merge: true)
    }
}
