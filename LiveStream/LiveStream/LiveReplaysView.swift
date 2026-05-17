import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

// MARK: - MODEL
struct LiveReplay: Identifiable {
    var id: String
    var title: String
    var thumbnail: String
    var viewers: Int
    var videoURL: String
    var createdAt: Date
}

// MARK: - VIEWMODEL
class LiveReplayViewModel: ObservableObject {
    
    @Published var replays: [LiveReplay] = []
    
    private let db = Firestore.firestore()
    
    func fetchReplays() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("lives")
            .whereField("barberId", isEqualTo: userId)
            .whereField("isReplay", isEqualTo: true)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else { return }
                
                var temp: [LiveReplay] = []
                let group = DispatchGroup()
                
                for doc in docs {
                    
                    let liveId = doc.documentID
                    let liveData = doc.data()
                    
                    // 🔥 fallback videoURL depuis le LIVE
                    let liveVideoURL = liveData["videoURL"] as? String ?? ""
                    
                    group.enter()
                    
                    self.db.collection("lives")
                        .document(liveId)
                        .collection("clips")
                        .getDocuments { clipSnapshot, _ in
                            
                            if let clips = clipSnapshot?.documents {
                                
                                for clip in clips {
                                    
                                    let data = clip.data()
                                    
                                    let replay = LiveReplay(
                                        id: clip.documentID,
                                        title: data["title"] as? String ?? "Clip",
                                        thumbnail: data["thumbnail"] as? String ?? "",
                                        viewers: data["views"] as? Int ?? 0,
                                        
                                        // 🔥 ICI LA MAGIE
                                        videoURL: data["videoURL"] as? String ?? liveVideoURL,
                                        
                                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                                    )
                                    
                                    temp.append(replay)
                                }
                            }
                            
                            group.leave()
                        }
                }
                
                group.notify(queue: .main) {
                    self.replays = temp.sorted { $0.createdAt > $1.createdAt }
                }
            }
    }
}

// MARK: - VIEW
struct LiveReplaysView: View {
    
    @StateObject var vm = LiveReplayViewModel()
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack(spacing: 20) {
                    
                    header
                    
                    if vm.replays.isEmpty {
                        Text("Aucun replay pour le moment")
                            .foregroundColor(.gray)
                            .padding(.top, 100)
                    }
                    
                    ForEach(vm.replays) { replay in
                        
                        NavigationLink {
                            LiveReplayDetailView(replay: replay)
                        } label: {
                            ReplayCard(replay: replay)
                        }
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitle("Enregistrements LIVE", displayMode: .inline)
            .onAppear {
                vm.fetchReplays()
            }
        }
    }
}

// MARK: - HEADER
extension LiveReplaysView {
    
    var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text("🎥 Tes replays LIVE")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            
            Text("Retrouve tes lives et publie des clips.")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - CARD
struct ReplayCard: View {
    
    var replay: LiveReplay
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            ZStack {
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                if let url = URL(string: replay.thumbnail), !replay.thumbnail.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray
                    }
                }
                
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .font(.title)
            }
            .frame(height: 200)
            .cornerRadius(12)
            
            Text(replay.title)
                .foregroundColor(.white)
                .font(.headline)
            
            HStack {
                Text("\(replay.viewers) vues")
                Spacer()
                Text(formatDate(replay.createdAt))
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(16)
    }
}

// MARK: - DATE
func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd/MM/yyyy HH:mm"
    return formatter.string(from: date)
}
