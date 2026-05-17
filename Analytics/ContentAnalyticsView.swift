import SwiftUI
import FirebaseFirestore

struct ContentAnalyticsView: View {
    
    @State private var selectedPeriod: AnalyticsPeriod = .seven
    @State private var selectedTab = 0
    
    @StateObject private var service = ContentAnalyticsService()
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 24) {
                
                // Périodes (7 / 28 / 60 / 365 / personnalisé)
                
                AnalyticsPeriodSelector(selectedPeriod: $selectedPeriod)
                
                
                // =========================
                // TES MEILLEURES PUBLICATIONS
                // =========================
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    HStack {
                        Text("Tes meilleures publications")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Spacer()
                        
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                    }
                    
                    
                    // Onglets
                    
                    HStack(spacing: 12) {
                        
                        Button {
                            selectedTab = 0
                            service.loadVideos(period: selectedPeriod)
                        } label: {
                            
                            Text("Les plus vues")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTab == 0 ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Button {
                            selectedTab = 1
                            service.loadVideos(period: selectedPeriod)
                        } label: {
                            
                            Text("Spectateurs les plus récents")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTab == 1 ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                    }
                    
                    
                    // =========================
                    // LISTE VIDÉOS
                    // =========================
                    
                    if service.videos.isEmpty {
                        
                        VStack(spacing: 16) {
                            
                            Image(systemName: "play.rectangle")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.6))
                            
                            Text("Aucune vidéo disponible")
                                .foregroundColor(.gray)
                            
                            Text("Publie des vidéos pour voir leurs statistiques")
                                .font(.system(size: 13))
                                .foregroundColor(.gray.opacity(0.7))
                            
                        }
                        .frame(height: 200)
                        
                    } else {
                        
                        VStack(spacing: 18) {
                            
                            ForEach(service.videos.indices, id: \.self) { index in
                                
                                let video = service.videos[index]
                                
                                NavigationLink(destination: VideoAnalyticsDetailView(video: video)) {

                                    HStack(spacing: 12) {
                                    
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .frame(width: 24)
                                    
                                    if video.thumbnail.contains(".mp4") {
                                        
                                        VideoThumbnailView(videoURL: video.thumbnail)
                                        
                                    } else {
                                        
                                        AsyncImage(url: URL(string: video.thumbnail)) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Color.gray.opacity(0.3)
                                        }
                                        .frame(width: 60, height: 80)
                                        .cornerRadius(8)
                                        
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        
                                        Text(video.caption)
                                            .font(.system(size: 14, weight: .semibold))
                                            .lineLimit(2)
                                        
                                        Text("\(video.views) vues")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                        
                                        Text(video.date)
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        
                                    }
                                    
                                    Spacer()
                                }
                                }
                                
                            }
                            
                        }
                        
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
            }
            .padding()
        }
        .onAppear {
            service.loadVideos(period: selectedPeriod)
        }
        .onChange(of: selectedPeriod) { newPeriod in
            service.loadVideos(period: newPeriod)
        }
    }
}
import AVKit

struct VideoThumbnailView: View {

    let videoURL: String

    var body: some View {

        VideoPlayer(player: AVPlayer(url: URL(string: videoURL)!))
            .frame(width: 60, height: 80)
            .cornerRadius(8)

    }
}
