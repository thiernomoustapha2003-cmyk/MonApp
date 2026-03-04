import SwiftUI

struct ShareActionButton: View {
    
    let postId: String
    
    var body: some View {
        
        VStack(spacing: 4) {
            
            Button {
                print("Share tapped")
            } label: {
                Image(systemName: "arrowshape.turn.up.right.fill")
                    .resizable()
                    .frame(width: 26, height: 26)
                    .foregroundColor(.white)
            }
            
            Text("Partager")
                .font(.caption2)
                .foregroundColor(.white)
        }
    }
}
