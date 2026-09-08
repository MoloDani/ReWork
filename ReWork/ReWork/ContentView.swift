//
//  ContentView.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI
import Combine
import ReWork_package

struct ContentView: View {
    @State private var store = HabitStore(summary: HabitStorage.loadOrSeed())
    @State private var path: [String] = []
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var filter: HabitFilter = .all
    
    private var compact: Bool { store.settings.compactView }

    @Environment(\.scenePhase) private var scenePhase

    private var visible: [Habit] {
        filter.apply(to: store.activeHabits,
                     today: store.today,
                     sinkCompleted: compact && store.settings.sinkCompleted,
                     hideRoutines: store.settings.hideRoutineHabits)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(white: 0.04).ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    routineButton
                    habitList
                }
                // safeAreaInset rather than an overlay: this tells the List to
                // reserve space, so the last card can scroll clear of the bar
                // instead of hiding under it.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    routineBar.padding(.bottom, 12)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                HabitDetailView(habitID: id, store: store)
            }
            .sheet(isPresented: $showingAdd) {
                AddHabitView(store: store)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(store: store)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.reload() }
        }
        // Covers the app being left open across midnight, which scenePhase
        // never catches. refreshToday early-returns when nothing changed.
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            store.refreshToday()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 1) {
                Text(Self.weekday.string(from: anchorDate))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
                Text(Self.dayMonth.string(from: anchorDate))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    var new = store.settings
                    new.compactView.toggle()
                    store.apply(new)
                }
            } label: {
                Image(systemName: compact ? "rectangle.grid.1x2" : "list.bullet")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button { showingAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button { showingSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Layout.screenPadding)
        .frame(maxWidth: Layout.maxContentWidth)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    /// Derived from store.today rather than Date() so the whole screen agrees
    /// on which day it is, including across a midnight rollover.
    private var anchorDate: Date {
        DayKey.date(from: store.today) ?? Date()
    }

    private static let weekday: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEE"; return f
    }()

    private static let dayMonth: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMMM"; return f
    }()

    // MARK: - Routine button

    @ViewBuilder
    private var routineButton: some View {
            if let routine = filter.routine {
                let hour = Calendar.current.component(.hour, from: Date())
                let day = store.routineTargetDay(for: routine, hour: hour)
                let isYesterday = day != store.today
                let left = store.remaining(in: routine, on: day)

                Button {
                    Haptics.complete()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        store.completeRoutine(routine, on: day)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: left == 0 ? "checkmark.circle.fill" : "circle.badge.checkmark")
                        Text(left == 0
                             ? "\(filter.label) routine done"
                             : isYesterday
                                ? "Complete last night"
                                : "Complete \(filter.label.lowercased())")
                            .font(.system(size: 14, weight: .semibold))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(left == 0 ? Color(white: 0.10) : Color.accentColor.opacity(0.18))
                    .foregroundStyle(left == 0 ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.accentColor))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
                .disabled(left == 0)
                .padding(.horizontal, Layout.screenPadding)
                .frame(maxWidth: Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)
                
            }
        }
    
    

    // MARK: - List

    private var habitList: some View {
        List {
            ForEach(visible) { habit in
                row(for: habit)
                    // Insets at zero: the frames below handle both the width
                    // cap and the centring, and insets applied outside them
                    // would measure from the full window width.
                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            withAnimation { store.archive(habit.id) }
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.orange)
                    }
                    .contextMenu {
                        if habit.count(on: store.today) > 0 {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    store.decrement(habit.id)
                                }
                            } label: {
                                Label("Undo one", systemImage: "arrow.uturn.backward")
                            }
                        }

                        Button {
                            withAnimation { store.archive(habit.id) }
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                    }
            }
            .padding(.horizontal, Layout.screenPadding)
            .frame(maxWidth: Layout.maxContentWidth)
            .frame(maxWidth: .infinity)

            if visible.isEmpty {
                ContentUnavailableView(
                    filter == .all ? "No habits yet" : "Nothing in this routine",
                    systemImage: filter.icon,
                    description: Text(filter == .all
                        ? "Tap + to add your first habit."
                        : "Edit a habit to add it to this routine.")
                )
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func row(for habit: Habit) -> some View {
        if compact {
            CompactHabitRow(habit: habit, today: store.today) {
                feedback(for: habit)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    store.toggle(habit.id)
                }
            }
        } else {
            HabitRow(habit: habit,
                     today: store.today,
                     firstWeekday: store.settings.firstWeekday) {
                feedback(for: habit)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    store.toggle(habit.id)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { path.append(habit.id) }
        }
    }

    /// Fires before the mutation, predicting what the tap will do — haptics
    /// must lead the visual change or the delay reads as lag.
    private func feedback(for habit: Habit) {
        let current = habit.count(on: store.today)
        let max = habit.completionsPerDay

        if current >= max {
            Haptics.undo()
        } else if current + 1 >= max {
            Haptics.complete()
        } else {
            Haptics.tap()
        }
    }

    // MARK: - Routine bar

    private var routineBar: some View {
        HStack(spacing: 4) {
            ForEach(HabitFilter.allCases) { f in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        filter = f
                    }
                } label: {
                    Label(f.label, systemImage: f.icon)
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(filter == f ? Color(white: 0.18) : .clear))
                        .foregroundStyle(filter == f ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color(white: 0.16), lineWidth: 1))
    }
}

#Preview {
    ContentView()
}
