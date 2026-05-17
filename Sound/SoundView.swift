import SwiftUI
import AVKit
import FirebaseFirestore   // 🔥 AJOUT

struct SoundView: View {
    
    let post: Post
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                Text("Son utilisé")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                
                Text(post.safeCreatorName)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button {
                    
                    // =========================
                    // 🔥 INJECTER LE VRAI SON DEPUIS FIRESTORE
                    // =========================
                    
                    guard let soundId = post.soundId else {
                        print("❌ Aucun soundId")
                        return
                    }
                    
                    Firestore.firestore()
                        .collection("sounds")
                        .document(soundId)
                        .getDocument { snapshot, error in
                            
                            if let error = error {
                                print("❌ Erreur récupération son:", error)
                                return
                            }
                            
                            guard let sound = try? snapshot?.data(as: Sound.self) else {
                                print("❌ Son introuvable")
                                return
                            }
                            
                            FeedSoundManager.shared.selectedSound = sound
                            
                            // =========================
                            // 🔥 FERMER LA SHEET
                            // =========================
                            
                            dismiss()
                            
                            // =========================
                            // 🔥 OUVRIR UPLOAD
                            // =========================
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("OpenUpload"),
                                    object: nil
                                )
                            }
                        }
                    
                } label: {
                    Text("Utiliser ce son")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
        }
    }
}
