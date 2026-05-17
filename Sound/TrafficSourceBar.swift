import SwiftUI

struct TrafficSourceBar: View {

    let source: TrafficSource

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            HStack {

                Text(source.name)

                Spacer()

                Text("\(Int(source.percent))%")
            }

            GeometryReader { geo in

                ZStack(alignment: .leading) {

                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)

                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * (source.percent/100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
