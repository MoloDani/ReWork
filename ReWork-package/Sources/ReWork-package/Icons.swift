//
//  Icons.swift
//  ReWork-package
//
//  Created by Daniel Molodet on 27/08/2026.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum IconCatalog {
    public struct Group: Identifiable, Sendable {
        public let id: String
        public let symbols: [String]

        public init(id: String, symbols: [String]) {
            self.id = id
            self.symbols = symbols
        }
    }

    public static let groups: [Group] = [
        Group(id: "Fitness", symbols: [
            "figure.run", "figure.walk", "figure.hiking", "figure.pool.swim",
            "figure.yoga", "figure.strengthtraining.traditional", "figure.cooldown",
            "figure.mind.and.body", "figure.climbing", "dumbbell.fill",
            "bicycle", "sportscourt.fill", "soccerball", "basketball.fill",
            "shoeprints.fill", "stopwatch.fill",
        ]),
        Group(id: "Health", symbols: [
            "heart.fill", "lungs.fill", "brain.head.profile", "pills.fill",
            "cross.case.fill", "stethoscope", "bandage.fill", "eye.fill",
            "ear.fill", "mouth.fill", "waveform.path.ecg", "drop.fill",
        ]),
        Group(id: "Mind", symbols: [
            "book.closed.fill", "text.book.closed.fill", "graduationcap.fill",
            "pencil.and.outline", "highlighter", "quote.bubble.fill",
            "lightbulb.fill", "puzzlepiece.fill", "chart.line.uptrend.xyaxis",
            "newspaper.fill", "globe", "character.book.closed.fill",
        ]),
        Group(id: "Creative", symbols: [
            "paintbrush.fill", "paintpalette.fill", "music.note", "guitars.fill",
            "pianokeys", "camera.fill", "video.fill", "mic.fill",
            "theatermasks.fill", "scissors", "hammer.fill",
            "wrench.and.screwdriver.fill",
        ]),
        Group(id: "Food & Drink", symbols: [
            "cup.and.saucer.fill", "mug.fill", "wineglass.fill", "fork.knife",
            "carrot.fill", "leaf.fill", "birthday.cake.fill",
            "takeoutbag.and.cup.and.straw.fill", "refrigerator.fill",
        ]),
        Group(id: "Routine", symbols: [
            "sunrise.fill", "sun.max.fill", "sunset.fill", "moon.stars.fill",
            "bed.double.fill", "alarm.fill", "shower.fill", "washer.fill",
            "house.fill", "trash.fill", "sparkles", "clock.fill",
        ]),
        Group(id: "Life", symbols: [
            "dog.fill", "cat.fill", "phone.fill", "envelope.fill",
            "person.2.fill", "gift.fill", "creditcard.fill", "cart.fill",
            "banknote.fill", "airplane", "car.fill", "tram.fill",
            "map.fill", "flag.fill", "star.fill", "flame.fill",
        ]),
    ]

    public static let all: [String] = groups.flatMap(\.symbols)
    public static let fallback = "star.fill"

    /// Emoji habits predate the switch to SF Symbols. Mapping at the display
    /// boundary means old saves keep working with no migration step.
    private static let emojiMap: [String: String] = [
        "🏃": "figure.run",      "📚": "book.closed.fill",
        "🧘": "figure.yoga",     "💧": "drop.fill",
        "💪": "dumbbell.fill",   "✍️": "pencil.and.outline",
        "🎨": "paintbrush.fill", "🎸": "guitars.fill",
        "🥗": "carrot.fill",     "😴": "bed.double.fill",
        "🧹": "house.fill",      "💊": "pills.fill",
        "🌱": "leaf.fill",       "☕️": "cup.and.saucer.fill",
        "🚶": "figure.walk",     "🎯": "star.fill",
    ]

    /// Resolves a stored `icon` to a usable SF Symbol name. Symbol
    /// availability varies by OS version and an invalid name renders as a
    /// blank square, so unknown names fall back rather than looking broken.
    public static func symbol(for stored: String) -> String {
        let candidate: String

        if let mapped = emojiMap[stored] {
            candidate = mapped
        } else if stored.unicodeScalars.first?.properties.isEmoji == true {
            return fallback
        } else {
            candidate = stored
        }

        #if canImport(UIKit)
        if #available(iOS 13.0, *) {
            return UIImage(systemName: candidate) != nil ? candidate : fallback
        } else {
            // Fallback on earlier versions
        }
        #endif // canImport(UIKit)
        
        return candidate
    }
}
