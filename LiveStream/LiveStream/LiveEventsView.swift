import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

struct LiveEvent: Identifiable {
    var id: String
    var title: String
    var date: Date
}

class LiveEventsViewModel: ObservableObject {
    
    @Published var events: [LiveEvent] = []
    
    private let db = Firestore.firestore()
    
    func fetchEvents() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("liveEvents")
            .whereField("barberId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, _ in
                
                guard let docs = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    self.events = docs.map {
                        LiveEvent(
                            id: $0.documentID,
                            title: $0["title"] as? String ?? "Live",
                            date: ($0["date"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                }
            }
    }
}

struct LiveEventsView: View {
    
    @StateObject var vm = LiveEventsViewModel()
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 16) {
                
                
                NavigationLink(destination: CreateLiveEventView()) {
                    Text("+ Programmer un live")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                ForEach(vm.events) { event in
                    
                    VStack(alignment: .leading, spacing: 8) {
                        
                        Text(event.title)
                            .font(.headline)
                        
                        Text(event.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("EN DIRECT BIENTÔT")
                            .font(.caption)
                            .padding(6)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .onAppear {
            vm.fetchEvents()
        }
    }
}
