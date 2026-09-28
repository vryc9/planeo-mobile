//
//  AppState.swift
//  planeo-app
//

import SwiftUI
import Observation

// MARK: - Screens

enum AppScreen: String, CaseIterable {
    case dashboard, calendar, expenses

    var title: String {
        switch self {
        case .dashboard: return "Tableau de bord"
        case .calendar:  return "Calendrier"
        case .expenses:  return "Dépenses"
        }
    }

    var subtitle: String {
        switch self {
        case .dashboard: return "Vue d'ensemble"
        case .calendar:  return "Planification"
        case .expenses:  return "Historique"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house"
        case .calendar:  return "calendar"
        case .expenses:  return "creditcard"
        }
    }

    var drawerLabel: String {
        switch self {
        case .dashboard: return "Tableau de bord"
        case .calendar:  return "Calendrier"
        case .expenses:  return "Dépenses"
        }
    }
}

// MARK: - AppState

@Observable final class AppState {
    var screen: AppScreen = .dashboard
    var drawerOpen = false
    var showAddExpense = false
    var addExpenseDate: Date?
    var incomeMode = false
    var dataVersion = 0

    func select(_ screen: AppScreen) {
        self.screen = screen
        drawerOpen = false
    }

    func openAddExpense(date: Date? = nil) {
        incomeMode = false
        addExpenseDate = date
        showAddExpense = true
    }

    func openIncome() {
        incomeMode = true
        addExpenseDate = nil
        showAddExpense = true
    }

    func notifyDataChanged() {
        dataVersion += 1
    }
}
