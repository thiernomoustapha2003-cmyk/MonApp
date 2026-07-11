//
//  AdminDashboardReports.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AdminDashboardReports: View {

    let reports: [AdminReportItem]
    let onRefresh: () -> Void
    let onWarn: (AdminReportItem) -> Void
    let onRestrict: (AdminReportItem) -> Void
    let onBan: (AdminReportItem) -> Void

    @State private var searchText = ""
    @State private var selectedFilter: ReportFilter = .all
    @State private var selectedPriority: ReportPriority = .all
    @State private var selectedReport: AdminReportItem?
    @State private var showAIAnalysis = false

    enum ReportFilter: String, CaseIterable, Identifiable {
        case all = "Tous"
        case pending = "En attente"
        case warned = "Avertis"
        case restricted = "Restreints"
        case banned = "Bannis"
        case resolved = "Résolus"

        var id: String { rawValue }
    }

    enum ReportPriority: String, CaseIterable, Identifiable {
        case all = "Toutes"
        case low = "Faible"
        case medium = "Moyenne"
        case high = "Élevée"
        case critical = "Critique"

        var id: String { rawValue }
    }

    var filteredReports: [AdminReportItem] {
        reports.filter { report in
            let text = "\(report.reason) \(report.details) \(report.status) \(report.reportedUserId) \(report.reportedBy)"
                .lowercased()

            let matchesSearch = searchText.isEmpty || text.contains(searchText.lowercased())

            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .pending:
                matchesFilter = report.status.lowercased().contains("pending") || report.status.lowercased().contains("nouveau")
            case .warned:
                matchesFilter = report.status.lowercased().contains("warn") || report.status.lowercased().contains("averti")
            case .restricted:
                matchesFilter = report.status.lowercased().contains("restrict") || report.status.lowercased().contains("restreint")
            case .banned:
                matchesFilter = report.status.lowercased().contains("ban") || report.status.lowercased().contains("banni")
            case .resolved:
                matchesFilter = report.status.lowercased().contains("resolved") || report.status.lowercased().contains("résolu")
            }

            let matchesPriority: Bool
            switch selectedPriority {
            case .all:
                matchesPriority = true
            case .low:
                matchesPriority = computedPriority(report) == .low
            case .medium:
                matchesPriority = computedPriority(report) == .medium
            case .high:
                matchesPriority = computedPriority(report) == .high
            case .critical:
                matchesPriority = computedPriority(report) == .critical
            }

            return matchesSearch && matchesFilter && matchesPriority
        }
    }

    var body: some View {
        VStack(spacing: 22) {

            AdminPremiumHeader(
                title: "Signalements & Modération",
                subtitle: "Centre de contrôle sécurité : plaintes, abus, sanctions, analyse IA et décisions administrateur.",
                icon: "exclamationmark.shield.fill"
            )

            statsGrid

            searchAndFilters

            reportsList
        }
        .sheet(item: $selectedReport) { report in
            AdminReportDetailSheet(
                report: report,
                priority: computedPriority(report),
                onWarn: {
                    onWarn(report)
                    selectedReport = nil
                },
                onRestrict: {
                    onRestrict(report)
                    selectedReport = nil
                },
                onBan: {
                    onBan(report)
                    selectedReport = nil
                }
            )
        }
    }

    var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 16
        ) {
            AdminDashboardCard(
                title: "Total signalements",
                value: "\(reports.count)",
                subtitle: "Tous les dossiers",
                icon: "tray.full.fill"
            )

            AdminDashboardCard(
                title: "En attente",
                value: "\(reports.filter { $0.status.lowercased().contains("pending") || $0.status.lowercased().contains("nouveau") }.count)",
                subtitle: "À traiter",
                icon: "clock.fill"
            )

            AdminDashboardCard(
                title: "Critiques",
                value: "\(reports.filter { computedPriority($0) == .critical }.count)",
                subtitle: "Risque élevé",
                icon: "flame.fill"
            )

            AdminDashboardCard(
                title: "Sanctionnés",
                value: "\(reports.filter { $0.status.lowercased().contains("ban") || $0.status.lowercased().contains("restrict") || $0.status.lowercased().contains("warn") }.count)",
                subtitle: "Actions appliquées",
                icon: "shield.lefthalf.filled"
            )
        }
    }

    var searchAndFilters: some View {
        AdminSectionBox(title: "Recherche & filtres", icon: "magnifyingglass") {
            VStack(spacing: 14) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.headline.bold())
                        .foregroundColor(.black)

                    TextField("Rechercher par motif, détail, utilisateur, statut...", text: $searchText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.headline.bold())
                                .foregroundColor(.black.opacity(0.75))
                        }
                    }
                }
                .padding(16)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .cornerRadius(16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(ReportFilter.allCases) { filter in
                            Button {
                                selectedFilter = filter
                            } label: {
                                Text(filter.rawValue)
                                    .font(.system(size: 15, weight: .bold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(selectedFilter == filter ? Color.purple : Color.gray.opacity(0.12))
                                    .foregroundColor(selectedFilter == filter ? .white : .black)
                                    .cornerRadius(18)
                            }
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(ReportPriority.allCases) { priority in
                            Button {
                                selectedPriority = priority
                            } label: {
                                Text(priority.rawValue)
                                    .font(.system(size: 15, weight: .bold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(selectedPriority == priority ? priorityColor(priority) : Color.gray.opacity(0.12))
                                    .foregroundColor(selectedPriority == priority ? .white : .black)
                                    .cornerRadius(18)
                            }
                        }
                    }
                }
            }
        }
    }

    var reportsList: some View {
        AdminSectionBox(title: "Liste des signalements", icon: "list.bullet.rectangle.portrait.fill") {
            if filteredReports.isEmpty {
                AdminEmptyState(text: "Aucun signalement trouvé")
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredReports) { report in
                        reportCard(report)
                    }
                }
            }
        }
    }

    func reportCard(_ report: AdminReportItem) -> some View {
        Button {
            selectedReport = report
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(priorityColor(computedPriority(report)).opacity(0.22))
                                .frame(width: 52, height: 52)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.headline.bold())
                                .foregroundColor(priorityColor(computedPriority(report)))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(report.reason.isEmpty ? "Signalement" : report.reason)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.black)

                            Text(report.details.isEmpty ? "Aucun détail fourni" : report.details)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black.opacity(0.82))
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        priorityBadge(computedPriority(report))
                        statusBadge(report.status)
                    }
                }

                Divider()

                HStack {
                    Label("Signalé : \(shortId(report.reportedUserId))", systemImage: "person.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black.opacity(0.78))

                    Spacer()

                    Label(formattedDate(report.createdAt), systemImage: "calendar")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black.opacity(0.78))

                    Image(systemName: "chevron.right")
                        .font(.headline.bold())
                        .foregroundColor(.black.opacity(0.70))
                }
            }
            .padding(18)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
            )
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }

    func computedPriority(_ report: AdminReportItem) -> ReportPriority {
        let text = "\(report.reason) \(report.details)".lowercased()

        if text.contains("mineur") ||
            text.contains("menace") ||
            text.contains("chantage") ||
            text.contains("violence") ||
            text.contains("danger") ||
            text.contains("arnaque grave") {
            return .critical
        }

        if text.contains("harcèlement") ||
            text.contains("arnaque") ||
            text.contains("usurpation") ||
            text.contains("nudité") ||
            text.contains("contenu sexuel") {
            return .high
        }

        if text.contains("insulte") ||
            text.contains("spam") ||
            text.contains("faux compte") {
            return .medium
        }

        return .low
    }

    func priorityColor(_ priority: ReportPriority) -> Color {
        switch priority {
        case .all: return .purple
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .pink
        }
    }

    func priorityBadge(_ priority: ReportPriority) -> some View {
        Text(priority.rawValue)
            .font(.system(size: 15, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(priorityColor(priority).opacity(0.16))
            .foregroundColor(priorityColor(priority))
            .cornerRadius(12)
    }

    func statusBadge(_ status: String) -> some View {
        Text(status.isEmpty ? "nouveau" : status)
            .font(.system(size: 14, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.purple.opacity(0.18))
            .foregroundColor(.purple)
            .cornerRadius(14)
    }

    func shortId(_ id: String) -> String {
        guard !id.isEmpty else { return "inconnu" }
        return String(id.prefix(8)) + "…"
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}
struct AdminReportDetailSheet: View {

    let report: AdminReportItem
    let priority: AdminDashboardReports.ReportPriority
    let onWarn: () -> Void
    let onRestrict: () -> Void
    let onBan: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var internalNote = ""
    @State private var aiSummary = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {

                    header

                    AdminSectionBox(title: "Détails du signalement", icon: "doc.text.magnifyingglass") {
                        VStack(spacing: 10) {
                            detailLine("Motif", report.reason)
                            detailLine("Statut", report.status)
                            detailLine("Priorité", priority.rawValue)
                            detailLine("Utilisateur signalé", report.reportedUserId)
                            detailLine("Signalé par", report.reportedBy)

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.secondary)

                                Text(report.details.isEmpty ? "Aucun détail fourni." : report.details)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    AdminSectionBox(title: "Actions rapides", icon: "bolt.shield.fill") {
                        VStack(spacing: 12) {
                            Button {
                                onWarn()
                            } label: {
                                actionRow("Avertir l’utilisateur", "Envoyer un avertissement officiel", "exclamationmark.bubble.fill", .orange)
                            }

                            Button {
                                onRestrict()
                            } label: {
                                actionRow("Restreindre le compte", "Limiter temporairement certaines actions", "hand.raised.fill", .purple)
                            }

                            Button(role: .destructive) {
                                onBan()
                            } label: {
                                actionRow("Bannir le compte", "Désactiver l’accès à la plateforme", "nosign", .red)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    AdminSectionBox(title: "Assistant IA Modération", icon: "brain.head.profile") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ici, on branchera OpenAI pour analyser le signalement, résumer les preuves, détecter les récidives et suggérer une décision.")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if !aiSummary.isEmpty {
                                Text(aiSummary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.purple.opacity(0.08))
                                    .cornerRadius(14)
                            }

                            HStack {
                                Button("Analyser avec IA") {
                                    aiSummary =
                                    """
                                    🤖 Analyse IA prévue :
                                    - Résumé du signalement
                                    - Niveau de risque
                                    - Historique probable
                                    - Action recommandée
                                    - Message automatique à l’utilisateur
                                    """
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Préparer réponse") {
                                    aiSummary =
                                    """
                                    Bonjour,

                                    Nous avons reçu un signalement concernant votre compte. Après vérification, nous vous rappelons que Cutly exige le respect des règles de la communauté.

                                    Merci d’adopter un comportement respectueux.
                                    """
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }

                    AdminSectionBox(title: "Note interne admin", icon: "note.text") {
                        VStack(spacing: 12) {
                            TextEditor(text: $internalNote)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(14)

                            Button("Enregistrer la note") {
                                print("📝 TODO sauvegarder note interne:", internalNote)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    AdminSectionBox(title: "Journal d’audit", icon: "clock.arrow.circlepath") {
                        VStack(alignment: .leading, spacing: 10) {
                            auditLine("Signalement reçu", "Le dossier a été créé dans Firestore.")
                            auditLine("Analyse admin", "En attente d’une décision.")
                            auditLine("IA Support", "Branchement OpenAI prévu.")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dossier signalement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Fermer") {
                    dismiss()
                }
            }
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 66, height: 66)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                        .font(.title2.bold())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(report.reason.isEmpty ? "Signalement" : report.reason)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)

                    Text("Priorité : \(priority.rawValue)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black.opacity(0.82))
                }

                Spacer()
            }

            Text("Dossier de modération sécurisé. Les actions réalisées ici doivent rester proportionnées, justifiées et enregistrées.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black.opacity(0.82))
        }
        .padding(22)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
    }

    func detailLine(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black.opacity(0.82))

            Spacer()

            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.trailing)
        }
    }

    func actionRow(_ title: String, _ subtitle: String, _ icon: String, _ color: Color) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.20))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.headline.bold())
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)

                Text(subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black.opacity(0.82))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline.bold())
                .foregroundColor(.black.opacity(0.70))
        }
        .padding(18)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(18)
    }

    func auditLine(_ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.purple)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

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
}
