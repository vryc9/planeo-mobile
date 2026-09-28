//
//  SideDrawer.swift
//  planeo-app
//
//  Menu latéral coulissant repris de app.jsx (Drawer).
//

import SwiftUI

struct SideDrawer: View {
    @Environment(AppState.self) private var appState
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            // Backdrop
            if appState.drawerOpen {
                Color(hex: "0C2828").opacity(0.42)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                            appState.drawerOpen = false
                        }
                    }
            }

            // Panneau
            panel
                .frame(width: width)
                .frame(maxHeight: .infinity)
                .background(Theme.surface)
                .clipShape(.rect(topTrailingRadius: 0, bottomTrailingRadius: 0))
                .shadow(color: .black.opacity(0.18), radius: 40, x: 8)
                .offset(x: appState.drawerOpen ? 0 : -(width + 60))
                .ignoresSafeArea(edges: .vertical)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: appState.drawerOpen)
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Marque
            HStack(spacing: 11) {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent, Theme.accent.shade(0.2)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "wallet.bifold")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text("Planeo")
                        .font(Theme.font(18, .heavy))
                        .foregroundStyle(Theme.text)
                    Text("Budget & dépenses")
                        .font(Theme.font(11.5, .semibold))
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
            .padding(.top, 60)

            Rectangle()
                .fill(Theme.hair)
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

            // Navigation
            VStack(spacing: 4) {
                ForEach(AppScreen.allCases, id: \.self) { item in
                    navRow(item)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // Compte
            HStack(spacing: 11) {
                Circle()
                    .fill(Theme.accent.shade(0.1))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text("Mon compte")
                        .font(Theme.font(13.5, .bold))
                        .foregroundStyle(Theme.text)
                    Text("Gérer le profil")
                        .font(Theme.font(11.5))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.faint)
            }
            .padding(14)
            .background(Theme.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
            .padding(12)
        }
    }

    private func navRow(_ item: AppScreen) -> some View {
        let on = appState.screen == item
        return Button {
            appState.select(item)
        } label: {
            HStack(spacing: 13) {
                Image(systemName: item.icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(on ? Theme.accentDark : Theme.muted)
                    .frame(width: 22)
                Text(item.drawerLabel)
                    .font(Theme.font(15, on ? .heavy : .semibold))
                    .foregroundStyle(on ? Theme.accentDark : Theme.text2)
                Spacer()
                if on {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(on ? Theme.accentSoft : .clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
        }
    }
}
