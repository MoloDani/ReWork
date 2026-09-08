//
//  TileRow.swift
//  ReWork
//
//  Created by Daniel Molodet on 05/09/2026.
//

import SwiftUI
import ReWork_package

/// A single week of tiles for the compact row — same visual language as
/// TileGrid, but one line and a fixed count rather than filling the width.
struct TileRow: View {
    let habit: Habit
    let today: String
    var days: Int = 7
    var tile: CGFloat = 18
    var spacing: CGFloat = 3

    /// Oldest first, so the most recent day sits on the right where the eye
    /// lands last — matching the grid's direction.
    private var keys: [String] {
        guard let end = DayKey.date(from: today) else { return [] }
        let cal = Habit.utcCalendar

        return (1..<days + 1).compactMap { offset in
            cal.date(byAdding: .day, value: -offset, to: end)
                .map(DayKey.string(from:))
        }
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(keys, id: \.self) { day in
                RoundedRectangle(cornerRadius: tile * 0.25)
                    .fill(fill(for: day))
                    .frame(width: tile, height: tile)
            }
        }
    }

    private func fill(for day: String) -> Color {
        let base = Color(hex: habit.color)
        let count = habit.count(on: day)
        guard count > 0 else { return base.opacity(0.10) }

        let ratio = Double(count) / Double(max(habit.completionsPerDay, 1))
        return base.opacity(0.35 + 0.65 * min(ratio, 1.0))
    }
}
