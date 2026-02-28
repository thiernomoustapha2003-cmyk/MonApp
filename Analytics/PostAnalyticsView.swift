import SwiftUI

struct PostAnalyticsView: View {
    
    let post: Post
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Total Views: \(post.totalViews ?? 0)")
                .font(.headline)
            
            if let stats = post.countryStats,
               let total = post.totalViews,
               total > 0 {
                
                ForEach(Array(stats.keys), id: \.self) { country in
                    
                    let count = stats[country] ?? 0
                    let percentage = (Double(count) / Double(total)) * 100
                    
                    HStack {
                        Text(country)
                        Spacer()
                        Text(String(format: "%.1f%%", percentage))
                    }
                }
                
            }
        }
        .padding()
    }
    
}
