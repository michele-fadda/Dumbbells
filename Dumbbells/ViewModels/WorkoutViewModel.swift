//
//  WorkoutViewModel.swift
//  DumbBells
//
//  Enhanced with validation, completion tracking, and data persistence
//

import Foundation
import SwiftUI

// MARK: - Pill States (moved here to avoid ambiguity)
enum PillState {
    case start
    case activeTimer
    case keyboard
    case restPicker
    case countdown
}

// MARK: - Data Models for Persistence

struct WorkoutHistory: Codable {
    let date: Date
    let exerciseName: String
    let sets: [CompletedSet]
}

struct CompletedSet: Codable {
    let setNumber: Int
    let kg: String
    let reps: String
    let elapsedTime: String
}

// MARK: - ViewModel

class WorkoutViewModel: ObservableObject {
    @Published var selectedField: FieldSelection? = nil
    @Published var sets: [WorkoutSet] = []
    
    // Pill state management
    @Published var currentPillState: PillState = .start
    @Published var previousPillState: PillState = .start
    
    @Published var workoutStarted: Bool = false
    @Published var workoutStartTime: Date? = nil
    @Published var elapsedSeconds: Int = 0

    // Rest timer properties
    @Published var restTimeRemaining: Int = 0
    @Published var restTimerDuration: Int = 0
    @Published var isRestTimerActive: Bool = false
    
    // NEW: Completion tracking
    @Published var currentSetIndex: Int = 0
    @Published var showCompletionModal: Bool = false
    
    // NEW: Previous workout data
    @Published var previousWorkout: [CompletedSet] = []

    private var timer: Timer?
    private var restTimer: Timer?
    
    // NEW: Data persistence
    private let dataManager: WorkoutDataManagerProtocol
    private let exerciseName = "Bench Press (Dumbbell)"

    init(totalSets: Int = 3, dataManager: WorkoutDataManagerProtocol? = nil) {
        self.dataManager = dataManager ?? WorkoutDataManager()
        sets = (1...totalSets).map { WorkoutSet(setNumber: $0) }
        loadPreviousWorkout()
    }

    // MARK: - Data Persistence
    
    private func loadPreviousWorkout() {
        previousWorkout = dataManager.loadPreviousWorkout(for: exerciseName)
    }
    
    private func saveWorkout() {
        let completedSets = sets.filter { !$0.kg.isEmpty && !$0.reps.isEmpty && $0.isCompleted }
            .map { CompletedSet(setNumber: $0.setNumber, kg: $0.kg, reps: $0.reps, elapsedTime: $0.completionTime) }
        
        let workout = WorkoutHistory(
            date: Date(),
            exerciseName: exerciseName,
            sets: completedSets
        )
        
        dataManager.saveWorkout(workout)
    }
    
    // MARK: - Data Access Methods
    
    func getCompletedSetsWithTime() -> [CompletedSet] {
        return sets.filter { !$0.kg.isEmpty && !$0.reps.isEmpty && $0.isCompleted }
            .map { CompletedSet(setNumber: $0.setNumber, kg: $0.kg, reps: $0.reps, elapsedTime: $0.completionTime) }
    }
    
    // MARK: - Validation Logic
    
    var canStartWorkout: Bool {
        guard currentSetIndex < sets.count else { return false }
        let currentSet = sets[currentSetIndex]
        return !currentSet.kg.isEmpty && !currentSet.reps.isEmpty && !currentSet.isCompleted
    }
    
    private var hasNextIncompleteSet: Bool {
        return sets.indices.contains(currentSetIndex + 1) &&
               sets[currentSetIndex + 1].hasData &&
               !sets[currentSetIndex + 1].isCompleted
    }
    
    private var shouldShowSummary: Bool {
        // Show summary if current set is the last one OR next set has no data
        return currentSetIndex == sets.count - 1 ||
               (currentSetIndex + 1 < sets.count && !sets[currentSetIndex + 1].hasData)
    }

    // MARK: - Workout Flow Logic

    func startWorkout() {
        guard canStartWorkout else { return }
        
        // Deselect any field when starting workout
        selectedField = nil
        workoutStarted = true
        workoutStartTime = Date()
        currentPillState = .activeTimer
        startTimer()
    }

    func stopWorkout() {
        // Only mark set as completed if explicitly called from "Finish" button
        // Do not automatically complete sets from other contexts
        
        stopTimer()
        stopRestTimer()
        
        // Determine next action only when explicitly finishing a set
        if shouldShowSummary {
            // Mark current set as completed when finishing workout
            if currentSetIndex < sets.count {
                sets[currentSetIndex].isCompleted = true
                sets[currentSetIndex].completionTime = formattedElapsedTime
            }
            
            // Save workout and show completion modal
            saveWorkout()
            showCompletionModal = true
            resetWorkoutState()
        } else if hasNextIncompleteSet {
            // Mark current set as completed
            if currentSetIndex < sets.count {
                sets[currentSetIndex].isCompleted = true
                sets[currentSetIndex].completionTime = formattedElapsedTime
            }
            
            // Move to next set and rearm start button
            currentSetIndex += 1
            currentPillState = .start
            workoutStarted = false
            workoutStartTime = nil
            elapsedSeconds = 0
        } else {
            // Mark current set as completed
            if currentSetIndex < sets.count {
                sets[currentSetIndex].isCompleted = true
                sets[currentSetIndex].completionTime = formattedElapsedTime
            }
            
            // Default reset
            resetWorkoutState()
        }
    }
    
    private func resetWorkoutState() {
        selectedField = nil  // Ensure field is deselected on reset
        workoutStarted = false
        workoutStartTime = nil
        elapsedSeconds = 0
        currentPillState = .start
    }
    
    // NEW: Reset for new workout
    func startNewWorkout() {
        currentSetIndex = 0
        // Create completely fresh sets with empty fields
        sets = (1...3).map { WorkoutSet(setNumber: $0) }
        showCompletionModal = false
        selectedField = nil
        resetWorkoutState()
        loadPreviousWorkout() // Refresh previous data for display
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.workoutStartTime else { return }
            self.elapsedSeconds = Int(Date().timeIntervalSince(start))
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Rest Timer Logic
    
    func startRestTimer(duration: Int) {
        restTimerDuration = duration
        restTimeRemaining = duration
        isRestTimerActive = true
        currentPillState = .countdown
        
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.restTimeRemaining > 0 {
                self.restTimeRemaining -= 1
            } else {
                self.stopRestTimer()
                // After rest completes, return to the previous state without ending exercise
                self.currentPillState = self.previousPillState
            }
        }
    }

    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isRestTimerActive = false
        restTimeRemaining = 0
    }

    func skipRestTimer() {
        stopRestTimer()
        // Return to the previous state without ending exercise
        currentPillState = previousPillState
    }

    // MARK: - Pill State Management
    
    func showKeyboard() {
        if currentPillState != .keyboard {
            previousPillState = currentPillState
            currentPillState = .keyboard
        }
    }

    func hideKeyboard() {
        // Explicitly deselect the field
        selectedField = nil
        
        // Return to previous pill state
        if previousPillState != .keyboard {
            currentPillState = previousPillState
        } else {
            currentPillState = workoutStarted ? .activeTimer : .start
        }
    }
    
    // Additional method to ensure field deselection
    func deselectField() {
        selectedField = nil
    }

    func showRestPicker() {
        // Store the selected field to restore it later (don't deselect it)
        if currentPillState != .restPicker {
            previousPillState = currentPillState
            currentPillState = .restPicker
        }
    }

    func hideRestPicker() {
        currentPillState = previousPillState
    }

    deinit {
        stopTimer()
        stopRestTimer()
    }

    var formattedElapsedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Input Logic

    func valueFor(set: Int, field: String) -> String {
        guard let index = sets.firstIndex(where: { $0.setNumber == set }) else { return "" }
        return field == "kg" ? sets[index].kg : sets[index].reps
    }
    
    // NEW: Get previous data for display
    func previousValueFor(set: Int) -> String {
        guard let previousSet = previousWorkout.first(where: { $0.setNumber == set }) else {
            return "-N/A-"
        }
        return "\(previousSet.kg) x \(previousSet.reps)"
    }

    func updateValue(_ key: String) {
        guard let currentSelection = selectedField else { return }
        guard let index = sets.firstIndex(where: { $0.setNumber == currentSelection.set }) else { return }

        var currentValue = currentSelection.field == "kg" ? sets[index].kg : sets[index].reps

        if currentValue.count < 3,
           key == "." || key.range(of: #"^\d$"#, options: .regularExpression) != nil {
            currentValue.append(key)
            updateField(at: index, field: currentSelection.field, with: currentValue)
        }
    }

    func deleteLastCharacter() {
        guard let currentSelection = selectedField else { return }
        guard let index = sets.firstIndex(where: { $0.setNumber == currentSelection.set }) else { return }

        var currentValue = currentSelection.field == "kg" ? sets[index].kg : sets[index].reps

        if !currentValue.isEmpty {
            currentValue.removeLast()
            updateField(at: index, field: currentSelection.field, with: currentValue)
        }
    }

    func moveToNextField() {
        let totalFields = sets.count * 2
        let flatIndex: Int

        if let current = selectedField {
            let row = current.set - 1
            let col = current.field == "kg" ? 0 : 1
            flatIndex = row * 2 + col
        } else {
            flatIndex = -1
        }

        let nextIndex = (flatIndex + 1) % totalFields
        let nextSet = (nextIndex / 2) + 1
        let nextField = (nextIndex % 2 == 0) ? "kg" : "reps"

        selectedField = FieldSelection(set: nextSet, field: nextField)
    }

    private func updateField(at index: Int, field: String, with value: String) {
        if field == "kg" {
            sets[index].kg = value
        } else {
            sets[index].reps = value
        }
    }
}

// MARK: - Enhanced Models

struct WorkoutSet {
    let setNumber: Int
    var kg: String = ""
    var reps: String = ""
    var isCompleted: Bool = false
    var completionTime: String = ""
    
    var hasData: Bool {
        return !kg.isEmpty && !reps.isEmpty
    }
}

struct FieldSelection: Equatable {
    let set: Int
    let field: String
}

// MARK: - Data Manager Protocol

protocol WorkoutDataManagerProtocol {
    func saveWorkout(_ workout: WorkoutHistory)
    func loadPreviousWorkout(for exerciseName: String) -> [CompletedSet]
}

// MARK: - Data Manager

class WorkoutDataManager: WorkoutDataManagerProtocol {
    private let userDefaults = UserDefaults.standard
    private let workoutHistoryKey = "WorkoutHistory"
    
    func saveWorkout(_ workout: WorkoutHistory) {
        var history = loadWorkoutHistory()
        history.append(workout)
        
        // Keep only last 10 workouts to prevent unlimited growth
        if history.count > 10 {
            history = Array(history.suffix(10))
        }
        
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: workoutHistoryKey)
        }
    }
    
    func loadPreviousWorkout(for exerciseName: String) -> [CompletedSet] {
        let history = loadWorkoutHistory()
        return history.last(where: { $0.exerciseName == exerciseName })?.sets ?? []
    }
    
    private func loadWorkoutHistory() -> [WorkoutHistory] {
        guard let data = userDefaults.data(forKey: workoutHistoryKey),
              let history = try? JSONDecoder().decode([WorkoutHistory].self, from: data) else {
            return []
        }
        return history
    }
}

// MARK: - Previews

#Preview("WorkoutViewModel States") {
    VStack(spacing: 20) {
        Text("WorkoutViewModel Preview")
            .font(.headline)
        
        Text("This shows various states of the workout")
            .font(.caption)
            .foregroundColor(.secondary)
        
        // Note: WorkoutViewModel is used by WorkoutPanel
        // See WorkoutPanel previews for visual representation
        
        VStack(alignment: .leading, spacing: 8) {
            Text("States:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Text("• Start")
                Spacer()
                Text("Ready to begin")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("• Active Timer")
                Spacer()
                Text("Workout in progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("• Keyboard")
                Spacer()
                Text("Entering data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("• Rest Picker")
                Spacer()
                Text("Selecting rest time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("• Countdown")
                Spacer()
                Text("Rest in progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    .padding()
}
