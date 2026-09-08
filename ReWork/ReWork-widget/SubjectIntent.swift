//
//  SubjectIntent.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import AppIntents
import ReWork_package

/// What a widget is pointed at: one habit, or a routine.
struct WidgetSubject: AppEntity {
    let id: String          // "habit:<uuid>" or "routine:morning"
    let title: String
    let symbol: String?

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit or Routine"
    static var defaultQuery = WidgetSubjectQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            image: symbol.map { .init(systemName: $0) }
        )
    }
}

struct WidgetSubjectQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [WidgetSubject] {
        all().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [WidgetSubject] { all() }

    func defaultResult() async -> WidgetSubject? { all().first }

    private func all() -> [WidgetSubject] {
        let habits = (HabitStorage.load() ?? .sample()).habits

        var options = [
            WidgetSubject(id: "routine:all",
                          title: "All Habits",
                          symbol: "square.grid.2x2.fill")
        ]

        // A routine is only offered if something is actually in it.
        if habits.contains(where: { $0.routines.contains(.morning) }) {
            options.append(WidgetSubject(id: "routine:morning",
                                         title: "Morning Routine",
                                         symbol: "sunrise.fill"))
        }
        if habits.contains(where: { $0.routines.contains(.evening) }) {
            options.append(WidgetSubject(id: "routine:evening",
                                         title: "Evening Routine",
                                         symbol: "moon.stars.fill"))
        }

        options += habits.map {
            WidgetSubject(id: "habit:\($0.id)",
                          title: $0.name,
                          symbol: IconCatalog.symbol(for: $0.icon))
        }
        return options
    }
}

struct SelectSubjectIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Habit or Routine"
    static var description = IntentDescription("Choose what this widget shows.")

    @Parameter(title: "Show")
    var subject: WidgetSubject?

    init() {}
}
