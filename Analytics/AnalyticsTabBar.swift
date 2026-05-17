import SwiftUI

struct AnalyticsTabBar: View {

    @Binding var selectedTab: AnalyticsTab

    var body: some View {

        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 20) {

                ForEach(AnalyticsTab.allCases, id: \.self) { tab in

                    Button {

                        selectedTab = tab

                    } label: {

                        VStack(spacing: 6) {

                            Text(tab.rawValue)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .black : .gray)

                            if selectedTab == tab {

                                Rectangle()
                                    .fill(Color.black)
                                    .frame(height: 2)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
