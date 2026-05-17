import SwiftUI
import Charts

struct SpectatorDonutChart: View {

    let male: Double
    let female: Double
    let other: Double

    var body: some View {

        VStack(spacing: 22) {

            // DONUT CHART STYLE TIKTOK

            Chart {

                SectorMark(
                    angle: .value("Homme", male),
                    innerRadius: .ratio(0.7),
                    angularInset: 2
                )
                .foregroundStyle(Color.blue)

                SectorMark(
                    angle: .value("Femme", female),
                    innerRadius: .ratio(0.7),
                    angularInset: 2
                )
                .foregroundStyle(Color.blue.opacity(0.45))

                SectorMark(
                    angle: .value("Autre", other),
                    innerRadius: .ratio(0.7),
                    angularInset: 2
                )
                .foregroundStyle(Color.gray.opacity(0.35))

            }
            .chartLegend(.hidden)
            .frame(height: 180)

            // LÉGENDE STYLE TIKTOK

            VStack(spacing: 16) {

                AudienceRow(
                    color: .blue,
                    title: "Homme",
                    value: male
                )

                Divider()

                AudienceRow(
                    color: Color.blue.opacity(0.45),
                    title: "Femme",
                    value: female
                )

                Divider()

                AudienceRow(
                    color: Color.gray.opacity(0.35),
                    title: "Autre",
                    value: other
                )

            }
            .padding(.horizontal, 4)

        }
        .padding(.top, 6)
    }
}

struct AudienceRow: View {

    let color: Color
    let title: String
    let value: Double

    var body: some View {

        HStack(spacing: 10) {

            Circle()
                .fill(color)
                .frame(width: 9, height: 9)

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)

            Spacer()

            Text("\(Int(value)) %")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)

        }
        .padding(.vertical, 2)

    }
}
