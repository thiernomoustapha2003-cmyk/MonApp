import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct SplashView: View {
    
    @State private var scissorsAngle: Double = -30
    @State private var hairOffset: CGFloat = -250
    @State private var logoOpacity: Double = 0
    @State private var showMainView = false
    @State private var lineScale: CGFloat = 0
    
    // 👉 États pour la navigation (NOUVEAU)
    @State private var goToClient = false
    @State private var goToBarber = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                // 🎨 FOND PREMIUM (dégradé sobre)
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.2)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if !showMainView {
                    
                    VStack(spacing: 35) {
                        
                        ZStack {
                            
                            // === CHEVEUX (lignes fines qui passent) ===
                            ForEach(0..<10) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.7))
                                    .frame(width: 2, height: 35)
                                    .offset(x: CGFloat(i * 18 - 80), y: hairOffset)
                            }
                            
                            // === CISEAU PREMIUM ===
                            Image(systemName: "scissors")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 130, height: 130)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(scissorsAngle))
                                .shadow(color: .white.opacity(0.3), radius: 6, x: 0, y: 0)
                        }
                        .frame(height: 220)
                        
                        // === LIGNE MINIMALISTE SOUS LE LOGO ===
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 120 * lineScale, height: 2)
                            .animation(.easeOut(duration: 0.8), value: lineScale)
                        
                        // === NOM DE L’APP (PRO) ===
                        Text("CUTLY")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(logoOpacity)
                            .animation(.easeIn(duration: 1.2), value: logoOpacity)
                        
                        Text("Votre salon, votre style, votre rendez-vous")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .opacity(logoOpacity)
                    }
                    .onAppear {
                        launchAnimation()
                    }
                    
                } else {
                    
                    // ✅ NOUVEL ÉCRAN APRÈS L’ANIMATION (SANS SUPPRIMER TON STYLE)
                    VStack(spacing: 16) {
                        
                        Text("Bienvenue sur CUTLY")
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        
                        Text("Choisissez votre profil")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        Button(action: {
                            UserDefaults.standard.set("client", forKey: "selectedRole")
                            goToClient = true
                        }) {
                            Text("Je suis Client")
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        
                        Button(action: {
                            UserDefaults.standard.set("barber", forKey: "selectedRole")
                            goToBarber = true
                        }) {
                            Text("Je suis Coiffeur")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        
                        NavigationLink(destination: ClientHomeView(), isActive: $goToClient) {
                            EmptyView()
                        }

                        NavigationLink(destination: HomeView(), isActive: $goToBarber) {
                            EmptyView()
                        }
                    }
                }
            }
        }
    }
    
    // ===========================
    // ANIMATION PRO (TA VERSION — INCHANGÉE)
    // ===========================
    func launchAnimation() {
        
        // 1) Animation du ciseau (effet coupe)
        withAnimation(
            Animation.easeInOut(duration: 0.4)
                .repeatCount(5, autoreverses: true)
        ) {
            scissorsAngle = 25
        }
        
        // 2) Cheveux qui tombent / passent
        withAnimation(
            Animation.linear(duration: 1.6)
                .repeatCount(2, autoreverses: false)
        ) {
            hairOffset = 250
        }
        
        // 3) Apparition du logo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            logoOpacity = 1
            lineScale = 1
        }
        
        // 4) Transition vers l’écran de choix après 2.8s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut) {
                showMainView = true
            }
        }
    }
    func setRoleAndContinue(role: String) {

        // On sauvegarde seulement localement
        UserDefaults.standard.set(role, forKey: "selectedRole")

        // Navigation vers RootRouter
        if role == "barber" {
            goToBarber = true
        } else {
            goToClient = true
        }
    }
}
