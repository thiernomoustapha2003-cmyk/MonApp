import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SaveButton: View {
    
    let postId: String
    @State private var saved = false
    
    var body: some View {
        
        Button {
            toggleSave()
        } label: {
            Image(systemName: saved ? "bookmark.fill" : "bookmark")
                .resizable()
                .frame(width: 26, height: 26)
                .foregroundColor(.white)
        }
        .onAppear {
            checkSaved()
        }
    }
    
    func checkSaved() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("postSaves")
            .document("(postId)(uid)")
            .getDocument { doc, _ in
                saved = doc?.exists ?? false
            }
    }
    
    func toggleSave() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Firestore.firestore().collection("postSaves").document("(postId)(uid)")
        
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
}
