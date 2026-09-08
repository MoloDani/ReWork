//
//  HabitIcon.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI
import ReWork_package

struct HabitIcon: View{
    let habit: Habit
    let today: String
    var size: CGFloat = 36
    var glyph: CGFloat = 17

    var body: some View {
        Image(systemName: IconCatalog.symbol(for: habit.icon))
            .font(.system(size: glyph, weight: .medium))
            .foregroundStyle(habit.isComplete(on: today) ? Color(hex: habit.color) : .secondary)
            .frame(width: size, height: size)
            .background(Color(hex: habit.color).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28))
    }
}
