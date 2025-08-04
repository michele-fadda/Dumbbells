
//
//  MorphingPill.swift
//  DumbBells
//
//  Created by Michele Fadda on 02/08/2025.
//

import SwiftUI



// MARK: - Morphing Pill View
struct MorphingPill: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let pillState: PillState
    
    // Keyboard handlers
    let onKeyTap: (String) -> Void
    let onBackspace: () -> Void
    let onNext: () -> Void
    
    // Timer handlers
    let onFinish: () -> Void
    let onTimerTap: () -> Void
    
    // Rest handlers
    let onRestPick: (Int) -> Void
    let onRestDismiss: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        Group {
            switch pillState {
            case .start:
                startPillView
            case .activeTimer:
                activeTimerPillView
            case .keyboard:
                keyboardView
            case .restPicker:
                restPickerPillView
            case .countdown:
                countdownPillView
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: pillState)
    }
    
    // MARK: - Start Pill View
    private var startPillView: some View {
        Button(action: {
            if viewModel.canStartWorkout {
                viewModel.startWorkout()
            }
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text(startButtonText)
                    .fontWeight(.semibold)
            }
            .foregroundColor(viewModel.canStartWorkout ? .white : .gray)
            .padding()
            .frame(maxWidth: .infinity)
            .background(viewModel.canStartWorkout ? Color.black : Color.gray.opacity(0.3))
            .cornerRadius(32)
        }
        .disabled(!viewModel.canStartWorkout)
        .padding(.horizontal)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    private var startButtonText: String {
        if !viewModel.canStartWorkout {
            if viewModel.currentSetIndex < viewModel.sets.count {
                let currentSet = viewModel.sets[viewModel.currentSetIndex]
                if currentSet.kg.isEmpty || currentSet.reps.isEmpty {
                    return "Enter Kg & Reps"
                } else if currentSet.isCompleted {
                    return "Set Complete"
                }
            }
            return "Start"
        }
        
        if viewModel.currentSetIndex == 0 {
            return "Start"
        } else {
            return "Start Set \(viewModel.currentSetIndex + 1)"
        }
    }
    
    // MARK: - Active Timer Pill View
    private var activeTimerPillView: some View {
        HStack(spacing: 16) {
            Button(action: onFinish) {
                Text("Finish")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .frame(width: 80, height: 40)
                    .background(Color.green)
                    .cornerRadius(20)
            }
            
            Spacer()
            
            Text(viewModel.formattedElapsedTime)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            TimerIconButton(action: onTimerTap)
        }
        .padding()
        .background(Color.black)
        .cornerRadius(32)
        .padding(.horizontal)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    // MARK: - Keyboard View
    private var keyboardView: some View {
        VStack(spacing: 16) {
            ForEach(keyRows, id: \.self) { row in
                keyRowView(row)
            }
            
            HStack {
                Spacer(minLength: 60)
                
                Button(action: onNext) {
                    Text("Next")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(height: 44)
                        .frame(width: 120)
                        .background(Color.white)
                        .cornerRadius(32)
                }
                
                Spacer(minLength: 16)
                
                TimerIconButton(action: onTimerTap)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.black)
        .cornerRadius(32)
        .padding(.horizontal)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
    }
    
    // MARK: - Rest Picker Pill View
    private var restPickerPillView: some View {
        HStack(spacing: 8) {
            ForEach(restOptions, id: \.self) { seconds in
                Button(action: { onRestPick(seconds) }) {
                    Text("\(seconds / 60 > 0 ? "\(seconds / 60) min" : "\(seconds) sec")")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
            }
            
            Spacer(minLength: 8)
            
            DismissIconButton(action: onRestDismiss)
        }
        .padding()
        .background(Color.black)
        .cornerRadius(32)
        .padding(.horizontal)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    // MARK: - Countdown Pill View
    private var countdownPillView: some View {
        HStack(alignment: .center) {
            Text(timeString(from: viewModel.restTimeRemaining))
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .frame(width: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 1)
                )
            
            VStack {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: CGFloat(geometry.size.width) * CGFloat(max(0.01, Double(viewModel.restTimeRemaining) / Double(viewModel.restTimerDuration))), height: 6)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxHeight: .infinity)
            
            Button(action: onSkip) {
                Text("Skip")
                    .foregroundColor(.black)
                    .frame(width: 60, height: 36)
                    .background(Color.white)
                    .cornerRadius(16)
            }
        }
        .frame(height: 56)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black)
        .cornerRadius(32)
        .padding(.horizontal)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    // MARK: - Helper Properties and Methods
    private let keyRows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "<"]
    ]
    
    private let restOptions = [30, 60, 120, 180]
    
    private func keyRowView(_ row: [String]) -> some View {
        HStack(spacing: 12) {
            ForEach(row, id: \.self) { key in
                Button(action: {
                    if key == "<" {
                        onBackspace()
                    } else {
                        onKeyTap(key)
                    }
                }) {
                    Group {
                        if key == "<" {
                            Image(systemName: "chevron.backward")
                        } else {
                            Text(key)
                        }
                    }
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .background(Color.black)
                    .cornerRadius(16)
                }
            }
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Previews

#Preview("Start State") {
    VStack(spacing: 20) {
        Text("Start State")
            .font(.headline)
        
        MorphingPill(
            viewModel: {
                let vm = WorkoutViewModel()
                vm.currentPillState = .start
                return vm
            }(),
            pillState: .start,
            onKeyTap: { _ in },
            onBackspace: { },
            onNext: { },
            onFinish: { },
            onTimerTap: { },
            onRestPick: { _ in },
            onRestDismiss: { },
            onSkip: { }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Active Timer State") {
    VStack(spacing: 20) {
        Text("Active Timer State")
            .font(.headline)
        
        MorphingPill(
            viewModel: {
                let vm = WorkoutViewModel()
                vm.currentPillState = .activeTimer
                vm.elapsedSeconds = 85 // 1:25
                return vm
            }(),
            pillState: .activeTimer,
            onKeyTap: { _ in },
            onBackspace: { },
            onNext: { },
            onFinish: { },
            onTimerTap: { },
            onRestPick: { _ in },
            onRestDismiss: { },
            onSkip: { }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Keyboard State") {
    VStack(spacing: 20) {
        Text("Keyboard State")
            .font(.headline)
        
        MorphingPill(
            viewModel: {
                let vm = WorkoutViewModel()
                vm.currentPillState = .keyboard
                return vm
            }(),
            pillState: .keyboard,
            onKeyTap: { key in print("Key tapped: \(key)") },
            onBackspace: { print("Backspace") },
            onNext: { print("Next") },
            onFinish: { },
            onTimerTap: { print("Timer") },
            onRestPick: { _ in },
            onRestDismiss: { },
            onSkip: { }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Rest Picker State") {
    VStack(spacing: 20) {
        Text("Rest Picker State")
            .font(.headline)
        
        MorphingPill(
            viewModel: {
                let vm = WorkoutViewModel()
                vm.currentPillState = .restPicker
                return vm
            }(),
            pillState: .restPicker,
            onKeyTap: { _ in },
            onBackspace: { },
            onNext: { },
            onFinish: { },
            onTimerTap: { },
            onRestPick: { duration in print("Rest duration: \(duration)s") },
            onRestDismiss: { print("Dismiss rest picker") },
            onSkip: { }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Countdown State") {
    VStack(spacing: 20) {
        Text("Countdown State")
            .font(.headline)
        
        MorphingPill(
            viewModel: {
                let vm = WorkoutViewModel()
                vm.currentPillState = .countdown
                vm.restTimeRemaining = 45
                vm.restTimerDuration = 60
                return vm
            }(),
            pillState: .countdown,
            onKeyTap: { _ in },
            onBackspace: { },
            onNext: { },
            onFinish: { },
            onTimerTap: { },
            onRestPick: { _ in },
            onRestDismiss: { },
            onSkip: { print("Skip rest") }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("All States") {
    ScrollView {
        VStack(spacing: 30) {
            Group {
                Text("Start State")
                    .font(.headline)
                MorphingPill(
                    viewModel: {
                        let vm = WorkoutViewModel()
                        vm.currentPillState = .start
                        return vm
                    }(),
                    pillState: .start,
                    onKeyTap: { _ in }, onBackspace: { }, onNext: { },
                    onFinish: { }, onTimerTap: { }, onRestPick: { _ in },
                    onRestDismiss: { }, onSkip: { }
                )
            }
            
            Group {
                Text("Active Timer State")
                    .font(.headline)
                MorphingPill(
                    viewModel: {
                        let vm = WorkoutViewModel()
                        vm.currentPillState = .activeTimer
                        vm.elapsedSeconds = 125
                        return vm
                    }(),
                    pillState: .activeTimer,
                    onKeyTap: { _ in }, onBackspace: { }, onNext: { },
                    onFinish: { }, onTimerTap: { }, onRestPick: { _ in },
                    onRestDismiss: { }, onSkip: { }
                )
            }
            
            Group {
                Text("Rest Picker State")
                    .font(.headline)
                MorphingPill(
                    viewModel: {
                        let vm = WorkoutViewModel()
                        vm.currentPillState = .restPicker
                        return vm
                    }(),
                    pillState: .restPicker,
                    onKeyTap: { _ in }, onBackspace: { }, onNext: { },
                    onFinish: { }, onTimerTap: { }, onRestPick: { _ in },
                    onRestDismiss: { }, onSkip: { }
                )
            }
            
            Group {
                Text("Countdown State")
                    .font(.headline)
                MorphingPill(
                    viewModel: {
                        let vm = WorkoutViewModel()
                        vm.currentPillState = .countdown
                        vm.restTimeRemaining = 30
                        vm.restTimerDuration = 60
                        return vm
                    }(),
                    pillState: .countdown,
                    onKeyTap: { _ in }, onBackspace: { }, onNext: { },
                    onFinish: { }, onTimerTap: { }, onRestPick: { _ in },
                    onRestDismiss: { }, onSkip: { }
                )
            }
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}
