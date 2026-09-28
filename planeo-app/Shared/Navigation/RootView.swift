//
//  RootView.swift
//  planeo-app
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        GeometryReader { geo in
            let drawerWidth = min(geo.size.width * 0.76, 300)

            ZStack(alignment: .leading) {
                // Contenu principal
                VStack(spacing: 0) {
                    AppHeader()
                    contentView
                }

                // Drawer par-dessus
                SideDrawer(width: drawerWidth)
            }
        }
        .task {
            // Premier lancement : aucune banque → on amène l'utilisateur sur l'écran Banques.
            if let exist: Bool = try? await APIClient.shared.request(.accountsExist), !exist {
                appState.screen = .accounts
            }
        }
        .sheet(isPresented: Binding(
            get: { appState.showAddExpense },
            set: { appState.showAddExpense = $0 }
        )) {
            AddExpenseView(
                isIncome: appState.incomeMode,
                presetDate: appState.addExpenseDate
            )
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch appState.screen {
        case .dashboard: DashboardView()
        case .calendar:  CalendarView()
        case .expenses:  ExpensesView()
        case .accounts:  AccountsView()
        case .categories: CategoriesView()
        }
    }
}
