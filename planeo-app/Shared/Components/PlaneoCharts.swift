//
//  PlaneoCharts.swift
//  planeo-app
//
//  LineChart (courbe Catmull-Rom + gradient) et Donut (arcs trim).
//

import SwiftUI

// MARK: - LineChart

struct LineChart: View {
    let points: [Double]           // valeurs brutes
    let labels: [String]           // labels axe X (mois etc.)

    private var normalized: [Double] {
        let mn = points.min() ?? 0, mx = points.max() ?? 1
        guard mx > mn else { return points.map { _ in 0.5 } }
        return points.map { ($0 - mn) / (mx - mn) }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let n = normalized
            let pts = n.enumerated().map { i, v in
                CGPoint(x: w * CGFloat(i) / CGFloat(max(n.count - 1, 1)),
                        y: h * (1 - v * 0.85 - 0.05))
            }

            ZStack {
                // Gradient fill
                if pts.count >= 2 {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h))
                        path.addLine(to: pts[0])
                        catmullPath(pts: pts, path: &path)
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(
                        colors: [Theme.accent.opacity(0.22), Theme.accent.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    ))

                    // Ligne
                    Path { path in
                        path.move(to: pts[0])
                        catmullPath(pts: pts, path: &path)
                    }
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    // Point final
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 8, height: 8)
                        .position(pts.last ?? .zero)
                }

                // Labels X
                HStack(spacing: 0) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { _, l in
                        Text(l)
                            .font(Theme.font(9.5, .semibold))
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 2)
            }
        }
    }

    private func catmullPath(pts: [CGPoint], path: inout Path) {
        for i in 1..<pts.count {
            let p0 = pts[max(i - 2, 0)]
            let p1 = pts[i - 1]
            let p2 = pts[i]
            let p3 = pts[min(i + 1, pts.count - 1)]
            let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
    }
}

// MARK: - DonutChart

struct DonutChart: View {
    struct Slice: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let color: Color
    }

    let slices: [Slice]
    let total: Double
    var centerLabel: String = ""

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(Array(slices.enumerated()), id: \.element.id) { i, s in
                    let start = slices[..<i].reduce(0.0) { $0 + $1.value } / max(total, 1)
                    let end   = start + s.value / max(total, 1)
                    Circle()
                        .trim(from: start, to: end)
                        .stroke(s.color, style: StrokeStyle(lineWidth: side * 0.15, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                // Centre
                VStack(spacing: 2) {
                    Text(centerLabel)
                        .font(Theme.font(14, .heavy))
                        .foregroundStyle(Theme.text)
                    Text("total")
                        .font(Theme.font(10))
                        .foregroundStyle(Theme.muted)
                }
            }
            .frame(width: side, height: side)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
