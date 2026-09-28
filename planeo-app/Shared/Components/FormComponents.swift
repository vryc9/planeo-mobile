//
//  FormComponents.swift
//  planeo-app
//
//  Briques communes aux formulaires en modal (banque, virement, catégorie).
//

import SwiftUI
import PhotosUI

/// Libellé de champ (uppercase, gris) + contenu.
struct FormField<Content: View>: View {
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

extension View {
    /// Cadre arrondi standard des champs de saisie.
    func inputBox(height: CGFloat = 46) -> some View {
        self
            .padding(.horizontal, 13)
            .frame(height: height)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
    }
}

/// En-tête de modal : pastille d'icône, titre, sous-titre, bouton fermer.
struct SheetHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                .fill(Theme.accentSoft)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.accentDark)
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Theme.font(18, .heavy))
                    .foregroundStyle(Theme.text)
                Text(subtitle)
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
}

/// Boutons Annuler / Valider en bas de modal.
struct SheetButtons: View {
    let confirmTitle: String
    let isValid: Bool
    let isSubmitting: Bool
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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

            Button(action: onConfirm) {
                Group {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(confirmTitle).font(Theme.font(15, .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
            }
            .frame(maxWidth: .infinity)
            .opacity(isValid ? 1 : 0.5)
            .disabled(!isValid || isSubmitting)
        }
    }
}

/// Champ montant avec préfixe €.
struct AmountInput: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 0) {
            Text("€")
                .font(Theme.font(15, .heavy))
                .foregroundStyle(Theme.accentDark)
                .frame(width: 40, height: 46)
                .background(Theme.accentSoft)
            TextField("0", text: $text)
                .font(Theme.font(14.5, .bold))
                .foregroundStyle(Theme.text)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 12)
                .frame(height: 46)
        }
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
    }
}

// MARK: - Logo de banque

/// Affiche le logo d'une banque : data URL / base64 (comme stocké par l'API), URL http, sinon initiales.
struct AccountLogo: View {
    let logo: String
    let label: String
    var size: CGFloat = 44

    private static let cache = NSCache<NSString, UIImage>()

    var body: some View {
        Group {
            if let image = Self.image(from: logo) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if logo.hasPrefix("http"), let url = URL(string: logo) {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { fallback }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }

    private var fallback: some View {
        ZStack {
            Theme.accentSoft2
            Text(String(label.prefix(1)).uppercased())
                .font(Theme.font(size * 0.42, .heavy))
                .foregroundStyle(Theme.accentDark)
        }
    }

    private static func image(from logo: String) -> UIImage? {
        guard !logo.isEmpty, !logo.hasPrefix("http") else { return nil }
        if let cached = cache.object(forKey: logo as NSString) { return cached }
        let base64 = logo.firstIndex(of: ",").map { String(logo[logo.index(after: $0)...]) } ?? logo
        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
              let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: logo as NSString)
        return image
    }

    /// Réduit l'image choisie (côté max 160 px) et l'encode en data URL PNG pour l'API.
    static func dataURL(from data: Data, maxSide: CGFloat = 160) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        guard let png = resized.pngData() else { return nil }
        return "data:image/png;base64," + png.base64EncodedString()
    }
}
