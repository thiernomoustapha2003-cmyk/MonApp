import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import AuthenticationServices




struct ClientHomeView: View {

    @StateObject var viewModel = BarberViewModel()

    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    @State private var isAdmin = false
    @State private var isPlatformOwner = false

    @State private var showLoginSheet = false
    @State private var selectedBarberForAction: Barber? = nil
    @State private var pendingAction: PendingAction? = nil

    // MARK: - ROUTAGE APPEL WHATSAPP-LIKE
    @State private var openConversation = false
    @State private var routedConversationId = ""
    @State private var routedOtherUserName = "Conversation"

    @State private var showRoutedCall = false
    @State private var routedCallId: String?
    @State private var routedCallType = "audio"
    
    @State private var path = NavigationPath()
    
    
    enum PendingAction {
        case call
        case whatsapp
        case book
    }
    enum HomeDestination: Hashable {
        case messages
        case bookings
        case marketplace
        case profile
    }
    
    
    var filteredBarbers: [Barber] {
        viewModel.barbers.filter { barber in
            let matchesSearch = searchText.isEmpty ||
            barber.name.lowercased().contains(searchText.lowercased()) ||
            barber.city.lowercased().contains(searchText.lowercased())

            let matchesFavorite = !showFavoritesOnly || barber.isFavorite
            return matchesSearch && matchesFavorite
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        if isAdmin && isPlatformOwner {
                            adminCenterCard
                        }

                        NavigationLink {
                            MarketplaceHomeView()
                        } label: {
                            CutlyMarketplaceCard()
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            LiveDiscoveryView()
                        } label: {
                            CutlyLiveCard()
                        }
                        .buttonStyle(.plain)

                        TextField("Rechercher un coiffeur...", text: $searchText)
                            .font(.system(size: 16, weight: .semibold))
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal)

                        Toggle("Afficher mes favoris", isOn: $showFavoritesOnly)
                            .font(.headline)
                            .padding(.horizontal)

                        if viewModel.isLoading {
                            ProgressView("Chargement des coiffeurs...")
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else if filteredBarbers.isEmpty {
                            Text("Aucun coiffeur trouvé")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredBarbers) { barber in
                                    barberRow(barber)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        Spacer(minLength: 95)
                    }
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
                    
                    
                }
                .background(Color(red: 0.96, green: 0.96, blue: 0.99))

                premiumBottomBar
            }
            .navigationTitle("Coiffeurs")
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .messages:
                    ChatListView()
                case .bookings:
                    ClientBookingsView()
                case .marketplace:
                    MarketplaceHomeView()
                case .profile:
                    ClientProfilePlaceholderView()
                }
            }
            .onAppear {
                viewModel.fetchBarbers()
                checkAdminAccess()
            }
            .sheet(isPresented: $showLoginSheet, onDismiss: {
                if Auth.auth().currentUser != nil {
                    performPendingAction()
                }
            }) {
                LoginView()
            }
            .fullScreenCover(isPresented: $showRoutedCall) {
                CallScreenView(
                    name: routedOtherUserName,
                    avatarURL: nil,
                    mode: routedCallType == "video" ? .video : .audio,
                    callId: routedCallId,
                    conversationId: routedConversationId
                ) { duration in
                    if let callId = routedCallId {
                        CallService.shared.endCall(
                            callId: callId,
                            conversationId: routedConversationId,
                            type: routedCallType,
                            duration: duration
                        )
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenAcceptedCall"))) { notification in
                handleOpenAcceptedCall(notification)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Se déconnecter") {
                    try? Auth.auth().signOut()
                    print("🔴 Déconnecté")
                }
            }
        }
    }

    var adminCenterCard: some View {
        NavigationLink {
            AdminDashboardView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Cutly Business Center")
                        .font(.headline.bold())

                    Text("Dashboard propriétaire")
                        .font(.caption.weight(.semibold))
                }

                Spacer()

                Image(systemName: "lock.shield.fill")
            }
            .foregroundColor(.black)
            .padding()
            .background(Color.yellow)
            .cornerRadius(20)
            .padding(.horizontal)
        }
    }

    var premiumBottomBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                bottomItem("Accueil", "house.fill") { }

                bottomItem("Messages", "message.fill") {
                    path.append(HomeDestination.messages)
                }

                bottomItem("Réservations", "calendar.badge.checkmark") {
                    path.append(HomeDestination.bookings)
                }

                bottomItem("Marketplace", "bag.fill") {
                    path.append(HomeDestination.marketplace)
                }

                bottomItem("Profil", "person.crop.circle.fill") {
                    path.append(HomeDestination.profile)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    func bottomItem(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))

                Text(title)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundColor(.purple)
            .frame(width: 92, height: 58)
            .background(Color.purple.opacity(0.10))
            .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }
    
    
    
    private func barberRow(_ barber: Barber) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink(destination: BarberDetailView(barber: barber)) {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: barber.imageUrl ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(barber.name).font(.headline)

                            Text("Disponible")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                        }

                        Text(barber.city)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Text("💰 \(barber.price, specifier: "%.2f") €")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    Button {
                        toggleFavorite(barber: barber)
                    } label: {
                        Image(systemName: barber.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(barber.isFavorite ? .red : .gray)
                            .font(.title3)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())

            Divider()

            HStack {
                Button("📅 Réserver") {
                    handleAction(barber: barber, action: .book)
                }
                .foregroundColor(.blue)
                .buttonStyle(BorderlessButtonStyle())

                Spacer()

                Button("📞 Appeler") {
                    handleAction(barber: barber, action: .call)
                }
                .foregroundColor(.orange)
                .buttonStyle(BorderlessButtonStyle())

                Spacer()

                Button("💬 WhatsApp") {
                    handleAction(barber: barber, action: .whatsapp)
                }
                .foregroundColor(.green)
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.vertical, 6)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    // MARK: - ROUTAGE CALLKIT

    func handleOpenAcceptedCall(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        let callId = userInfo["callId"] as? String
        let conversationId = userInfo["conversationId"] as? String ?? ""
        let type = userInfo["type"] as? String ?? "audio"
        let callerName = userInfo["callerName"] as? String ?? "Appel Cutly"

        guard !conversationId.isEmpty else {
            print("❌ OpenAcceptedCall sans conversationId")
            return
        }

        routedCallId = callId
        routedConversationId = conversationId
        routedCallType = type
        routedOtherUserName = callerName

        openConversation = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showRoutedCall = true
        }

        print("📞 ClientHomeView route vers conversation + appel:", conversationId)
    }

    func handleAction(barber: Barber, action: PendingAction) {
        selectedBarberForAction = barber
        pendingAction = action

        if Auth.auth().currentUser == nil {
            showLoginSheet = true
        } else {
            performPendingAction()
        }
    }

    func performPendingAction() {
        guard let barber = selectedBarberForAction,
              let action = pendingAction else { return }

        switch action {
        case .call:
            let cleaned = barber.phone.replacingOccurrences(of: " ", with: "")
            if let url = URL(string: "tel://\(cleaned)") {
                UIApplication.shared.open(url)
            }

        case .whatsapp:
            let cleaned = barber.phone.replacingOccurrences(of: " ", with: "")
            let whatsappURL = "https://wa.me/\(cleaned)"
            if let url = URL(string: whatsappURL) {
                UIApplication.shared.open(url)
            }

        case .book:
            print("👉 Réserver avec \(barber.name)")
        }
    }

    
    func checkAdminAccess() {
        guard let user = Auth.auth().currentUser else {
            isAdmin = false
            isPlatformOwner = false
            return
        }

        let uid = user.uid
        let email = user.email ?? ""

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { snapshot, error in

                if let error = error {
                    print("❌ Erreur admin access:", error.localizedDescription)
                    return
                }

                let data = snapshot?.data() ?? [:]

                let role = data["role"] as? String ?? ""
                let owner = data["isPlatformOwner"] as? Bool ?? false
                let adminBool = data["isAdmin"] as? Bool ?? false
                let adminLevel = data["adminLevel"] as? String ?? ""
                
                print("========== ADMIN CHECK ==========")
                print("UID :", uid)
                print("Email :", email)
                print("Firestore data :", data)
                print("role =", role)
                print("isAdmin =", adminBool)
                print("isPlatformOwner =", owner)
                print("adminLevel =", adminLevel)
                print("=================================")
                

                let allowedEmails = [
                    "thiernomoustapha2003@gmail.com"
                ]

                let access =
                    role == "admin" ||
                    adminBool == true ||
                    owner == true ||
                    adminLevel == "owner" ||
                    allowedEmails.contains(email)

                DispatchQueue.main.async {
                    self.isAdmin = access
                    self.isPlatformOwner = owner || allowedEmails.contains(email)

                    print("🔐 Admin access check")
                    print("UID:", uid)
                    print("Email:", email)
                    print("role:", role)
                    print("isAdmin:", adminBool)
                    print("isPlatformOwner:", owner)
                    print("adminLevel:", adminLevel)
                    print("ACCESS:", access)
                }
            }
    }
    

    func toggleFavorite(barber: Barber) {
        guard let clientId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let barberId = barber.authId

        let clientFavRef = db.collection("users")
            .document(clientId)
            .collection("favoriteBarbers")
            .document(barberId)

        clientFavRef.getDocument { snap, _ in
            if snap?.exists == true {
                clientFavRef.delete()
            } else {
                clientFavRef.setData([
                    "barberId": barberId,
                    "barberName": barber.name,
                    "barberCity": barber.city,
                    "barberImageUrl": barber.imageUrl ?? "",
                    "createdAt": Timestamp()
                ])
            }

            viewModel.fetchBarbers()
        }
    }
}

struct CutlyLiveCard: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 54, height: 54)

                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.red)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("CUTLY LIVE")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }

                Text("Découvre les coiffeurs en direct")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.black,
                    Color.red.opacity(0.85),
                    Color.purple.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .red.opacity(0.35), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }
}
struct CutlyMarketplaceCard: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.purple.opacity(0.16))
                    .frame(width: 58, height: 58)

                Image(systemName: "bag.fill")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("CUTLY MARKETPLACE")
                        .font(.headline.bold())
                        .foregroundColor(.black)

                    Text("Nouveau")
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(7)
                }

                Text("Acheter, vendre, expédier")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.black.opacity(0.72))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.black.opacity(0.45))
        }
        .padding()
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.purple.opacity(0.45), lineWidth: 1.5)
        )
        .cornerRadius(22)
        .shadow(color: .purple.opacity(0.18), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }
}

struct MarketplaceHomeView: View {
    var body: some View {
        Text("Bienvenue sur Cutly Marketplace")
            .font(.title.bold())
    }
}

struct ClientProfilePlaceholderView: View {
    var body: some View {
        Text("Mon profil")
            .font(.title.bold())
    }
}
