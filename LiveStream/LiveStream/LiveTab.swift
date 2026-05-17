import SwiftUI

struct LiveTab: View {
    
    let title: String
    let index: Int
    
    @Binding var selectedTab: Int
    
    var body: some View {
        
        Text(title)
            .font(.caption)
            .foregroundColor(selectedTab == index ? .white : .gray)
            .onTapGesture {
                selectedTab = index
            }
    }
}
