import SwiftUI

struct AnalyticsRootView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            // HEADER
            HStack {
                
                Button {
                    // action retour si nécessaire
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Spacer()
                
                Text("Analytique")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                Rectangle()
                    .frame(width: 18, height: 18)
                    .opacity(0)
            }
            .padding()
            
            
            // TABS
            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: 28) {

                    tabButton("Vue d'ensemble", index: 0)
                    tabButton("Contenu", index: 1)
                    tabButton("Spectateurs", index: 2)
                    tabButton("Followers", index: 3)
                    tabButton("LIVE", index: 4)

                }
                .padding(.horizontal)

            }
            
            Divider()
            
            
            // PAGES
            TabView(selection: $selectedTab) {

                // OVERVIEW
                AnalyticsOverviewView()
                    .tag(0)

                // CONTENU
                ContentAnalyticsView()
                    .tag(1)

                // SPECTATEURS (CORRIGÉ)
                SpectatorsAnalyticsView()
                    .tag(2)

                // FOLLOWERS
                ScrollView {

                    VStack(spacing: 24) {

                        FollowersAnalyticsView()

                    }
                    .padding()

                }
                .tag(3)

                // LIVE
                LiveAnalyticsView()
                    .tag(4)

            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
        }
    }
    
    
    // TAB BUTTON
    func tabButton(_ title: String, index: Int) -> some View {
        
        Button {
            selectedTab = index
        } label: {
            
            VStack(spacing: 6) {
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundColor(selectedTab == index ? .black : .gray)
                
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(selectedTab == index ? .black : .clear)
                
            }
        }
    }
}
