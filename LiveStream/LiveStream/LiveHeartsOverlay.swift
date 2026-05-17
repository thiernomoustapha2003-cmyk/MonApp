import SwiftUI

struct LiveHeartsOverlay: View {
    
    @Binding var trigger: Int
    
    @State private var hearts: [Heart] = []
    
    struct Heart: Identifiable {
        let id = UUID()
        let x: CGFloat
        let size: CGFloat
    }
    
    var body: some View {
        
        GeometryReader { geo in
            
            ZStack {
                
                ForEach(hearts) { heart in
                    
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .font(.system(size: heart.size))
                        .position(
                            x: heart.x,
                            y: geo.size.height
                        )
                        .offset(y: -300)
                        .animation(.easeOut(duration: 2), value: trigger)
                        .transition(.move(edge: .bottom))
                }
            }
            .onChange(of: trigger) { _ in
                spawnHearts(width: geo.size.width)
            }
        }
        .allowsHitTesting(false)
    }
    
    func spawnHearts(width: CGFloat) {
        
        for _ in 0..<3 {
            let heart = Heart(
                x: CGFloat.random(in: width * 0.6...width * 0.9),
                size: CGFloat.random(in: 18...32)
            )
            
            hearts.append(heart)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                hearts.removeAll { $0.id == heart.id }
            }
        }
    }
}
