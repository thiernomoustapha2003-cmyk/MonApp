import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct RightActionColumn: View {
    
    let post: Post
    @State private var showSoundView = false
    @State private var animateSound = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    
    var body: some View {
        
        VStack(spacing: 28)
        {
            Spacer()
            
            // MARK: - PROFILE + FOLLOW
            ProfileFollowButton(
                userId: post.creatorId ?? "",
                avatarURL: post.creatorAvatar ?? "",
                isLive: true
            )
            
            // MARK: - LIKE
            LikeButton(post: post)
            
            // MARK: - COMMENT
            CommentButton(postId: post.id ?? "")
            
            // MARK: - SAVE
            SaveButton(postId: post.id ?? "")
            
            // MARK: - SHARE
            Button {
                sharePost()
            } label: {
                Image(systemName: "arrowshape.turn.up.right.fill")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)
            }
            
            // =========================
            // MARK: - DELETE BUTTON (PRO)
            // =========================

            if post.creatorId == Auth.auth().currentUser?.uid {
                Button {
                    showDeleteAlert = true
                } label: {
                    if isDeleting {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "trash")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.red)
                    }
                }
                .alert("Supprimer la publication ?", isPresented: $showDeleteAlert) {
                    Button("Annuler", role: .cancel) {}
                    
                    Button("Supprimer", role: .destructive) {
                        deletePostCompletely()
                    }
                } message: {
                    Text("Cette action est irréversible.")
                }
            }
            
            // =========================
            // MARK: - SOUND BUTTON
            // =========================
            
            if post.soundId != nil {
                
                Button {
                    showSoundView = true
                } label: {
                    
                    ZStack {
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .blur(radius: 6)
                            .opacity(0.6)
                        
                        Circle()
                            .fill(Color.black.opacity(0.9))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.pink, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(animateSound ? 360 : 0))
                            .animation(
                                .linear(duration: 3)
                                .repeatForever(autoreverses: false),
                                value: animateSound
                            )
                    }
                }
                .onAppear {
                    animateSound = true
                }
                .sheet(isPresented: $showSoundView) {
                    SoundView(post: post)
                }
            }
        }
        .padding(.trailing, 12)
        .padding(.bottom, 150)
    }
    
    // =========================
    // MARK: - SHARE FUNCTION
    // =========================
    
    private func sharePost() {
        guard let url = URL(string: post.mediaURL) else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
    
    // =========================
    // MARK: - DELETE COMPLETE (Firestore + Storage)
    // =========================
    
    private func deletePostCompletely() {
        guard let postId = post.id else { return }
        guard let mediaURL = URL(string: post.mediaURL) else { return }
        
        isDeleting = true
        
        let storageRef = Storage.storage().reference(forURL: mediaURL.absoluteString)
        
        // 1️⃣ Supprimer du Storage
        storageRef.delete { storageError in
            
            if let storageError = storageError {
                print("❌ Storage delete error:", storageError)
            }
            
            // 2️⃣ Supprimer du Firestore
            Firestore.firestore()
                .collection("posts")
                .document(postId)
                .delete { error in
                    
                    isDeleting = false
                    
                    if let error = error {
                        print("❌ Firestore delete error:", error)
                    } else {
                        print("✅ Post complètement supprimé")
                    }
                }
        }
    }
}
