import SwiftUI

struct LiveBadgeView: View {
    
    @State private var animate = false
    
    var body: some View {
        
        Text("LIVE")
            .font(.caption2)
            .bold()
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(6)
            .scaleEffect(animate ? 1.05 : 0.95)
            .opacity(animate ? 1 : 0.8)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                    animate.toggle()
                }
            }
    }
}
