import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LiveCenterView: View {
    
    @StateObject var vm = LiveAnalyticsViewModel()
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 16) {
                
                // =========================
                // HEADER
                // =========================
                
                HStack {
                    
                    Image(systemName: "chevron.left")
                    
                    Spacer()
                    
                    Text("Centre LIVE")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Spacer()
                    
                    NavigationLink(destination: LiveStreamView()) {
                        Image(systemName: "video")
                    }
                }
                .padding()
                
                
                // =========================
                // PARCOURS LIVE
                // =========================
                
                CardView {
                    
                    HStack {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            
                            Text("Parcours LIVE")
                                .font(.headline)
                            
                            Text("Étape \(vm.liveStep)")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text("Gagne \(vm.pointsNeeded) points pour atteindre la prochaine étape et réclamer des récompenses.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("🎁")
                            .font(.largeTitle)
                    }
                }
                
                
                // =========================
                // ANALYTICS
                // =========================
                
                CardView {
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("Données analytiques LIVE")
                            .font(.headline)
                        
                        HStack {
                            StatItem(value: "\(vm.viewers)", title: "Vues")
                            Spacer()
                            StatItem(value: "\(vm.newFollowers)", title: "Followers")
                            Spacer()
                            StatItem(value: "\(vm.comments)", title: "Commentaires")
                        }
                        
                        HStack {
                            StatItem(value: "\(vm.likes)", title: "J'aime")
                            Spacer()
                            StatItem(value: "\(vm.shares)", title: "Partages")
                            Spacer()
                            StatItem(value: "\(vm.duration / 60)m", title: "Durée")
                        }
                    }
                }
                
                
                // =========================
                // RECOMPENSES
                // =========================
                
                CardView {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        
                        Text("Récompenses LIVE")
                            .font(.headline)
                        
                        HStack {
                            Text("\(vm.missionRewards)$")
                            Spacer()
                            Text("\(vm.weeklyRewards)$")
                        }
                        
                        Text("Total Diamants 💎 \(vm.diamonds)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                
                // =========================
                // DONATEURS
                // =========================
                
                CardView {
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("Meilleurs donateurs")
                            .font(.headline)
                        
                        ForEach(vm.topDonators, id: \.id) { donor in
                            DonatorRow(name: donor.name, coins: "\(donor.coins)")
                        }
                    }
                }
                
                
                // =========================
                // CAMPAGNES
                // =========================
                
                CardView {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        
                        Text("Campagnes")
                            .font(.headline)
                        
                        Text("\(vm.campaignCount) nouvelles campagnes disponibles")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button("C'est parti") {}
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                
                // =========================
                // OUTILS
                // =========================
                
                CardView {
                    
                    VStack(alignment: .leading) {
                        
                        Text("Outils et ressources")
                            .font(.headline)
                        
                        HStack {
                            
                            NavigationLink(destination: LiveReplaysView()) {
                                ToolItem(icon: "video", title: "Replays")
                            }
                            NavigationLink(destination: LiveEventsView()) {
                                ToolItem(icon: "calendar", title: "Events")
                            }
                            ToolItem(icon: "play", title: "Posts")
                            ToolItem(icon: "heart", title: "Fan Club")
                            
                        }
                    }
                }
                
                
                // =========================
                // ACADEMY
                // =========================
                
                CardView {
                    
                    VStack(alignment: .leading) {
                        
                        Text("LIVE Academy")
                            .font(.headline)
                        
                        Text("Apprends à monétiser tes lives")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
            }
            .padding()
        }
        .onAppear {
            vm.listenLiveData()
        }
    }
}
