//
//  SharedStore.swift
//  planeo-app + PlaneoWidgetExtension
//
//  ⚠️ Target Membership : cocher BOTH targets dans Xcode.
//

import Foundation
import WidgetKit

// MARK: - Modèle partagé

struct BalanceSnapshot: Codable {
    var soldeActuel: Double
    var soldeAVenir: Double
    var resteAPayer: Double
    var updatedAt: Date

    static let empty = BalanceSnapshot(
        soldeActuel: 0, soldeAVenir: 0, resteAPayer: 0, updatedAt: .distantPast
    )
    static let preview = BalanceSnapshot(
        soldeActuel: 1_240.50, soldeAVenir: 980.00, resteAPayer: 260.50, updatedAt: Date()
    )
}

// MARK: - Accès partagé

enum SharedStore {
    /// App Group créé dans Signing & Capabilities de CHAQUE target.
    static let appGroup = "group.planeo.planeo-app"
    private static let key = "planeo.balanceSnapshot"

    static func save(_ snapshot: BalanceSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroup) else { return }
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func load() -> BalanceSnapshot {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let data = defaults.data(forKey: key),
            let snap = try? JSONDecoder().decode(BalanceSnapshot.self, from: data)
        else { return .empty }
        return snap
    }
}
