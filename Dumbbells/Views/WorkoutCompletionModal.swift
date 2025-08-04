//
//  WorkoutCompletionModal.swift
//  DumbBells
//
//  Created by Michele Fadda on 03/08/2025.
//

import SwiftUI

struct WorkoutCompletionModal: View {
    let completedSets: [CompletedSet]
    let exerciseName: String
    let onStartNewWorkout: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Workout Summary Card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(exerciseName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                }
                
                Divider()
                
                // Sets Summary
                ForEach(completedSets, id: \.setNumber) { set in
                    HStack {
                        Text("\(set.setNumber)")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 24, height: 24)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        Text("\(set.kg)kg x \(set.reps) - \(set.elapsedTime)")
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                       
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onTapGesture {
            dismiss()
        }
    }
}

#Preview {
    WorkoutCompletionModal(
        completedSets: [
            CompletedSet(setNumber: 1, kg: "45", reps: "10", elapsedTime: "1:30"),
            CompletedSet(setNumber: 2, kg: "45", reps: "10", elapsedTime: "3:15"),
            CompletedSet(setNumber: 3, kg: "45", reps: "8", elapsedTime: "4:45")
        ],
        exerciseName: "Bench Press (Dumbbell)",
        onStartNewWorkout: {},
        onDismiss: {}
    )
}

