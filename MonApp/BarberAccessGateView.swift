import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct BarberAccessGateView: View {
    
    @State private var completionPercentage: Int = 0
    @State private var isProfileComplete = false
    @State private var loading = true
    
    private let db = Firestore.firestore()
    private let uid = Auth.auth().currentUser?.uid ?? ""
    
    var body: some View {
        Group {
            if loading {
                ProgressView("Vérification du profil...")
            }
            else if isProfileComplete {
                BarberDashboardView()
            }
            else {
                lockedView
            }
        }
        .onAppear {
            checkProfileCompletion()
        }
    }
    
    var lockedView: some View {
        VStack(spacing: 25) {
            
            Text("🔒 Dashboard verrouillé")
                .font(.title)
                .bold()
            
            Text("Profil professionnel complété à \(completionPercentage)%")
                .font(.headline)
            
            ProgressView(value: Double(completionPercentage), total: 100)
                .padding(.horizontal)
            
            Button("Compléter mon profil") {
                // redirection vers profil
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    func checkProfileCompletion() {
        
        db.collection("users").document(uid).getDocument { snapshot, _ in
            
            guard let data = snapshot?.data() else {
                loading = false
                return
            }
            
            var score = 0
            
            if !(data["name"] as? String ?? "").isEmpty { score += 15 }
            if !(data["city"] as? String ?? "").isEmpty { score += 15 }
            if !(data["phone"] as? String ?? "").isEmpty { score += 15 }
            if !(data["imageUrl"] as? String ?? "").isEmpty { score += 15 }
            // Stripe optionnel → pas bloquant
            if data["acceptsOnlinePayment"] as? Bool == true {
                score += 10
            }
            if data["isPro"] as? Bool == true { score += 20 }
            
            DispatchQueue.main.async {
                completionPercentage = score
                isProfileComplete = score >= 70
                loading = false
            }
        }
    }
}
