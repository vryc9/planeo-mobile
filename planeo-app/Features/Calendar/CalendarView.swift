//
//  CalendarView.swift
//  planeo-app
//

import SwiftUI

struct CalendarView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = CalendarViewModel()
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let dayNames = ["Dim","Lun","Mar","Mer","Jeu","Ven","Sam"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthNavigator
                dayNamesRow
                calendarGrid
                if let date = selectedDate, let expenses = viewModel.expensesByDate[iso(date)], !expenses.isEmpty {
                    dayPanel(date: date, expenses: expenses)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Theme.bg)
        .task(id: appState.dataVersion) { await viewModel.load() }
    }

    // MARK: - Navigateur de mois

    private var monthNavigator: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accentDark)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthTitle)
                    .font(Theme.font(17, .heavy))
                    .foregroundStyle(Theme.text)
                Button {
                    withAnimation { displayedMonth = Date() }
                } label: {
                    Text("Aujourd'hui")
                        .font(Theme.font(12, .semibold))
                        .foregroundStyle(Theme.accentDark)
                        .fixedSize()
                }
            }

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accentDark)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Noms des jours

    private var dayNamesRow: some View {
        LazyVGrid(columns: cols, spacing: 4) {
            ForEach(dayNames, id: \.self) { d in
                Text(d)
                    .font(Theme.font(11, .bold))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Grille 42 cellules

    private var calendarGrid: some View {
        let cells = CalendarBuilder.cells(for: displayedMonth)
        return Card(padding: 10) {
            LazyVGrid(columns: cols, spacing: 4) {
                ForEach(cells, id: \.self) { date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 42)
                    }
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let key = iso(date)
        let events = viewModel.expensesByDate[key] ?? []
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isPast = date < Date() && !isToday

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                if isSelected { selectedDate = nil }
                else if events.isEmpty { appState.openAddExpense(date: date); selectedDate = nil }
                else { selectedDate = date }
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        Circle().fill(Theme.accent).frame(width: 30, height: 30)
                    } else if isToday {
                        Circle().stroke(Theme.accent, lineWidth: 1.5).frame(width: 30, height: 30)
                    }
                    Text("\(calendar.component(.day, from: date))")
                        .font(Theme.font(13.5, isToday || isSelected ? .heavy : .semibold))
                        .foregroundStyle(isSelected ? .white : isToday ? Theme.accentDark : isPast ? Theme.faint : Theme.text)
                }
                .frame(width: 30, height: 30)

                // Pastilles catégories
                HStack(spacing: 2) {
                    ForEach(Array(events.prefix(3).enumerated()), id: \.offset) { _, e in
                        Circle()
                            .fill(ExpenseCategory.meta(for: e.cat, icon: e.catIcon).color)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(height: 42)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Panel du jour sélectionné

    private func dayPanel(date: Date, expenses: [Expense]) -> some View {
        Card(padding: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text(Format.dateFullFR(date))
                        .font(Theme.font(14, .heavy))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Button { withAnimation { selectedDate = nil } } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .padding(14)

                Divider().background(Theme.hair)

                ForEach(Array(expenses.enumerated()), id: \.element.id) { i, e in
                    if i > 0 { Divider().background(Theme.hair) }
                    HStack(spacing: 10) {
                        IconCircle(cat: e.cat, catIcon: e.catIcon, size: 34)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(e.label)
                                .font(Theme.font(13.5, .bold))
                                .foregroundStyle(Theme.text)
                                .lineLimit(1)
                            CatChip(cat: e.cat)
                        }
                        Spacer()
                        Text("-\(Format.eur(e.amount))")
                            .font(Theme.font(14, .heavy))
                            .foregroundStyle(Theme.text)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                }

                // Bouton ajouter sur ce jour
                Button {
                    appState.openAddExpense(date: date)
                } label: {
                    Label("Ajouter une dépense", systemImage: "plus")
                        .font(Theme.font(13, .semibold))
                        .foregroundStyle(Theme.accentDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accentSoft)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Helpers

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth).capitalized
    }

    private func iso(_ date: Date) -> String { Format.isoDate(date) }
}

// MARK: - CalendarBuilder

enum CalendarBuilder {
    /// Renvoie 42 cellules (6 semaines × 7), nil = cellule vide hors mois.
    static func cells(for month: Date) -> [Date?] {
        var cal = Calendar.current
        cal.firstWeekday = 1 // dimanche = 1
        let range = cal.range(of: .day, in: .month, for: month)!
        var comps = cal.dateComponents([.year, .month], from: month)
        comps.day = 1
        let first = cal.date(from: comps)!
        let weekday = cal.component(.weekday, from: first) - 1 // 0-based, dim=0
        var cells: [Date?] = Array(repeating: nil, count: weekday)
        for d in range {
            cells.append(cal.date(byAdding: .day, value: d - 1, to: first))
        }
        while cells.count < 42 { cells.append(nil) }
        return cells
    }
}

#Preview {
    CalendarView()
        .environment(AppState())
}
