//
//  TileGrid.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI
import ReWork_package

struct TileGrid: View {
    let habit: Habit
    let today: String
    let firstWeekday: Int
    var tile: CGFloat = 11
    var spacing: CGFloat = 3
    var maxWeeks: Int = 53
    var showsLabels: Bool = true

    private static let monthName: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLL"
        return f
    }()

    /// Mon, Wed, Fri, Sun — every other row, so labels don't crowd.
    private static let weekdayRowsM: [Int: String] = [0: "M", 2: "W", 4: "F", 6: "S"]
    private static let weekdayRowsS: [Int: String] = [1: "M", 3: "W", 5: "F"]

    private static let labelColor = Color.secondary
    private static let labelFont = Font.system(size: 8, weight: .bold)

    /// An instance property, not a static: the week-start setting has to be
    /// observable, and SwiftUI cannot see changes to a global.
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = firstWeekday
        return c
    }

    private var gridHeight: CGFloat { 7 * tile + 6 * spacing }
    private var headerHeight: CGFloat { showsLabels ? 13 : 0 }

    var body: some View {
        GeometryReader { proxy in
            let fitted = Int((proxy.size.width + spacing) / (tile + spacing))
            let weeks = max(1, min(fitted, maxWeeks))
            let cols = columns(weeks: weeks)

            VStack(alignment: .leading, spacing: 2) {
                if showsLabels {
                    monthHeader(cols)
                }
                tiles(cols)
            }
            // Trailing so the leftover few points land on the oldest end,
            // where the gap is invisible.
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        // GeometryReader is greedy in both axes. The height is known — seven
        // tiles plus six gaps — so fixing it confines the reader to width.
        .frame(height: gridHeight + headerHeight + (showsLabels ? 2 : 0))
    }

    // MARK: - Month header

    private func monthHeader(_ cols: [[String]]) -> some View {
        HStack(spacing: spacing) {
            ForEach(Array(cols.enumerated()), id: \.offset) { index, week in
                // Color.clear holds the column position; the overlay text is
                // unconstrained and spills right over the next few columns,
                // which is what GitHub does and reads fine.
                Color.clear
                    .frame(width: tile, height: headerHeight)
                    .overlay(alignment: .leading) {
                        Text(label(at: index, week: week, in: cols))
                            .font(Self.labelFont)
                            .foregroundStyle(Self.labelColor)
                            .fixedSize()
                    }
            }
        }
    }

    private func label(at index: Int, week: [String], in cols: [[String]]) -> String {
        guard let first = week.first else { return "" }
        let month = String(first.prefix(7))

        // Skip the gutter columns and only label a month the first time it
        // appears; a label at index 0 would hang off the left edge.
        guard index > 2,
              let previous = cols[index - 1].first,
              String(previous.prefix(7)) != month,
              let date = DayKey.date(from: first)
        else { return "" }

        return Self.monthName.string(from: date)
    }

    // MARK: - Tiles

    private func tiles(_ cols: [[String]]) -> some View {
        HStack(spacing: spacing) {
            ForEach(Array(cols.enumerated()), id: \.offset) { column, week in
                VStack(spacing: spacing) {
                    ForEach(Array(week.enumerated()), id: \.offset) { row, day in
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(isGutter(column) ? .clear : fill(for: day))
                            .frame(width: tile, height: tile)
                            .overlay {
                                // The letter rides inside the tile it names,
                                // so it cannot drift out of alignment.
                                if showsLabels, column == 0, let letter = (firstWeekday == 2 ? Self.weekdayRowsM[row] : Self.weekdayRowsS[row]) {
                                    Text(letter)
                                        .font(Self.labelFont)
                                        .foregroundStyle(Self.labelColor)
                                }
                            }
                    }
                }
            }
        }
    }

    /// The first column is a label gutter, not data — blanking it gives the
    /// weekday letters a clean background instead of a lit tile.
    private func isGutter(_ column: Int) -> Bool {
        showsLabels && column < 1
    }

    private func columns(weeks: Int) -> [[String]] {
        guard let end = DayKey.date(from: today),
              let thisWeek = cal.dateInterval(of: .weekOfYear, for: end)?.start,
              let start = cal.date(byAdding: .day, value: -7 * (weeks - 1), to: thisWeek)
        else { return [] }

        return (0..<weeks).map { week in
            (0..<7).compactMap { day in
                cal.date(byAdding: .day, value: week * 7 + day, to: start)
                    .map(DayKey.string(from:))
            }
        }
    }

    private func fill(for day: String) -> Color {
        guard day <= today else { return .clear }

        let base = Color(hex: habit.color)
        let count = habit.count(on: day)
        guard count > 0 else { return base.opacity(0.10) }

        // Opacity encodes partial completion, so a 3× habit with 1 done is
        // dimmer than one with 3 — strictly more information, for free.
        let ratio = Double(count) / Double(max(habit.completionsPerDay, 1))
        return base.opacity(0.35 + 0.65 * min(ratio, 1.0))
    }
}
