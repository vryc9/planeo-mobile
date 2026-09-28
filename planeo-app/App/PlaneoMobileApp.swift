//
//  PlaneoMobileApp.swift
//  planeo-app
//

import SwiftUI

@main struct PlaneoMobileApp: App {
    @State private var authManager = AuthManager.shared
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated { RootView() }
                else { LoginView() }
            }
            .environment(appState)
            .preferredColorScheme(.light)
        }
    }
}
