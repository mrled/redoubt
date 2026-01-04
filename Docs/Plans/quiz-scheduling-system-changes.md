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
var minimumSlotBuffer: TimeInterval      // e.g., 6 hours (21600 seconds)
```

## Notification Slots

Slots are a **generic delivery mechanism** independent of schedule logic.

**Concept:**
- Slots define "good times to notify" (e.g., 9am, 6pm)
- Schedule determines when a secret is "due"
- Once due, notify at the **next available slot** that respects the buffer

**Buffer rule:** Minimum time between notification opportunities (e.g., 6 hours) to prevent clustering like 11:30am → 12:30pm.

**Finding next notification time:**
```swift
func nextNotificationTime(dueDate: Date, slots: [DateComponents], buffer: TimeInterval, now: Date = Date()) -> Date? {
    // Find the earliest slot that is:
    // 1. On or after dueDate
    // 2. At least `buffer` from now (to prevent immediate re-fire)
    // 3. In the future
}
```

**Examples:**
- Daily schedule, slots = [9am]: notify every day at 9am
- Expanding interval, slots = [9am, 6pm]: once due, notify at next 9am or 6pm
- If user ignores 9am, re-notify at 6pm (6hr buffer satisfied)
- If slots = [9am, 10am], buffer = 6hr: effectively only 9am fires (10am skipped due to buffer)

## Notification Logic

```
On app launch / scene becomes active / after quiz completion:
  1. Check if any secret is due (using active schedule)
  2. If due → schedule notification for next valid slot (respecting buffer)
  3. If not due → cancel pending notifications, optionally schedule for future due date

On notification fire:
  - Generic message: "Time to practice"
  - If user ignores, next app activation will re-check and re-schedule if still due
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
