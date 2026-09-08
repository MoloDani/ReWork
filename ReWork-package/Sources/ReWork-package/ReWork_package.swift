// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Observation
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - Model

public enum Routine: String, Codable, CaseIterable, Sendable {
    case morning
    case evening
}

public enum GoalType: String, Codable, Sendable {
    case daily, weekly, monthly
}

public struct Habit: Codable, Identifiable, Sendable {
    public enum HabitState: String, Codable, Sendable {
        case active, archived
    }
    
    public let id: String
    public let name: String
    public let color: String
    public let icon: String
    public let routines: [Routine]
    public let goalType: GoalType
    public let target: Int
    public let completionsPerDay: Int
    public let reminderTime: String?
    public var completions: [String: Int]
    public let createdAt: String?
    public var sortIndex: Int?
    public var state: HabitState?

    public init(id: String, name: String, color: String, icon: String,
                routines: [Routine], goalType: GoalType, target: Int,
                completionsPerDay: Int, reminderTime: String?,
                completions: [String: Int], createdAt: String?,
                sortIndex: Int? = nil, state: HabitState? = .active) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.routines = routines
        self.goalType = goalType
        self.target = target
        self.completionsPerDay = completionsPerDay
        self.reminderTime = reminderTime
        self.completions = completions
        self.createdAt = createdAt
        self.sortIndex = sortIndex
        self.state = state
    }
}

public struct HabitSummary: Codable, Sendable {
    public let today: String
    public let habits: [Habit]

    public init(today: String, habits: [Habit]) {
        self.today = today
        self.habits = habits
    }
}

// MARK: - Completion helpers

public extension Habit {
    func count(on day: String) -> Int { completions[day] ?? 0 }

    func isComplete(on day: String) -> Bool { count(on: day) >= completionsPerDay }

    /// Day keys sort lexicographically in calendar order, so string comparison
    /// is a valid date comparison for the YYYY-MM-DD format.
    func canLog(on day: String, today: String) -> Bool {
        day <= today
    }
}


// MARK: - Streaks

public extension Habit {
    var isArchived: Bool { state == .archived }
}

public extension Habit {
    /// Set from AppSettings at launch. Mutable because the user chooses whether
    /// their week starts Monday or Sunday, and streaks, the tile grid, and the
    /// calendar all have to agree.
    nonisolated(unsafe) static var firstWeekday: Int = 2
    
    /// UTC always. Period arithmetic must not shift under DST or a user's
    /// regional calendar settings.
    static var utcCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = firstWeekday
        return c
    }

    /// Streak measured in completed DAYS, not periods: a 5-per-week goal where
    /// the user managed 7/7 reports 7. For daily habits a period holds at most
    /// one good day, so this is identical to counting periods.
    func currentStreak(today: String) -> Int {
        let cal = Self.utcCalendar

        var totals: [String: Int] = [:]
        for (day, count) in completions where count >= completionsPerDay {
            totals[Self.periodKey(day, goalType, cal), default: 0] += 1
        }

        let goal = max(1, target)
        let daysIn: (String) -> Int = { totals[$0] ?? 0 }

        var key = Self.periodKey(today, goalType, cal)

        // The current period is still in progress, so it cannot have failed
        // yet. Counting whatever has been done keeps the number moving every
        // day; withholding it makes the counter sit frozen then leap.
        var streak = daysIn(key)
        key = Self.previousPeriod(key, goalType, cal)

        while daysIn(key) >= goal {
            streak += daysIn(key)
            key = Self.previousPeriod(key, goalType, cal)
        }
        return streak
    }

    static func periodKey(_ day: String, _ goal: GoalType, _ cal: Calendar) -> String {
        switch goal {
        case .daily:   return day
        case .monthly: return String(day.prefix(7))
        case .weekly:
            guard let d = DayKey.date(from: day),
                  let start = cal.dateInterval(of: .weekOfYear, for: d)?.start
            else { return day }
            return DayKey.string(from: start)
        }
    }

    static func previousPeriod(_ key: String, _ goal: GoalType, _ cal: Calendar) -> String {
        switch goal {
        case .monthly:
            guard let d = DayKey.date(from: key + "-01"),
                  let prev = cal.date(byAdding: .month, value: -1, to: d)
            else { return key }
            return String(DayKey.string(from: prev).prefix(7))
        case .daily, .weekly:
            guard let d = DayKey.date(from: key),
                  let prev = cal.date(byAdding: .day, value: goal == .weekly ? -7 : -1, to: d)
            else { return key }
            return DayKey.string(from: prev)
        }
    }
}


// MARK: - Store

@available(iOS 17.0, *)
@MainActor
@Observable
public final class HabitStore {
    public private(set) var today: String
    public private(set) var habits: [Habit]
    public private(set) var settings: AppSettings

    public init(summary: HabitSummary) {
        let loaded = HabitStorage.loadSettings()
        Habit.firstWeekday = loaded.firstWeekday
        Haptics.enabled = loaded.hapticsEnabled

        self.settings = loaded
        self.today = DayKey.todayLocal()
        self.habits = summary.habits.sorted {
            ($0.sortIndex ?? .max) < ($1.sortIndex ?? .max)
        }
    }

    // MARK: Day

    /// Recomputes the current day. Called when the app returns to the
    /// foreground and once a minute, since an app left open overnight would
    /// otherwise keep logging to yesterday.
    public func refreshToday() {
        let now = DayKey.todayLocal()
        guard now != today else { return }
        today = now
    }

    /// Re-reads the shared file. The widget can write to it while the app is
    /// backgrounded, so the in-memory copy goes stale.
    public func reload() {
        guard let summary = HabitStorage.load() else { return }
        habits = summary.habits.sorted {
            ($0.sortIndex ?? .max) < ($1.sortIndex ?? .max)
        }
        today = DayKey.todayLocal()
    }

    // MARK: Completions

    /// Advances a habit's count for a day, wrapping back to zero past the max.
    public func toggle(_ habitID: String, on day: String? = nil) {
        let day = day ?? today
        guard let i = habits.firstIndex(where: { $0.id == habitID }) else { return }

        // The store is the only place mutation happens, so guarding here means
        // no caller — view, widget, or future sync code — can bypass it.
        guard habits[i].canLog(on: day, today: today) else { return }

        let current = habits[i].count(on: day)
        let next = current >= habits[i].completionsPerDay ? 0 : current + 1

        habits[i].completions[day] = next == 0 ? nil : next
        persist()
    }

    /// Adds one completion and stops at the maximum. Unlike `toggle`, tapping
    /// an already-finished habit does nothing rather than wiping the day — the
    /// wrong behaviour when someone is tapping quickly down a checklist.
    public func complete(_ habitID: String, on day: String? = nil) {
        let day = day ?? today
        guard let i = habits.firstIndex(where: { $0.id == habitID }) else { return }
        guard habits[i].canLog(on: day, today: today) else { return }

        let current = habits[i].count(on: day)
        guard current < habits[i].completionsPerDay else { return }

        habits[i].completions[day] = current + 1
        persist()
    }

    /// Removes one completion from a day. The counterpart to `complete`.
    public func decrement(_ habitID: String, on day: String? = nil) {
        let day = day ?? today
        guard let i = habits.firstIndex(where: { $0.id == habitID }) else { return }

        let current = habits[i].count(on: day)
        guard current > 0 else { return }

        // nil rather than 0: a zero entry would still count as a key, skewing
        // the earliest-completion date used by stats.
        habits[i].completions[day] = current == 1 ? nil : current - 1
        persist()
    }

    /// Logs one completion for every incomplete habit in a routine. Habits
    /// already finished are left alone, so tapping twice is harmless.
    public func completeRoutine(_ routine: Routine, on day: String? = nil) {
        let day = day ?? today

        for i in habits.indices {
            guard habits[i].routines.contains(routine) else { continue }
            guard habits[i].canLog(on: day, today: today) else { continue }

            let current = habits[i].count(on: day)
            guard current < habits[i].completionsPerDay else { continue }

            habits[i].completions[day] = current + 1
        }
        // One write, not one per habit — otherwise a single tap would rewrite
        // the file six times and fire six widget reloads.
        persist()
    }

    /// How many habits in a routine still need work today.
    public func remaining(in routine: Routine, on day: String? = nil) -> Int {
        let day = day ?? today
        return habits.filter {
            $0.routines.contains(routine) && !$0.isComplete(on: day)
        }.count
    }

    // MARK: Habits

    public func add(name: String, icon: String, color: String,
                    completionsPerDay: Int, routines: [Routine],
                    reminderTime: String?, goalType: GoalType, target: Int) {
        let habit = Habit(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            color: color,
            icon: icon,
            routines: routines,
            goalType: goalType,
            // A one-day period can never hold two good days, so a daily goal
            // must have target 1. Same rule as the server validator.
            target: goalType == .daily ? 1 : target,
            completionsPerDay: completionsPerDay,
            reminderTime: reminderTime,
            completions: [:],
            createdAt: today,
            sortIndex: -1
        )
        habits.insert(habit, at: 0)
        reindex()
        persist()
    }

    public func update(_ habitID: String, name: String, icon: String, color: String,
                       completionsPerDay: Int, routines: [Routine],
                       reminderTime: String?, goalType: GoalType, target: Int) {
        guard let i = habits.firstIndex(where: { $0.id == habitID }) else { return }

        // Rebuilding rather than mutating forces an explicit decision about
        // every field. History, creation date, and order are carried over;
        // everything else comes from the form.
        habits[i] = Habit(
            id: habits[i].id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            color: color,
            icon: icon,
            routines: routines,
            goalType: goalType,
            target: goalType == .daily ? 1 : target,
            completionsPerDay: completionsPerDay,
            reminderTime: reminderTime,
            completions: habits[i].completions,
            createdAt: habits[i].createdAt,
            sortIndex: habits[i].sortIndex
        )
        persist()
    }

    public func move(from source: IndexSet, to destination: Int) {
        habits.move(fromOffsets: source, toOffset: destination)
        reindex()
        persist()
    }

    /// Rewrites every index so order is explicit rather than implied by array
    /// position — this is what survives a save/load round trip.
    private func reindex() {
        for i in habits.indices {
            habits[i].sortIndex = i
        }
    }

    // MARK: Settings

    public func apply(_ new: AppSettings) {
        settings = new
        Habit.firstWeekday = new.firstWeekday
        Haptics.enabled = new.hapticsEnabled
        HabitStorage.save(new)
        reloadWidgets()
    }

    // MARK: Persistence

    private func persist() {
        HabitStorage.save(HabitSummary(today: today, habits: habits))
        reloadWidgets()
        let snapshot = habits
        Task { await Reminders.reschedule(snapshot) }
    }

    private func reloadWidgets() {
        #if canImport(WidgetKit) && !targetEnvironment(macCatalyst)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    /// Habits shown on the dashboard.
    public var activeHabits: [Habit] {
        habits.filter { !$0.isArchived }
    }

    public var archivedHabits: [Habit] {
        habits.filter { $0.isArchived }
    }

    public func archive(_ habitID: String) {
        guard let i = habits.firstIndex(where: { $0.id == habitID }) else { return }
        habits[i].state = .archived      // assignment to optional is fine
        persist()
    }

    public func unarchive(_ habitID: String) {
        guard let i = habits.firstIndex(where: { $0.id == habitID }) else { return }
        habits[i].state = .active
        reindex()
        persist()
    }

    /// Permanent. Only reachable from the archive screen.
    public func delete(_ habitID: String) {
        habits.removeAll { $0.id == habitID }
        reindex()
        persist()
    }
    
    public func routineTargetDay(for routine: Routine, hour: Int) -> String {
        guard routine == .evening, hour < 4 else { return today }

        let cal = Habit.utcCalendar
        guard let date = DayKey.date(from: today),
              let previous = cal.date(byAdding: .day, value: -1, to: date)
        else { return today }

        let yesterday = DayKey.string(from: previous)
        // If last night is already finished, target today — otherwise an
        // early riser would keep logging backwards.
        return remaining(in: routine, on: yesterday) > 0 ? yesterday : today
    }
}

// MARK: - Day keys

public enum DayKey {
    /// en_US_POSIX is required for any fixed-format date string: without it a
    /// phone set to a non-Gregorian calendar formats 2026 as 2569 and every key
    /// silently stops matching.
    private static let utc: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")!
        return f
    }()

    public static func string(from date: Date) -> String { utc.string(from: date) }
    public static func date(from key: String) -> Date? { utc.date(from: key) }

    /// The user's current local day. "Did I run today?" is a question about the
    /// user's calendar, not UTC.
    public static func todayLocal() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f.string(from: Date())
    }
}

// MARK: - Sample data

public extension HabitSummary {
    static func sample() -> HabitSummary {
        guard let url = Bundle.module.url(forResource: "sample", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return HabitSummary(today: DayKey.todayLocal(), habits: []) }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let summary = try? decoder.decode(HabitSummary.self, from: data)
        else { return HabitSummary(today: DayKey.todayLocal(), habits: []) }

        return summary
    }
}
