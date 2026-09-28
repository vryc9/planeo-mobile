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
        }
    }
}
