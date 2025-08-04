//
//  WorkoutLogicTests.swift
//  Dumbbells
//
//  Created by Michele Fadda on 03/08/2025.
//
//  Core workout logic
//

import XCTest
@testable import Dumbbells

final class WorkoutLogicTests: XCTestCase {
    var viewModel: WorkoutViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = WorkoutViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    /// Test that the view model initializes with correct default values
    func testInitialState() {
        XCTAssertEqual(viewModel.sets.count, 3)
        XCTAssertEqual(viewModel.currentPillState, .start)
        XCTAssertEqual(viewModel.currentSetIndex, 0)
        XCTAssertFalse(viewModel.workoutStarted)
        XCTAssertNil(viewModel.selectedField)
        XCTAssertFalse(viewModel.showCompletionModal)
    }
    
    /// Test that all sets start empty and not completed
    func testInitialSetsAreEmpty() {
        for set in viewModel.sets {
            XCTAssertTrue(set.kg.isEmpty)
            XCTAssertTrue(set.reps.isEmpty)
            XCTAssertFalse(set.isCompleted)
            XCTAssertFalse(set.hasData)
        }
    }
    
    // MARK: - Start Validation Tests
    
    /// Test that workout cannot start when both kg and reps fields are empty
    func testCannotStartWithEmptyFields() {
        XCTAssertFalse(viewModel.canStartWorkout)
    }
    
    /// Test that workout cannot start with only kg field filled
    func testCannotStartWithOnlyKg() {
        viewModel.sets[0].kg = "45"
        XCTAssertFalse(viewModel.canStartWorkout)
    }
    
    /// Test that workout cannot start with only reps field filled
    func testCannotStartWithOnlyReps() {
        viewModel.sets[0].reps = "10"
        XCTAssertFalse(viewModel.canStartWorkout)
    }
    
    /// Test that workout can start when both kg and reps are filled
    func testCanStartWithBothFields() {
        viewModel.sets[0].kg = "45"
        viewModel.sets[0].reps = "10"
        XCTAssertTrue(viewModel.canStartWorkout)
    }
    
    /// Test that workout cannot start if the current set is already completed
    func testCannotStartCompletedSet() {
        viewModel.sets[0].kg = "45"
        viewModel.sets[0].reps = "10"
        viewModel.sets[0].isCompleted = true
        XCTAssertFalse(viewModel.canStartWorkout)
    }
    
    // MARK: - Workout Flow Tests
    
    /// Test that starting a workout updates the state correctly
    func testStartWorkout() {
        // Setup
        viewModel.sets[0].kg = "45"
        viewModel.sets[0].reps = "10"
        
        // Act
        viewModel.startWorkout()
        
        // Assert
        XCTAssertTrue(viewModel.workoutStarted)
        XCTAssertEqual(viewModel.currentPillState, .activeTimer)
        XCTAssertNotNil(viewModel.workoutStartTime)
        XCTAssertNil(viewModel.selectedField)
    }
    
    /// Test that stopping a workout marks the current set as completed
    func testStopWorkoutCompletesSet() {
        // Setup
        viewModel.sets[0].kg = "45"
        viewModel.sets[0].reps = "10"
        viewModel.startWorkout()
        
        // Act
        viewModel.stopWorkout()
        
        // Assert
        XCTAssertTrue(viewModel.sets[0].isCompleted)
    }
    
    /// Test that stopping a workout advances to the next set when available
    func testStopWorkoutAdvancesToNextSet() {
        // Setup - fill two sets
        viewModel.sets[0].kg = "45"
        viewModel.sets[0].reps = "10"
        viewModel.sets[1].kg = "50"
        viewModel.sets[1].reps = "8"
        viewModel.startWorkout()
        
        // Act
        viewModel.stopWorkout()
        
        // Assert
        XCTAssertEqual(viewModel.currentSetIndex, 1)
        XCTAssertEqual(viewModel.currentPillState, .start)
        XCTAssertFalse(viewModel.workoutStarted)
    }
    
    /// Test that stopping the last set shows the completion modal
    func testStopWorkoutShowsModalWhenLastSet() {
        // Setup - only first set
        viewModel.sets[0].kg = "45"
        viewModel.sets[0].reps = "10"
        viewModel.startWorkout()
        
        // Act
        viewModel.stopWorkout()
        
        // Assert
        XCTAssertTrue(viewModel.showCompletionModal)
    }
    
    // MARK: - Input Logic Tests
    
    /// Test that numeric input updates the correct field
    func testUpdateValueNumeric() {
        // Setup
        viewModel.selectedField = FieldSelection(set: 1, field: "kg")
        
        // Act
        viewModel.updateValue("4")
        viewModel.updateValue("5")
        
        // Assert
        XCTAssertEqual(viewModel.sets[0].kg, "45")
    }
    
    /// Test that decimal point input works correctly
    func testUpdateValueDecimal() {
        // Setup
        viewModel.selectedField = FieldSelection(set: 1, field: "kg")
        
        // Act
        viewModel.updateValue("4")
        viewModel.updateValue(".")
        viewModel.updateValue("5")
        
        // Assert
        XCTAssertEqual(viewModel.sets[0].kg, "4.5")
    }
    
    /// Test that input is limited to 3 characters
    func testUpdateValueLimit() {
        // Setup
        viewModel.selectedField = FieldSelection(set: 1, field: "reps")
        
        // Act
        viewModel.updateValue("1")
        viewModel.updateValue("2")
        viewModel.updateValue("3")
        viewModel.updateValue("4") // Should be ignored
        
        // Assert
        XCTAssertEqual(viewModel.sets[0].reps, "123")
    }
    
    /// Test that deleting removes the last character
    func testDeleteLastCharacter() {
        // Setup
        viewModel.selectedField = FieldSelection(set: 1, field: "kg")
        viewModel.sets[0].kg = "45"
        
        // Act
        viewModel.deleteLastCharacter()
        
        // Assert
        XCTAssertEqual(viewModel.sets[0].kg, "4")
    }
    
    /// Test that deleting from an empty field does nothing
    func testDeleteFromEmpty() {
        // Setup
        viewModel.selectedField = FieldSelection(set: 1, field: "kg")
        
        // Act
        viewModel.deleteLastCharacter()
        
        // Assert
        XCTAssertEqual(viewModel.sets[0].kg, "")
    }
    
    // MARK: - Field Navigation Tests
    
    /// Test that navigation moves to the next field in sequence
    func testMoveToNextField() {
        // Setup
        viewModel.selectedField = FieldSelection(set: 1, field: "kg")
        
        // Act
        viewModel.moveToNextField()
        
        // Assert
        XCTAssertEqual(viewModel.selectedField?.set, 1)
        XCTAssertEqual(viewModel.selectedField?.field, "reps")
    }
    
    /// Test that navigation wraps around from the last field to the first
    func testMoveToNextFieldWrapsAround() {
        // Setup
        viewModel.selectedField = FieldSelection(set: 3, field: "reps")
        
        // Act
        viewModel.moveToNextField()
        
        // Assert
        XCTAssertEqual(viewModel.selectedField?.set, 1)
        XCTAssertEqual(viewModel.selectedField?.field, "kg")
    }
    
    // MARK: - Pill State Tests
    
    /// Test that showing keyboard updates state and preserves previous state
    func testShowKeyboard() {
        // Setup
        viewModel.currentPillState = .start
        
        // Act
        viewModel.showKeyboard()
        
        // Assert
        XCTAssertEqual(viewModel.currentPillState, .keyboard)
        XCTAssertEqual(viewModel.previousPillState, .start)
    }
    
    /// Test that hiding keyboard restores previous state and deselects field
    func testHideKeyboard() {
        // Setup
        viewModel.currentPillState = .keyboard
        viewModel.previousPillState = .start
        viewModel.selectedField = FieldSelection(set: 1, field: "kg")
        
        // Act
        viewModel.hideKeyboard()
        
        // Assert
        XCTAssertEqual(viewModel.currentPillState, .start)
        XCTAssertNil(viewModel.selectedField)
    }
    
    /// Test that showing rest picker preserves the selected field
    func testShowRestPickerPreservesField() {
        // Setup
        viewModel.currentPillState = .keyboard
        viewModel.selectedField = FieldSelection(set: 1, field: "kg")
        
        // Act
        viewModel.showRestPicker()
        
        // Assert
        XCTAssertEqual(viewModel.currentPillState, .restPicker)
        XCTAssertEqual(viewModel.previousPillState, .keyboard)
        XCTAssertNotNil(viewModel.selectedField) // Should be preserved
    }
    
    // MARK: - Rest Timer Tests
    
    /// Test that starting rest timer initializes all timer properties correctly
    func testStartRestTimer() {
        // Setup
        viewModel.previousPillState = .keyboard
        
        // Act
        viewModel.startRestTimer(duration: 60)
        
        // Assert
        XCTAssertEqual(viewModel.currentPillState, .countdown)
        XCTAssertEqual(viewModel.restTimeRemaining, 60)
        XCTAssertEqual(viewModel.restTimerDuration, 60)
        XCTAssertTrue(viewModel.isRestTimerActive)
    }
    
    /// Test that skipping rest timer returns to previous state and cleans up timer
    func testSkipRestTimer() {
        // Setup
        viewModel.currentPillState = .countdown
        viewModel.previousPillState = .keyboard
        viewModel.restTimeRemaining = 30
        viewModel.isRestTimerActive = true
        
        // Act
        viewModel.skipRestTimer()
        
        // Assert
        XCTAssertEqual(viewModel.currentPillState, .keyboard)
        XCTAssertFalse(viewModel.isRestTimerActive)
        XCTAssertEqual(viewModel.restTimeRemaining, 0)
    }
    
    // MARK: - Data Access Tests
    
    /// Test that value retrieval works for different sets and fields
    func testValueForSet() {
        // Setup
        viewModel.sets[0].kg = "45"
        viewModel.sets[0].reps = "10"
        
        // Act & Assert
        XCTAssertEqual(viewModel.valueFor(set: 1, field: "kg"), "45")
        XCTAssertEqual(viewModel.valueFor(set: 1, field: "reps"), "10")
        XCTAssertEqual(viewModel.valueFor(set: 2, field: "kg"), "")
    }
    
    /// Test that previous value shows "not available" when no history exists
    func testPreviousValueWhenNoHistoryExists() {
        // Setup - ensure no previous workout data exists
        let testUserDefaults = UserDefaults(suiteName: "EmptyTestSuite")!
        testUserDefaults.removePersistentDomain(forName: "EmptyTestSuite")
        let emptyDataManager = TestableWorkoutDataManager(userDefaults: testUserDefaults)
        viewModel = WorkoutViewModel(dataManager: emptyDataManager)
        
        // Act & Assert
        XCTAssertEqual(viewModel.previousValueFor(set: 1), "-N/A-")
        XCTAssertEqual(viewModel.previousValueFor(set: 2), "-N/A-")
        XCTAssertEqual(viewModel.previousValueFor(set: 3), "-N/A-")
    }
    
    /// Test that previous value shows actual data when history exists
    func testPreviousValueWhenHistoryExists() {
        // Setup - create and save a previous workout
        let testUserDefaults = UserDefaults(suiteName: "HistoryTestSuite")!
        testUserDefaults.removePersistentDomain(forName: "HistoryTestSuite")
        let dataManagerWithHistory = TestableWorkoutDataManager(userDefaults: testUserDefaults)
        
        let workout = WorkoutHistory(
            date: Date().addingTimeInterval(-86400), // Yesterday
            exerciseName: "Bench Press (Dumbbell)",
            sets: [
                CompletedSet(setNumber: 1, kg: "45", reps: "10", elapsedTime: "1:30"),
                CompletedSet(setNumber: 2, kg: "50", reps: "8", elapsedTime: "3:00"),
                CompletedSet(setNumber: 3, kg: "40", reps: "12", elapsedTime: "4:30")
            ]
        )
        
        dataManagerWithHistory.saveWorkout(workout)
        viewModel = WorkoutViewModel(dataManager: dataManagerWithHistory)
        
        // Act & Assert
        XCTAssertEqual(viewModel.previousValueFor(set: 1), "45 x 10")
        XCTAssertEqual(viewModel.previousValueFor(set: 2), "50 x 8")
        XCTAssertEqual(viewModel.previousValueFor(set: 3), "40 x 12")
    }
    
    // MARK: - New Workout Tests
    
    /// Test that starting a new workout resets all state to initial values
    func testStartNewWorkout() {
        // Setup - simulate completed workout
        viewModel.sets[0].kg = "45"
        viewModel.sets[0].reps = "10"
        viewModel.sets[0].isCompleted = true
        viewModel.currentSetIndex = 1
        viewModel.workoutStarted = true
        viewModel.selectedField = FieldSelection(set: 2, field: "kg")
        viewModel.showCompletionModal = true
        
        // Act
        viewModel.startNewWorkout()
        
        // Assert
        XCTAssertEqual(viewModel.currentSetIndex, 0)
        XCTAssertFalse(viewModel.showCompletionModal)
        XCTAssertNil(viewModel.selectedField)
        XCTAssertFalse(viewModel.workoutStarted)
        XCTAssertEqual(viewModel.currentPillState, .start)
        
        // All sets should be fresh
        for set in viewModel.sets {
            XCTAssertTrue(set.kg.isEmpty)
            XCTAssertTrue(set.reps.isEmpty)
            XCTAssertFalse(set.isCompleted)
        }
    }
    
    // MARK: - Time Formatting Tests
    
    /// Test that elapsed time formats correctly in MM:SS format
    func testFormattedElapsedTime() {
        viewModel.elapsedSeconds = 65 // 1:05
        XCTAssertEqual(viewModel.formattedElapsedTime, "1:05")
        
        viewModel.elapsedSeconds = 3661 // 61:01
        XCTAssertEqual(viewModel.formattedElapsedTime, "61:01")
        
        viewModel.elapsedSeconds = 5 // 0:05
        XCTAssertEqual(viewModel.formattedElapsedTime, "0:05")
    }
    
    // MARK: - Model Property Tests
    
    /// Test that WorkoutSet.hasData returns correct boolean based on field content
    func testWorkoutSetHasData() {
        let emptySet = WorkoutSet(setNumber: 1)
        XCTAssertFalse(emptySet.hasData)
        
        var partialSet = WorkoutSet(setNumber: 1)
        partialSet.kg = "45"
        XCTAssertFalse(partialSet.hasData)
        
        var completeSet = WorkoutSet(setNumber: 1)
        completeSet.kg = "45"
        completeSet.reps = "10"
        XCTAssertTrue(completeSet.hasData)
    }
    
    // MARK: - Edge Cases
    
    /// Test that invalid set numbers return empty strings safely
    func testInvalidSetNumber() {
        XCTAssertEqual(viewModel.valueFor(set: 99, field: "kg"), "")
        XCTAssertEqual(viewModel.valueFor(set: 0, field: "reps"), "")
    }
    
    /// Test that non-numeric input is ignored
    func testNonNumericInput() {
        viewModel.selectedField = FieldSelection(set: 1, field: "kg")
        viewModel.updateValue("a") // Should be ignore
    }
}
