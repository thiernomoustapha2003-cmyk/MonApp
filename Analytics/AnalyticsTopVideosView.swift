import SwiftUI

struct AnalyticsTopVideosView: View {

    @ObservedObject var engine: AnalyticsEngine

    var body: some View {

        VStack(alignment: .leading, spacing: 20) {

            Text("Top vidéos")
                .font(.headline)

            ForEach(engine.topVideos) { video in

                VStack(alignment: .leading, spacing: 10) {

                    HStack {

                        VStack(alignment: .leading, spacing: 4) {

                            Text("Vidéo \(video.id)")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            HStack(spacing: 16) {

                                Label("\(video.views)", systemImage: "eye")

                                Label("\(video.likes)", systemImage: "heart")

                                Label("\(video.comments)", systemImage: "bubble.right")
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }

                        Spacer()
                    }

                    Divider()
                }
            }

            if engine.topVideos.isEmpty {

                Text("Aucune vidéo disponible")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding()
    }
}
