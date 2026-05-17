import SwiftUI

struct AnalyticsPeriodSelector: View {

    @Binding var selectedPeriod: AnalyticsPeriod

    var body: some View {

        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 12) {

                ForEach(AnalyticsPeriod.allCases, id: \.self) { period in

                    Button {

                        selectedPeriod = period

                    } label: {

                        Text(period.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedPeriod == period
                                ? Color.white
                                : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(
                                selectedPeriod == period
                                ? .black
                                : .white
                            )
                            .cornerRadius(20)

                    }

                }

            }
            .padding(.horizontal)

        }

    }

}
