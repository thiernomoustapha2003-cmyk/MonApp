import SwiftUI

struct ScanClientButton: View {

    var action: () -> Void

    var body: some View {
        Button(action: action) {

            VStack(spacing: 14) {

                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.black.opacity(0.85))
                        .frame(width: 150, height: 150)

                    Image(systemName: "qrcode.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 55, height: 55)
                        .foregroundColor(.white)
                }

                Text("Scanner")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(ScanPressEffect())
    }
}
