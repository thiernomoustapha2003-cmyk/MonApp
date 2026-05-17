import SwiftUI
import AVKit
import Charts
import FirebaseFirestore
import FirebaseAuth


struct VideoAnalyticsDetailView: View {
    
    @State private var chartData: [VideoViewPoint] = []
    
    // 🔥 nouvelles stats
    @State private var likesCount: Int = 0
    @State private var commentsCount: Int = 0
    @State private var sharesCount: Int = 0
    @State private var viewsCount: Int = 0
    
    let video: AnalyticsVideo
    
    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading, spacing: 20) {
                
                // VIDEO PLAYER

                if let url = URL(string: video.thumbnail), !video.thumbnail.isEmpty {

                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 400)
                        .cornerRadius(12)

                } else {

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 400)
                        .cornerRadius(12)
                        .overlay(
                            Text("Vidéo indisponible")
                                .foregroundColor(.white)
                        )
                }
                
                // CAPTION
                
                Text(video.caption)
                    .font(.headline)
                
                
                // STATS
                
                HStack(spacing: 16) {

                    statItem(title: "Vues", value: "\(viewsCount)")
                    statItem(title: "Likes", value: "\(likesCount)")
                    statItem(title: "Commentaires", value: "\(commentsCount)")
                    statItem(title: "Sauvegardes", value: "\(sharesCount)")

                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
                
                
                // REVENUE
                
                VStack(alignment: .leading, spacing: 6) {
                    
                    Text("Revenus générés")
                        .font(.headline)
                    
                    Text("0.00 €")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                
                // GRAPH

                VStack(alignment: .leading, spacing: 16) {
                    
                    HStack {
                        Text("Performance")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.blue)
                    }
                    
                    if chartData.isEmpty {
                        
                        VStack {
                            Spacer()
                            
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            
                            Text("Pas encore assez de données")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                        }
                        .frame(height: 220)
                        
                    } else {
                        
                        Chart {
                            
                            ForEach(chartData) { point in
                                
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Vues", point.views)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.blue)
                                
                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Vues", point.views)
                                )
                                .foregroundStyle(Color.blue)
                            }
                        }
                        .frame(height: 220)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic)
                        }
                    }
                    
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemGray6))
                )
                
                
            }
            .padding()
            
        }
        .navigationTitle("Statistiques vidéo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            
            loadStats()
            loadViewsChart()
            
        }
    }
}
    extension VideoAnalyticsDetailView {
        
        func loadStats() {
            
            let db = Firestore.firestore()
            
            // VUES
            
            db.collection("postViews")
                .whereField("postId", isEqualTo: video.id)
                .getDocuments { snapshot, _ in
                    
                    viewsCount = snapshot?.documents.count ?? 0
                }
            
            
            // LIKES
            
            db.collection("postLikes")
                .whereField("postId", isEqualTo: video.id)
                .getDocuments { snapshot, _ in
                    
                    likesCount = snapshot?.documents.count ?? 0
                }
            
            
            // COMMENTAIRES
            
            db.collection("postComments")
                .whereField("postId", isEqualTo: video.id)
                .getDocuments { snapshot, _ in
                    
                    commentsCount = snapshot?.documents.count ?? 0
                }
            
            
            // PARTAGES
            
            db.collection("postSaves")
                .whereField("postId", isEqualTo: video.id)
                .getDocuments { snapshot, _ in
                    
                    sharesCount = snapshot?.documents.count ?? 0
                }
        }
    }

extension VideoAnalyticsDetailView {
    
    func loadViewsChart() {

        let db = Firestore.firestore()

        db.collection("postViews")
            .whereField("postId", isEqualTo: video.id)
            .order(by: "createdAt")
            .getDocuments { snapshot, _ in

                guard let docs = snapshot?.documents else { return }

                var grouped: [Date: Int] = [:]

                for doc in docs {

                    if let timestamp = doc["createdAt"] as? Timestamp {

                        let date = Calendar.current.startOfDay(for: timestamp.dateValue())

                        grouped[date, default: 0] += 1
                    }
                }

                var points = grouped.map {
                    VideoViewPoint(date: $0.key, views: $0.value)
                }

                points.sort { $0.date < $1.date }

                // 🔥 si pas assez de données on ajoute un point
                if points.count == 1 {
                    points.append(
                        VideoViewPoint(
                            date: Date(),
                            views: points.first?.views ?? 0
                        )
                    )
                }

                chartData = points
            }
    }
    func statItem(title: String, value: String) -> some View {
        
        VStack(spacing: 6) {
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
        }
        .frame(maxWidth: .infinity)
    }
    }

