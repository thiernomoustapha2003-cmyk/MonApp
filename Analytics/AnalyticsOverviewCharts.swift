import SwiftUI
import Charts

struct AnalyticsOverviewCharts: View {

    @ObservedObject var engine: AnalyticsEngine

    var body: some View {

        VStack(spacing: 30) {

            // MARK: VUES PAR JOUR

            VStack(alignment: .leading) {

                Text("Vues")
                    .font(.headline)

                Chart(engine.dailyViews) { item in

                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Vues", item.views)
                    )
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Vues", item.views)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 220)

            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 2)

            // MARK: SOURCES DE TRAFIC

            VStack(alignment: .leading) {

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

                        }

                    }
                }
                .padding(.top,10)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 2)

        }
        .padding()
    }
}
