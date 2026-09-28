//
//  PlaneoComponents.swift
//  planeo-app
//
//  Composants réutilisables : Card, IconCircle, StatusBadge, MiniKpi, CatChip.
//

import SwiftUI

// MARK: - Card

struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .shadow(color: Color(hex: "0F6E69").opacity(0.07), radius: 12, y: 4)
    }
}

// MARK: - IconCircle

struct IconCircle: View {
    var cat: String?
    var icon: String?
    var color: Color?
    var bg: Color?
    var size: CGFloat = 40

    var body: some View {
        let meta: CategoryMeta? = cat.map { ExpenseCategory.meta(for: $0) }
        let bgColor = bg ?? meta?.color.tint(0.78) ?? Theme.accentSoft
        let fgColor = color ?? meta?.color ?? Theme.accent
        let iconName = icon ?? meta?.icon ?? "questionmark"

        Circle()
            .fill(bgColor)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: iconName)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(fgColor)
            )
    }
}

// MARK: - StatusBadge

struct StatusBadge: View {
    let status: ExpenseStatus

    var body: some View {
        let (label, fg, bg): (String, Color, Color) = switch status {
        case .paid:    ("Payée",    Color(hex: "22543D"), Color(hex: "C6F6D5"))
        case .pending: ("En attente", Theme.warn, Theme.warnSoft)
        }

        Text(label)
            .font(Theme.font(11, .bold))
            .foregroundStyle(fg)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(bg)
            .clipShape(Capsule())
    }
}

// MARK: - MiniKpi

struct MiniKpi: View {
    let icon: String
    let label: String
    let value: String
    var sub: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                IconCircle(icon: icon, color: Theme.accent, bg: Theme.accentSoft, size: 30)
                Text(label.uppercased())
                    .font(Theme.font(9.5, .bold))
                    .tracking(0.3)
                    .foregroundStyle(Theme.muted)
            }
            Text(value)
                .font(Theme.font(20, .heavy))
                .foregroundStyle(Theme.text)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            if let sub {
                Text(sub)
                    .font(Theme.font(11, .semibold))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
        .shadow(color: Color(hex: "0F6E69").opacity(0.06), radius: 6, y: 3)
    }
}

// MARK: - CatChip

struct CatChip: View {
    let cat: String

    var body: some View {
        let meta = ExpenseCategory.meta(for: cat)
        Text(cat)
            .font(Theme.font(11, .bold))
            .foregroundStyle(meta.color.shade(0.3))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(meta.color.tint(0.82))
            .clipShape(Capsule())
    }
}
