//
//  ReWork_widget.swift
//  ReWork-widget
//
//  Created by Daniel Molodet on 27/08/2026.
//

import WidgetKit
import SwiftUI
import AppIntents
import ReWork_package

struct SubjectEntry: TimelineEntry {
    let date: Date
    let today: String
    let subject: Habit?
    let firstWeekday: Int
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SubjectEntry {
        let summary = HabitSummary.sample()
        return SubjectEntry(date: Date(),
                            today: summary.today,
                            subject: summary.habits.first,
                            firstWeekday: 2)
    }

    func snapshot(for configuration: SelectSubjectIntent, in context: Context) async -> SubjectEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: SelectSubjectIntent, in context: Context) async -> Timeline<SubjectEntry> {
        // The only scheduled change is the day rolling over. Everything else
        // is pushed by the app calling reloadAllTimelines().
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        return Timeline(entries: [entry(for: configuration)], policy: .after(midnight))
    }

    private func entry(for configuration: SelectSubjectIntent) -> SubjectEntry {
        let summary = HabitStorage.load() ?? .sample()
        let settings = HabitStorage.loadSettings()

        // Also set the static, since currentStreak and stats still read it.
        // Without this the widget would compute weekly streaks differently
        // from the app.
        Habit.firstWeekday = settings.firstWeekday

        return SubjectEntry(
            date: Date(),
            today: DayKey.todayLocal(),
            subject: SubjectResolver.resolve(configuration.subject?.id, habits: summary.habits),
            firstWeekday: settings.firstWeekday
        )
    }
}

struct SubjectWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SubjectEntry

    var body: some View {
        Group {
            if let subject = entry.subject {
                if family == .systemSmall {
                    smallLayout(subject)
                } else {
                    wideLayout(subject)
                }
            } else {
                ContentUnavailableView("No habits", systemImage: "square.dashed")
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Small

    /// Roughly square, so the content stacks vertically and the spacers
    /// distribute the leftover height rather than letting it pile up.
    private func smallLayout(_ subject: Habit) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                icon(subject, size: 34, glyph: 17)
                Spacer()
                tappableRing(subject)
            }

            Spacer(minLength: 1)

            HStack(alignment: .center){
                Text(subject.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)

                streakLabel(subject)
            }

            Spacer(minLength: 4)

            TileGrid(habit: subject,
                     today: entry.today,
                     firstWeekday: entry.firstWeekday,
                     tile: 7, spacing: 2,
                     showsLabels: false)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Medium and large

    private func wideLayout(_ subject: Habit) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                icon(subject, size: 32, glyph: 16)

                VStack(alignment: .leading, spacing: 1) {
                    Text(subject.name)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    streakLabel(subject)
                }

                Spacer(minLength: 2)

                tappableRing(subject)
            }

            TileGrid(habit: subject,
                     today: entry.today,
                     firstWeekday: entry.firstWeekday,
                     tile: 9, spacing: 2,
                     showsLabels: true)

            if family == .systemLarge {
                Spacer(minLength: 0)
                statsRow(subject)
            }
        }
    }

    // MARK: - Pieces

    private func icon(_ subject: Habit, size: CGFloat, glyph: CGFloat) -> some View {
        Image(systemName: IconCatalog.symbol(for: subject.icon))
            .font(.system(size: glyph, weight: .medium))
            .foregroundStyle(subject.isComplete(on: entry.today) ? Color(hex: subject.color) : .secondary)
            .frame(width: size, height: size)
            .background(Color(hex: subject.color).opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28))
    }

    @ViewBuilder
    private func streakLabel(_ subject: Habit) -> some View {
        let streak = subject.currentStreak(today: entry.today)
        if streak > 0 {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill").font(.system(size: 9))
                Text("\(streak)").font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(subject.isComplete(on: entry.today) ? Color(hex: subject.color) : .secondary)
            .padding(.top, 1)
        }
    }

    /// Routines are synthesized from several habits, so "complete the routine"
    /// is ambiguous — they show the ring without a button.
    @ViewBuilder
    private func tappableRing(_ subject: Habit) -> some View {
        if subject.id.hasPrefix("routine:") {
            square(subject)
        } else {
            Button(intent: CompleteHabitIntent(habitID: subject.id)) {
                square(subject)
            }
            .buttonStyle(.plain)
        }
    }

    private func ring(_ subject: Habit) -> some View {
        SegmentedRing(
            completed: subject.count(on: entry.today),
            total: subject.completionsPerDay,
            color: Color(hex: subject.color),
            size: 24,
            lineWidth: 2.5
        )
    }
    
    private func square(_ subject: Habit) -> some View {
        SegmentedSquare(
            completed: subject.count(on: entry.today),
            total: subject.completionsPerDay,
            color: Color(hex: subject.color),
            size: 24,
            lineWidth: 2.5
        )
    }

    private func statsRow(_ subject: Habit) -> some View {
        let stats = subject.stats(today: entry.today)
        return HStack(spacing: 0) {
            stat("\(stats.currentStreak)", "Current", subject.color)
            stat("\(stats.bestStreak)", "Best", subject.color)
            stat("\(Int(stats.completionRate * 100))%", "Rate", subject.color)
            stat("\(stats.totalCompletions)", "Total", subject.color)
        }
    }

    private func stat(_ value: String, _ label: String, _ hex: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: hex))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ReWork_widget: Widget {
    let kind: String = "Habit_widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind,
                               intent: SelectSubjectIntent.self,
                               provider: Provider()) { entry in
            SubjectWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit")
        .description("A habit or routine, with its history.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
