//
//  AdminDashboardAppeals.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

//
//  AdminDashboardAppeals.swift
//  MonApp
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AdminAppealItem: Identifiable {

    let id: String

    let userId: String

    let userName: String

    let email: String

    let country: String

    let sanctionType: String

    let reason: String

    let explanation: String

    let evidenceCount: Int

    let aiScore: Int

    let status: String

    let priority: String

    let moderator: String

    let createdAt: Date

}

enum AdminAppealMenu: String, CaseIterable, Identifiable {

    case waiting = "En attente"

    case reviewing = "En cours"

    case accepted = "Acceptés"

    case rejected = "Refusés"

    case ai = "IA"

    var id: String {

        rawValue

    }

}

struct AdminDashboardAppeals: View {
    
    @State private var appeals: [AdminAppealItem] = []
    
    @State private var selectedMenu: AdminAppealMenu = .waiting
    
    @State private var search = ""
    
    @State private var loading = true
    
    @State private var totalAppeals = 0
    
    @State private var pendingAppeals = 0
    
    @State private var acceptedAppeals = 0
    
    @State private var rejectedAppeals = 0
    
    @State private var aiSuggestions = 0
    
    private let db = Firestore.firestore()
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing:24){
                
                premiumHeader
                
                statisticsCards
                
                menuBar
                
                contentView
                
            }
            .padding()
            
        }
        .background(
            
            Color(
                red:0.96,
                green:0.97,
                blue:1
            )
            
        )
        
        .navigationTitle("Contestations")
        
        .task {
            
            await loadAppeals()
            
        }
        
    }
    // MARK: - HEADER PREMIUM

    private var premiumHeader: some View {

        VStack(alignment:.leading,spacing:20){

            HStack{

                VStack(alignment:.leading,spacing:6){

                    Text("Centre des Contestations")
                        .font(.system(size:34,weight:.bold))

                    Text("Gestion complète des recours utilisateurs")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))

                }

                Spacer()

                Button{

                    Task{

                        await loadAppeals()

                    }

                }label:{

                    Label(
                        "Actualiser",
                        systemImage:"arrow.clockwise"
                    )
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

                TextField("Rechercher un utilisateur, un dossier...", text: $search)
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

    // MARK: - STATISTIQUES

    private var statisticsCards: some View {

        LazyVGrid(
            columns:[
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing:18
        ){

            AdminDashboardCard(
                title:"Recours",
                value:"\(totalAppeals)",
                subtitle:"Total",
                icon:"doc.text.fill"
            )

            AdminDashboardCard(
                title:"En attente",
                value:"\(pendingAppeals)",
                subtitle:"À traiter",
                icon:"clock.fill"
            )

            AdminDashboardCard(
                title:"Acceptés",
                value:"\(acceptedAppeals)",
                subtitle:"Validés",
                icon:"checkmark.seal.fill"
            )

            AdminDashboardCard(
                title:"Refusés",
                value:"\(rejectedAppeals)",
                subtitle:"Rejetés",
                icon:"xmark.seal.fill"
            )

            AdminDashboardCard(
                title:"IA",
                value:"\(aiSuggestions)",
                subtitle:"Suggestions",
                icon:"brain.head.profile"
            )

        }

    }

    // MARK: - MENU

    private var menuBar: some View {

        ScrollView(.horizontal,showsIndicators:false){

            HStack(spacing:14){

                ForEach(AdminAppealMenu.allCases){ menu in

                    Button{

                        withAnimation(.spring()){

                            selectedMenu = menu

                        }

                    }label:{

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
    
    // MARK: - CONTENU

    @ViewBuilder
    private var contentView: some View {

        switch selectedMenu {

        case .waiting:
            waitingAppealsView

        case .reviewing:
            reviewingAppealsView

        case .accepted:
            acceptedAppealsView

        case .rejected:
            rejectedAppealsView

        case .ai:
            aiAppealsView

        }

    }

    // MARK: - EN ATTENTE

    private var waitingAppealsView: some View {

        VStack(spacing:20){

            let filtered = appeals.filter {

                $0.status == "waiting"

            }

            if filtered.isEmpty {

                AdminEmptyState(
                    text: "Aucune contestation en attente."
                )

            } else {

                ForEach(filtered) { appeal in

                    appealCard(appeal)

                }

            }

        }

    }

    // MARK: - EN COURS

    private var reviewingAppealsView: some View {

        VStack(spacing:20){

            let filtered = appeals.filter {

                $0.status == "reviewing"

            }

            if filtered.isEmpty {

                AdminEmptyState(
                    text: "Aucun dossier en cours."
                )

            } else {

                ForEach(filtered) { appeal in

                    appealCard(appeal)

                }

            }

        }

    }

    // MARK: - ACCEPTÉS

    private var acceptedAppealsView: some View {

        VStack(spacing:20){

            let filtered = appeals.filter {

                $0.status == "accepted"

            }

            if filtered.isEmpty {

                AdminEmptyState(
                    text: "Aucun recours accepté."
                )

            } else {

                ForEach(filtered) { appeal in

                    appealCard(appeal)

                }

            }

        }

    }

    // MARK: - REFUSÉS

    private var rejectedAppealsView: some View {

        VStack(spacing:20){

            let filtered = appeals.filter {

                $0.status == "rejected"

            }

            if filtered.isEmpty {

                AdminEmptyState(
                    text: "Aucun recours refusé."
                )

            } else {

                ForEach(filtered) { appeal in

                    appealCard(appeal)

                }

            }

        }

    }

    // MARK: - CARTE

    @ViewBuilder
    private func appealCard(
        _ appeal: AdminAppealItem
    ) -> some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                VStack(alignment: .leading, spacing: 6) {
                    Text(appeal.userName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)

                    Text(appeal.email.isEmpty ? "Email non renseigné" : appeal.email)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black.opacity(0.82))
                }

                Spacer()

                priorityBadge(appeal.priority)
            }

            Divider()

            HStack {
                Label(appeal.country.isEmpty ? "Pays inconnu" : appeal.country, systemImage: "location.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.82))

                Spacer()

                Label(appeal.sanctionType.isEmpty ? "Sanction" : appeal.sanctionType, systemImage: "shield.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.82))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Motif de la contestation")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)

                Text(appeal.reason.isEmpty ? "Aucun motif renseigné." : appeal.reason)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)

                Text(appeal.explanation.isEmpty ? "Aucune explication fournie." : appeal.explanation)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black.opacity(0.82))
            }

            Divider()

            HStack {
                Label("\(appeal.evidenceCount) preuve(s)", systemImage: "photo.stack.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.82))

                Spacer()

                Label("IA \(appeal.aiScore)%", systemImage: "brain.head.profile")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.purple)
            }

            Divider()

            HStack {
                Button {
                    print("Voir le dossier")
                } label: {
                    Label("Voir", systemImage: "eye.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    print("Analyser IA")
                } label: {
                    Label("IA", systemImage: "brain.head.profile")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(22)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: .black.opacity(0.06), radius: 8)
    }
    // MARK: - ACTIONS MODÉRATEUR

    private func moderatorActions(
        _ appeal: AdminAppealItem
    ) -> some View {

        VStack(alignment:.leading,spacing:18){

            Text("Décision du modérateur")
                .font(.headline)

            LazyVGrid(
                columns:[
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing:12
            ){

                decisionButton(
                    title:"Accepter",
                    icon:"checkmark.circle.fill",
                    color:.green
                ){
                    print("Accept Appeal")
                }

                decisionButton(
                    title:"Refuser",
                    icon:"xmark.circle.fill",
                    color:.red
                ){
                    print("Reject Appeal")
                }

                decisionButton(
                    title:"Restaurer le compte",
                    icon:"person.crop.circle.badge.checkmark",
                    color:.blue
                ){
                    print("Restore Account")
                }

                decisionButton(
                    title:"Maintenir la sanction",
                    icon:"lock.fill",
                    color:.orange
                ){
                    print("Keep Sanction")
                }

                decisionButton(
                    title:"Demander plus de preuves",
                    icon:"photo.badge.plus.fill",
                    color:.purple
                ){
                    print("Need More Evidence")
                }

                decisionButton(
                    title:"Attribuer",
                    icon:"person.badge.plus.fill",
                    color:.indigo
                ){
                    print("Assign Moderator")
                }

            }

            Divider()

            Text("Commentaire interne")
                .font(.headline)

            TextEditor(text:.constant(""))
                .frame(height:120)
                .padding(8)
                .background(Color.gray.opacity(0.08))
                .clipShape(
                    RoundedRectangle(cornerRadius:16)
                )

            Divider()

            Text("Historique")

            appealHistoryRow(
                icon:"flag.fill",
                color:.red,
                title:"Compte signalé",
                subtitle:"Signalement confirmé"
            )

            appealHistoryRow(
                icon:"brain.head.profile",
                color:.purple,
                title:"Analyse IA",
                subtitle:"Risque élevé"
            )

            appealHistoryRow(
                icon:"person.badge.shield.checkmark.fill",
                color:.blue,
                title:"Modérateur",
                subtitle:"Dossier attribué"
            )

        }

    }

    private func decisionButton(

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

    private func appealHistoryRow(
        icon: String,
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
                HStack {
                    Image(systemName: icon)
                        .font(.headline.bold())
                        .foregroundColor(color)

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
        .padding(.vertical, 4)
    }

    private func priorityBadge(
        _ priority: String
    ) -> some View {

        let color: Color = {
            switch priority.lowercased() {
            case "critique":
                return .red
            case "élevée":
                return .orange
            case "moyenne":
                return .yellow
            default:
                return .green
            }
        }()

        return Text(priority.isEmpty ? "Moyenne" : priority)
            .font(.system(size: 14, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(color.opacity(0.20))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
    // MARK: - IA DES CONTESTATIONS

    private var aiAppealsView: some View {

        ScrollView {

            VStack(spacing:20){

                aiOverviewCard

                aiDecisionCard

                aiStatisticsCard

                aiRecommendationCard

            }

        }

    }

    // MARK: - VUE GÉNÉRALE IA

    private var aiOverviewCard: some View {

        VStack(alignment:.leading,spacing:18){

            HStack{

                Image(systemName:"brain.head.profile")
                    .font(.system(size:34))
                    .foregroundStyle(.purple)

                VStack(alignment:.leading){

                    Text("Cutly AI")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)

                    Text("Analyse automatique des contestations")
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
                icon:"doc.text.fill",
                title:"Dossiers analysés",
                value:"\(totalAppeals)"
            )

            aiStatusRow(
                icon:"brain.fill",
                title:"Suggestions",
                value:"\(aiSuggestions)"
            )

            aiStatusRow(
                icon:"clock.fill",
                title:"Temps moyen",
                value:"2,3 s"
            )

            aiStatusRow(
                icon:"checkmark.seal.fill",
                title:"Précision",
                value:"97 %"
            )

        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )

    }

    // MARK: - DÉCISION IA

    private var aiDecisionCard: some View {

        VStack(alignment:.leading,spacing:18){

            Label(
                "Décision proposée",
                systemImage:"brain.head.profile"
            )
            .font(.title3.bold())

            aiDecisionRow(
                color:.green,
                title:"Accepter automatiquement",
                subtitle:"Recours très solide."
            )

            aiDecisionRow(
                color:.orange,
                title:"Révision humaine",
                subtitle:"Cas complexe."
            )

            aiDecisionRow(
                color:.red,
                title:"Refus conseillé",
                subtitle:"Preuves insuffisantes."
            )

        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )

    }

    // MARK: - STATISTIQUES

    private var aiStatisticsCard: some View {

        VStack(alignment:.leading,spacing:18){

            Label(
                "Statistiques IA",
                systemImage:"chart.bar.fill"
            )
            .font(.title3.bold())

            HStack{

                statisticBox(
                    title:"Acceptés",
                    value:"82 %"
                )

                statisticBox(
                    title:"Refusés",
                    value:"18 %"
                )

            }

            HStack{

                statisticBox(
                    title:"Score moyen",
                    value:"91 %"
                )

                statisticBox(
                    title:"Confiance",
                    value:"96 %"
                )

            }

        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )

    }

    // MARK: - RECOMMANDATIONS

    private var aiRecommendationCard: some View {

        VStack(alignment:.leading,spacing:18){

            Label(
                "Recommandations IA",
                systemImage:"sparkles"
            )
            .font(.title3.bold())

            aiRecommendation("Analyser les preuves automatiquement")
            aiRecommendation("Comparer avec les précédents dossiers")
            aiRecommendation("Détecter les faux recours")
            aiRecommendation("Détecter les faux documents")
            aiRecommendation("Détecter les comptes multiples")
            aiRecommendation("Détecter les tentatives de fraude")
            aiRecommendation("Préparer une réponse automatique")
            aiRecommendation("Préparer le résumé du dossier")

        }
        .padding(24)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius:26)
        )

    }

    // MARK: - COMPOSANTS

    private func aiDecisionRow(
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

    private func statisticBox(
        title: String,
        value: String
    ) -> some View {

        VStack(spacing: 10) {
            Text(value)
                .font(.system(size: 26, weight: .bold))
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

    private func aiRecommendation(
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
    // MARK: - FIRESTORE

    @MainActor
    private func loadAppeals() async {

        loading = true

        defer {

            loading = false

        }

        do {

            let snapshot = try await db
                .collection("appeals")
                .order(by: "createdAt", descending: true)
                .getDocuments()

            appeals.removeAll()

            var pending = 0
            var accepted = 0
            var rejected = 0

            for document in snapshot.documents {

                let data = document.data()

                let item = AdminAppealItem(

                    id: document.documentID,

                    userId: data["userId"] as? String ?? "",

                    userName: data["userName"] as? String ?? "Utilisateur",

                    email: data["email"] as? String ?? "",

                    country: data["country"] as? String ?? "",

                    sanctionType: data["sanctionType"] as? String ?? "",

                    reason: data["reason"] as? String ?? "",

                    explanation: data["explanation"] as? String ?? "",

                    evidenceCount: data["evidenceCount"] as? Int ?? 0,

                    aiScore: data["aiScore"] as? Int ?? 0,

                    status: data["status"] as? String ?? "waiting",

                    priority: data["priority"] as? String ?? "Moyenne",

                    moderator: data["moderator"] as? String ?? "",

                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                )

                appeals.append(item)

                switch item.status {

                case "waiting":
                    pending += 1

                case "accepted":
                    accepted += 1

                case "rejected":
                    rejected += 1

                default:
                    break

                }

            }

            totalAppeals = appeals.count
            pendingAppeals = pending
            acceptedAppeals = accepted
            rejectedAppeals = rejected

            aiSuggestions = appeals.filter {

                $0.aiScore >= 80

            }.count

        }

        catch {

            print("Erreur Appeals :", error)

        }

    }

    // MARK: - EXPORTS

    private func exportAppealsPDF() {

        print("Export PDF")

    }

    private func exportAppealsCSV() {

        print("Export CSV")

    }

    // MARK: - NOTIFICATIONS

    private func notifyUser(

        appeal: AdminAppealItem,

        accepted: Bool

    ){

        if accepted {

            print("Envoyer notification : recours accepté")

        } else {

            print("Envoyer notification : recours refusé")

        }

    }

    // MARK: - JOURNAL D'AUDIT

    private func addAuditLog(

        action: String,

        moderator: String,

        appealId: String

    ){

        print("Audit :", action)

    }

    // MARK: - FORMAT

    private func formattedDate(
        _ date: Date
    ) -> String {

        let formatter = DateFormatter()

        formatter.dateStyle = .medium

        formatter.timeStyle = .short

        formatter.locale = Locale(identifier: "fr_FR")

        return formatter.string(from: date)

    }
}
