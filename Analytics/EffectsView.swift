import SwiftUI

struct EffectsView: View {
    
    var effects: [LiveEffect]
    var onSelect: (LiveEffect) -> Void
    
    var body: some View {
        
        VStack {
            
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray)
                .padding(.top, 8)
            
            Text("Effets")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                
                HStack(spacing: 16) {
                    
                    ForEach(effects) { effect in
                        
                        Button {
                            onSelect(effect)
                        } label: {
                            
                            VStack {
                                Image(systemName: effect.icon)
                                    .font(.title2)
                                
                                Text(effect.name)
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(height: 200)
        .background(Color.black.opacity(0.9))
    }
}
