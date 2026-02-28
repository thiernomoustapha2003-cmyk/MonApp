import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddClientNoteView: View {
    
    var client: Client
    @State private var note = ""
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Ajouter note pour \(client.name)")
                .font(.headline)
            
            TextEditor(text: $note)
                .frame(height: 150)
                .border(Color.gray)
            
            Button("Enregistrer") {
                saveNote()
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
    }
    
    private func saveNote() {
        guard let barberId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        db.collection("clientNotes")
            .addDocument(data: [
                "clientId": client.id ?? "",
                "barberId": barberId,
                "content": note,
                "createdAt": Timestamp(date: Date())
            ])
    }
}
