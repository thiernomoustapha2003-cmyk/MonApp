//
//  AdminDashboardComponents.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI

struct AdminDashboardCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title2.bold())
                    .foregroundStyle(.purple)
                    .padding(12)
                    .background(Color.purple.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                Spacer()
            }

            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(AdminTheme.strongText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AdminTheme.strongText)

            Text(subtitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AdminTheme.readableText)
                .lineLimit(2)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: AdminTheme.cardRadius)
                .stroke(AdminTheme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AdminTheme.cardRadius))
        .shadow(color: AdminTheme.cardShadow, radius: 16, x: 0, y: 8)
    }
}

struct AdminSectionBox<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline.bold())
                    .foregroundStyle(.purple)
                    .padding(11)
                    .background(Color.purple.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 13))

                Text(title)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(AdminTheme.strongText)

                Spacer()
            }

            content
                .foregroundColor(AdminTheme.strongText)
        }
        .padding(26)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: AdminTheme.cardRadius)
                .stroke(AdminTheme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AdminTheme.cardRadius))
        .shadow(color: AdminTheme.cardShadow, radius: 16, x: 0, y: 8)
    }
}

struct AdminEmptyState: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.headline.bold())
                .foregroundStyle(.purple)

            Text(text)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AdminTheme.strongText)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: AdminTheme.smallRadius)
                .stroke(AdminTheme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AdminTheme.smallRadius))
    }
}
