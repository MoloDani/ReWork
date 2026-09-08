//
//  CompactHabitRow.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI
import ReWork_package

/// The checklist row: the whole thing is one tap target, so you can go
/// straight down the list with a thumb.
struct CompactHabitRow: View {
    let habit: Habit
    let today: String
    let onTap: () -> Void

    private var done: Bool { habit.isComplete(on: today) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                IconRing(habit: habit,
                         completed: habit.count(on: today),
                         total: habit.completionsPerDay)

                VStack(alignment: .leading){
                    Text(habit.name)
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                        .foregroundStyle(done ? .secondary : .primary)
                        .strikethrough(done, color: .secondary)
                    
                    let streak = habit.currentStreak(today: today)
                    if streak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(streak)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Color(hex: habit.color).opacity(0.6))
                    }
                }

                Spacer()

                TileRow(habit: habit, today: today)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color(white: done ? 0.06 : 0.085))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(done ? Color(hex: habit.color).opacity(0.25) : Color(white: 0.13),
                            lineWidth: 1)
            )
            .opacity(done ? 0.72 : 1)
        }
        .buttonStyle(.plain)
    }
}
