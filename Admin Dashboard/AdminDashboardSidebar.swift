//
//  AdminDashboardSidebar.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI

struct AdminDashboardSidebar: View {

    @Binding var selectedTab: AdminDashboardTab
    @Binding var isCollapsed: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(AdminDashboardTab.allCases) { tab in
                        sidebarButton(tab)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
            }

            footer
        }
        .frame(width: isCollapsed ? 88 : 280)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.10))
                .frame(width: 1),
            alignment: .trailing
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isCollapsed)
    }

    var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Text("C")
                    .foregroundColor(.white)
                    .font(.title.bold())
            }

            if !isCollapsed {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cutly")
                        .font(.title3.bold())
                        .foregroundColor(.black)

                    Text("Admin Center")
                        .font(.subheadline.bold())
                        .foregroundColor(.black.opacity(0.75))
                }
            }

            Spacer()

            if !isCollapsed {
                Button {
                    isCollapsed.toggle()
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                }
            }
        }
        .padding()
    }

    func sidebarButton(_ tab: AdminDashboardTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            isSelected
                            ? Color.white.opacity(0.25)
                            : Color.purple.opacity(0.16)
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: tab.icon)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(isSelected ? .white : .purple)
                }

                if !isCollapsed {
                    Text(tab.rawValue)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(isSelected ? .white : .black)

                    Spacer()

                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.purple.opacity(0.08)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : Color.black.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .cornerRadius(20)
            .shadow(
                color: isSelected ? Color.purple.opacity(0.28) : Color.black.opacity(0.04),
                radius: isSelected ? 10 : 4,
                x: 0,
                y: isSelected ? 6 : 2
            )
        }
        .buttonStyle(.plain)
    }

    var footer: some View {
        VStack(spacing: 10) {
            Divider()
                .background(Color.black.opacity(0.25))

            Button {
                isCollapsed.toggle()
            } label: {
                HStack {
                    Image(systemName: isCollapsed ? "line.3.horizontal" : "sidebar.leading")
                        .font(.title3.bold())

                    if !isCollapsed {
                        Text(isCollapsed ? "Menu" : "Réduire le menu")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.purple)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.purple.opacity(0.16))
                .cornerRadius(18)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
}
