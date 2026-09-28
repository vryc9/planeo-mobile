//
//  AddExpenseView.swift
//  planeo-app
//
//  Modal "Nouvelle dépense" repris de modals.jsx (FormModal, mode create).
//

import SwiftUI

struct AddExpenseView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddExpenseViewModel()

    @State private var showCategories = false
    @State private var showNewCategory = false
    @State private var showDatePicker = false
    
    init(isIncome: Bool, presetDate: Date?) {
            let vm = AddExpenseViewModel()
            vm.isIncome = isIncome
            if let presetDate { vm.date = presetDate }
            _viewModel = State(initialValue: vm)
        }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                if viewModel.isIncome {
                    incomeBanner
                    accountField(label: "Banque à créditer")
                    amountField
                } else {
                    categoryField
                    Field(label: "Libellé") {
                        TextField("Ex: Netflix", text: $viewModel.label)
                            .font(Theme.font(14.5))
                            .padding(.horizontal, 13)
                            .frame(height: 46)
                            .background(Theme.surface)
                            .overlay(roundedBorder)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                    }
                    HStack(spacing: 12) {
                        dateField
                        amountField
                    }
                    accountField(label: "Banque")
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(Theme.font(13))
                        .foregroundStyle(.red)
                }

                buttons
                    .padding(.top, 6)
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 24)
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $showNewCategory) {
            AddCategoryView { created in
                Task {
                    await viewModel.load()
                    if let created { viewModel.selectedCategory = created }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Bandeau entrée d'argent

    private var incomeBanner: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.accent.tint(0.7))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.accentDark)
                )
            Text("Entrée d'argent — vient augmenter votre solde")
                .font(Theme.font(13.5, .semibold))
                .foregroundStyle(Theme.accentDark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accentSoft)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                .stroke(Theme.accentBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                .fill(Theme.accentSoft)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: viewModel.isIncome ? "arrow.up" : "wallet.bifold")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.accentDark)
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.isIncome ? "Nouvelle entrée" : "Nouvelle dépense")
                    .font(Theme.font(18, .heavy))
                    .foregroundStyle(Theme.text)
                Text(viewModel.isIncome ? "Enregistrer une entrée d'argent" : "Dépense ponctuelle")
                    .font(Theme.font(12.5))
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.text2)
                    .frame(width: 34, height: 34)
                    .background(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Champ Catégorie (dropdown custom)

    private var categoryField: some View {
        Field(label: "Catégorie") {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showCategories.toggle() }
                } label: {
                    HStack(spacing: 9) {
                        if let category = viewModel.selectedCategory {
                            IconCircle(cat: category.name, catIcon: category.icon, size: 24)
                            Text(category.name)
                                .font(Theme.font(14.5, .bold))
                                .foregroundStyle(Theme.text)
                        } else {
                            Text("Sélectionner une catégorie")
                                .font(Theme.font(14.5))
                                .foregroundStyle(Theme.faint)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                            .rotationEffect(.degrees(showCategories ? 180 : 0))
                    }
                    .padding(.horizontal, 13)
                    .frame(height: 46)
                    .background(Theme.surface)
                    .overlay(roundedBorder)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                }

                if showCategories {
                    VStack(spacing: 2) {
                        ForEach(viewModel.categories) { category in
                            Button {
                                viewModel.selectedCategory = category
                                withAnimation(.easeInOut(duration: 0.18)) { showCategories = false }
                            } label: {
                                HStack(spacing: 10) {
                                    IconCircle(cat: category.name, catIcon: category.icon, size: 28)
                                    Text(category.name)
                                        .font(Theme.font(14, .bold))
                                        .foregroundStyle(Theme.text)
                                    Spacer()
                                }
                                .padding(10)
                                .background(viewModel.selectedCategory == category ? Theme.accentSoft : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) { showCategories = false }
                            showNewCategory = true
                        } label: {
                            HStack(spacing: 10) {
                                IconCircle(icon: "plus", color: Theme.accentDark, bg: Theme.accentSoft, size: 28)
                                Text("Nouvelle catégorie")
                                    .font(Theme.font(14, .bold))
                                    .foregroundStyle(Theme.accentDark)
                                Spacer()
                            }
                            .padding(10)
                        }
                    }
                    .padding(6)
                    .background(Theme.surface)
                    .overlay(roundedBorder)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                    .padding(.top, 6)
                }
            }
        }
    }

    // MARK: - Champ Banque

    private func accountField(label: String) -> some View {
        Field(label: label) {
            if viewModel.accounts.isEmpty {
                Text("Aucune banque — ajoutez-en une depuis le menu Banques")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .inputBox()
            } else {
                AccountPicker(accounts: viewModel.accounts, selection: $viewModel.selectedAccountId)
            }
        }
    }

    // MARK: - Champ Date

    private var dateField: some View {
        Field(label: "Date") {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showDatePicker.toggle() }
                } label: {
                    HStack {
                        Text(viewModel.dateDisplay)
                            .font(Theme.font(14.5))
                            .foregroundStyle(Theme.text2)
                        Spacer()
                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.horizontal, 13)
                    .frame(height: 46)
                    .background(Theme.surfaceAlt)
                    .overlay(roundedBorder)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                }

                if showDatePicker {
                    DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(Theme.accent)
                        .padding(8)
                        .background(Theme.surface)
                        .overlay(roundedBorder)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                        .padding(.top, 6)
                }
            }
        }
    }

    // MARK: - Champ Montant

    private var amountField: some View {
        Field(label: "Montant") {
            HStack(spacing: 0) {
                Text("€")
                    .font(Theme.font(15, .heavy))
                    .foregroundStyle(Theme.accentDark)
                    .frame(width: 40, height: 46)
                    .background(Theme.accentSoft)
                TextField("0", text: $viewModel.amountText)
                    .font(Theme.font(14.5, .bold))
                    .foregroundStyle(Theme.text)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 12)
                    .frame(height: 46)
            }
            .background(Theme.surface)
            .overlay(roundedBorder)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
        }
    }

    // MARK: - Boutons

    private var buttons: some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: {
                Text("Annuler")
                    .font(Theme.font(15, .bold))
                    .foregroundStyle(Theme.text2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
            }

            Button {
                Task {
                    let ok = await viewModel.submit()
                    if ok {
                        appState.notifyDataChanged()
                        dismiss()
                    }
                }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(viewModel.isIncome ? "Ajouter l'entrée" : "Créer la dépense")
                            .font(Theme.font(15, .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
            }
            .frame(maxWidth: .infinity)
            .opacity(viewModel.isValid ? 1 : 0.5)
            .disabled(!viewModel.isValid || viewModel.isSubmitting)
        }
    }

    private var roundedBorder: some View {
        RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
            .stroke(Theme.border, lineWidth: 1)
    }
}

/// Libellé de champ (uppercase, gris) + contenu.
private struct Field<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(Theme.font(10.5, .heavy))
                .tracking(0.5)
                .foregroundStyle(Theme.muted)
            content
        }
    }
}
