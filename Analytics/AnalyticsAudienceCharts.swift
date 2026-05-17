import SwiftUI
import Charts

struct AnalyticsAudienceCharts: View {

    @ObservedObject var engine: AnalyticsEngine

    var body: some View {

        VStack(alignment: .leading, spacing: 20) {

            Text("Activité des spectateurs")
                .font(.headline)

            Chart(engine.hourlyAudience) { item in

                BarMark(
                    x: .value("Heure", item.hour),
                    y: .value("Spectateurs", item.viewers)
                )
                .foregroundStyle(.purple)
            }
            .frame(height: 240)

            VStack(alignment: .leading, spacing: 8) {

                ForEach(engine.hourlyAudience) { item in

                    HStack {

                        Text("\(item.hour)h")

                        Spacer()

                        Text("\(item.viewers) vues")
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
