//
//  MonthCalendar.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI
import ReWork_package

struct MonthCalendar: View {
    let habit: Habit
    let today: String
    let firstWeekday: Int
    let onTap: (String) -> Void

    /// Months back from the current one. 0 is the month containing `today`.
    @State private var offset = 0

    private static let title: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = firstWeekday
        return c
    }

    /// Fifty years back, which is more than anyone needs. Bounding this by the
    /// habit's creation date would stop people backfilling old history.
    private var range: ClosedRange<Int> { -600...0 }

    private var weekdayLetters: [String] {
        let base = ["S", "M", "T", "W", "T", "F", "S"]
        let shift = firstWeekday - 1
        return (0..<7).map { base[($0 + shift) % 7] }
    }

    private func month(_ delta: Int) -> Date {
        let now = DayKey.date(from: today) ?? Date()
        return cal.date(byAdding: .month, value: delta, to: now) ?? now
    }

    private func shift(_ months: Int) {
        let next = offset + months
        guard range.contains(next) else { return }
        withAnimation(.easeInOut(duration: 0.2)) { offset = next }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            header
            weekdayLabels

            // Page mode gives real finger tracking and edge rubber-banding.
            // It will not size to its content, so the height is fixed at the
            // six rows the longest month needs.
            TabView(selection: $offset) {
                ForEach(range, id: \.self) { delta in
                    grid(for: month(delta))
                        .padding(.horizontal, 10)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .tag(delta)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            // Negative padding cancels the per-page inset, so the grid keeps
            // its full width while adjacent months get a gutter while dragging.
            .padding(.horizontal, -10)
            .frame(height: 6 * 38)
        }
    }

    private var header: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                .disabled(offset <= range.lowerBound)

            Spacer()

            Text(Self.title.string(from: month(offset)))
                .font(.system(size: 15, weight: .semibold))
                .contentTransition(.numericText())

            Spacer()

            Button { shift(1) } label: { Image(systemName: "chevron.right") }
                .disabled(offset >= range.upperBound)
        }
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
    }

    private var weekdayLabels: some View {
        HStack(spacing: 4) {
            ForEach(Array(weekdayLetters.enumerated()), id: \.offset) { _, day in
                Text(day)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Grid

    @ViewBuilder
    private func grid(for anchor: Date) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
            spacing: 4
        ) {
            ForEach(Array(slots(for: anchor).enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(DayKey.string(from: date),
                            number: cal.component(.day, from: date))
                } else {
                    // Padding so the 1st lands on the correct weekday.
                    Color.clear.frame(height: 34)
                }
            }
        }
    }

    private func slots(for anchor: Date) -> [Date?] {
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: anchor)),
              let days = cal.range(of: .day, in: .month, for: start)
        else { return [] }

        let leading = (cal.component(.weekday, from: start) - cal.firstWeekday + 7) % 7

        return Array(repeating: nil, count: leading)
            + days.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    // MARK: - Day cell

    @ViewBuilder
    private func dayCell(_ key: String, number: Int) -> some View {
        let count = habit.count(on: key)
        let base = Color(hex: habit.color)
        let allowed = habit.canLog(on: key, today: today)

        Button { onTap(key) } label: {
            Text("\(number)")
                .font(.system(size: 12, weight: count > 0 ? .semibold : .regular))
                .foregroundStyle(count > 0 ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(base.opacity(fillOpacity(count: count, allowed: allowed)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(base, lineWidth: key == today ? 1.5 : 0)
                )
                .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!allowed)
    }

    private func fillOpacity(count: Int, allowed: Bool) -> Double {
        guard allowed else { return 0.03 }
        guard count > 0 else { return 0.08 }
        let ratio = Double(count) / Double(max(habit.completionsPerDay, 1))
        return 0.35 + 0.55 * min(ratio, 1.0)
    }
}
