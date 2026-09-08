//
//  IconRing.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI
import ReWork_package

/// Icon and progress track merged into one element: the icon sits inside a
/// segmented rounded square, so the whole thing is a single tap target.
struct IconRing: View {
    let habit: Habit
    let completed: Int
    let total: Int
    var size: CGFloat = 44

    private var corner: CGFloat { size * 0.30 }
    private var lineWidth: CGFloat { size * 0.09 }
    private var gap: CGFloat { total > 1 ? 0.05 : 0 }
    private var color: Color { Color(hex: habit.color) }
    private var isComplete: Bool { completed >= total }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner)
                .fill(color.opacity(isComplete ? 0.22 : 0.14))

            Image(systemName: IconCatalog.symbol(for: habit.icon))
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(color)

            ForEach(0..<max(total, 1), id: \.self) { index in
                let slice = 1.0 / CGFloat(max(total, 1))
                RoundedRectangle(cornerRadius: corner)
                    .inset(by: lineWidth / 2)
                    .trim(from: CGFloat(index) * slice + gap / 2,
                          to: CGFloat(index + 1) * slice - gap / 2)
                    .stroke(
                        // Neutral grey for the unfilled track, not a faded
                        // tint — otherwise progress reads as "the same thing
                        // but washed out" rather than as a distinct layer.
                        index < completed ? color : Color.primary.opacity(0.12),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
            }
        }
        .frame(width: size, height: size)
        .contentShape(RoundedRectangle(cornerRadius: corner))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: completed)
    }
}
