//
//  CompleteHabitIntent.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import AppIntents
import WidgetKit
import ReWork_package

struct CompleteHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Habit"

    @Parameter(title: "Habit ID")
    var habitID: String

    init() {}

    init(habitID: String) {
        self.habitID = habitID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // The widget process cannot reach into the app's memory, so it edits
        // the shared file directly. This is why HabitStorage was built on a
        // file in the App Group container rather than in-process state.
        guard var summary = HabitStorage.load() else { return .result() }

        let today = DayKey.todayLocal()
        guard let i = summary.habits.firstIndex(where: { $0.id == habitID }) else { return .result() }
        guard summary.habits[i].canLog(on: today, today: today) else { return .result() }

        var habits = summary.habits
        let current = habits[i].count(on: today)

        // Wraps to zero at the maximum, matching the app's toggle. A widget
        // has no other undo affordance, so wrapping is the honest choice.
        habits[i].completions[today] = current >= habits[i].completionsPerDay
            ? nil
            : current + 1

        summary = HabitSummary(today: summary.today, habits: habits)
        HabitStorage.save(summary)
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}
