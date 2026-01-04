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
- **Start fresh**: No explicit migration - if app reads data missing required fields, reset to defaults (app is in alpha)
- **All secrets enrolled**: No per-secret opt-in; all secrets participate in the active schedule
- **No schedule = no notifications**: If `activeScheduleId` is nil, no notifications are scheduled

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

    // Notification configuration (schedule provides defaults, user can customize)
    let defaultSlots: [DateComponents]    // e.g., [9am, 6pm]
    let minimumSlotBuffer: TimeInterval   // e.g., 6 hours (21600 seconds)

    func nextReviewDate(lastQuizzed: Date?, consecutiveSuccesses: Int) -> Date? {
        guard let last = lastQuizzed else { return Date() }
        let index = min(consecutiveSuccesses, intervals.count - 1)
        return Calendar.current.date(byAdding: .day, value: intervals[index], to: last)
    }

    static let `default` = ExpandingIntervalSchedule(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Expanding Intervals",
        intervals: [1, 2, 3, 5, 8, 13, 21, 34],
        defaultSlots: [
            DateComponents(hour: 9, minute: 0),   // 9:00 AM
            DateComponents(hour: 18, minute: 0)   // 6:00 PM
        ],
        minimumSlotBuffer: 6 * 60 * 60  // 6 hours
    )
}
```

### ScheduleSettings (in SecretCollection)

```swift
var availableSchedules: [ReviewSchedule]
var activeScheduleId: UUID?              // nil = notifications disabled
var notificationSlots: [DateComponents]? // User-customized slots; nil = use schedule defaults
```

**Slot customization rules:**
- Schedule provides `defaultSlots` and `minimumSlotBuffer`
- User can override slot times but must maintain at least `minimumSlotBuffer` between slots
- If user sets slots closer than buffer allows, UI should prevent/warn

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

    guard !slots.isEmpty else { return nil }

    let calendar = Calendar.current
    let earliestAllowed = max(dueDate, now.addingTimeInterval(buffer))

    // Generate candidate slot times for today and tomorrow (covers all cases)
    var candidates: [Date] = []
    for dayOffset in 0...1 {
        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: earliestAllowed) else { continue }
        for slot in slots {
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = slot.hour
            components.minute = slot.minute
            components.second = 0
            if let candidate = calendar.date(from: components) {
                candidates.append(candidate)
            }
        }
    }

    // Return the earliest candidate that meets all criteria
    return candidates
        .filter { $0 >= earliestAllowed }
        .sorted()
        .first
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

## UI Changes

### Settings Sheet (`SettingsSheet.swift`)

Replace existing schedule controls with:

```
┌─────────────────────────────────────────┐
│ Schedule                                │
│ ┌─────────────────────────────────────┐ │
│ │ Expanding Intervals              ▼  │ │  ← Picker for available schedules
│ └─────────────────────────────────────┘ │
│                                         │
│ Notification Times                      │
│ ┌─────────────────────────────────────┐ │
│ │ Morning    [9:00 AM]                │ │  ← Time pickers
│ │ Evening    [6:00 PM]                │ │
│ └─────────────────────────────────────┘ │
│ ⓘ Times must be at least 6 hours apart │  ← Dynamic based on buffer
│                                         │
│ [ ] Notifications enabled               │  ← Toggle; off = activeScheduleId nil
└─────────────────────────────────────────┘
```

**Behavior:**
- Schedule picker shows `availableSchedules` by name
- Changing schedule resets notification slots to that schedule's defaults
- Time pickers validate against `minimumSlotBuffer`
- Notifications toggle controls whether `activeScheduleId` is set or nil

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

## Data Reset on Load

When `SecretCollection` is decoded and required fields are missing:

```swift
// In SecretCollection init(from decoder:)
// If decoding fails for new fields or old fields exist that shouldn't:
// - Clear secrets array
// - Reset to default schedule settings
// - Log that data was reset due to schema change
```

**What triggers reset:**
- Missing `consecutiveSuccesses` or `lastQuizPassed` on any Secret
- Missing `availableSchedules` on SecretCollection
- Presence of deprecated `spacedRepetitionCategory` field

**User experience:** On first launch after update, user sees empty secrets list and default schedule. No migration prompt needed (alpha app).

## Tests

Focus on algorithm correctness with minimal, high-value tests.

### NotificationSchedulingTests

Test `nextNotificationTime(dueDate:slots:buffer:now:)`:

| Case | now | dueDate | slots | buffer | expected |
|------|-----|---------|-------|--------|----------|
| Due in past, before first slot | 7am | yesterday | [9am, 6pm] | 6h | 9am today |
| Due in past, between slots | 2pm | yesterday | [9am, 6pm] | 6h | 6pm today |
| Due in past, after last slot | 10pm | yesterday | [9am, 6pm] | 6h | 9am tomorrow |
| Due in future | 7am | tomorrow 8am | [9am, 6pm] | 6h | 9am tomorrow |
| Buffer enforcement | 9:30am | yesterday | [9am, 6pm] | 6h | 6pm today (9am too close) |
| Empty slots | 9am | yesterday | [] | 6h | nil |

### ReviewScheduleTests

Test `ExpandingIntervalSchedule.nextReviewDate(lastQuizzed:consecutiveSuccesses:)`:

| Case | lastQuizzed | consecutiveSuccesses | intervals | expected |
|------|-------------|---------------------|-----------|----------|
| Never quizzed | nil | 0 | [1,2,3,5,8] | now |
| After first success | today | 0 | [1,2,3,5,8] | today + 1 day |
| After 3 successes | today | 3 | [1,2,3,5,8] | today + 5 days |
| Beyond interval count | today | 10 | [1,2,3,5,8] | today + 8 days (clamped) |

### Files

| File | Contents |
|------|----------|
| **New:** `MindFortTests/NotificationSchedulingTests.swift` | `nextNotificationTime` tests |
| **New:** `MindFortTests/ReviewScheduleTests.swift` | `nextReviewDate` tests |
