import SwiftUI

struct WorkoutPanel: View {
    @StateObject private var viewModel = WorkoutViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background that captures taps outside keyboard and fields
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if viewModel.selectedField != nil {
                        viewModel.hideKeyboard()
                    }
                }
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bench Press (Dumbbell)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top)

                    HStack(spacing: 8) {
                        Text("Set").frame(width: 32)
                        Text("Previous").frame(width: 70)
                        Text("Kg").frame(width: 70)
                        Text("Reps").frame(width: 60)
                        Text("").frame(width: 24)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    VStack(spacing: 12) {
                        ForEach(viewModel.sets, id: \.setNumber) { set in
                            WorkoutTableRow(
                                setNumber: set.setNumber,
                                previous: viewModel.previousValueFor(set: set.setNumber),
                                selectedField: $viewModel.selectedField,
                                kg: viewModel.valueFor(set: set.setNumber, field: "kg"),
                                reps: viewModel.valueFor(set: set.setNumber, field: "reps"),
                                isCompleted: set.isCompleted,
                                isCurrentSet: viewModel.currentSetIndex == set.setNumber - 1,
                                onFieldSelected: {
                                    viewModel.showKeyboard()
                                }
                            )
                        }
                    }
                    .padding()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
                .onTapGesture {
                    if viewModel.selectedField != nil {
                        viewModel.hideKeyboard()
                    }
                }
                
                Spacer()
            }

            // Unified MorphingPill
            MorphingPill(
                viewModel: viewModel,
                pillState: viewModel.currentPillState,
                onKeyTap: { key in
                    viewModel.updateValue(key)
                },
                onBackspace: {
                    viewModel.deleteLastCharacter()
                },
                onNext: {
                    viewModel.moveToNextField()
                },
                onFinish: {
                    viewModel.stopWorkout()
                },
                onTimerTap: {
                    viewModel.showRestPicker()
                },
                onRestPick: { duration in
                    viewModel.hideRestPicker()
                    viewModel.startRestTimer(duration: duration)
                },
                onRestDismiss: {
                    viewModel.hideRestPicker()
                },
                onSkip: {
                    viewModel.skipRestTimer()
                }
            )
            .padding(.bottom)
        }
        .sheet(isPresented: $viewModel.showCompletionModal, onDismiss: {
            viewModel.startNewWorkout()
        }) {
            WorkoutCompletionModal(
                completedSets: viewModel.getCompletedSetsWithTime(),
                exerciseName: "Bench Press (Dumbbell)",
                onStartNewWorkout: {
                    viewModel.startNewWorkout()
                },
                onDismiss: {
                    viewModel.showCompletionModal = false
                }
            )
        }
    }
}



// MARK: - Previews

#Preview("Empty Workout") {
    WorkoutPanel()
}


