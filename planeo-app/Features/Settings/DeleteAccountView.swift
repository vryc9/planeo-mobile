//
//  DeleteAccountView.swift
//  planeo-app
//

import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var confirming = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Supprimer mon compte")
                .font(Theme.font(20, .heavy))
                .foregroundStyle(Theme.text)

            Text("Cette action est définitive : votre compte, vos banques, catégories et dépenses seront supprimés. Saisissez votre mot de passe pour confirmer.")
                .font(Theme.font(13.5))
                .foregroundStyle(Theme.muted)

            SecureField("Mot de passe", text: $password)
                .font(Theme.font(15))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color(hex: "f4f4f4"))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.font(13, .semibold))
                    .foregroundStyle(.red)
            }

            Spacer(minLength: 0)

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
                Button { confirming = true } label: {
                    Group {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Supprimer").font(Theme.font(15, .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                }
                .opacity(password.isEmpty ? 0.5 : 1)
                .disabled(password.isEmpty || isSubmitting)
            }
        }
        .padding(24)
        .background(Theme.surface)
        .interactiveDismissDisabled(isSubmitting)
        .confirmationDialog("Supprimer définitivement votre compte ?",
                            isPresented: $confirming, titleVisibility: .visible) {
            Button("Supprimer définitivement", role: .destructive) { submit() }
            Button("Annuler", role: .cancel) {}
        }
    }

    private func submit() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                try await AuthManager.shared.deleteAccount(password: password)
                dismiss()
            } catch let APIError.httpError(code) where code == 401 {
                errorMessage = "Mot de passe incorrect."
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
