//
//  AccountsView.swift
//  planeo-app
//
//  Écran Banques : comptes de l'utilisateur, ajout d'une banque, virement entre comptes.
//

import SwiftUI
import PhotosUI

struct AccountsView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AccountsViewModel()
    @State private var showAdd = false
    @State private var showTransfer = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                totalCard
                actions
                if let error = viewModel.error {
                    Text(error).font(Theme.font(13)).foregroundStyle(.red)
                }
                list
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(Theme.bg)
        .refreshable { await viewModel.load() }
        .task(id: appState.dataVersion) { await viewModel.load() }
        .sheet(isPresented: $showAdd) {
            AddAccountView().presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTransfer) {
            TransferView(accounts: viewModel.accounts).presentationDetents([.medium, .large])
        }
    }

    private var totalCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Theme.accent, Theme.accent.shade(0.32)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 6) {
                Text("TOTAL DES BANQUES")
                    .font(Theme.font(11, .bold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.8))
                Text(Format.eur(viewModel.total))
                    .font(Theme.font(34, .heavy))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("\(viewModel.accounts.count) compte\(viewModel.accounts.count > 1 ? "s" : "")")
                    .font(Theme.font(13, .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
    }

    private var actions: some View {
        HStack(spacing: 10) {
            actionButton(icon: "plus", title: "Ajouter une banque") { showAdd = true }
            actionButton(icon: "arrow.left.arrow.right", title: "Virement") { showTransfer = true }
                .opacity(viewModel.accounts.count >= 2 ? 1 : 0.5)
                .disabled(viewModel.accounts.count < 2)
        }
    }

    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 13, weight: .bold))
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

    private var list: some View {
        Card(padding: 0) {
            if viewModel.accounts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "building.columns")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.faint)
                    Text(viewModel.isLoading ? "Chargement…" : "Aucune banque — ajoutez votre premier compte")
                        .font(Theme.font(13.5))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.accounts.enumerated()), id: \.element.id) { i, a in
                        if i > 0 { Divider().background(Theme.hair) }
                        HStack(spacing: 12) {
                            AccountLogo(logo: a.logo, label: a.label, size: 42)
                            Text(a.label)
                                .font(Theme.font(15, .bold))
                                .foregroundStyle(Theme.text)
                                .lineLimit(1)
                            Spacer()
                            Text(Format.eur(a.amount))
                                .font(Theme.font(15, .heavy))
                                .foregroundStyle(a.amount < 0 ? .red : Theme.text)
                        }
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }
}

// MARK: - Ajouter une banque

struct AddAccountView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddAccountViewModel()
    @State private var pickedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SheetHeader(icon: "building.columns", title: "Nouvelle banque", subtitle: "Ajouter un compte")

                FormField(label: "Nom de la banque") {
                    TextField("Ex: Boursorama", text: $viewModel.label)
                        .font(Theme.font(14.5))
                        .inputBox()
                }

                FormField(label: "Solde actuel") {
                    AmountInput(text: $viewModel.amountText)
                }

                FormField(label: "Logo (optionnel)") {
                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        HStack(spacing: 12) {
                            AccountLogo(logo: viewModel.logo, label: viewModel.label, size: 40)
                            Text(viewModel.logo.isEmpty ? "Choisir une image" : "Changer l'image")
                                .font(Theme.font(14, .semibold))
                                .foregroundStyle(Theme.accentDark)
                            Spacer()
                            Image(systemName: "photo")
                                .foregroundStyle(Theme.muted)
                        }
                        .padding(.horizontal, 13)
                        .frame(height: 56)
                        .background(Theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error).font(Theme.font(13)).foregroundStyle(.red)
                }

                SheetButtons(
                    confirmTitle: "Ajouter la banque",
                    isValid: viewModel.isValid,
                    isSubmitting: viewModel.isSubmitting
                ) {
                    Task {
                        if await viewModel.submit() {
                            appState.notifyDataChanged()
                            dismiss()
                        }
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 24)
        }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let url = AccountLogo.dataURL(from: data) {
                    viewModel.logo = url
                }
            }
        }
    }
}

// MARK: - Virement

struct TransferView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TransferViewModel()
    let accounts: [Account]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SheetHeader(icon: "arrow.left.arrow.right", title: "Virement", subtitle: "Entre vos banques")

                FormField(label: "Depuis") {
                    AccountPicker(accounts: accounts, selection: $viewModel.originId, excluding: viewModel.targetId)
                }
                FormField(label: "Vers") {
                    AccountPicker(accounts: accounts, selection: $viewModel.targetId, excluding: viewModel.originId)
                }
                FormField(label: "Montant (min. 1 €)") {
                    AmountInput(text: $viewModel.amountText)
                }

                if let error = viewModel.errorMessage {
                    Text(error).font(Theme.font(13)).foregroundStyle(.red)
                }

                SheetButtons(
                    confirmTitle: "Effectuer le virement",
                    isValid: viewModel.isValid,
                    isSubmitting: viewModel.isSubmitting
                ) {
                    Task {
                        if await viewModel.submit() {
                            appState.notifyDataChanged()
                            dismiss()
                        }
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Sélecteur de banque (menu)

struct AccountPicker: View {
    let accounts: [Account]
    @Binding var selection: Int?
    var excluding: Int? = nil

    var body: some View {
        let selected = accounts.first { $0.id == selection }
        Menu {
            ForEach(accounts.filter { $0.id != excluding }) { a in
                Button { selection = a.id } label: {
                    Text("\(a.label) · \(Format.eur(a.amount))")
                }
            }
        } label: {
            HStack(spacing: 10) {
                if let selected {
                    AccountLogo(logo: selected.logo, label: selected.label, size: 28)
                    Text(selected.label)
                        .font(Theme.font(14.5, .bold))
                        .foregroundStyle(Theme.text)
                } else {
                    Text("Sélectionner une banque")
                        .font(Theme.font(14.5))
                        .foregroundStyle(Theme.faint)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.muted)
            }
            .inputBox()
        }
    }
}
