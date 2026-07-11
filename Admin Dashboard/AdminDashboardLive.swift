//
//  AdminDashboardLive.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

//
//  AdminDashboardLive.swift
//  MonApp
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Charts

struct AdminLiveItem: Identifiable {

    let id: String

    let hostId: String

    let hostName: String

    let hostAvatar: String

    let title: String

    let category: String

    let viewers: Int

    let likes: Int

    let gifts: Int

    let revenue: Double

    let reports: Int

    let duration: TimeInterval

    let country: String

    let startedAt: Date

    let isFeatured: Bool

    let isRestricted: Bool

    let aiRiskLevel: Int

}

enum AdminLiveMenu: String, CaseIterable, Identifiable {

    case overview = "Vue générale"
    case moderation = "Modération"
    case reports = "Signalements"
    case revenues = "Revenus"
    case ai = "IA"

    var id: String { rawValue }

}

struct AdminDashboardLive: View {

    
    
    @StateObject private var aiService = AdminAIService.shared
    
    @State var liveListener: ListenerRegistration?

    @State var selectedModerationLive: AdminLiveItem?

    @State var pendingModerationAction: String?

    @State var showModerationConfirm = false

    @State var lives: [AdminLiveItem] = []

    @State var selectedMenu: AdminLiveMenu = .overview

    @State var search = ""

    @State var loading = true

    @State var totalLives = 0

    @State var totalViewers = 0

    @State var totalRevenue: Double = 0

    @State var totalReports = 0

    @State var aiAlerts = 0

    let db = Firestore.firestore()

    var body: some View {
        
        ScrollView {
            VStack(spacing:24){
                premiumHeader
                statisticsCards
                liveMenu
                liveBody
            }
            .padding()
        }
        .confirmationDialog(
            "Confirmer l’action de modération",
            isPresented: $showModerationConfirm,
            titleVisibility: .visible
        ) {
            Button("Confirmer", role: .destructive) {
                runPendingModerationAction()
            }

            Button("Annuler", role: .cancel) {
                selectedModerationLive = nil
                pendingModerationAction = nil
            }
        } message: {
            Text("Cette action sera enregistrée dans l’audit admin et l’utilisateur recevra une notification.")
        }
        .background(
            Color(
                red:0.96,
                green:0.97,
                blue:1
            )
        )
        .navigationTitle("Live Center")
        
        .onAppear {
            startLiveRealtimeListener()
        }
        .onDisappear {
            stopLiveRealtimeListener()
        }
        
    }
    // MARK: - HEADER PREMIUM
    
    private var premiumHeader: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            
            HStack {
                
                VStack(alignment: .leading, spacing: 6) {
                    
                    Text("Centre de contrôle Live")
                        .font(.system(size: 34, weight: .bold))
                    
                    Text("Surveillance, modération et statistiques en temps réel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))
                    
                }
                
                Spacer()
                
                Button {
                    
                    Task {
                        await loadLives()
                    }
                    
                } label: {
                    
                    Label("Actualiser", systemImage: "arrow.clockwise")
                        .padding(.horizontal,18)
                        .padding(.vertical,10)
                        .background(Color.purple)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    
                }
                
            }
            
            HStack(spacing: 14) {

                Image(systemName: "magnifyingglass")
                    .font(.headline.bold())
                    .foregroundColor(.black)

                TextField("Rechercher un live, un créateur...", text: $search)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
            .padding(16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
        }
        
    }
    
    // MARK: - CARTES PREMIUM
    
    private var statisticsCards: some View {
        
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 18
        ) {
            
            AdminDashboardCard(
                title: "Lives",
                value: "\(totalLives)",
                subtitle: "En direct",
                icon: "dot.radiowaves.left.and.right"
            )
            
            AdminDashboardCard(
                title: "Spectateurs",
                value: "\(totalViewers)",
                subtitle: "Connectés",
                icon: "person.3.fill"
            )
            
            AdminDashboardCard(
                title: "Revenus",
                value: formatEUR(totalRevenue),
                subtitle: "Aujourd'hui",
                icon: "eurosign.circle.fill"
            )
            
            AdminDashboardCard(
                title: "Signalements",
                value: "\(totalReports)",
                subtitle: "À traiter",
                icon: "flag.fill"
            )
            
            AdminDashboardCard(
                title: "Alertes IA",
                value: "\(aiAlerts)",
                subtitle: "Détection automatique",
                icon: "brain.head.profile"
            )
            
        }
        
    }
    
    // MARK: - MENU
    
    private var liveMenu: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            
            HStack(spacing: 14) {
                
                ForEach(AdminLiveMenu.allCases) { menu in
                    
                    Button {
                        
                        withAnimation(.spring()) {
                            
                            selectedMenu = menu
                            
                        }
                        
                    } label: {
                        
                        Text(menu.rawValue)
                            .font(.headline)
                            .padding(.horizontal,18)
                            .padding(.vertical,12)
                            .background(
                                selectedMenu == menu
                                ? Color.purple
                                : Color.white
                            )
                            .foregroundStyle(
                                selectedMenu == menu
                                ? .white
                                : .primary
                            )
                            .clipShape(Capsule())
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    // MARK: - CONTENU PRINCIPAL
    
    @ViewBuilder
    private var liveBody: some View {
        
        switch selectedMenu {
            
        case .overview:
            liveOverview
            
        case .moderation:
            moderationView
            
        case .reports:
            reportsView
            
        case .revenues:
            revenuesView
            
        case .ai:
            aiModerationView
            
        }
        
    }
    
    // MARK: - LISTE DES LIVES
    
    private var liveOverview: some View {
        
        VStack(spacing:20){
            
            if loading{
                
                ProgressView()
                
            }else if lives.isEmpty{
                
                AdminEmptyState(
                    text: "Aucun live en cours."
                )
                
            }else{
                
                ForEach(lives){ live in
                    
                    liveCard(live)
                    
                }
                
            }
            
        }
        
    }
    
    // MARK: - CARTE LIVE
    @ViewBuilder
    private func liveCard(
        _ live: AdminLiveItem
    ) -> some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack(alignment: .top) {

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 120, height: 80)
                    .overlay {

                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(.red)

                    }

                VStack(alignment: .leading, spacing: 6) {

                    Text(live.hostName)
                        .font(.headline)

                    Text(live.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))

                    HStack {

                        Label(
                            "\(live.viewers)",
                            systemImage: "person.3.fill"
                        )

                        Label(
                            "\(live.likes)",
                            systemImage: "heart.fill"
                        )

                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black.opacity(0.78))

                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {

                    Text(formatEUR(live.revenue))
                        .font(.headline)

                    Text("Revenus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black.opacity(0.78))

                    aiRiskBadge(live.aiRiskLevel)

                }

            }

            Divider()

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 14
            ) {

                liveInfo(
                    icon: "gift.fill",
                    title: "Cadeaux",
                    value: "\(live.gifts)"
                )

                liveInfo(
                    icon: "flag.fill",
                    title: "Signalements",
                    value: "\(live.reports)"
                )

                liveInfo(
                    icon: "clock.fill",
                    title: "Durée",
                    value: liveDuration(live.duration)
                )

                liveInfo(
                    icon: "location.fill",
                    title: "Pays",
                    value: live.country
                )

            }

            Divider()

            HStack(spacing: 12) {

                Button {

                    print("Ouvrir live")

                } label: {

                    Label(
                        "Voir",
                        systemImage: "play.fill"
                    )

                }
                .buttonStyle(.borderedProminent)

                Button {

                    aiService.analyzeLiveText(
                        liveId: live.id,
                        hostId: live.hostId,
                        hostName: live.hostName,
                        text: live.title
                    )

                } label: {

                    Label(
                        "Analyser IA",
                        systemImage: "brain.head.profile"
                    )

                }
                .buttonStyle(.bordered)

                Button {

                    print("Statistiques")

                } label: {

                    Label(
                        "Stats",
                        systemImage: "chart.bar.fill"
                    )

                }
                .buttonStyle(.bordered)

            }

        }
        .padding(22)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 26)
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 10
        )

    }
    
    
    // MARK: - PETITES CARTES
    
    private func liveInfo(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        VStack(spacing: 10) {

            Image(systemName: icon)
                .font(.title2.bold())
                .foregroundStyle(.purple)

            Text(value.isEmpty ? "—" : value)
                .font(.headline.bold())
                .foregroundStyle(.primary)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary.opacity(0.75))

        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }
    // MARK: - MODÉRATION
    
    private var moderationView: some View {
        
        VStack(spacing:20){
            
            if lives.isEmpty{
                
                AdminEmptyState(
                    text: "Aucun live à modérer."
                )
                
            }else{
                
                ForEach(lives){ live in
                    
                    moderationCard(live)
                    
                }
                
            }
            
        }
        
    }
    @ViewBuilder
    private func moderationCard(
        _ live: AdminLiveItem
    ) -> some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                VStack(alignment: .leading, spacing: 5) {

                    Text(live.hostName)
                        .font(.headline)

                    Text(live.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))

                    HStack(spacing: 10) {
                        Label("\(live.viewers)", systemImage: "person.3.fill")
                        Label("\(live.reports)", systemImage: "flag.fill")
                        Label(formatEUR(live.revenue), systemImage: "eurosign.circle.fill")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black.opacity(0.78))
                }

                Spacer()

                aiRiskBadge(live.aiRiskLevel)
            }

            Divider()

            Text("Actions administrateur")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {

                moderationButton(
                    title: "Avertir",
                    icon: "exclamationmark.bubble.fill",
                    color: .orange
                ) {
                    selectedModerationLive = live
                    pendingModerationAction = "warn"
                    showModerationConfirm = true
                }

                moderationButton(
                    title: "Limiter visibilité",
                    icon: "eye.slash.fill",
                    color: .yellow
                ) {
                    selectedModerationLive = live
                    pendingModerationAction = "limit"
                    showModerationConfirm = true
                }

                moderationButton(
                    title: "Suspendre 7 jours",
                    icon: "pause.circle.fill",
                    color: .purple
                ) {
                    selectedModerationLive = live
                    pendingModerationAction = "suspend"
                    showModerationConfirm = true
                }

                moderationButton(
                    title: "Arrêter le live",
                    icon: "stop.circle.fill",
                    color: .red
                ) {
                    selectedModerationLive = live
                    pendingModerationAction = "stop"
                    showModerationConfirm = true
                }

                moderationButton(
                    title: "Restreindre compte",
                    icon: "person.crop.circle.badge.exclamationmark",
                    color: .pink
                ) {
                    selectedModerationLive = live
                    pendingModerationAction = "restrict"
                    showModerationConfirm = true
                }

                moderationButton(
                    title: "Bannir compte",
                    icon: "person.fill.xmark",
                    color: .black
                ) {
                    selectedModerationLive = live
                    pendingModerationAction = "ban"
                    showModerationConfirm = true
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {

                Label(
                    "Règles IA appliquées",
                    systemImage: "brain.head.profile"
                )
                .font(.headline)

                moderationRule("Insultes répétées", icon: "text.bubble.fill")
                moderationRule("Spam ou arnaque", icon: "exclamationmark.triangle.fill")
                moderationRule("Menaces ou harcèlement", icon: "shield.lefthalf.filled")
                moderationRule("Contenus interdits", icon: "eye.trianglebadge.exclamationmark.fill")
                moderationRule("Fraude cadeaux / coins", icon: "gift.fill")
                moderationRule("Comportement suspect", icon: "waveform.path.ecg")
            }
            .font(.caption)
        }
        .padding(22)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 26)
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 8
        )
    }
    private func moderationRule(
        _ text: String,
        icon: String
    ) -> some View {

        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline.bold())
                .foregroundStyle(.purple)

            Text(text)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)

            Spacer()
        }
    }
    
    
    
    private func moderationButton(
        title:String,
        icon:String,
        color:Color,
        action:@escaping()->Void
    )->some View{
        
        Button(action:action){
            
            HStack{
                
                Image(systemName:icon)
                
                Text(title)
                    .fontWeight(.semibold)
                
                Spacer()
                
            }
            .padding()
            
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        
    }
    
    private func aiRiskBadge(
        _ level:Int
    )->some View{
        
        Group{
            
            if level < 30{
                
                Label("Faible",systemImage:"checkmark.circle.fill")
                    .foregroundStyle(.green)
                
            }else if level < 70{
                
                Label("Moyen",systemImage:"exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                
            }else{
                
                Label("Élevé",systemImage:"xmark.octagon.fill")
                    .foregroundStyle(.red)
                
            }
            
        }
        
    }
    // MARK: - CENTRE DES SIGNALEMENTS
    
    private var reportsView: some View {
        
        VStack(spacing:20){
            
            if lives.isEmpty{
                
                AdminEmptyState(
                    text: "Aucun signalement."
                )
                
            }else{
                
                ForEach(lives){ live in
                    
                    reportCard(live)
                    
                }
                
            }
            
        }
        
    }
    
    @ViewBuilder
    private func reportCard(
        _ live: AdminLiveItem
    )->some View{
        
        VStack(alignment:.leading,spacing:18){
            
            HStack{
                
                VStack(alignment:.leading){
                    
                    Text(live.hostName)
                        .font(.headline)
                    
                    Text(live.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))
                    
                }
                
                Spacer()
                
                Text("\(live.reports) signalements")
                    .font(.caption.bold())
                    .padding(.horizontal,12)
                    .padding(.vertical,7)
                    .background(Color.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
                
            }
            
            Divider()
            
            Label(
                "Historique des sanctions",
                systemImage:"clock.arrow.circlepath"
            )
            .font(.headline)
            
            sanctionTimeline(
                color:.yellow,
                title:"Premier avertissement",
                subtitle:"Notification envoyée."
            )
            
            sanctionTimeline(
                color:.orange,
                title:"Visibilité réduite",
                subtitle:"Distribution limitée."
            )
            
            sanctionTimeline(
                color:.red,
                title:"Suspension temporaire",
                subtitle:"24 heures"
            )
            
            sanctionTimeline(
                color:.purple,
                title:"Suspension longue",
                subtitle:"7 jours"
            )
            
            sanctionTimeline(
                color:.black,
                title:"Bannissement définitif",
                subtitle:"En attente de validation"
            )
            
            Divider()
            
            Label(
                "Actions de modération",
                systemImage:"shield.lefthalf.filled"
            )
            .font(.headline)
            
            HStack{
                
                Button{
                    
                    print("Accepter le recours")
                    
                }label:{
                    
                    Label(
                        "Accepter",
                        systemImage:"checkmark.circle.fill"
                    )
                    
                }
                .buttonStyle(.borderedProminent)
                
                Button{
                    
                    print("Refuser le recours")
                    
                }label:{
                    
                    Label(
                        "Refuser",
                        systemImage:"xmark.circle.fill"
                    )
                    
                }
                .buttonStyle(.bordered)
                
                Button{
                    
                    print("Voir les preuves")
                    
                }label:{
                    
                    Label(
                        "Preuves",
                        systemImage:"photo.on.rectangle"
                    )
                    
                }
                .buttonStyle(.bordered)
                
            }
            
            Divider()
            
            VStack(alignment:.leading,spacing:8){
                
                Label(
                    "Analyse IA",
                    systemImage:"brain.head.profile"
                )
                .font(.headline)
                
                aiReportLine("Analyse du chat en direct")
                aiReportLine("Analyse de la voix")
                aiReportLine("Analyse vidéo")
                aiReportLine("Détection d'insultes")
                aiReportLine("Détection de harcèlement")
                aiReportLine("Détection de spam")
                aiReportLine("Détection de fraude")
                aiReportLine("Détection de nudité")
                aiReportLine("Détection de violence")
                aiReportLine("Score de confiance IA")
                
            }
            
        }
        .padding(22)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:8
        )
        
    }
    
    private func sanctionTimeline(
        color: Color,
        title: String,
        subtitle: String
    ) -> some View {

        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 13, height: 13)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)

                Text(subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black.opacity(0.82))
            }

            Spacer()
        }
    }
    
    private func aiReportLine(
        _ text: String
    ) -> some View {

        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.headline.bold())
                .foregroundStyle(.purple)

            Text(text)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)

            Spacer()
        }
    }
    // MARK: - REVENUS LIVE
    
    private var revenuesView: some View {
        
        VStack(spacing:20){
            
            revenueSummaryCard
            
            topCreatorsCard
            
            topLivesCard
            
        }
        
    }
    
    // MARK: - RÉSUMÉ DES REVENUS
    
    private var revenueSummaryCard: some View {
        
        VStack(alignment:.leading,spacing:20){
            
            Label(
                "Revenus des Lives",
                systemImage:"eurosign.circle.fill"
            )
            .font(.title2.bold())
            
            LazyVGrid(
                columns:[
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing:16
            ){
                
                liveRevenueBox(
                    icon:"gift.fill",
                    color:.pink,
                    title:"Cadeaux",
                    value:formatEUR(totalRevenue)
                )
                
                liveRevenueBox(
                    icon:"banknote.fill",
                    color:.green,
                    title:"Commission",
                    value:formatEUR(totalRevenue * 0.15)
                )
                
                liveRevenueBox(
                    icon:"person.3.fill",
                    color:.blue,
                    title:"Spectateurs",
                    value:"\(totalViewers)"
                )
                
                liveRevenueBox(
                    icon:"dot.radiowaves.left.and.right",
                    color:.orange,
                    title:"Lives",
                    value:"\(totalLives)"
                )
                
            }
            
        }
        .padding(22)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )
        .shadow(
            color:.black.opacity(0.05),
            radius:10
        )
        
    }
    
    // MARK: - TOP CRÉATEURS
    
    private var topCreatorsCard: some View{
        
        VStack(alignment:.leading,spacing:18){
            
            Label(
                "Top créateurs",
                systemImage:"crown.fill"
            )
            .font(.title3.bold())
            
            ForEach(
                lives
                    .sorted{
                        $0.revenue > $1.revenue
                    }
                    .prefix(5)
            ){ live in
                
                HStack{
                    
                    Image(systemName:"person.crop.circle.fill")
                        .font(.title)
                    
                    VStack(alignment:.leading){
                        
                        Text(live.hostName)
                            .font(.headline)
                        
                        Text(formatEUR(live.revenue))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black.opacity(0.82))
                        
                    }
                    
                    Spacer()
                    
                    Image(systemName:"chevron.right")
                    
                }
                .padding(.vertical,6)
                
            }
            
        }
        .padding(22)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )
        
    }
    
    // MARK: - TOP LIVES
    
    private var topLivesCard: some View{
        
        VStack(alignment:.leading,spacing:18){
            
            Label(
                "Top Lives",
                systemImage:"flame.fill"
            )
            .font(.title3.bold())
            
            ForEach(
                lives
                    .sorted{
                        $0.viewers > $1.viewers
                    }
                    .prefix(5)
            ){ live in
                
                HStack{
                    
                    VStack(alignment:.leading){
                        
                        Text(live.title)
                            .font(.headline)
                        
                        Text(live.hostName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black.opacity(0.82))
                        
                    }
                    
                    Spacer()
                    
                    Text("\(live.viewers)")
                        .bold()
                    
                }
                .padding(.vertical,5)
                
            }
            
        }
        .padding(22)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )
        
    }
    
    // MARK: - KPI
    
    private func liveRevenueBox(
        icon: String,
        color: Color,
        title: String,
        value: String
    ) -> some View {

        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title.bold())
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)

            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.82))
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    // MARK: - IA & SURVEILLANCE
    
    private var aiModerationView: some View {
        
        ScrollView {
            
            VStack(spacing:20){
                
                aiStatusCard
                
                aiRulesCard
                
                moderatorActivityCard
                
                realtimeAlertsCard
                
                exportsCard
                
            }
            
        }
        
    }
    
    // MARK: - ÉTAT IA
    
    private var aiStatusCard: some View {
        
        VStack(alignment:.leading,spacing:18){
            
            HStack{
                
                Image(systemName:"brain.head.profile")
                    .font(.system(size:34))
                    .foregroundStyle(.purple)
                
                VStack(alignment:.leading){
                    
                    Text("Cutly AI")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)

                    Text("Surveillance automatique des Lives")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))
                    
                }
                
                Spacer()
                
                Label(
                    "ACTIF",
                    systemImage:"checkmark.circle.fill"
                )
                .foregroundStyle(.green)
                
            }
            
            Divider()
            
            aiStatusRow(
                icon:"message.fill",
                title:"Analyse du chat",
                value:"Active"
            )
            
            aiStatusRow(
                icon:"waveform",
                title:"Analyse vocale",
                value:"Active"
            )
            
            aiStatusRow(
                icon:"video.fill",
                title:"Analyse vidéo",
                value:"Active"
            )
            
            aiStatusRow(
                icon:"shield.fill",
                title:"Protection anti-spam",
                value:"Active"
            )
            
            aiStatusRow(
                icon:"exclamationmark.triangle.fill",
                title:"Alertes IA",
                value:"\(aiAlerts)"
            )
            
        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )
        
    }
    
    // MARK: - RÈGLES IA
    
    private var aiRulesCard: some View {
        
        VStack(alignment:.leading,spacing:18){
            
            Label(
                "Moteur de règles",
                systemImage:"gearshape.2.fill"
            )
            .font(.title3.bold())
            
            aiRule("Insultes répétées")
            aiRule("Discours haineux")
            aiRule("Spam")
            aiRule("Menaces")
            aiRule("Arnaques")
            aiRule("Fraude cadeaux")
            aiRule("Usurpation d'identité")
            aiRule("Contenu interdit")
            aiRule("Violence")
            aiRule("Nudité")
            aiRule("Harcèlement")
            
        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )
        
    }
    
    // MARK: - ACTIVITÉ MODÉRATEURS
    
    private var moderatorActivityCard: some View {
        
        VStack(alignment:.leading,spacing:18){
            
            Label(
                "Journal des modérateurs",
                systemImage:"person.badge.shield.checkmark.fill"
            )
            .font(.title3.bold())
            
            moderatorLog(
                "Live suspendu",
                "IA + validation modérateur"
            )
            
            moderatorLog(
                "Visibilité réduite",
                "Spam détecté"
            )
            
            moderatorLog(
                "Avertissement envoyé",
                "Insultes"
            )
            
        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )
        
    }
    
    // MARK: - ALERTES
    
    private var realtimeAlertsCard: some View {
        
        VStack(alignment:.leading,spacing:18){
            
            Label(
                "Alertes temps réel",
                systemImage:"bell.badge.fill"
            )
            .font(.title3.bold())
            
            alertRow(
                color:.red,
                text:"Risque élevé détecté"
            )
            
            alertRow(
                color:.orange,
                text:"Hausse inhabituelle des signalements"
            )
            
            alertRow(
                color:.green,
                text:"Tous les serveurs fonctionnent"
            )
            
        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )
        
    }
    
    // MARK: - EXPORTS
    
    private var exportsCard: some View {
        
        VStack(alignment:.leading,spacing:18){
            
            Label(
                "Exports",
                systemImage:"square.and.arrow.up.fill"
            )
            .font(.title3.bold())
            
            HStack{
                
                Button("PDF"){
                    
                    exportPDF()
                    
                }
                .buttonStyle(.borderedProminent)
                
                Button("CSV"){
                    
                    exportCSV()
                    
                }
                .buttonStyle(.bordered)
                
            }
            
        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )
        
    }
    // MARK: - FIRESTORE

    @MainActor
    func loadLives() async {

        loading = true

        defer {

            loading = false

        }

        do {

            let snapshot = try await db
                .collection("lives")
                .getDocuments()

            lives.removeAll()

            var revenue: Double = 0

            var viewers = 0

            var reports = 0

            for document in snapshot.documents {

                let data = document.data()

                let item = AdminLiveItem(

                    id: document.documentID,

                    hostId: data["hostId"] as? String ?? "",

                    hostName: data["hostName"] as? String ?? "Créateur",

                    hostAvatar: data["hostAvatar"] as? String ?? "",

                    title: data["title"] as? String ?? "Live",

                    category: data["category"] as? String ?? "Général",

                    viewers: data["viewers"] as? Int ?? 0,

                    likes: data["likes"] as? Int ?? 0,

                    gifts: data["gifts"] as? Int ?? 0,

                    revenue: data["revenue"] as? Double ?? 0,

                    reports: data["reports"] as? Int ?? 0,

                    duration: data["duration"] as? Double ?? 0,

                    country: data["country"] as? String ?? "",

                    startedAt: (data["startedAt"] as? Timestamp)?.dateValue() ?? Date(),

                    isFeatured: data["isFeatured"] as? Bool ?? false,

                    isRestricted: data["isRestricted"] as? Bool ?? false,

                    aiRiskLevel: data["aiRiskLevel"] as? Int ?? 0

                )

                lives.append(item)

                revenue += item.revenue

                viewers += item.viewers

                reports += item.reports

            }

            totalLives = lives.count

            totalRevenue = revenue

            totalViewers = viewers

            totalReports = reports

            aiAlerts = lives.filter {

                $0.aiRiskLevel >= 70

            }.count

        }

        catch {

            print(error)

        }

    }

    // MARK: - EXPORTS

    private func exportPDF() {

        print("Export PDF")

    }

    private func exportCSV() {

        print("Export CSV")

    }

    // MARK: - FORMAT

    private func formatEUR(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) €"
    }

    private func liveDuration(
        _ seconds: TimeInterval
    ) -> String {

        let total = Int(seconds)

        let h = total / 3600

        let m = (total % 3600) / 60

        let s = total % 60

        return String(
            format: "%02d:%02d:%02d",
            h,
            m,
            s
        )

    }
    // MARK: - AUDIT CENTER

    private var liveAuditCenter: some View {

        VStack(spacing:20){

            auditHeader

            auditFilters

            auditTimeline

        }

    }

    // MARK: - HEADER

    private var auditHeader: some View{

        VStack(alignment:.leading,spacing:12){

            HStack{

                Image(systemName:"shield.lefthalf.filled")
                    .font(.system(size:32))
                    .foregroundStyle(.indigo)

                VStack(alignment:.leading){

                    Text("Centre d'audit")
                        .font(.title2.bold())

                    Text("Toutes les actions sont enregistrées.")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))

                }

                Spacer()

            }

        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )

    }

    // MARK: - FILTRES

    private var auditFilters: some View{

        ScrollView(.horizontal,showsIndicators:false){

            HStack(spacing:12){

                auditChip("Aujourd'hui")

                auditChip("7 jours")

                auditChip("30 jours")

                auditChip("90 jours")

                auditChip("Tous")

                auditChip("Signalements")

                auditChip("IA")

                auditChip("Modérateurs")

                auditChip("Contestations")

            }

        }

    }

    private func auditChip(
        _ text:String
    )->some View{

        Text(text)
            .font(.headline)
            .padding(.horizontal,18)
            .padding(.vertical,10)
            .background(Color.white)
            .clipShape(Capsule())

    }

    // MARK: - TIMELINE

    private var auditTimeline: some View{

        VStack(spacing:16){

            auditRow(

                color:.green,

                icon:"play.circle.fill",

                title:"Live démarré",

                subtitle:"Le créateur a lancé son live."

            )

            auditRow(

                color:.blue,

                icon:"person.3.fill",

                title:"Pic d'audience",

                subtitle:"1 245 spectateurs simultanés."

            )

            auditRow(

                color:.orange,

                icon:"brain.head.profile",

                title:"Alerte IA",

                subtitle:"Spam détecté."

            )

            auditRow(

                color:.red,

                icon:"flag.fill",

                title:"Signalement",

                subtitle:"Signalement confirmé."

            )

            auditRow(

                color:.purple,

                icon:"person.badge.shield.checkmark.fill",

                title:"Action modérateur",

                subtitle:"Visibilité réduite."

            )

            auditRow(

                color:.black,

                icon:"stop.circle.fill",

                title:"Fin du Live",

                subtitle:"Live terminé."

            )

        }

    }

    private func auditRow(
        color: Color,
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {

        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: icon)
                        .font(.headline.bold())

                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                }

                Text(subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black.opacity(0.82))
            }

            Spacer()
        }
        .padding(18)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    // MARK: - IA COMPONENTS

    private func aiStatusRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        HStack {
            Image(systemName: icon)
                .font(.headline.bold())
                .foregroundStyle(.purple)

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
        }
    }

    private func aiRule(
        _ text: String
    ) -> some View {

        HStack {
            Image(systemName: "checkmark.shield.fill")
                .font(.headline.bold())
                .foregroundStyle(.green)

            Text(text)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)

            Spacer()
        }
        .padding(.vertical, 4)
    }
    private func moderatorLog(
        _ title: String,
        _ subtitle: String
    ) -> some View {

        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.badge.shield.checkmark.fill")
                .font(.headline.bold())
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)

                Text(subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black.opacity(0.82))
            }

            Spacer()
        }
    }

    private func alertRow(
        color: Color,
        text: String
    ) -> some View {

        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 13, height: 13)

            Text(text)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)

            Spacer()
        }
    }
    private func runPendingModerationAction() {
        guard let live = selectedModerationLive,
              let action = pendingModerationAction else { return }

        switch action {
        case "warn":
            warnLive(live)
        case "limit":
            limitLiveVisibility(live)
        case "suspend":
            suspendLive(live)
        case "stop":
            stopLive(live)
        case "restrict":
            restrictLiveHost(live)
        case "ban":
            banLiveHost(live)
        default:
            break
        }

        selectedModerationLive = nil
        pendingModerationAction = nil
    }
}
