//
//  CategoriesViewModel.swift
//  planeo-app
//

import Foundation
import Observation

@Observable final class CategoriesViewModel {
    var categories: [PlaneoCategory] = []
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let dtos: [CategoryDTO] = try await APIClient.shared.request(.categories)
            categories = dtos.compactMap { $0.toCategory() }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func delete(_ category: PlaneoCategory) async -> Bool {
        error = nil
        do {
            try await APIClient.shared.send(.deleteCategory(
                body: CategoryDTO(id: category.id, name: category.name, icon: category.icon)
            ))
            categories.removeAll { $0.id == category.id }
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}

/// État du formulaire "Nouvelle catégorie".
@Observable final class AddCategoryViewModel {
    var name = ""
    var icon = CategoryIcon.options[0].key
    var isSubmitting = false
    var errorMessage: String?

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Retourne la catégorie créée (utile pour la présélectionner dans le formulaire de dépense).
    func submit() async -> PlaneoCategory? {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            let dto: CategoryDTO = try await APIClient.shared.request(.createCategory(
                body: CategoryCreateRequest(name: name.trimmingCharacters(in: .whitespaces), icon: icon)
            ))
            return dto.toCategory()
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
