//
//  ExpensesView.swift
//  planeo-app
//
//  Écran Dépenses (direction A) — repris de screen-expenses.jsx avec modifications :
//  KPI "Total dépensé" au lieu de "Récurrente", + onglet "Catégories" (tableau expandable).
//

import SwiftUI

struct ExpensesView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ExpensesViewModel()

    enum Tab { case upcoming, past, byCategory }
    @State private var tab: Tab = .upcoming
    @State private var search = ""
    @State private var expandedCategories: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                addButton
                kpiScroller
                tabs

                if tab == .byCategory {
                    categoryTable
                } else {
                    searchBar
                    expenseList
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(Theme.bg)
        .task(id: appState.dataVersion) { await viewModel.load() }
    }

    // MARK: - Boutons d'action (tonals, minimalistes)

    private var addButton: some View {
        HStack(spacing: 10) {
            actionButton(icon: "arrow.up", title: "Entrée d'argent") {
                appState.openIncome()
            }
            actionButton(icon: "plus", title: "Nouvelle dépense") {
                appState.openAddExpense()
            }
        }
    }

    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(Theme.font(13.5, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(Theme.accentDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
        }
    }

    // MARK: - KPIs (scroller horizontal)

    private var kpiScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                kpiPill(icon: "calendar", label: "À venir", value: "\(viewModel.aVenirCount)")
                kpiPill(icon: "creditcard", label: "Total dépensé", value: Format.eur(viewModel.totalDepense))
                kpiPill(icon: "building.columns", label: "Solde actuel", value: Format.eur(viewModel.soldeActuel))
                kpiPill(icon: "wallet.bifold", label: "Solde à venir", value: Format.eur(viewModel.soldeAVenir))
                kpiPill(icon: "eurosign", label: "Reste à payer", value: Format.eur(viewModel.resteAPayer))
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
    }

    private func kpiPill(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            IconCircle(icon: icon, color: Theme.accent, bg: Theme.accentSoft, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(Theme.font(9.5, .bold))
                    .tracking(0.3)
                    .foregroundStyle(Theme.muted)
                    .fixedSize()
                Text(value)
                    .font(Theme.font(16, .heavy))
                    .foregroundStyle(Theme.text)
                    .fixedSize()
            }
        }
        .padding(12)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                .stroke(Theme.hair, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
        .shadow(color: Color(hex: "0F6E69").opacity(0.06), radius: 6, y: 3)
    }

    // MARK: - Onglets

    private var tabs: some View {
        HStack(spacing: 4) {
            tabButton(.upcoming, "À venir")
            tabButton(.past, "Passées")
            tabButton(.byCategory, "Catégories")
        }
        .padding(4)
        .background(Theme.surfaceAlt)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                .stroke(Theme.hair, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
    }

    private func tabButton(_ key: Tab, _ label: String) -> some View {
        let on = tab == key
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { tab = key }
        } label: {
            Text(label)
                .font(Theme.font(13, .bold))
                .foregroundStyle(on ? Theme.accentDark : Theme.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(on ? Theme.surface : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .shadow(color: on ? Color(hex: "11343A").opacity(0.10) : .clear, radius: 4, y: 1)
        }
    }

    // MARK: - Recherche

    private var searchBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.muted)
            TextField("Rechercher une dépense…", text: $search)
                .font(Theme.font(14))
                .foregroundStyle(Theme.text)
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 44)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
    }

    // MARK: - Liste (À venir / Passées)

    private var filteredExpenses: [Expense] {
        let base = viewModel.expenses.filter {
            tab == .upcoming ? $0.status == .pending : $0.status == .paid
        }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        let filtered = q.isEmpty ? base : base.filter {
            $0.label.lowercased().contains(q) || $0.cat.lowercased().contains(q)
        }
        return filtered.sorted { $0.date > $1.date }
    }

    private var expenseList: some View {
        Card(padding: 0) {
            if filteredExpenses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.faint)
                    Text("Aucune dépense trouvée")
                        .font(Theme.font(13.5))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredExpenses.enumerated()), id: \.element.id) { i, e in
                        if i > 0 { Divider().background(Theme.hair) }
                        expenseRow(e)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }

    private func expenseRow(_ e: Expense) -> some View {
        HStack(spacing: 11) {
            IconCircle(cat: e.cat, catIcon: e.catIcon, size: 38)
            VStack(alignment: .leading, spacing: 4) {
                Text(e.label)
                    .font(Theme.font(14.5, .bold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    CatChip(cat: e.cat)
                    Text(Format.dateShortFR(e.date))
                        .font(Theme.font(11.5, .semibold))
                        .foregroundStyle(Theme.muted)
                }
            }
            Spacer(minLength: 8)
            Text("-" + Format.eurCompact(e.amount))
                .font(Theme.font(15, .heavy))
                .foregroundStyle(Theme.text)
        }
        .padding(.vertical, 12)
        .contextMenu {
            Button(role: .destructive) {
                Task {
                    if await viewModel.delete(e) { appState.notifyDataChanged() }
                }
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }

    // MARK: - Tableau par catégorie (expandable)

    private let countWidth: CGFloat = 64
    private let totalWidth: CGFloat = 84

    private var categoryTable: some View {
        Card(padding: 0) {
            VStack(spacing: 0) {
                // En-tête de colonnes
                HStack(spacing: 0) {
                    Text("CATÉGORIE")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("DÉPENSES")
                        .frame(width: countWidth, alignment: .center)
                    Text("TOTAL")
                        .frame(width: totalWidth, alignment: .trailing)
                }
                .font(Theme.font(10, .bold))
                .tracking(0.4)
                .foregroundStyle(Theme.faint)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                ForEach(viewModel.categories) { group in
                    Divider().background(Theme.hair)
                    categoryRow(group)
                    if expandedCategories.contains(group.id) {
                        subTable(group)
                    }
                }

                if viewModel.categories.isEmpty {
                    Text("Aucune donnée")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                }
            }
        }
    }

    private func categoryRow(_ group: CategoryGroup) -> some View {
        let isOpen = expandedCategories.contains(group.id)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isOpen { expandedCategories.remove(group.id) }
                else { expandedCategories.insert(group.id) }
            }
        } label: {
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.accentDark)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                    CatChip(cat: group.label)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(group.count)")
                    .font(Theme.font(14.5, .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(width: countWidth, alignment: .center)

                Text(Format.eur(group.total))
                    .font(Theme.font(14.5, .heavy))
                    .foregroundStyle(Theme.text)
                    .frame(width: totalWidth, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
    }

    private func subTable(_ group: CategoryGroup) -> some View {
        VStack(spacing: 0) {
            // En-tête du sous-tableau
            HStack(spacing: 0) {
                Text("LIBELLÉ")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("MONTANT")
                    .frame(width: 90, alignment: .trailing)
                Text("DATE")
                    .frame(width: 84, alignment: .trailing)
            }
            .font(Theme.font(9.5, .bold))
            .tracking(0.4)
            .foregroundStyle(Theme.faint)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)

            ForEach(group.expenses) { e in
                HStack(spacing: 0) {
                    Text(e.label)
                        .font(Theme.font(13.5, .semibold))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(Format.eur(e.amount))
                        .font(Theme.font(13.5, .heavy))
                        .foregroundStyle(Theme.text)
                        .frame(width: 90, alignment: .trailing)
                    Text(shortDate(e.date))
                        .font(Theme.font(12.5))
                        .foregroundStyle(Theme.text2)
                        .frame(width: 84, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
        .background(Theme.surfaceAlt)
    }

    /// "06/06/2026"
    private func shortDate(_ iso: String) -> String {
        let p = iso.split(separator: "-")
        guard p.count == 3 else { return iso }
        return "\(p[2])/\(p[1])/\(p[0])"
    }
}

#Preview {
    ExpensesView()
        .environment(AppState())
}
