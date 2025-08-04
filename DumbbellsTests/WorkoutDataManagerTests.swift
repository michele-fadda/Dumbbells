//
//  WorkoutDataManagerTests.swift
//  DumbbellsTests
//
//  Unit tests for WorkoutDataManager persistence logic
//

import XCTest
@testable import Dumbbells

final class WorkoutDataManagerTests: XCTestCase {
    var dataManager: TestableWorkoutDataManager!
    var testUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        
        // Use a separate UserDefaults suite for testing
        testUserDefaults = UserDefaults(suiteName: "TestSuite")
        testUserDefaults.removePersistentDomain(forName: "TestSuite")
        
        // Create data manager that uses test UserDefaults
        dataManager = TestableWorkoutDataManager(userDefaults: testUserDefaults)
    }
    
    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: "TestSuite")
        testUserDefaults = nil
        dataManager = nil
        super.tearDown()
    }
    
    // MARK: - Save Workout Tests
    
    /// Test that a single workout can be saved and persisted correctly
    func testSaveWorkout() {
        // Setup
        let workout = createTestWorkout()
        
        // Act
        dataManager.saveWorkout(workout)
        
        // Assert
        let history = loadWorkoutHistoryFromDefaults()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.exerciseName, "Bench Press (Dumbbell)")
        XCTAssertEqual(history.first?.sets.count, 3)
    }
    
    /// Test that multiple workouts accumulate in history
    func testSaveMultipleWorkouts() {
        // Setup
        let workout1 = createTestWorkout(exerciseName: "Bench Press")
        let workout2 = createTestWorkout(exerciseName: "Squats")
        
        // Act
        dataManager.saveWorkout(workout1)
        dataManager.saveWorkout(workout2)
        
        // Assert
        let history = loadWorkoutHistoryFromDefaults()
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].exerciseName, "Bench Press")
        XCTAssertEqual(history[1].exerciseName, "Squats")
    }
    
    /// Test that workout history is limited to 10 entries to prevent unlimited growth
    func testSaveWorkoutLimitsHistoryTo10() {
        // Setup - save 12 workouts
        for i in 1...12 {
            let workout = createTestWorkout(exerciseName: "Exercise \(i)")
            dataManager.saveWorkout(workout)
        }
        
        // Assert - should only keep last 10
        let history = loadWorkoutHistoryFromDefaults()
        XCTAssertEqual(history.count, 10)
        XCTAssertEqual(history.first?.exerciseName, "Exercise 3") // First 2 should be removed
        XCTAssertEqual(history.last?.exerciseName, "Exercise 12")
    }
    
    // MARK: - Load Previous Workout Tests
    
    /// Test that loading previous workout returns empty array when no history exists
    func testLoadPreviousWorkoutWithNoHistory() {
        // Act
        let previousSets = dataManager.loadPreviousWorkout(for: "Bench Press")
        
        // Assert
        XCTAssertTrue(previousSets.isEmpty)
    }
    
    /// Test that loading previous workout returns the correct sets when history exists
    func testLoadPreviousWorkoutWithHistory() {
        // Setup
        let workout = createTestWorkout()
        dataManager.saveWorkout(workout)
        
        // Act
        let previousSets = dataManager.loadPreviousWorkout(for: "Bench Press (Dumbbell)")
        
        // Assert
        XCTAssertEqual(previousSets.count, 3)
        XCTAssertEqual(previousSets[0].kg, "45")
        XCTAssertEqual(previousSets[0].reps, "10")
    }
    
    /// Test that loading previous workout returns the most recent entry for an exercise
    func testLoadPreviousWorkoutReturnsLatestForExercise() {
        // Setup - save multiple workouts for same exercise
        let workout1 = createTestWorkout(sets: [
            CompletedSet(setNumber: 1, kg: "40", reps: "12", elapsedTime: "2:00")
        ])
        let workout2 = createTestWorkout(sets: [
            CompletedSet(setNumber: 1, kg: "50", reps: "8", elapsedTime: "1:45")
        ])
        
        dataManager.saveWorkout(workout1)
        dataManager.saveWorkout(workout2)
        
        // Act
        let previousSets = dataManager.loadPreviousWorkout(for: "Bench Press (Dumbbell)")
        
        // Assert - should return latest workout
        XCTAssertEqual(previousSets.count, 1)
        XCTAssertEqual(previousSets[0].kg, "50")
        XCTAssertEqual(previousSets[0].reps, "8")
    }
    
    /// Test that different exercises maintain separate history
    func testLoadPreviousWorkoutForDifferentExercise() {
        // Setup
        let benchWorkout = createTestWorkout(exerciseName: "Bench Press")
        let squatWorkout = createTestWorkout(exerciseName: "Squats")
        
        dataManager.saveWorkout(benchWorkout)
        dataManager.saveWorkout(squatWorkout)
        
        // Act
        let benchPrevious = dataManager.loadPreviousWorkout(for: "Bench Press")
        let squatPrevious = dataManager.loadPreviousWorkout(for: "Squats")
        let nonExistentPrevious = dataManager.loadPreviousWorkout(for: "Deadlifts")
        
        // Assert
        XCTAssertEqual(benchPrevious.count, 3)
        XCTAssertEqual(squatPrevious.count, 3)
        XCTAssertTrue(nonExistentPrevious.isEmpty)
    }
    
    // MARK: - Data Integrity Tests
    
    /// Test that WorkoutHistory can be properly encoded and decoded
    func testWorkoutHistoryCodable() {
        // Setup
        let originalWorkout = createTestWorkout()
        
        // Act - encode and decode
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try! encoder.encode([originalWorkout])
        let decodedWorkouts = try! decoder.decode([WorkoutHistory].self, from: encodedData)
        
        // Assert
        let decodedWorkout = decodedWorkouts.first!
        XCTAssertEqual(decodedWorkout.exerciseName, originalWorkout.exerciseName)
        XCTAssertEqual(decodedWorkout.sets.count, originalWorkout.sets.count)
        XCTAssertEqual(decodedWorkout.sets[0].kg, originalWorkout.sets[0].kg)
    }
    
    /// Test that CompletedSet can be properly encoded and decoded
    func testCompletedSetCodable() {
        // Setup
        let originalSet = CompletedSet(setNumber: 1, kg: "45", reps: "10", elapsedTime: "1:30")
        
        // Act - encode and decode
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try! encoder.encode(originalSet)
        let decodedSet = try! decoder.decode(CompletedSet.self, from: encodedData)
        
        // Assert
        XCTAssertEqual(decodedSet.setNumber, originalSet.setNumber)
        XCTAssertEqual(decodedSet.kg, originalSet.kg)
        XCTAssertEqual(decodedSet.reps, originalSet.reps)
        XCTAssertEqual(decodedSet.elapsedTime, originalSet.elapsedTime)
    }
    
    // MARK: - Error Handling Tests
    
    /// Test that corrupted data in UserDefaults doesn't crash the app
    func testLoadCorruptedData() {
        // Setup - save corrupted data
        let corruptedData = "corrupted data".data(using: .utf8)!
        testUserDefaults.set(corruptedData, forKey: "WorkoutHistory")
        
        // Act
        let previousSets = dataManager.loadPreviousWorkout(for: "Any Exercise")
        
        // Assert - should return empty array instead of crashing
        XCTAssertTrue(previousSets.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    /// Creates a test workout with default or custom parameters
    private func createTestWorkout(
        exerciseName: String = "Bench Press (Dumbbell)",
        sets: [CompletedSet]? = nil
    ) -> WorkoutHistory {
        let defaultSets = [
            CompletedSet(setNumber: 1, kg: "45", reps: "10", elapsedTime: "1:30"),
            CompletedSet(setNumber: 2, kg: "45", reps: "10", elapsedTime: "3:15"),
            CompletedSet(setNumber: 3, kg: "45", reps: "8", elapsedTime: "4:45")
        ]
        
        return WorkoutHistory(
            date: Date(),
            exerciseName: exerciseName,
            sets: sets ?? defaultSets
        )
    }
    
    /// Loads workout history directly from UserDefaults for testing
    private func loadWorkoutHistoryFromDefaults() -> [WorkoutHistory] {
        return dataManager.loadWorkoutHistory()
    }
}

// MARK: - Testable Data Manager

/// Testable version of WorkoutDataManager that allows injection of UserDefaults
class TestableWorkoutDataManager: WorkoutDataManagerProtocol {
    private let testUserDefaults: UserDefaults
    private let workoutHistoryKey = "WorkoutHistory"
    
    init(userDefaults: UserDefaults) {
        self.testUserDefaults = userDefaults
    }
    
    func saveWorkout(_ workout: WorkoutHistory) {
        var history = loadWorkoutHistory()
        history.append(workout)
        
        // Keep only last 10 workouts to prevent unlimited growth
        if history.count > 10 {
            history = Array(history.suffix(10))
        }
        
        if let encoded = try? JSONEncoder().encode(history) {
            testUserDefaults.set(encoded, forKey: workoutHistoryKey)
        }
    }
    
    func loadPreviousWorkout(for exerciseName: String) -> [CompletedSet] {
        let history = loadWorkoutHistory()
        return history.last(where: { $0.exerciseName == exerciseName })?.sets ?? []
    }
    
    func loadWorkoutHistory() -> [WorkoutHistory] {
        guard let data = testUserDefaults.data(forKey: workoutHistoryKey),
              let history = try? JSONDecoder().decode([WorkoutHistory].self, from: data) else {
            return []
        }
        return history
    }
}
