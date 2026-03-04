import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SaveButton: View {
    
    let postId: String
    
    @State private var saved = false
    @State private var saveCount: Int = 0
    
    private let db = Firestore.firestore()
    
    var body: some View {
        
        VStack(spacing: 4) {
            
            Button {
                toggleSave()
            } label: {
                Image(systemName: saved ? "bookmark.fill" : "bookmark")
                    .resizable()
                    .frame(width: 26, height: 30)
                    .foregroundColor(saved ? .yellow : .white)
                    .scaleEffect(saved ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: saved)
            }
            
            Text(formatNumber(saveCount))
                .font(.caption2)
                .foregroundColor(.white)
        }
        .onAppear {
            checkSaved()
            listenSaveCount()
        }
    }
    
    // MARK: - Check if current user saved
    func checkSaved() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("postSaves")
            .document("\(postId)_\(uid)")
            .getDocument { doc, _ in
                saved = doc?.exists ?? false
            }
    }
    
    // MARK: - Toggle Save
    func toggleSave() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = db.collection("postSaves")
            .document("\(postId)_\(uid)")
        
        if saved {
            ref.delete()
        } else {
            ref.setData([
                "postId": postId,
                "userId": uid,
                "createdAt": Timestamp()
            ])
        }
    }
    
    // MARK: - Listen Save Count
    func listenSaveCount() {
        db.collection("postSaves")
            .whereField("postId", isEqualTo: postId)
            .addSnapshotListener { snap, _ in
                saveCount = snap?.documents.count ?? 0
            }
    }
    
    // MARK: - Format numbers like TikTok
    func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
}
