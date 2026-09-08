//
//  Haptics.swift
//  ReWork-package
//
//  Created by Daniel Molodet on 27/08/2026.
//

import Foundation
#if os(iOS)
import UIKit
#endif

public enum Haptics {
    /// Set from AppSettings. Checked in each method so callers don't have to.
    nonisolated(unsafe) public static var enabled = true

    /// A single completion logged.
    @MainActor
    public static func tap() {
        #if os(iOS)
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    /// A habit just hit its daily target.
    @MainActor
    public static func complete() {
        #if os(iOS)
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    /// A count was wrapped back to zero.
    @MainActor
    public static func undo() {
        #if os(iOS)
        guard enabled else { return }
        if #available(iOS 13.0, *) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } else {
            // Fallback on earlier versions
        }
        #endif
    }
}
