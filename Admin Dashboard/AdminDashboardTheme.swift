//
//  AdminDashboardTheme.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 29/06/2026.
//

import SwiftUI

enum AdminThemeMode: String, CaseIterable, Identifiable {
    case light = "Clair"
    case dark = "Sombre"
    case system = "Système"

    var id: String { rawValue }
}

struct AdminTheme {
    static let background = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let card = Color.white
    static let primaryText = Color.black
    static let secondaryText = Color.black.opacity(0.82)
    static let tertiaryText = Color.black.opacity(0.68)
    static let border = Color.black.opacity(0.08)
    static let strongText = Color.black
    static let readableText = Color.black.opacity(0.86)
    static let mutedText = Color.black.opacity(0.72)

    static let cardRadius: CGFloat = 26
    static let smallRadius: CGFloat = 18
    static let cardShadow = Color.black.opacity(0.07)
    static let cardBorder = Color.black.opacity(0.10)
    
    static let purple = Color.purple
    static let green = Color.green
    static let yellow = Color.yellow
    static let red = Color.red
    static let softPurple = Color.purple.opacity(0.12)
    static let softGreen = Color.green.opacity(0.12)
    static let softRed = Color.red.opacity(0.12)
}

struct AdminPremiumHeader: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)

                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.title2.bold())
            }

            VStack(alignment: .leading, spacing: 6) {

                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AdminTheme.primaryText)

                Text(subtitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AdminTheme.secondaryText)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
    }
}
