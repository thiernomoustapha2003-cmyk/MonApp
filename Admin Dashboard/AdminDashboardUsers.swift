//
//  AdminDashboardUsers.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI

struct AdminDashboardUsers: View {

    let users: [AdminUserItem]
    let onRefresh: () -> Void

    @State private var searchText = ""
    @State private var selectedFilter: UserFilter = .all
    @State private var selectedUser: AdminUserItem?

    enum UserFilter: String, CaseIterable, Identifiable {
        case all = "Tous"
        case active = "Actifs"
        case restricted = "Restreints"
        case banned = "Bannis"
        case admins = "Admins"

        var id: String { rawValue }
    }

    var filteredUsers: [AdminUserItem] {
        users.filter { user in
            let matchesSearch =
            searchText.isEmpty ||
            user.name.lowercased().contains(searchText.lowercased()) ||
            user.email.lowercased().contains(searchText.lowercased()) ||
            user.role.lowercased().contains(searchText.lowercased())

            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .active:
                matchesFilter = !user.isBanned && !user.isRestricted
            case .restricted:
                matchesFilter = user.isRestricted
            case .banned:
                matchesFilter = user.isBanned
            case .admins:
                matchesFilter = user.role == "admin"
            }

            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        VStack(spacing: 22) {

            AdminPremiumHeader(
                title: "Utilisateurs Cutly",
                subtitle: "Gestion complète des clients, coiffeurs, créateurs, modération et analyse IA.",
                icon: "person.3.fill"
            )

            topStats

            AdminSectionBox(title: "Recherche et filtres", icon: "magnifyingglass") {
                VStack(spacing: 12) {
                    TextField("Rechercher nom, email, rôle...", text: $searchText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black.opacity(0.12), lineWidth: 1)
                        )
                        .cornerRadius(16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(UserFilter.allCases) { filter in
                                Button {
                                    selectedFilter = filter
                                } label: {
                                    Text(filter.rawValue)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 9)
                                        .background(selectedFilter == filter ? Color.purple : Color.gray.opacity(0.12))
                                        .foregroundColor(selectedFilter == filter ? .white : .black)
                                        .cornerRadius(18)
                                }
                            }
                        }
                    }
                }
            }

            AdminSectionBox(title: "Liste des utilisateurs", icon: "list.bullet.rectangle") {
                if filteredUsers.isEmpty {
                    AdminEmptyState(text: "Aucun utilisateur trouvé")
                } else {
                    ForEach(filteredUsers) { user in
                        userRow(user)
                    }
                }
            }
        }
        .sheet(item: $selectedUser) { user in
            AdminUserDetailSheet(user: user)
        }
    }

    var topStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            AdminDashboardCard(
                title: "Total utilisateurs",
                value: "\(users.count)",
                subtitle: "Comptes enregistrés",
                icon: "person.3.fill"
            )

            AdminDashboardCard(
                title: "Comptes actifs",
                value: "\(users.filter { !$0.isBanned && !$0.isRestricted }.count)",
                subtitle: "Sans restriction",
                icon: "checkmark.seal.fill"
            )

            AdminDashboardCard(
                title: "À surveiller",
                value: "\(users.filter { $0.isBanned || $0.isRestricted }.count)",
                subtitle: "Bannis ou restreints",
                icon: "shield.lefthalf.filled"
            )
        }
    }

    func userRow(_ user: AdminUserItem) -> some View {
        Button {
            selectedUser = user
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(statusColor(user).opacity(0.20))
                        .frame(width: 56, height: 56)

                    Text(String((user.name.isEmpty ? "U" : user.name).prefix(1)).uppercased())
                        .font(.title3.bold())
                        .foregroundColor(statusColor(user))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(user.name.isEmpty ? "Utilisateur" : user.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)

                    Text(user.email.isEmpty ? "Email non renseigné" : user.email)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black.opacity(0.78))

                    Text("Rôle : \(user.role)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.purple)
                }

                Spacer()

                statusBadge(user)

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
        .buttonStyle(.plain)
    }

    func statusBadge(_ user: AdminUserItem) -> some View {
        Text(user.isBanned ? "Banni" : user.isRestricted ? "Restreint" : "Actif")
            .font(.system(size: 14, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(statusColor(user).opacity(0.18))
            .foregroundColor(statusColor(user))
            .cornerRadius(14)
    }

    func statusColor(_ user: AdminUserItem) -> Color {
        if user.isBanned { return .red }
        if user.isRestricted { return .orange }
        return .green
    }
}

struct AdminUserDetailSheet: View {

    let user: AdminUserItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {

                    VStack(spacing: 10) {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 92, height: 92)
                            .overlay(
                                Text(String((user.name.isEmpty ? "U" : user.name).prefix(1)).uppercased())
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.purple)
                            )

                        Text(user.name.isEmpty ? "Utilisateur" : user.name)
                            .font(.title2.bold())

                        Text(user.email.isEmpty ? "Email non renseigné" : user.email)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black.opacity(0.82))
                    }

                    AdminSectionBox(title: "Résumé du compte", icon: "person.text.rectangle") {
                        detailLine("ID", user.id)
                        detailLine("Rôle", user.role)
                        detailLine("Statut", user.isBanned ? "Banni" : user.isRestricted ? "Restreint" : "Actif")
                    }

                    AdminSectionBox(title: "Actions modération", icon: "shield.fill") {
                        VStack(spacing: 10) {
                            Button("Envoyer un avertissement") {
                                print("⚠️ TODO admin warning user:", user.id)
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Restreindre temporairement") {
                                print("⛔️ TODO restrict user:", user.id)
                            }
                            .buttonStyle(.bordered)

                            Button("Bannir le compte") {
                                print("🚫 TODO ban user:", user.id)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }

                    AdminSectionBox(title: "Analyse IA du compte", icon: "brain.head.profile") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ici, on branchera OpenAI pour générer un résumé automatique du compte : activité récente, risques, signalements, comportement suspect, recommandations de modération.")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black.opacity(0.82))

                            Button("Analyser avec l’IA") {
                                print("🤖 TODO OpenAI analyse user:", user.id)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    AdminSectionBox(title: "Données sensibles", icon: "lock.shield.fill") {
                        Text("Pour rester professionnel et conforme, le dashboard ne doit pas afficher les numéros complets de cartes bancaires ni les données privées inutiles. Il affichera uniquement les statuts de paiement, preuves utiles, signalements et journaux autorisés.")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black.opacity(0.82))
                    }
                }
                .padding()
            }
            .navigationTitle("Fiche utilisateur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Fermer") {
                    dismiss()
                }
            }
        }
    }

    func detailLine(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black.opacity(0.82))

            Spacer()

            Text(value.isEmpty ? "—" : value)
                .bold()
        }
        .font(.subheadline)
    }
}
