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

## Data Model

### Secret (revised)

```swift
struct Secret {
    let id: UUID
    var name: String
    var value: String
    var lastQuizzed: Date?
    var lastQuizPassed: Bool?
    var consecutiveSuccesses: Int  // Resets to 0 on failure
}
```

Remove: `spacedRepetitionCategory: String?`

### ReviewSchedule (new)

```swift
protocol ReviewSchedule {
    var id: UUID { get }
    var name: String { get }
    func nextReviewDate(lastQuizzed: Date?, consecutiveSuccesses: Int) -> Date?
}
```

### ExpandingIntervalSchedule (new)

```swift
struct ExpandingIntervalSchedule: ReviewSchedule {
    let id: UUID
    var name: String
    let intervals: [Int] = [1, 2, 3, 5, 8, 13, 21, 34] // days

    func nextReviewDate(lastQuizzed: Date?, consecutiveSuccesses: Int) -> Date? {
        guard let last = lastQuizzed else { return Date() }
        let index = min(consecutiveSuccesses, intervals.count - 1)
        return Calendar.current.date(byAdding: .day, value: intervals[index], to: last)
    }
}
```

### ScheduleSettings (in SecretCollection or ViewModel)

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
| `Secret.swift` | Add `lastQuizPassed`, `consecutiveSuccesses`; remove `spacedRepetitionCategory` |
| `SpacedRepetitionCategory.swift` | Delete or repurpose into `ReviewSchedule` protocol |
| New: `ReviewSchedule.swift` | Protocol + `ExpandingIntervalSchedule` implementation |
| `SecretCollection.swift` | Add `availableSchedules`, `activeScheduleId`, `notificationSlots` |
| `SecretsViewModel.swift` | Add `secretsDue` logic, schedule switching |
| `SecretsNotificationManager.swift` | Implement due-check + slot-based notification scheduling |
| `RedoubtApp.swift` or lifecycle | Trigger notification re-evaluation on launch/resume |
| Settings UI | Allow user to pick active schedule, configure time slots |

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
