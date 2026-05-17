import SwiftUI

struct MetricBox: View {

    let title: String
    let value: String

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 22, weight: .bold))

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
