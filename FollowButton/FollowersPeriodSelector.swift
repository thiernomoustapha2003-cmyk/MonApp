import SwiftUI

struct FollowersPeriodSelector: View {
    
    @Binding var selectedPeriod: FollowersPeriod
    
    // AJOUT CALENDRIER
    @State private var showCalendar = false
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var endDate = Date()
    
    var body: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            
            HStack(spacing: 10) {
                
                ForEach(FollowersPeriod.allCases) { period in
                    
                    Button {
                        
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPeriod = period
                        }
                        
                        // SI PERSONNALISÉ → OUVRIR CALENDRIER
                        if period == .custom {
                            showCalendar = true
                        }
                        
                    } label: {
                        
                        Text(period.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedPeriod == period
                                ? Color.black
                                : Color(.systemGray5)
                            )
                            .foregroundColor(
                                selectedPeriod == period
                                ? .white
                                : .black
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        
        
        // CALENDRIER PERSONNALISÉ
        
        .sheet(isPresented: $showCalendar) {
            
            NavigationStack {
                
                VStack(spacing: 20) {
                    
                    Text("Choisir une période")
                        .font(.headline)
                    
                    
                    // DATE DEBUT
                    
                    DatePicker(
                        "Date début",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    
                    
                    // DATE FIN
                    
                    DatePicker(
                        "Date fin",
                        selection: $endDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    
                    
                    // BOUTON APPLIQUER
                    
                    Button {
                        
                        // on ferme le calendrier
                        showCalendar = false
                        
                        // ici ton ViewModel filtrera les données
                        NotificationCenter.default.post(
                            name: Notification.Name("CustomFollowersPeriod"),
                            object: nil,
                            userInfo: [
                                "startDate": startDate,
                                "endDate": endDate
                            ]
                        )
                        
                    } label: {
                        
                        Text("Appliquer")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Période personnalisée")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
