import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ExpertFeedView: View {

    @State private var posts: [Post] = []
    @State private var loading = true
    @State private var currentPostId: String?
    @State private var showUpload = false
    
    // 🔥 Algorithme feed
    @StateObject private var rankingEngine = FeedRankingEngine()
    
    
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
        .onAppear {
            loadFeed()
        }
        
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenUpload"))) { _ in
            showUpload = true
        }
        .sheet(isPresented: $showUpload) {
            UploadContentView()
        }
    }

    // MARK: LOAD FEED WITH ALGORITHM
    private func loadFeed() {
        
        rankingEngine.loadRecommendedFeed()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            
            let ids = rankingEngine.recommendedPosts
            
            if ids.isEmpty {
                fetchPostsFallback()
                return
            }
            
            Firestore.firestore()
                .collection("posts")
                .whereField(FieldPath.documentID(), in: ids)
                .getDocuments { snapshot, error in
                    
                    guard let documents = snapshot?.documents else {
                        print("❌ Feed error:", error?.localizedDescription ?? "")
                        return
                    }
                    
                    self.posts = documents.compactMap { doc in
                        try? doc.data(as: Post.self)
                    }
                    
                    self.loading = false
                }
        }
    }

    // MARK: FALLBACK (if algorithm empty)
    private func fetchPostsFallback() {

        Firestore.firestore()
            .collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in

                guard let documents = snapshot?.documents else {
                    print("❌ No posts:", error?.localizedDescription ?? "")
                    return
                }

                self.posts = documents.compactMap { doc in
                    try? doc.data(as: Post.self)
                }

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
