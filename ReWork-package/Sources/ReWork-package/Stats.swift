//
//  Stats.swift
//  ReWork-package
//
//  Created by Daniel Molodet on 27/08/2026.
//

import Foundation

public struct HabitStats: Sendable {
    public let currentStreak: Int
    public let bestStreak: Int
    public let totalCompletions: Int
    public let completedDays: Int
    public let trackedDays: Int

    public var completionRate: Double {
        trackedDays > 0 ? Double(completedDays) / Double(trackedDays) : 0
    }
}

public extension Habit {
    func stats(today: String) -> HabitStats {
        let cal = Self.utcCalendar

        let qualifying = completions
            .filter { $0.value >= completionsPerDay }
            .map(\.key)

        // Longest run of consecutive qualifying periods, measured in days —
        // the same unit currentStreak uses.
        var totals: [String: Int] = [:]
        for day in qualifying {
            totals[Self.periodKey(day, goalType, cal), default: 0] += 1
        }

        let goal = max(1, target)
        let keys = totals.filter { $0.value >= goal }.keys.sorted()

        var best = 0, run = 0, previous: String?
        for key in keys {
            if let p = previous, Self.previousPeriod(key, goalType, cal) == p {
                run += totals[key] ?? 0
            } else {
                run = totals[key] ?? 0
            }
            best = max(best, run)
            previous = key
        }

        // The window starts at the first actual entry rather than the creation
        // date, so backfilling old history does not collapse the rate.
        let start = completions.keys.min()
            ?? createdAt.map { String($0.prefix(10)) }
            ?? today

        var tracked = 1
        if let a = DayKey.date(from: start), let b = DayKey.date(from: today) {
            tracked = max(1, (cal.dateComponents([.day], from: a, to: b).day ?? 0) + 1)
        }

        return HabitStats(
            currentStreak: currentStreak(today: today),
            bestStreak: best,
            totalCompletions: completions.values.reduce(0, +),
            completedDays: qualifying.count,
            trackedDays: tracked
        )
    }
}
