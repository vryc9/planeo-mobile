//
//  AppHeader.swift
//  planeo-app
//
//  Header dégradé teal (direction A) avec hamburger + bouton +.
//

import SwiftUI

struct AppHeader: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack(alignment: .bottom) {
            // Fond dégradé
            LinearGradient(
                colors: [Theme.accent, Theme.accent.shade(0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            HStack(spacing: 0) {
                // Hamburger
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        appState.drawerOpen.toggle()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Titre
                VStack(spacing: 2) {
                    Text(appState.screen.title)
                        .font(Theme.font(17, .heavy))
                        .foregroundStyle(.white)
                    Text(appState.screen.subtitle)
                        .font(Theme.font(11.5, .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }

                Spacer()

                // Bouton +
                Button {
                    appState.openAddExpense()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.accentDark)
                        .frame(width: 36, height: 36)
                        .background(.white)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
            .padding(.top, 4)
        }
        .frame(height: 90)
        // Coins bas arrondis
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 18,
                bottomTrailingRadius: 18, topTrailingRadius: 0
            )
        )
    }
}
