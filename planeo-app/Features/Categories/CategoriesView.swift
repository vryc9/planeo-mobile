//
//  CategoriesView.swift
//  planeo-app
//
//  Écran Catégories : liste, création (nom + icône) et suppression.
//

import SwiftUI

struct CategoriesView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = CategoriesViewModel()
    @State private var showAdd = false
    @State private var pendingDelete: PlaneoCategory?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Button { showAdd = true } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                        Text("Nouvelle catégorie").font(Theme.font(13.5, .bold))
                    }
                    .foregroundStyle(Theme.accentDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                }

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
            AddCategoryView { _ in appState.notifyDataChanged() }
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Supprimer cette catégorie ?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { category in
            Button("Supprimer « \(category.name) »", role: .destructive) {
                Task {
                    if await viewModel.delete(category) { appState.notifyDataChanged() }
                }
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    private var list: some View {
        Card(padding: 0) {
            if viewModel.categories.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tag")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.faint)
                    Text(viewModel.isLoading ? "Chargement…" : "Aucune catégorie")
                        .font(Theme.font(13.5))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.categories.enumerated()), id: \.element.id) { i, c in
                        if i > 0 { Divider().background(Theme.hair) }
                        HStack(spacing: 12) {
                            IconCircle(cat: c.name, catIcon: c.icon, size: 40)
                            CatChip(cat: c.name)
                            Spacer()
                            Button { pendingDelete = c } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Theme.muted)
                                    .frame(width: 34, height: 34)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }
}

// MARK: - Nouvelle catégorie

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddCategoryViewModel()
    /// Appelée après création réussie, avant fermeture.
    var onCreated: (PlaneoCategory?) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SheetHeader(icon: "tag", title: "Nouvelle catégorie", subtitle: "Nom et icône")

                FormField(label: "Nom") {
                    TextField("Ex: Sport", text: $viewModel.name)
                        .font(Theme.font(14.5))
                        .inputBox()
                }

                FormField(label: "Icône") {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(CategoryIcon.options, id: \.key) { option in
                            let on = viewModel.icon == option.key
                            Button { viewModel.icon = option.key } label: {
                                IconCircle(
                                    icon: option.symbol,
                                    color: on ? .white : Theme.accentDark,
                                    bg: on ? Theme.accent : Theme.accentSoft,
                                    size: 44
                                )
                            }
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error).font(Theme.font(13)).foregroundStyle(.red)
                }

                SheetButtons(
                    confirmTitle: "Créer la catégorie",
                    isValid: viewModel.isValid,
                    isSubmitting: viewModel.isSubmitting
                ) {
                    Task {
                        if let created = await viewModel.submit() {
                            onCreated(created)
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
