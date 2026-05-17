import SwiftUI
import Charts

struct AgeChartView: View {
    
    var ageStats: [AgeStat]
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Répartition par âge")
                .font(.headline)
            
            Chart(ageStats) {
                
                BarMark(
                    x: .value("Age", $0.range),
                    y: .value("Percent", $0.percentage)
                )
                .foregroundStyle(Color.blue)
            }
            .frame(height: 200)
        }
    }
}
