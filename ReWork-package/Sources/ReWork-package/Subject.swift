//
//  Subject.swift
//  ReWork-package
//
//  Created by Daniel Molodet on 27/08/2026.
//

import Foundation

public enum SubjectResolver {
    /// Returns the habit to display, synthesizing one for routines.
    public static func resolve(_ id: String?, habits: [Habit]) -> Habit? {
        let id = id ?? "routine:all"

        if id.hasPrefix("habit:") {
            let habitID = String(id.dropFirst(6))
            return habits.first { $0.id == habitID }
        }

        let scope = String(id.dropFirst(8))
        let members: [Habit]
        switch scope {
        case "morning": members = habits.filter { $0.routines.contains(.morning) }
        case "evening": members = habits.filter { $0.routines.contains(.evening) }
        default:        members = habits
        }
        return aggregate(members, scope: scope)
    }

    /// A routine behaves exactly like a multi-completion habit: its count for a
    /// day is how many member habits were finished, and its per-day target is
    /// how many members it has. Every downstream view — tile grid, ring,
    /// streak — then works unchanged, with no special case anywhere.
    private static func aggregate(_ members: [Habit], scope: String) -> Habit? {
        guard !members.isEmpty else { return nil }

        var completions: [String: Int] = [:]
        for habit in members {
            for (day, count) in habit.completions where count >= habit.completionsPerDay {
                completions[day, default: 0] += 1
            }
        }

        let name: String
        let icon: String
        switch scope {
        case "morning": name = "Morning Routine"; icon = "sunrise.fill"
        case "evening": name = "Evening Routine"; icon = "moon.stars.fill"
        default:        name = "All Habits";      icon = "square.grid.2x2.fill"
        }

        return Habit(
            id: "routine:\(scope)",
            name: name,
            color: members[0].color,
            icon: icon,
            routines: [],
            goalType: .daily,
            target: 1,
            completionsPerDay: members.count,
            reminderTime: nil,
            completions: completions,
            createdAt: members.compactMap { $0.createdAt }.min(),
            sortIndex: nil
        )
    }
}
