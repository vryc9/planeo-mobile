//
//  LoginView.swift
//  planeo-app
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()

    var body: some View {
        ZStack {
            Theme.accent.ignoresSafeArea()

            VStack {
                Spacer()
                card
                Spacer()
            }
            .padding(.horizontal, 28)
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            // Logo
            HStack(spacing: 10) {
                Image("LogoPlaneo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .foregroundStyle(Theme.accent)
                Text("laneo")
                    .font(Theme.font(28, .heavy))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.bottom, 32)
            .padding(.top, 32)

            // Champs
            VStack(alignment: .leading, spacing: 20) {
                fieldGroup(label: "Username") {
                    TextField("Votre identifiant", text: $viewModel.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .inputField()
                }

                fieldGroup(label: "Mot de passe") {
                    SecureField("••••••••", text: $viewModel.password)
                        .inputField()
                }
            }
            .padding(.horizontal, 24)

            if let err = viewModel.errorMessage {
                Text(err)
                    .font(Theme.font(13, .semibold))
                    .foregroundStyle(.red)
                    .padding(.top, 12)
            }

            // Bouton
            Button {
                Task { await viewModel.login() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("SE CONNECTER")
                            .font(Theme.font(14, .heavy))
                            .tracking(1)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
            }
            .disabled(!viewModel.isValid || viewModel.isLoading)
            .opacity(viewModel.isValid ? 1 : 0.6)
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 30, y: 10)
    }

    private func fieldGroup<C: View>(label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(Theme.font(13, .bold))
                .foregroundStyle(Theme.text2)
            content()
        }
    }
}

private extension View {
    func inputField() -> some View {
        self
            .font(Theme.font(15))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color(hex: "f4f4f4"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
    }
}

#Preview {
    LoginView()
}
