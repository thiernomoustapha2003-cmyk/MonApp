import SwiftUI

struct AudienceTabButton: View {

    let tab: AudienceTab
    @Binding var selectedAudienceTab: AudienceTab

    var body: some View {

        Button {
            
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedAudienceTab = tab
            }

        } label: {

            Text(tab.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    selectedAudienceTab == tab
                    ? Color.blue.opacity(0.15)
                    : Color(.systemGray5)
                )
                .foregroundColor(
                    selectedAudienceTab == tab
                    ? .blue
                    : .primary
                )
                .cornerRadius(10)
        }
    }
}
