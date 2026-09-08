//
//  AddHabitView.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI
import ReWork_package

struct AddHabitView: View {
    let store: HabitStore
    var editing: Habit?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var icon: String
    @State private var color: String
    @State private var perDay: Int
    @State private var routines: Set<Routine>
    @State private var goalType: GoalType
    @State private var target: Int
    @State private var reminderOn: Bool
    @State private var reminderTime: Date
    @State private var showSettingsAlert = false

    static let palette = ["#f87171", "#fb7185", "#f472b6", "#e879f9",
                          "#c084fc", "#a78bfa", "#818cf8", "#60a5fa",
                          "#38bdf8", "#22d3ee", "#0891b2", "#2dd4bf",
                          "#0d9488", "#34d399", "#4ade80", "#84cc16",
                          "#65a30d", "#facc15", "#fbbf24", "#f59e0b",
                          "#fb923c", "#94a3b8", "#a8a29e", "#d6d3d1"]

    // The underscore prefix reaches the State wrapper itself, which is the
    // only way to seed @State from an init parameter.
    init(store: HabitStore, editing: Habit? = nil) {
        self.store = store
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _icon = State(initialValue: editing?.icon ?? "figure.run")
        _color = State(initialValue: editing?.color ?? Self.palette[0])
        _perDay = State(initialValue: editing?.completionsPerDay ?? 1)
        _routines = State(initialValue: Set(editing?.routines ?? []))
        _goalType = State(initialValue: editing?.goalType ?? .daily)
        _target = State(initialValue: editing?.target ?? 1)
        _reminderOn = State(initialValue: editing?.reminderTime != nil)
        _reminderTime = State(initialValue: Self.parse(editing?.reminderTime) ?? Self.defaultTime)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                goalSection
                colorSection
                routineSection
                reminderSection
                previewSection
            }
            .navigationTitle(editing == nil ? "New Habit" : "Edit Habit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { toolbarContent }
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section {
            TextField("Habit name", text: $name)

            NavigationLink {
                IconPickerView(selection: $icon, tint: color)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: IconCatalog.symbol(for: icon))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(hex: color))
                        .frame(width: 38, height: 38)
                        .background(Color(hex: color).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text("Icon")
                }
            }
        }
    }

    private var goalSection: some View {
        Section("Goal") {
            Picker("Period", selection: $goalType) {
                Text("Daily").tag(GoalType.daily)
                Text("Weekly").tag(GoalType.weekly)
                Text("Monthly").tag(GoalType.monthly)
            }

            if goalType != .daily {
                Stepper("\(target) \(target == 1 ? "day" : "days") per \(goalType == .weekly ? "week" : "month")",
                        value: $target,
                        in: 1...(goalType == .weekly ? 7 : 31))
            }

            Stepper("\(perDay)× per day", value: $perDay, in: 1...20)
        }
        .onChange(of: goalType) { _, new in
            // A one-day period can never contain two completed days, so a
            // daily goal must have target 1.
            if new == .daily { target = 1 }
            else { target = min(target, new == .weekly ? 7 : 31) }
        }
    }

    private var colorSection: some View {
        Section("Colour") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                ForEach(Self.palette, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(.primary, lineWidth: color == hex ? 2 : 0))
                        .contentShape(Circle())
                        .onTapGesture { color = hex }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var routineSection: some View {
        Section("Routine") {
            ForEach(Routine.allCases, id: \.self) { routine in
                Toggle(routine.rawValue.capitalized, isOn: binding(for: routine))
            }
        }
    }

    /// A Set has no Bool to bind to, so one is synthesized from a getter and
    /// a setter — which is all a Binding actually is.
    private func binding(for routine: Routine) -> Binding<Bool> {
        Binding(
            get: { routines.contains(routine) },
            set: { on in
                if on { routines.insert(routine) } else { routines.remove(routine) }
            }
        )
    }

    private var reminderSection: some View {
        Section("Reminder") {
            Toggle("Daily reminder", isOn: $reminderOn)
            if reminderOn {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }
        }
        .onChange(of: reminderOn) { _, on in
            guard on else { return }
            Task {
                // requestAuthorization returns false immediately without
                // prompting if the user denied before — iOS only ever asks once.
                let granted = await Reminders.requestPermission()
                if !granted { showSettingsAlert = true }
            }
        }
        .alert("Notifications are off", isPresented: $showSettingsAlert) {
            Button("Open Settings") {
                #if os(iOS)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                #endif
            }
            Button("Not now", role: .cancel) { reminderOn = false }
        } message: {
            Text("Turn on notifications in Settings to get habit reminders.")
        }
    }

    private var previewSection: some View {
        Section("Preview") {
            HabitRow(habit: preview,
                     today: store.today,
                     firstWeekday: store.settings.firstWeekday,
                     onTap: {})
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(editing == nil ? "Add" : "Save") { save() }
                .disabled(!isValid)
        }
    }

    private func save() {
        if let editing {
            store.update(editing.id, name: name, icon: icon, color: color,
                         completionsPerDay: perDay, routines: Array(routines),
                         reminderTime: reminderString, goalType: goalType, target: target)
        } else {
            store.add(name: name, icon: icon, color: color,
                      completionsPerDay: perDay, routines: Array(routines),
                      reminderTime: reminderString, goalType: goalType, target: target)
        }
        dismiss()
    }

    // MARK: - Helpers

    /// Live preview built from the form's current state, keeping the real id
    /// and history when editing so the grid shows accurate data.
    private var preview: Habit {
        Habit(id: editing?.id ?? "preview",
              name: name.isEmpty ? "New habit" : name,
              color: color,
              icon: icon,
              routines: Array(routines),
              goalType: goalType,
              target: target,
              completionsPerDay: perDay,
              reminderTime: reminderString,
              completions: editing?.completions ?? [:],
              createdAt: editing?.createdAt ?? store.today,
              sortIndex: nil)
    }

    /// "%02d:%02d:00" matches MySQL's TIME format, so this round-trips to the
    /// backend without conversion.
    private var reminderString: String? {
        guard reminderOn else { return nil }
        let c = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        return String(format: "%02d:%02d:00", c.hour ?? 9, c.minute ?? 0)
    }

    private static let defaultTime: Date = {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }()

    private static func parse(_ time: String?) -> Date? {
        guard let parts = time?.split(separator: ":").compactMap({ Int($0) }),
              parts.count >= 2 else { return nil }
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: Date())
    }
}
