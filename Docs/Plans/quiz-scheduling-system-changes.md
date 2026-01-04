# Revised Notification & Scheduling System Plan

## Goals

1. Track when secrets are due for review (independent of notifications)
2. Retry notifications at reasonable time slots until user completes review
3. Decouple secrets from scheduling logic to allow future flexibility

## Design Decisions

- **One active schedule at a time**, applies to all secrets
- **Schedules define logic**, not secret assignments
- **Notifications are generic** ("time to practice"), not per-secret
- **Simple expanding intervals** (Fibonacci-like), not complex SR algorithms
- **Failure resets progress** to the beginning
- **Start fresh**: No data migration - existing secrets/settings will be cleared (app is in alpha)

## Data Model

### Secret (revised)

```swift
class Secret {
    let id: UUID
    var name: String
    var digest: String
    var digestType: SupportedDigestType
    var lastQuizzed: Date?
    var lastQuizPassed: Bool = false      // Default: false (never passed)
    var consecutiveSuccesses: Int = 0     // Default: 0, resets on failure
}
```

Remove: `spacedRepetitionCategory: String?`

### ReviewSchedule (enum with associated values - Codable friendly)

```swift
enum ReviewSchedule: Codable, Identifiable {
    case expanding(ExpandingIntervalSchedule)
    // Future: case custom(CustomSchedule)

    var id: UUID {
        switch self {
        case .expanding(let schedule): return schedule.id
        }
    }

    var name: String {
        switch self {
        case .expanding(let schedule): return schedule.name
        }
    }

    func nextReviewDate(lastQuizzed: Date?, consecutiveSuccesses: Int) -> Date? {
        switch self {
        case .expanding(let schedule):
            return schedule.nextReviewDate(lastQuizzed: lastQuizzed, consecutiveSuccesses: consecutiveSuccesses)
        }
    }
}
```

### ExpandingIntervalSchedule

```swift
struct ExpandingIntervalSchedule: Codable {
    let id: UUID
    var name: String
    let intervals: [Int]  // days, e.g. [1, 2, 3, 5, 8, 13, 21, 34]

    func nextReviewDate(lastQuizzed: Date?, consecutiveSuccesses: Int) -> Date? {
        guard let last = lastQuizzed else { return Date() }
        let index = min(consecutiveSuccesses, intervals.count - 1)
        return Calendar.current.date(byAdding: .day, value: intervals[index], to: last)
    }

    static let `default` = ExpandingIntervalSchedule(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Expanding Intervals",
        intervals: [1, 2, 3, 5, 8, 13, 21, 34]
    )
}
```

### ScheduleSettings (in SecretCollection)

```swift
var availableSchedules: [ReviewSchedule]
var activeScheduleId: UUID?
var notificationSlots: [DateComponents]  // e.g., 9am, 6pm
```

## Notification Logic

```
On app launch / after quiz completion:
  1. Check if any secret is due (using active schedule)
  2. If due → ensure notification scheduled for next time slot
  3. If not due → cancel pending notifications

On notification fire:
  - Generic message: "Time to practice"
  - If user ignores, next slot will re-check and re-notify if still due
```

## Files to Change

| File | Changes |
|------|---------|
| `Models/Secret.swift` | Add `lastQuizPassed`, `consecutiveSuccesses`; remove `spacedRepetitionCategory` |
| `Models/SpacedRepetitionCategory.swift` | **Delete** |
| `Models/ScheduleType.swift` | **Delete** (replaced by ReviewSchedule) |
| **New:** `Models/ReviewSchedule.swift` | Enum + `ExpandingIntervalSchedule` struct |
| `Models/SecretCollection.swift` | Add `availableSchedules`, `activeScheduleId`, `notificationSlots`; remove `spacedRepetitionCategories` |
| `ViewModels/SecretsViewModel.swift` | Add `secretsDue` computed property, schedule switching |
| `Managers/SecretsNotificationManager.swift` | Implement due-check + slot-based notification scheduling |
| `Views/Screens/ContentView.swift:18` | Add notification re-evaluation in existing `.onChange(of: scenePhase)` |
| `Views/Screens/SecretListViewSheets/SettingsSheet.swift` | Update `ScheduleControls` (~line 79) and replace `SpacedRepetitionScheduleControls` (~line 61) with new schedule picker |
| `Storage/Storage.swift` | Remove `scheduleType` key if stored there |

## Quiz Flow Update

```
User completes quiz:
  If passed:
    secret.consecutiveSuccesses += 1
    secret.lastQuizPassed = true
  If failed:
    secret.consecutiveSuccesses = 0
    secret.lastQuizPassed = false
  secret.lastQuizzed = Date()

  → Re-evaluate notifications
```
