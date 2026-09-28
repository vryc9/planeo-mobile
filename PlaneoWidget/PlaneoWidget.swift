//
//  PlaneoWidget.swift
//  PlaneoWidgetExtension
//
//  Remplace le contenu du fichier généré par Xcode pour la Widget Extension.
//

import WidgetKit
import SwiftUI

// MARK: - Couleurs (self-contained, pas de dépendance à l'app)

private extension Color {
    init(h: String) {
        let s = h.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255,
            opacity: 1
        )
    }
}

private enum W {
    static let accent = Color(h: "4fd1c5")
    static let accentDark = Color(h: "2c9c92")

    static let gradient = LinearGradient(
        colors: [accent, accentDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func eur(_ n: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = " "
        f.decimalSeparator = ","
        return (f.string(from: NSNumber(value: n)) ?? "0,00") + " €"
    }
}

// MARK: - Timeline

struct BalanceEntry: TimelineEntry {
    let date: Date
    let snapshot: BalanceSnapshot
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceEntry {
        BalanceEntry(date: Date(), snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        let snap = context.isPreview ? .preview : SharedStore.load()
        completion(BalanceEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let entry = BalanceEntry(date: Date(), snapshot: SharedStore.load())
        // Rafraîchissement indicatif dans 1h (iOS décide du moment réel).
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Vues

struct SmallView: View {
    let snapshot: BalanceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "building.columns")
                    .font(.system(size: 12, weight: .semibold))
                Text("SOLDE ACTUEL")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.4)
            }
            .foregroundStyle(.white.opacity(0.9))

            Spacer()

            Text(W.eur(snapshot.soldeActuel))
                .font(.system(size: 23, weight: .heavy))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("À venir · \(W.eur(snapshot.soldeAVenir))")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct MediumView: View {
    let snapshot: BalanceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: "wallet.bifold")
                    .font(.system(size: 13, weight: .semibold))
                Text("PLANEO")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.2)
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.9))

            Spacer()

            HStack(spacing: 0) {
                stat("Solde actuel", snapshot.soldeActuel)
                divider
                stat("À venir", snapshot.soldeAVenir)
                divider
                stat("Reste à payer", snapshot.resteAPayer)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func stat(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(W.eur(value))
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.25))
            .frame(width: 1, height: 34)
            .padding(.horizontal, 6)
    }
}

struct PlaneoWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: BalanceEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall: SmallView(snapshot: entry.snapshot)
            default:           MediumView(snapshot: entry.snapshot)
            }
        }
        .containerBackground(W.gradient, for: .widget)
    }
}

// MARK: - Widget
struct PlaneoWidget: Widget {
    let kind = "PlaneoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PlaneoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Soldes Planeo")
        .description("Vos soldes en un coup d'œil.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    PlaneoWidget()
} timeline: {
    BalanceEntry(date: Date(), snapshot: .preview)
}

#Preview(as: .systemMedium) {
    PlaneoWidget()
} timeline: {
    BalanceEntry(date: Date(), snapshot: .preview)
}
