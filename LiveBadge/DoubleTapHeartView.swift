import SwiftUI

struct DoubleTapHeartView: View {
    
    @State private var animate = false
    
    var body: some View {
        
        Image(systemName: "heart.fill")
            .resizable()
            .frame(width: 120, height: 110)
            .foregroundColor(.white)
            .scaleEffect(animate ? 1.2 : 0.3)
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animate = true
                }
            }
    }
}
