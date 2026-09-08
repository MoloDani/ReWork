//
//  Storage.swift
//  ReWork-package
//
//  Created by Daniel Molodet on 27/08/2026.
//

import Foundation

public enum HabitStorage {
    public static let appGroupID = "group.com.molodet.ReWork"

    /// The App Group container if the entitlement exists, otherwise the app's
    /// own Documents directory. The fallback means this still works if the
    /// entitlement is ever unavailable — the widget just stops sharing.
    public static var containerURL: URL {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static var fileURL: URL {
        containerURL.appendingPathComponent("summary.json")
    }

    private static var settingsURL: URL {
        containerURL.appendingPathComponent("settings.json")
    }

    private static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.outputFormatting = .prettyPrinted
        return e
    }

    private static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }

    // MARK: - Habits

    public static func save(_ summary: HabitSummary) {
        do {
            // macOS registers the group container path but does not create the
            // directory until something does. Harmless when it already exists.
            try FileManager.default.createDirectory(
                at: containerURL, withIntermediateDirectories: true)

            let data = try encoder.encode(summary)
            // Atomic: writes to a temp file then renames, so a crash mid-write
            // leaves either the old file intact or the new one complete.
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Could not save habits: \(error)")
        }
    }

    public static func load() -> HabitSummary? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(HabitSummary.self, from: data)
    }

    /// Saved data if there is any, otherwise the bundled sample.
    public static func loadOrSeed() -> HabitSummary {
        load() ?? .sample()
    }

    public static func reset() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Settings

    /// A separate file from summary.json: settings change rarely and habits
    /// change constantly, so a settings write cannot corrupt habit data.
    public static func save(_ settings: AppSettings) {
        do {
            try FileManager.default.createDirectory(
                at: containerURL, withIntermediateDirectories: true)
            try encoder.encode(settings).write(to: settingsURL, options: .atomic)
        } catch {
            print("Could not save settings: \(error)")
        }
    }

    public static func loadSettings() -> AppSettings {
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? decoder.decode(AppSettings.self, from: data)
        else { return .default }
        return settings
    }
    
    
}
