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

## Implementation Phases

The implementation is broken into phases where each phase builds on the previous while keeping the app functional. Phases 1-5 are additive/parallel changes that don't break existing functionality. Phase 6 is cleanup that removes old code once everything new is working.

### Phase 1: Add New Types (Zero Risk)

New code with no dependencies on existing code. Can be added and tested in isolation.

**Step 1: Create `ReviewSchedule.swift`**
- Add new file `Models/ReviewSchedule.swift`
- Implement `ReviewSchedule` enum and `ExpandingIntervalSchedule` struct
- Include `nextReviewDate()` logic and `static let default`
- No existing code touches this yet

**Step 2: Add `ReviewScheduleTests.swift`**
- Create `MindFortTests/ReviewScheduleTests.swift`
- Test `nextReviewDate(lastQuizzed:consecutiveSuccesses:)` with table-driven cases
- Validates interval logic before any integration

**Step 3: Add slot calculation function**
- Add `nextNotificationTime(dueDate:slots:buffer:now:)` to `Helpers/NotificationHelpers.swift`
- Pure function with no side effects or dependencies

**Step 4: Add `NotificationSchedulingTests.swift`**
- Create `MindFortTests/NotificationSchedulingTests.swift`
- Test slot calculation with all edge cases (buffer enforcement, empty slots, etc.)

### Phase 2: Extend Models (Additive, Backward Compatible)

Add new fields to existing models without removing old ones. Existing data continues to load.

**Step 5: Add new fields to `Secret`**
- Add `lastQuizPassed: Bool = false`
- Add `consecutiveSuccesses: Int = 0`
- Make Codable with defaults via `decodeIfPresent` so existing data loads
- Keep `spacedRepetitionCategory` field for now (removed in Phase 6)

**Step 6: Add new fields to `SecretCollection`**
- Add `availableSchedules: [ReviewSchedule]`
- Add `activeScheduleId: UUID?`
- Add `notificationSlots: [DateComponents]?`
- Provide defaults in `init(from decoder:)` for backward compatibility
- Keep `spacedRepetitionCategories` temporarily

**Step 7: Add `@Published` properties to `SecretsViewModel`**
- Add properties mirroring new `SecretCollection` fields
- Update `SecretsDataManager.saveItems()` to include new fields in saved collection
- Update `SecretsDataManager.loadItems()` to populate new properties from loaded collection

### Phase 3: Wire Up Quiz Logic

Connect new fields to quiz completion flow.

**Step 8: Update quiz completion in `Secret.validate()`**
- On successful validation: increment `consecutiveSuccesses`, set `lastQuizPassed = true`
- On failure (if tracked): reset `consecutiveSuccesses = 0`, set `lastQuizPassed = false`
- `lastQuizzed = Date()` already happens

**Step 9: Add `secretsDue` computed property to `SecretsViewModel`**
```swift
var secretsDue: [Secret] {
    guard let scheduleId = activeScheduleId,
          let schedule = availableSchedules.first(where: { $0.id == scheduleId }) else {
        return []
    }
    return secrets.filter { secret in
        guard let dueDate = schedule.nextReviewDate(
            lastQuizzed: secret.lastQuizzed,
            consecutiveSuccesses: secret.consecutiveSuccesses
        ) else { return false }
        return dueDate <= Date()
    }
}
```

### Phase 4: Update Notification System

Implement the new slot-based notification scheduling.

**Step 10: Add new scheduling logic to `SecretsNotificationManager`**
- Implement the TODO at line 105
- Add method that uses `secretsDue` + `nextNotificationTime()` to schedule notifications
- Conditional on `activeScheduleId != nil` so old system continues working if new system not configured

**Step 11: Update `ContentView` scene phase handler**
- Filter `.onChange(of: scenePhase)` to only trigger on `.active`
- Call notification re-evaluation when app becomes active
- Current implementation calls `requestPermission()` on every phase change (inefficient)

### Phase 5: Update UI

Add new UI controls for the new scheduling system.

**Step 12: Create new schedule picker in `SettingsSheet`**
- Add `Picker` for `availableSchedules` (by name)
- Add `DatePicker`s for notification slot times
- Add `Toggle` for notifications enabled (controls `activeScheduleId`)
- Validate slot times against `minimumSlotBuffer`
- Can initially coexist with old controls

**Step 13: Fix `scheduleType` sync issue**
- Current bug: `@AppStorage(MFAStorage.K.scheduleType)` in SettingsSheet is separate from `SecretsViewModel.scheduleType`
- Option A: Remove `@AppStorage` version, use only ViewModel (preferred)
- Option B: Sync `@AppStorage` to ViewModel on change
- This affects the old system but prevents confusion during transition

### Phase 6: Clean Up (Breaking Changes)

Remove deprecated code once new system is fully working.

**Step 14: Remove deprecated `Secret` field**
- Remove `spacedRepetitionCategory: String?`
- Add reset logic in `init(from decoder:)`: if old field detected, reset to defaults

**Step 15: Remove deprecated `SecretCollection` fields**
- Remove `spacedRepetitionCategories: [SpacedRepetitionCategory]`
- Consider removing `regularIntervalNotifications` and `oneTimeNotifications` if fully replaced
- Add reset logic for old data

**Step 16: Delete obsolete files**
- Delete `Models/SpacedRepetitionCategory.swift`
- Delete `Models/ScheduleType.swift`

**Step 17: Remove old UI controls from `SettingsSheet`**
- Remove `RegularIntervalScheduleControls` (lines 18-58)
- Remove `SpacedRepetitionScheduleControls` (lines 61-76)
- Simplify `ScheduleControls` to only use new system
- Remove `@AppStorage(MFAStorage.K.scheduleType)` binding

**Step 18: Remove `SecretsPublisherManager` category tracking**
- Remove `spRepCatCancellables` dictionary
- Remove `addSpacedRepCategoryPublisher()` / `removeSpacedRepCategoryPublisher()` methods
- Remove category subscription setup from `setupPublishers()`

**Step 19: Clean up `Storage.swift`**
- Remove `MFAStorage.K.scheduleType` key definition
- Remove any other obsolete keys

## Implementation Notes

### Recommended Starting Point

Start with **Phase 1** (Steps 1-4) since they have zero risk and validate core algorithms. Then proceed to **Phase 2** (Steps 5-7) which extends models without breaking existing functionality.

### Testing Strategy

- Run existing tests after each step to catch regressions
- New tests in Steps 2 and 4 validate algorithms before integration
- Manual testing of notification flow after Phase 4

### Rollback Safety

- Phases 1-5 are fully reversible (additive changes only)
- Phase 6 is the point of no return for old data format
- Consider tagging a release before Phase 6 for easy rollback
