//
//  SettingsView.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI
import ReWork_package

struct SettingsView: View {
    let store: HabitStore

    @Environment(\.dismiss) private var dismiss
    @State private var settings: AppSettings

    init(store: HabitStore) {
        self.store = store
        _settings = State(initialValue: store.settings)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Week") {
                    Picker("Starts on", selection: $settings.firstWeekday) {
                        Text("Monday").tag(2)
                        Text("Sunday").tag(1)
                    }
                }

                Section("Behaviour") {
                    Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                    Toggle("Move completed to bottom", isOn: $settings.sinkCompleted)
                    Toggle("Hide routine habits", isOn: $settings.hideRoutineHabits)
                }

                Section("Habits") {
                    NavigationLink("Reorder habits") {
                        ReorderView(store: store)
                    }
                    NavigationLink("Archive") {
                        ArchiveView(store: store)
                    }
                }

                Section {
                    Text("Sync is not set up yet. Everything is stored on this device.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Account")
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // AppSettings being Equatable is what makes this work: it compares
            // the whole struct, so any field changing triggers one save.
            .onChange(of: settings) { _, new in
                store.apply(new)
            }
        }
    }
}

struct ReorderView: View {
    let store: HabitStore
    
    @State private var filter: HabitFilter = .all
    
    private var visible: [Habit] {
        filter.apply(to: store.activeHabits,
                     today: store.today,
                     sinkCompleted: false && store.settings.sinkCompleted)
    }

    var body: some View {
        List {
            ForEach(visible) { habit in
                HStack(spacing: 12) {
                    HabitIcon(habit: habit, today: store.today, size: 30, glyph: 14)
                    Text(habit.name)
                }
            }
            .onMove { store.move(from: $0, to: $1) }
        }
        // Permanently active, so the drag handles are always visible and
        // there is no Edit button to press first.
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Reorder")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
