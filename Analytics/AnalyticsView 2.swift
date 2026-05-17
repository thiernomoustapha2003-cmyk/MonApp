import SwiftUI

struct AnalyticsView: View {
    
    @State private var selectedTab = 0
    
    // 🔥 moteur analytics UNIQUE
    @StateObject var engine = AnalyticsEngine()
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            // HEADER
            
            HStack {
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text("Analytique")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Spacer()
                    .frame(width: 20)
            }
            .padding()
            
            
            // TABS
            
            ScrollView(.horizontal, showsIndicators: false) {
                
                HStack(spacing: 20) {
                    
                    TabButton(title: "Vue d'ensemble", index: 0, selectedTab: $selectedTab)
                    TabButton(title: "Contenu", index: 1, selectedTab: $selectedTab)
                    TabButton(title: "Spectateurs", index: 2, selectedTab: $selectedTab)
                    TabButton(title: "Followers", index: 3, selectedTab: $selectedTab)
                    TabButton(title: "LIVE", index: 4, selectedTab: $selectedTab)
                    
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            
            // CONTENT
            
            Group {
                
                if selectedTab == 0 {
                    
                    // OVERVIEW
                    AnalyticsOverviewView()
                    
                }
                
                else if selectedTab == 1 {
                    
                    // CONTENT
                    
                    ScrollView {
                        
                        VStack(spacing: 24) {
                            
                            AnalyticsTopVideosView(engine: engine)
                            
                        }
                        .padding()
                    }
                    
                }
                
                else if selectedTab == 2 {
                    
                    // SPECTATORS
                    
                    SpectatorsAnalyticsView()
                }
                
                else if selectedTab == 3 {
                    
                    // FOLLOWERS
                    
                    FollowersAnalyticsView()
                    
                }
                
                else if selectedTab == 4 {
                    
                    // LIVE
                    
                    VStack {
                        
                        Spacer()
                        
                        Text("Statistiques LIVE")
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                }
            }
        }
    }
}



struct TabButton: View {
    
    let title: String
    let index: Int
    
    @Binding var selectedTab: Int
    
    var body: some View {
        
        VStack(spacing: 6) {
            
            Button {
                selectedTab = index
            } label: {
                
                Text(title)
                    .font(.system(size: 16, weight: selectedTab == index ? .semibold : .regular))
                    .foregroundColor(selectedTab == index ? .black : .gray)
            }
            
            Rectangle()
                .fill(selectedTab == index ? Color.black : Color.clear)
                .frame(height: 2)
        }
    }
}
