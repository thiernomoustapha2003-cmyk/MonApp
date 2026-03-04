import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileFollowButton: View {
    
    let userId: String
    let avatarURL: String?
    
    // 🆕 AJOUT : état live (tu pourras le connecter plus tard à Firestore)
    var isLive: Bool = false
    
    @State private var isFollowing = false
    @State private var loading = true
    @State private var livePulse = false   // 🆕 animation live
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private let db = Firestore.firestore()
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            // 🔵 Cercle extérieur style TikTok
            Circle()
                .stroke(
                    LinearGradient(
                        colors: isLive ? [.red, .orange] : [.cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 54, height: 54)
                .scaleEffect(isLive && livePulse ? 1.08 : 1)
                .shadow(color: isLive ? .red.opacity(0.6) : .clear,
                        radius: isLive ? 8 : 0)
                .animation(
                    isLive ?
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                    value: livePulse
                )
            
            // 🔵 Avatar réel (TON CODE INTACT)
            avatarView
                .frame(width: 48, height: 48)
            
            // 🔴 Bouton +
            if shouldShowFollowButton && !loading {
                Circle()
                    .fill(Color.red)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(y: 12)
                    .transition(.scale)
            }
            
            // 🆕 Badge LIVE
            if isLive {
                Text("LIVE")
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .offset(y: 24) // 🔥 REMONTÉ
            }
        }
        .contentShape(Circle())
        .onTapGesture {
            toggleFollow()
        }
        .onAppear {
            checkFollowState()
            
            // 🆕 démarrage animation live
            if isLive {
                livePulse.toggle()
            }
        }
    }
    
    // MARK: - Avatar View (TON CODE EXACT)
    
    private var avatarView: some View {
        Group {
            if let avatarURL,
               let url = URL(string: avatarURL) {
                
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .clipShape(Circle())
                
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        }
    }
    
    // MARK: - Logique (100% intacte)
    
    private var shouldShowFollowButton: Bool {
        guard let currentUserId else { return false }
        if currentUserId == userId { return false }
        return !isFollowing
    }
    
    private func checkFollowState() {
        
        guard let currentUserId else { return }
        guard currentUserId != userId else {
            loading = false
            return
        }
        
        let docId = "\(userId)_\(currentUserId)"
        
        db.collection("userFollows")
            .document(docId)
            .getDocument { doc, _ in
                
                isFollowing = doc?.exists ?? false
                loading = false
            }
    }
    
    private func toggleFollow() {
        
        guard let currentUserId else { return }
        guard currentUserId != userId else { return }
        
        let docId = "\(userId)_\(currentUserId)"
        let ref = db.collection("userFollows").document(docId)
        
        if isFollowing {
            ref.delete()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isFollowing = false
            }
        } else {
            ref.setData([
                "targetUserId": userId,
                "currentUserId": currentUserId,
                "createdAt": Timestamp()
            ])
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isFollowing = true
            }
        }
    }
}
