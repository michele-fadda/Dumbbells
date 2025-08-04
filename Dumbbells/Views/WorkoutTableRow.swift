
//
//  WorkoutTableRow.swift
//  DumbBells
//
//  Created by Michele Fadda on 02/08/2025.
//

//
//  WorkoutTableRow.swift
//  DumbBells
//
//  Enhanced with completion status and non-interactive checkboxes
//

import SwiftUI

struct WorkoutTableRow: View {
    let setNumber: Int
    let previous: String
    @Binding var selectedField: FieldSelection?
    let kg: String
    let reps: String
    let isCompleted: Bool
    let isCurrentSet: Bool
    let onFieldSelected: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(setNumber)")
                .frame(width: 32, height: 32)
                .background(isCurrentSet ? Color.blue.opacity(0.2) : Color(.systemGray5))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCurrentSet ? Color.blue : Color.clear, lineWidth: 2)
                )

            Text(previous)
                .foregroundColor(.gray)
                .frame(width: 70, alignment: .leading)
                .font(.system(size: 12))

            RoundedInputBox(
                text: kg,
                isSelected: selectedField?.set == setNumber && selectedField?.field == "kg",
                isCompleted: isCompleted,
                onTap: {
                    // Only allow editing if not completed
                    if !isCompleted {
                        selectedField = FieldSelection(set: setNumber, field: "kg")
                        onFieldSelected()
                    }
                }
            )
            .frame(width: 70)

            RoundedInputBox(
                text: reps,
                isSelected: selectedField?.set == setNumber && selectedField?.field == "reps",
                isCompleted: isCompleted,
                onTap: {
                    // Only allow editing if not completed
                    if !isCompleted {
                        selectedField = FieldSelection(set: setNumber, field: "reps")
                        onFieldSelected()
                    }
                }
            )
            .frame(width: 60)

            // Non-interactive completion indicator
            CompletionIndicator(isCompleted: isCompleted)
        }
        .opacity(isCompleted ? 0.7 : 1.0) // Dim completed sets
    }
}

struct RoundedInputBox: View {
    var text: String
    var isSelected: Bool
    var isCompleted: Bool
    var onTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .frame(height: 36)
                .onTapGesture(perform: onTap)

            Text(text)
                .foregroundColor(textColor)
                .font(.system(size: 14, weight: .medium))
        }
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return Color.green.opacity(0.2)
        } else if isSelected {
            return Color.black
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var textColor: Color {
        if isCompleted {
            return Color.green
        } else if isSelected {
            return Color.white
        } else {
            return Color.black
        }
    }
}

struct CompletionIndicator: View {
    let isCompleted: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .stroke(isCompleted ? Color.green : Color.gray, lineWidth: 2)
                .background(isCompleted ? Color.green.opacity(0.2) : Color.clear)
                .frame(width: 24, height: 24)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isCompleted)
    }
}

#Preview("Input Box States") {
    VStack(spacing: 16) {
        Text("Input Box States")
            .font(.headline)
        
        HStack(spacing: 12) {
            VStack {
                Text("Normal")
                    .font(.caption)
                RoundedInputBox(
                    text: "45",
                    isSelected: false,
                    isCompleted: false,
                    onTap: { }
                )
            }
            
            VStack {
                Text("Selected")
                    .font(.caption)
                RoundedInputBox(
                    text: "45",
                    isSelected: true,
                    isCompleted: false,
                    onTap: { }
                )
            }
            
            VStack {
                Text("Completed")
                    .font(.caption)
                RoundedInputBox(
                    text: "45",
                    isSelected: false,
                    isCompleted: true,
                    onTap: { }
                )
            }
            
            VStack {
                Text("Empty")
                    .font(.caption)
                RoundedInputBox(
                    text: "",
                    isSelected: false,
                    isCompleted: false,
                    onTap: { }
                )
            }
        }
        .frame(height: 36)
        
        HStack(spacing: 16) {
            VStack {
                Text("Incomplete")
                    .font(.caption)
                CompletionIndicator(isCompleted: false)
            }
            
            VStack {
                Text("Complete")
                    .font(.caption)
                CompletionIndicator(isCompleted: true)
            }
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
