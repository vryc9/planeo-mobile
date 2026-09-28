//
//  PlaneoTheme.swift
//  planeo-app
//
//  Système de design repris de la maquette (direction A).
//

import SwiftUI

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: UInt64
        switch h.count {
        case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }

    /// Mélange entre deux couleurs (t = 0 → self, t = 1 → other)
    func mix(with other: Color, amount t: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(
            .sRGB,
            red: Double(ar + (br - ar) * t),
            green: Double(ag + (bg - ag) * t),
            blue: Double(ab + (bb - ab) * t),
            opacity: 1
        )
    }

    func tint(_ t: Double) -> Color { mix(with: .white, amount: t) }
    func shade(_ t: Double) -> Color { mix(with: Color(hex: "08201e"), amount: t) }
}

/// Thème global (équivalent du `makeTheme` de la maquette, variante "direction A").
enum Theme {
    static let accent = Color(hex: "4fd1c5")
    static var accentDark: Color { accent.shade(0.30) }
    static var accentDeep: Color { accent.shade(0.50) }
    static var accentSoft: Color { accent.tint(0.86) }
    static var accentSoft2: Color { accent.tint(0.74) }
    static var accentBorder: Color { accent.opacity(0.28) }

    static let bg = Color(hex: "eaf6f4")
    static let surface = Color.white
    static let surfaceAlt = Color(hex: "f2fbf9")

    static let text = Color(hex: "11343a")
    static let text2 = Color(hex: "3c5a5e")
    static let muted = Color(hex: "7d9498")
    static let faint = Color(hex: "a9bcbe")

    static let border = Color(hex: "0F6E69").opacity(0.13)
    static let hair = Color(hex: "0F6E69").opacity(0.09)

    static let radius: CGFloat = 20
    static let radiusSm: CGFloat = 12
    static let radiusLg: CGFloat = 28

    static let warn = Color(hex: "E0913A")
    static let warnSoft = Color(hex: "FBEFDC")

    // Police de la maquette : Plus Jakarta Sans.
    // Si tu ne l'ajoutes pas au projet, SwiftUI retombera sur la police système.
    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}
