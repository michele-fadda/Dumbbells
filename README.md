# Dumbbells - Workout Logging App

A SwiftUI workout logging application that implements a minimalist interface with a morphing pill interface for tracking dumbbell exercises.

## Overview

This app allows users to log workout sets with weight (kg) and repetitions, featuring a dynamic pill-shaped UI component that transforms between different states during the workout flow.

Assumptions: max 3 series, can be less than that. User can have a rest any time (during data input or while timer is active).
User needs to select rest time duration each time.
Setting a rest timer at the end of all series is deemed not useful.

I would have normally discussed these issues with the designer team or a product owner. For lack of those roles, I decided to operate as a product owner and took these design decisions myself.
Also driven by tradeoff needs: app should not be too complicated than it is needed, and works well.


## Key Features

- **Morphing Pill Interface**: Fluid animations between start, timer, keyboard, rest picker, and countdown states
- **Custom Number Pad**: Native number input with decimal support
- **Rest Timer**: Configurable rest periods with visual countdown
- **Workout Tracking**: Logs completion times and displays previous workout data
- **Data Persistence**: Saves workout history using UserDefaults
- **Set Completion Status**: Visual indicators for completed sets

## Architecture

The app follows MVVM architecture with clear separation of concerns:

- **Views**: SwiftUI components with declarative UI
- **ViewModel**: `WorkoutViewModel` manages state and business logic, in the future, a State Machine could be separated from the ViewModel
- **Models**: Data structures for workout sets and history
- **Data Layer**: Persistence through `WorkoutDataManager` - at the moment the app does not use a database, this would ne an enhancement for when more exercise categories are added

### Key Components

- `WorkoutPanel`: Main container view
- `MorphingPill`: Dynamic pill component with multiple states 
- `WorkoutTableRow`: Individual set input rows
- `WorkoutViewModel`: Central state management
- `WorkoutDataManager`: Data persistence layer

## Design Decisions & Changes

### Flow Modifications

The implementation differs from the original design in several ways:

1. **Set Validation**: Users must enter both kg and reps before starting a set (the behaviour was specified as "start button" is shown at the beginning, no visual cue on which series we are on, no data validation)
2. **Progressive Flow**: Sets must be completed in order (1 → 2 → 3, user can specify just one or two rows, more than 3 series would be strange and very boring in a gym, at the moment only 3 series are handled)
3. **Field Selection**: Explicit field selection with visual feedback
4. **Completion Tracking**: Clear visual indicators for completed sets, the tick boxes that are not described in the requirements are used as tick boxes for completion
5. **Rest timer**: The user can decide to have a rest either when inputting exercise data, or when the active Finish/Timer is shown. The elapsed time for each series is shown at the end, in the final modal pane.

### Technical Choices

**State Management**
- Used `@ObservedObject` for ViewModel binding
- Centralised state in `WorkoutViewModel` rather than distributed across views (easier to control, even without a separate state machine, and in general cleaner as an approach)
- Explicit pill state enum instead of computed states

**Animation Approach**
- Spring animations for smooth transitions
- Asymmetric transitions for different pill states
- Maintained consistent timing across state changes

**Data Input**
- Custom keyboard instead of native input to match design, that implied simulating the "input field behaviour" 
- 3-character limit for practical weight/rep values (can be changed if necessary, most dumbbells are in Kg, the half Kg ones are quite uncommon.
- Decimal point support for precise weight entry (and normally those are low value weights in practice: e.g. 2.5 Kg, You won't normally find 22.5 Kg dumbbells, at least to my limited experience with gyms

## Tradeoffs

### Design vs Functionality

**Simplified Start Logic**
- **Original**: Start button always available, the user needs to hide the keyboard if not shown.
- **Current**: Validation required before starting, the start button now shows which series we are doing.
- **Reason**: Prevents empty sets of exercises, that would not make any sense and would create problems (what was the last series in terms of reps and weight?)


**Field Selection**
- **Added**: Explicit field selection with visual feedback
- **Reason**: Clearer user intent, better accessibility

**Set Progression**
- **Added**: Sequential set completion
- **Reason**: More logical workout flow, prevents confusion, user see at what point of the exercise they currently are

### Technical Compromises

**Animation Complexity**
- **Simplified**: Some micro-animations omitted for stability, just used spring. No further attempts at fancy animations
- **Focus**: Prioritised core morphing animations over decorative ones

**Error Handling**
- **Basic**: Simple validation without detailed error messages, besides not prescribed, there was no style guidance for errors in the designs.
- **Reason**: Maintains clean UI, validation is straightforward and easily understandable.

**Data Persistence**
- **UserDefaults**: Simple but not scalable, however, proper layering keeps it distinct and easily replaced if/when needed
- **Alternative**: Core Data would be better for complex querying and further development.
- **Reason**: Sufficient for MVP, faster implementation, satisfies requirements in a simple way

## Testing

The project includes unit tests:

- **WorkoutLogicTests**: Core workout flow and validation
- **WorkoutDataManagerTests**: Data persistence functionality
- **Coverage**: State transitions, input validation, data integrity

### Test Structure
```
WorkoutLogicTests.swift
├── Initial State Tests
├── Start Validation Tests
├── Workout Flow Tests
├── Input Logic Tests
├── Field Navigation Tests
├── Pill State Tests
└── Rest Timer Tests

WorkoutDataManagerTests.swift
├── Save Workout Tests
├── Load Previous Workout Tests
└── Data Integrity Tests
```

## File Structure

```
Dumbbells/
├── Views/
│   ├── WorkoutPanel.swift           # Main container
│   ├── MorphingPill.swift          # Dynamic pill component
│   ├── WorkoutTableRow.swift       # Set input rows
│   ├── WorkoutCompletionModal.swift # Summary modal
│   └── Components/
│       ├── TimerIconButton.swift
│       └── RestPickerPillView.swift
├── ViewModels/
│   └── WorkoutViewModel.swift       # State management
├── Models/
│   ├── WorkoutSet.swift            # Set data structure
│   ├── WorkoutHistory.swift        # Persistence models
│   └── FieldSelection.swift        # Input selection
├── Data/
│   └── WorkoutDataManager.swift    # Persistence layer
└── Tests/
    ├── WorkoutLogicTests.swift
    └── WorkoutDataManagerTests.swift
```

## Key Implementation Details

### Pill State Management

The morphing pill cycles through five states:
1. **Start**: Initial state, validates input before allowing start
2. **Active Timer**: Shows elapsed time with finish button
3. **Keyboard**: Custom number pad for input
4. **Rest Picker**: Time selection buttons
5. **Countdown**: Visual progress bar with skip option

### Input Handling

- **Field Selection**: Tap to select kg/reps fields
- **Custom Keyboard**: Numbers 0-9, decimal point, backspace
- **Validation**: 3-character limit, numeric input only
- **Navigation**: "Next" button cycles through fields

### Data Flow

1. User enters kg/reps → Validation → Start enabled
2. Start workout → Timer begins → Active state
3. Finish set → Mark complete → Move to next set or summary
4. Rest picker → Timer countdown → Return to previous state
5. End of all series -> completion screen -> restart

## Future Improvements

### Features
- Multiple exercise support
- Workout templates
- Progress charts
- Export functionality

### Technical
- Core Data or Swift Data for persistence
- Haptic feedback
- Better error handling
- Accessibility

### UI/UX
- Dark mode support
- iPad layout
- Voice input
- Apple Watch companion

## Development Notes

The app prioritises clear user flow over feature complexity. The morphing pill is the central design element, with all other components supporting this interaction pattern.

Test coverage focuses on business logic and data integrity rather than UI testing, ensuring reliable core functionality while maintaining development speed.

The codebase tries to maximise readability and maintainability, with clear separation between UI, business logic, and data layers.
