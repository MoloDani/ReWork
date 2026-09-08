//
//  Settings.swift
//  ReWork-package
//
//  Created by Daniel Molodet on 27/08/2026.
//

import Foundation

public struct AppSettings: Codable, Sendable, Equatable {
    /// 2 = Monday, 1 = Sunday. Matches Calendar.firstWeekday.
    public var firstWeekday: Int
    public var hapticsEnabled: Bool
    public var sinkCompleted: Bool
    public var compactView: Bool
    public var hideRoutineHabits: Bool

    public static let `default` = AppSettings(
        firstWeekday: 2,
        hapticsEnabled: true,
        sinkCompleted: true,
        compactView: false,
        hideRoutineHabits: false
    )

    public init(firstWeekday: Int, hapticsEnabled: Bool, sinkCompleted: Bool, compactView: Bool, hideRoutineHabits: Bool) {
        self.firstWeekday = firstWeekday
        self.hapticsEnabled = hapticsEnabled
        self.sinkCompleted = sinkCompleted
        self.compactView = compactView
        self.hideRoutineHabits = hideRoutineHabits
    }
}
