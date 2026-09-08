//
//  HabitRow.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI
import ReWork_package

struct HabitRow: View {
    let habit: Habit
    let today: String
    let firstWeekday: Int
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                header
                Spacer()
                ring
            }
            TileGrid(habit: habit, today: today, firstWeekday: firstWeekday)
        }
        .padding(13)
        .background(Color(white: 0.078))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(white: 0.12), lineWidth: 1))
    }

    private var header: some View {
        HStack(spacing: 10) {
            HabitIcon(habit: habit, today: today)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    let streak = habit.currentStreak(today: today)

                    if streak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(habit.isComplete(on: today) ? Color(hex: habit.color) : .secondary)
                            Text("\(streak)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if habit.goalType != .daily {
                        Text("\(habit.target)×/\(habit.goalType == .weekly ? "wk" : "mo")")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }

                    if habit.completionsPerDay > 1 {
                        Text("\(habit.count(on: today))/\(habit.completionsPerDay) today")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: habit.color).opacity(0.7))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color(hex: habit.color).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
            }
        }
    }

    private var ring: some View {
        Button(action: onTap) {
            SegmentedSquare(
                completed: habit.count(on: today),
                total: habit.completionsPerDay,
                color: Color(hex: habit.color)
            )
        }
        .buttonStyle(.plain)
    }
}
