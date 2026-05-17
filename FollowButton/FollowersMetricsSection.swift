import SwiftUI

struct FollowersMetricsSection: View {

    var viewModel: FollowersAnalyticsViewModel

    var body: some View {

        HStack(spacing: 16) {

            metricCard(
                title: "Total des followers",
                value: formatted(viewModel.totalFollowers),
                subtitle: "Depuis le début"
            )

            metricCard(
                title: "Followers nets",
                value: formatted(viewModel.netFollowers),
                subtitle: "Gain récent"
            )
        }
    }

    @ViewBuilder
    func metricCard(title: String, value: String, subtitle: String? = nil) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .contentTransition(.numericText()) // animation des chiffres

            if let subtitle {

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // Format des nombres (ex: 1200 → 1.2K)
    func formatted(_ value: Int) -> String {

        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }

        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }

        return "\(value)"
    }
}
