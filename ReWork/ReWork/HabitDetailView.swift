//
//  HabitDetailView.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI
import ReWork_package

struct HabitDetailView: View {
    let habitID: String
    let store: HabitStore

    @State private var editing = false

    /// Looked up by id on every body evaluation rather than held as a value:
    /// a struct passed in would be a frozen snapshot, and tapping a calendar
    /// day would update the store without moving the screen.
    private var habit: Habit? { store.habits.first { $0.id == habitID } }

    var body: some View {
        ScrollView {
            if let habit {
                let stats = habit.stats(today: store.today)

                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 12) {
                        HabitIcon(habit: habit, today: store.today, size: 44, glyph: 21)
                        Text(habit.name)
                            .font(.system(size: 24, weight: .bold))
                    }

                    HStack(spacing: 10) {
                        stat("Current", "\(stats.currentStreak)", habit.color)
                        stat("Best", "\(stats.bestStreak)", habit.color)
                        stat("Rate", "\(Int(stats.completionRate * 100))%", habit.color)
                        stat("Total", "\(stats.totalCompletions)", habit.color)
                    }

                    TileGrid(habit: habit,
                             today: store.today,
                             firstWeekday: store.settings.firstWeekday)

                    MonthCalendar(habit: habit,
                                  today: store.today,
                                  firstWeekday: store.settings.firstWeekday) { day in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            store.toggle(habitID, on: day)
                        }
                    }
                }
                .padding(Layout.screenPadding)
                .frame(maxWidth: 500)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(white: 0.04))
        .navigationTitle(habit?.name ?? "")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { editing = true }
            }
        }
        .sheet(isPresented: $editing) {
            if let habit {
                AddHabitView(store: store, editing: habit)
            }
        }
    }

    private func stat(_ label: String, _ value: String, _ hex: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Color(hex: hex))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(white: 0.078))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
