//
//  HabitFilter.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import Foundation
import ReWork_package

enum HabitFilter: String, CaseIterable, Identifiable {
    case all, morning, evening

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:     return "All"
        case .morning: return "Morning"
        case .evening: return "Evening"
        }
    }

    var icon: String {
        switch self {
        case .all:     return "square.grid.2x2"
        case .morning: return "sunrise"
        case .evening: return "moon.stars"
        }
    }

    var routine: Routine? {
        switch self {
        case .morning: return .morning
        case .evening: return .evening
        case .all:     return nil
        }
    }

    func apply(to habits: [Habit], today: String, sinkCompleted: Bool = false, hideRoutines: Bool = false) -> [Habit] {
        let filtered: [Habit]
        switch self {
        case .all:
            if(!hideRoutines){
                filtered = habits
            }else{
                filtered = habits.filter { $0.routines.isEmpty }
            }
        case .morning: filtered = habits.filter { $0.routines.contains(.morning) }
        case .evening: filtered = habits.filter { $0.routines.contains(.evening) }
        }

        guard sinkCompleted else { return filtered }

        // Partitioning rather than sorting: Swift's sort is not guaranteed
        // stable, so equal elements could reshuffle unpredictably as you tap.
        let pending = filtered.filter { !$0.isComplete(on: today) }
        let done    = filtered.filter {  $0.isComplete(on: today) }
        return pending + done
    }
}
