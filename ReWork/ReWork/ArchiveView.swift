//
//  ArchiveView.swift
//  ReWork
//
//  Created by Daniel Molodet on 03/09/2026.
//

import SwiftUI
import ReWork_package

struct ArchiveView: View {
    let store: HabitStore

    @State private var pendingDelete: Habit?

    var body: some View {
        List {
            ForEach(store.archivedHabits) { habit in
                HStack(spacing: 6) {
                    HabitIcon(habit: habit, today: store.today, size: 32, glyph: 15)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                        Text("\(habit.completions.values.reduce(0, +)) completions")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Restore") { store.unarchive(habit.id) }
                        .buttonStyle(.bordered)
                    Button("Delete", role: .destructive) { pendingDelete = habit }
                        .buttonStyle(.bordered)
                }
            }

            if store.archivedHabits.isEmpty {
                ContentUnavailableView("Nothing archived", systemImage: "archivebox")
            }
        }
        .navigationTitle("Archive")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        // The one irreversible action in the app, so it gets a confirmation
        // naming the habit and the history being destroyed.
        .confirmationDialog(
            "Delete \(pendingDelete?.name ?? "")?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete permanently", role: .destructive) {
                if let habit = pendingDelete { store.delete(habit.id) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("This removes all history for this habit and cannot be undone.")
        }
    }
}
