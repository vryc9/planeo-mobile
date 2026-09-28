//
//  DashboardView.swift
//  planeo-app
//

import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                kpiGrid
                monthlyCard
                categoryCard
                recentCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(Theme.bg)
        .refreshable { await viewModel.load() }
        .task(id: appState.dataVersion) { await viewModel.load() }
        .overlay {
            if viewModel.isLoading && viewModel.balance == nil {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(Theme.accent)
            }
        }
    }

    // MARK: - Hero (solde actuel)

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Theme.accent, Theme.accent.shade(0.32)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 6) {
                Text("SOLDE ACTUEL")
                    .font(Theme.font(11, .bold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.8))
                Text(Format.eur(viewModel.soldeActuel))
                    .font(Theme.font(34, .heavy))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("À venir · \(Format.eur(viewModel.soldeAVenir))")
                    .font(Theme.font(13, .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
    }

    // MARK: - KPI Grid 2 colonnes

    private var kpiGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MiniKpi(icon: "eurosign",       label: "Reste à payer", value: Format.eur(viewModel.resteAPayer))
            MiniKpi(icon: "creditcard",     label: "Dépenses",      value: "\(viewModel.expenses.count)")
            MiniKpi(icon: "calendar",       label: "En attente",    value: "\(viewModel.expenses.filter { $0.status == .pending }.count)")
            MiniKpi(icon: "checkmark.seal", label: "Payées",        value: "\(viewModel.expenses.filter { $0.status == .paid }.count)")
        }
    }

    // MARK: - Courbe mensuelle

    private var monthlyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Dépenses mensuelles")
                    .font(Theme.font(15, .heavy))
                    .foregroundStyle(Theme.text)
                if viewModel.lineValues.isEmpty {
                    Text("Aucune donnée")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                } else {
                    LineChart(points: viewModel.lineValues, labels: viewModel.lineLabels)
                        .frame(height: 140)
                }
            }
        }
    }

    // MARK: - Donut catégories

    private var categoryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Par catégorie")
                    .font(Theme.font(15, .heavy))
                    .foregroundStyle(Theme.text)

                if viewModel.donutSlices.isEmpty {
                    Text("Aucune donnée")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    HStack(alignment: .center, spacing: 16) {
                        DonutChart(
                            slices: viewModel.donutSlices,
                            total: viewModel.donutTotal,
                            centerLabel: Format.eurCompact(viewModel.donutTotal)
                        )
                        .frame(width: 110, height: 110)

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.donutSlices.prefix(6)) { s in
                                HStack(spacing: 7) {
                                    Circle().fill(s.color).frame(width: 8, height: 8)
                                    Text(s.label)
                                        .font(Theme.font(12))
                                        .foregroundStyle(Theme.text2)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(Format.eurCompact(s.value))
                                        .font(Theme.font(12, .bold))
                                        .foregroundStyle(Theme.text)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Récentes

    private var recentCard: some View {
        Card(padding: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("Récentes")
                        .font(Theme.font(15, .heavy))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Button {
                        withAnimation { appState.select(.expenses) }
                    } label: {
                        Text("Voir tout")
                            .font(Theme.font(13, .semibold))
                            .foregroundStyle(Theme.accentDark)
                    }
                }
                .padding(16)

                if viewModel.recentExpenses.isEmpty {
                    Text("Aucune dépense")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.muted)
                        .padding(.bottom, 24)
                } else {
                    ForEach(Array(viewModel.recentExpenses.enumerated()), id: \.element.id) { i, e in
                        if i > 0 { Divider().background(Theme.hair) }
                        HStack(spacing: 11) {
                            IconCircle(cat: e.cat, size: 36)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(e.label)
                                    .font(Theme.font(14, .bold))
                                    .foregroundStyle(Theme.text)
                                    .lineLimit(1)
                                Text(Format.dateShortFR(e.date))
                                    .font(Theme.font(11.5))
                                    .foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("-" + Format.eurCompact(e.amount))
                                    .font(Theme.font(14, .heavy))
                                    .foregroundStyle(Theme.text)
                                StatusBadge(status: e.status)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
}
