import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CreateLiveEventView: View {
    
    @State private var title = ""
    @State private var date = Date()
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            Text("Programmer un LIVE")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("Titre du live", text: $title)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            DatePicker("Date", selection: $date)
                .datePickerStyle(.compact)
            
            Button("Publier le live") {
                createEvent()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
    }
    
    
    func createEvent() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        db.collection("liveEvents").addDocument(data: [
            "title": title,
            "date": Timestamp(date: date),
            "isActive": true,
            "barberId": userId
        ]) { error in
            
            if let error = error {
                print("❌ erreur:", error.localizedDescription)
            } else {
                print("✅ live créé")
            }
        }
    }
}
