import SwiftUI

struct StudioButton: View {

    var icon: String
    var title: String
    var color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40)

            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(color.gradient)
        .cornerRadius(18)
    }
}
