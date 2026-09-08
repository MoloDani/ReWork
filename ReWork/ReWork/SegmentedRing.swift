//
//  SegmentedRing.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI

struct SegmentedRing: View {
    let completed: Int
    let total: Int
    let color: Color
    var size: CGFloat = 28
    var lineWidth: CGFloat = 3

    private var gapFraction: CGFloat { total > 1 ? 0.06 : 0 }

    var body: some View {
        ZStack {
            ForEach(0..<max(total, 1), id: \.self) { index in
                RingSegment(index: index, total: max(total, 1), gap: gapFraction)
                    .stroke(
                        color.opacity(index < completed ? 1 : 0.18),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
            }

            if completed >= total {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(color)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            } else if completed > 0 {
                Text("\(completed)")
                    .font(.system(size: size * 0.46, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText(value: Double(completed)))
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        // Padding then contentShape: a stroked path is only tappable on the
        // drawn line, which is unhittable with a mouse cursor.
        .padding(8)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: completed)
    }
}

struct RingSegment: Shape {
    let index: Int
    let total: Int
    let gap: CGFloat

    func path(in rect: CGRect) -> Path {
        let slice = 1.0 / CGFloat(total)
        let start = CGFloat(index) * slice + gap / 2
        let end = start + slice - gap

        return Path { p in
            p.addArc(
                center: CGPoint(x: rect.midX, y: rect.midY),
                radius: rect.width / 2,
                // -90 rotates the ring so segment one starts at the top,
                // since SwiftUI's zero degrees points right.
                startAngle: .degrees(Double(start) * 360 - 90),
                endAngle: .degrees(Double(end) * 360 - 90),
                clockwise: false
            )
        }
    }
}
