//
//  Reminder.swift
//  ReWork-package
//
//  Created by Daniel Molodet on 27/08/2026.
//

import Foundation
import UserNotifications

public enum Reminders {
    @available(iOS 13.0.0, *)
    public static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Rebuilds every scheduled notification from the current habits. Far less
    /// error-prone than tracking individual adds and removals — the system is
    /// the cache, not us.
    @available(iOS 13.0.0, *)
    public static func reschedule(_ habits: [Habit]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard await center.notificationSettings().authorizationStatus == .authorized else { return }

        for habit in habits {
            guard let time = habit.reminderTime else { continue }
            let parts = time.split(separator: ":").compactMap { Int($0) }
            guard parts.count >= 2 else { continue }

            var components = DateComponents()
            components.hour = parts[0]
            components.minute = parts[1]

            let content = UNMutableNotificationContent()
            content.title = habit.name
            content.body = habit.completionsPerDay > 1
                ? "Time for your \(habit.completionsPerDay)× today"
                : "Time to check this one off"
            content.sound = .default

            // Hour and minute only, repeating: the system fires it daily and
            // nothing needs rescheduling. Using the habit id as the identifier
            // means a re-add replaces the old request automatically.
            let request = UNNotificationRequest(
                identifier: habit.id,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            )
            try? await center.add(request)
        }
    }
}
