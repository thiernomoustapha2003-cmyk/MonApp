import SwiftUI
import Charts

struct AnalyticsTrafficSources: View {

    @ObservedObject var engine: AnalyticsEngine

    var body: some View {

        VStack(alignment: .leading, spacing: 20) {

            Text("Sources de trafic")
                .font(.headline)

            Chart(engine.trafficSources) { source in

                BarMark(
                    x: .value("Source", source.name),
                    y: .value("Pourcentage", source.percent)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 8) {

                ForEach(engine.trafficSources, id: \.id) { source in

                    HStack {

                        Text(source.name.capitalized)

                        Spacer()

                        Text(String(format: "%.1f %%", source.percent))
                            .foregroundColor(.gray)
                    }
                }
            }

        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding()
    }
}
