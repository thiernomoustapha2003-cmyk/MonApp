import SwiftUI

struct LiveAnalyticsView: View {
    
    @StateObject var viewModel = AnalyticsViewModel()
    
    
    @State private var showImage = false
    @State private var float = false
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack(spacing: 24) {
                    
                    // =========================
                    // 🔴 SI PAS DE LIVE
                    // =========================
                    
                    if viewModel.liveViewers == 0 {
                        
                        Image("live_analytics_illustration")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 160)
                            .rotationEffect(.degrees(float ? 2 : -2))
                            .offset(x: float ? 4 : -4, y: float ? -2 : 2)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: float)
                            .scaleEffect(showImage ? 1 : 0.8)
                            .opacity(showImage ? 1 : 0)
                            
                        // TITRE
                        Text("Explore de nouvelles données analytiques LIVE")
                            .font(.system(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // BLOCS INFO
                        VStack(spacing: 20) {
                            
                            InfoRow(
                                icon: "house",
                                title: "Nouvelle position",
                                description: "Découvre les données analytiques LIVE"
                            )
                            
                            InfoRow(
                                icon: "calendar",
                                title: "Périodes longues",
                                description: "Consulte jusqu'à 60 jours de données"
                            )
                            
                            InfoRow(
                                icon: "arrow.up",
                                title: "Mesures améliorées",
                                description: "Analyse ton engagement"
                            )
                        }
                        .padding(.horizontal)
                        
                        // 🔥 BOUTON CENTRE LIVE (SIMPLE)
                        NavigationLink(destination: LiveCenterView()) {
                            Text("Accède au Centre LIVE")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // 🔴 BOUTON LANCER LIVE (AJOUT SIMPLE)
                        NavigationLink(destination: LiveStreamView()) {
                            Text("Passer en LIVE")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pink)
                                .cornerRadius(30)
                        }
                        .padding(.horizontal)
                    }
                    
                    // =========================
                    // 🔴 SI LIVE ACTIF
                    // =========================
                    
                    else {
                        
                        VStack(spacing: 20) {
                            
                            MetricBox(title: "Spectateurs LIVE",
                                      value: "\(viewModel.liveViewers)")
                            
                            MetricBox(title: "Cadeaux reçus",
                                      value: "\(viewModel.liveGifts)")
                            
                            MetricBox(title: "Revenus LIVE",
                                      value: "\(viewModel.liveRevenue)$")
                        }
                        
                        Text("Statistiques LIVE")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Données live")
                            .foregroundColor(.gray)
                        
                        // 🔥 ACTION SIMPLE
                        NavigationLink(destination: LiveStreamView()) {
                            Text("Relancer un LIVE")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
                .onAppear {
                    showImage = true
                    float = true
                }
                .navigationTitle("LIVE")
                .navigationBarTitleDisplayMode(.inline)
                
                // 🔥 BOUTON EN HAUT À DROITE (TRÈS SIMPLE)
                .toolbar {
                    NavigationLink(destination: LiveStreamView()) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}










    
