# Current Notification Implementation

This document describes how notifications currently work in MindFort as of January 2026.

## Architecture Overview

The notification system is built on **spaced repetition scheduling** with iOS UserNotifications framework. It consists of:

- **Three-layer architecture**: Low-level iOS APIs, mid-level managers, and high-level scheduling logic
- **Legacy system**: Regular interval and one-time notifications (deprecated but retained for backward compatibility)
- **New system**: Schedule-based notifications with expandable intervals and customizable time slots

### Key Design Principle
The system prioritizes **user control** and **permission awareness** - notifications are only scheduled if the user has explicitly granted permission, and the app checks authorization status before attempting registration.

## Core Components

### 1. NotificationManager (Low-level APIs)
**File**: `Redoubt/Managers/NotificationManager.swift`

Singleton wrapper around iOS `UNUserNotificationCenter` API.

**Key Methods**:
- `registerNotification(title, body, identifier, trigger)` - Registers a notification with UNNotificationRequest
- `removeNotifications(pending, delivered)` - Clears pending/delivered notifications
- `listPendingNotifications()` - Queries all scheduled notifications for debugging
- `getAuthorizationStatus()` - Checks current permission status
- `canRequestPermissionDirectly()` - Returns true only if status == .notDetermined
- `requestPermission()` - Shows system permission prompt (only when notDetermined)

### 2. SecretsNotificationManager (Mid-level Orchestration)
**File**: `Redoubt/Managers/SecretsNotificationManager.swift`

Coordinates notification scheduling for quiz reminders based on review schedules.

**Core Method - `reregisterAllNotifications()`**:
```
1. Check authorization status
2. If authorized:
   a. Remove all existing notifications
   b. Re-add all legacy notifications (regular intervals + one-time)
   c. Call scheduleBasedOnActiveSchedule() for new system
3. If not authorized:
   └─ Log warning and skip registration
```

**Schedule-Based Notification Scheduling**:
```swift
scheduleBasedOnActiveSchedule()
  ├─ Checks if activeScheduleId exists
  ├─ Gets current ReviewSchedule and notification slots
  ├─ Finds earliest due date across all secrets
  ├─ Calculates next notification time using buffer enforcement
  └─ Registers single notification at that time with "ScheduleBased-" prefix
```

**Subscription Setup**:
- Listens to `viewModel.$regularIntervalNotifications` changes → reregister
- Listens to `viewModel.$oneTimeNotifications` changes → reregister

### 3. Notification Helpers
**File**: `Redoubt/Helpers/NotificationHelpers.swift`

**`addQuizNotification(components, prefix, repeats)`**:
- Creates notification content with title "Type the magic words"
- Sets body "Time to perform a passphrase ritual 🙏"
- Sets userInfo[notificationAction]: "startQuiz"
- Registers via NotificationManager

**`nextNotificationTime(dueDate, slots, buffer, lastNotificationTime?, now)`**:
Smart scheduling logic that returns the next appropriate notification time or nil.

Algorithm:
1. Guard: Return nil if slots are empty
2. Calculate earliest allowed time:
   `earliestAllowed = max(dueDate, lastNotificationTime + buffer, now)`
3. Generate candidate times for today and tomorrow for each slot
4. Filter candidates to keep only those >= earliestAllowed
5. Return earliest candidate or nil

### 4. Review Schedule System
**File**: `Redoubt/Models/ReviewSchedule.swift`

**ExpandingIntervalSchedule** defines scheduling rules:
- `id`: UUID - Immutable identifier
- `name`: String - Display name
- `intervals`: [Int] - Days between reviews: [1, 2, 3, 5, 8, 13, 21, 34]
- `defaultSlots`: [DateComponents] - Notification times (e.g., [9am, 6pm])
- `minimumSlotBuffer`: TimeInterval - Min seconds between slots (e.g., 6 hours)
- `slotLabels`: [String] - Friendly names (e.g., ["Morning", "Evening"])

**Pre-configured Schedules**:
1. **Default (2x daily)**: Slots at 9:00 AM, 6:00 PM with 6-hour buffer
2. **Once Daily**: Single slot at 9:00 AM with no buffer

### 5. Permission Handling
**File**: `Redoubt/Views/Components/PermissionButton.swift`

**Permission Flow**:
1. App checks status on `UIApplication.didBecomeActiveNotification`
2. If `.notDetermined`, user can tap button to see system prompt
3. If `.denied`, button directs to Settings app
4. If `.authorized`, button is disabled and shows checkmark
5. Once authorized, notifications can be registered via `SecretsNotificationManager`

### 6. Notification Reception & Handling
**File**: `Redoubt/Delegates/NotificationDelegate.swift`

**`willPresent()`** - When app is in foreground:
- Shows banner, plays sound, updates badge even though app is active

**`didReceive()`** - When user taps notification:
1. Extract userInfo from notification request
2. Check if app is in demo mode (if yes, ignore)
3. Extract action from userInfo
4. Pass to NotificationActionHandler

**File**: `Redoubt/Observables/NotificationActionHandler.swift`

Singleton observable that manages navigation from notifications:
- `@Published var openAction: OpenAction?`
  - `.home` → Open main app view
  - `.startQuiz` → Navigate directly to quiz view

## Notification Content

**Title**: "Type the magic words"
**Body**: "Time to perform a passphrase ritual 🙏"
**Sound**: Default notification sound
**Badge**: Incremented
**User Info**:
- `notificationAction`: "startQuiz"

**Presentation Options** (when app is in foreground):
- `.banner` → Shows as banner at top of screen
- `.sound` → Plays notification sound
- `.badge` → Updates app icon badge

**Notification Identifiers**:
- Legacy: `"RegularIntervals-YYYY-MM-DD-HH-MM-SS"` (repeating)
- Legacy: `"OneTime-YYYY-MM-DD-HH-MM-SS"` (single)
- New System: `"ScheduleBased-YYYY-MM-DD-HH-MM-SS"` (single from schedule)

## Settings & UI

### NewScheduleControls
**File**: `Redoubt/Views/Components/Settings/NewScheduleControls.swift`

Settings UI featuring:
- Notifications toggle
- Schedule picker dropdown
- Notification slots editor (when enabled)
- Permission prompt (if not authorized)

### NotificationSlotsEditor
**File**: `Redoubt/Views/Components/Settings/NotificationSlotsEditor.swift`

Time slot picker with:
- One DatePicker per notification slot
- Labels for each slot (e.g., "Morning", "Evening")
- Enforces minimum buffer between slots
- Shows buffer requirement in UI

## Data Storage

**File**: `Redoubt/Models/SecretCollection.swift`

```swift
struct SecretCollection: Codable {
    // Legacy notification system (deprecated)
    let regularIntervalNotifications: [DateComponents]
    let oneTimeNotifications: [DateComponents]

    // New schedule-based system
    let availableSchedules: [ReviewSchedule]      // [Default, OnceDaily]
    let activeScheduleId: UUID?                   // nil = notifications disabled
    let notificationSlots: [DateComponents]?      // nil = use schedule defaults
}
```

Stored in Application Support directory (excluded from device backups):
- `SecretsUser.plist` - Production secrets + notification settings
- `SecretsDemo.plist` - Demo mode secrets + settings

## App Lifecycle Integration

**File**: `Redoubt/RedoubtApp.swift`

App startup:
1. Sets notification delegate
2. Initializes in demo or production mode
3. Creates SecretsViewModel with appropriate data loader

**File**: `Redoubt/Views/Screens/ContentView.swift`

Runtime lifecycle:
```swift
.onChange(of: scenePhase) { newScenePhase in
    if newScenePhase == .active {
        // App came to foreground
        1. Check authorization status
        2. Update notificationsAllowed flag
        3. If authorized:
           └─ Call reregisterAllNotifications()
           └─ Re-evaluates all due secrets
           └─ Updates notification schedule
    }
}
```

## Trigger Points for Re-registration

1. **App becomes active** (from background/suspend)
   - ContentView checks authorization status
   - Reregisters notifications if authorized

2. **Settings change**
   - Toggle notifications ON/OFF
   - Change schedule (2x daily ↔ 1x daily)
   - Modify time slots
   - Subscription handlers trigger `reregisterAllNotifications()`

3. **Data changes**
   - Add new secret
   - Delete secret
   - Quiz secret (updates lastQuizzed, consecutiveSuccesses)
   - Secret state changes trigger data save
   - Data save triggers re-registration

4. **Developer actions** (DevNotifications screen)
   - Manual "Refresh Notifications" button
   - Add test notifications
   - Delete all notifications

## Complete Notification Lifecycle Flow

```
APP LAUNCH
    ↓
[AppDelegate] Sets NotificationDelegate
    ↓
[ContentView] Checks permission status on appear
    ↓
[SecretsViewModel] Initializes managers

USER ENABLES NOTIFICATIONS
    ↓
[PermissionButton] Shows system prompt
    ↓
[User] Grants permission
    ↓
[SecretsNotificationManager] Calls reregisterAllNotifications()
    └─ scheduleBasedOnActiveSchedule()
        ├─ Gets active schedule
        ├─ Finds earliest due secret
        ├─ Calculates next notification time
        └─ Registers with iOS

NOTIFICATION TIME ARRIVES
    ↓
[iOS] Delivers notification

USER TAPS NOTIFICATION
    ↓
[NotificationDelegate] Extracts action
    ↓
[NotificationActionHandler] Sets openAction = .startQuiz
    ↓
[ContentView] Navigates to quiz view

QUIZ COMPLETED
    ↓
[Secret] Updates lastQuizzed, consecutiveSuccesses
    ↓
[DataManager] Saves to plist
    ↓
[SecretsNotificationManager] Reregisters
    └─ Recalculates schedule with updated due dates
```

## Testing

**File**: `RedoubtTests/NotificationSchedulingTests.swift`

Comprehensive test coverage for `nextNotificationTime()` including:
- Past due scenarios
- Future due scenarios
- Buffer enforcement
- Edge cases (empty slots, single slot, multiple slots)

## Debugging

**File**: `Redoubt/Observables/NotificationList.swift`
**File**: `Redoubt/Views/Screens/SecretListViewSheets/DevNotifications.swift`

DevNotifications screen features:
- View pending notifications from iOS Notification Center
- View saved notification settings from ViewModel
- Trigger test notifications
- Delete all notifications
- Refresh list to see current state

## Key Design Decisions

1. **Authorization-First**: Never attempts notification registration without checking permission status
2. **Permission Awareness**: Differentiates between .notDetermined (can prompt) and .denied (must use Settings)
3. **Backward Compatibility**: Retains legacy notification fields in storage for old data
4. **Smart Re-registration**: Only reregisters on authorization change or settings modification
5. **Buffer Enforcement**: Prevents notification spam with configurable minimum intervals
6. **Slot-Based Scheduling**: Uses time slots + buffers instead of fixed intervals
7. **Lifecycle Hooks**: Reregisters when app returns from background to handle due secrets
8. **Demo Mode Isolation**: Notifications disabled in demo mode to avoid confusion
9. **Separate Identifiers**: Uses prefixes for different notification types
10. **Testability**: nextNotificationTime() is a pure function with injectable `now` parameter

## Recent Changes (January 2026)

The notification system was refactored to support the new schedule-based approach:

- **Added**: ReviewSchedule enum and ExpandingIntervalSchedule struct
- **Added**: Schedule-based notification scheduling via scheduleBasedOnActiveSchedule()
- **Maintained**: Backward compatibility with legacy regular/one-time notifications
- **Enhanced**: NotificationSlotsEditor for customizing notification times
- **Enhanced**: NewScheduleControls for schedule selection
- **Improved**: nextNotificationTime() algorithm for smarter slot selection

---

# Planned Improvements

## Current Limitations

1. **Just-in-time scheduling**: Only schedules the next immediate notification, not a full schedule
2. **No notification tracking**: Can't reliably cancel or manage specific notifications
3. **Missing redundancy**: If device is off or in focus mode, notifications are simply missed
4. **Inconsistent naming**: Notification identifiers lack clear categorization
5. **No badge support**: Users can't see at-a-glance when quizzes are due
6. **Time zone issues**: No handling for DST or time zone changes

## Proposed Architecture

### 1. Notification Categorization

**Goal**: Clear, consistent notification naming

**Changes**:
- Prefix all notification identifiers by type:
  - `dev.*` - Developer test notifications (from DevNotifications screen)
  - `quiz.*` - Quiz reminder notifications
- Enables selective cancellation and filtering by type

### 2. Persistent Notification Schedule Model

**Goal**: Maintain a persistent record of what notifications should exist

**New Model** - `NotificationScheduleModel`:
- Stores upcoming quiz due dates/times (next 30)
- Tracks which notifications have been issued to iOS
- Persists in SecretCollection (saved to plist)
- Single source of truth for notification state

**Benefits**:
- App can reconcile iOS pending notifications with the model
- Enables reliable cancellation of specific notifications
- Survives app restarts

### 3. Pre-scheduling Multiple Notifications

**Goal**: Schedule next ~30 notifications in advance

**Changes**:
- Calculate next 30 upcoming notification times from schedule
- Register all with iOS at once
- Update iOS limit: Consider 64 notification limit per app
- Strategy: Schedule primary + backup notifications (30 primary + 30 backup = 60 total)

**Benefits**:
- More reliable delivery
- Better user experience (consistent schedule visible in iOS)
- Reduces "just woke up the app" re-registration churn

### 4. Unified Re-issuing Strategy

**Goal**: Consistent notification refresh logic

**Trigger Points**:
- **Model changes**: Schedule modified, secret added/deleted/quizzed
- **App launch/foreground**: Reconcile with iOS state
- **Time zone/DST changes**: Re-calculate all times

**Process**:
1. Cancel all `quiz.*` notifications in iOS
2. Re-generate schedule from model (next 30 events)
3. Issue all notifications to iOS
4. Update model with issued notification IDs

### 5. Backup Reminders

**Goal**: Increase reliability when primary notification is missed

**Strategy**:
- For each quiz due event at time T, schedule:
  - **Primary**: `quiz.primary.<event-id>` at time T
  - **Backup**: `quiz.backup.<event-id>` at time T + 1 hour
- Track both in model with linkage
- On app launch/quiz completion:
  - Check if quiz was completed
  - If yes: Cancel corresponding backup notification
  - If no: Leave backup notification scheduled

**Benefits**:
- Handles device off, focus mode, DND scenarios
- User gets reminded even if primary was suppressed
- Can be cancelled if user responds in time

### 6. Repeating Notifications

**Goal**: Use iOS repeating notifications where appropriate

**Strategy**:
- For regular schedules (e.g., daily 9am), use repeating UNCalendarNotificationTrigger
- Set `repeats: true` parameter
- Reduces total notification count against iOS 64-notification limit
- Note: May not work well with backup system (re-evaluate if needed)

### 7. Badge Support

**Goal**: Visual indicator when quizzes are due, even without notification sound/banner

**Changes**:
- Set badge on app icon when any quiz is due
- Use simple badge (circle indicator), not a number
- Update badge state:
  - On app launch: Check if any secrets are due
  - On quiz completion: Re-check due state
  - Clear badge when no secrets are due
- Allow badge even if notifications are delivered silently

**Implementation**:
- Use `UNUserNotificationCenter.current().setBadgeCount()`
- Set to 1 when due secrets exist, 0 otherwise

### 8. Time Zone & DST Handling

**Goal**: Maintain correct notification times across time changes

**Changes**:
- Listen for `NSNotification.Name.NSSystemTimeZoneDidChange`
- Listen for `UIApplication.significantTimeChangeNotification`
- On either event:
  - Re-calculate all notification times in new time zone
  - Cancel and re-issue all notifications
  - Update model with new times

**Benefits**:
- Notifications fire at expected local time after travel
- Handles DST transitions automatically

## Implementation Phases

### Phase 1: Foundation
- Create NotificationScheduleModel
- Add to SecretCollection for persistence
- Update notification naming (dev./quiz. prefixes)
- Update identifier generation throughout

### Phase 2: Batch Scheduling
- Implement "next 30 notifications" calculation
- Update SecretsNotificationManager to issue batch
- Test iOS notification limit handling

### Phase 3: Backup Notifications
- Implement primary/backup notification pairing
- Add backup cancellation logic on quiz completion
- Track notification relationships in model

### Phase 4: Badge & Time Zone
- Implement badge update logic
- Add time zone change listeners
- Wire up re-scheduling on time changes

### Phase 5: Repeating Notifications (Optional)
- Evaluate if repeating notifications fit with backup system
- Implement if beneficial
- May defer or skip if complexity outweighs benefits

## Data Model Changes

```swift
struct NotificationScheduleModel: Codable {
    // Upcoming notification events
    var upcomingEvents: [ScheduledNotificationEvent]

    // Last time schedule was generated
    var lastGenerated: Date

    // Current time zone identifier
    var timeZone: String
}

struct ScheduledNotificationEvent: Codable, Identifiable {
    let id: UUID
    let secretId: UUID?  // nil for legacy notifications
    let scheduledTime: Date
    let notificationType: NotificationType

    // Tracking issued notifications
    var primaryNotificationId: String?
    var backupNotificationId: String?
    var issuedToiOS: Bool
}

enum NotificationType: String, Codable {
    case quizPrimary
    case quizBackup
    case dev
    case legacyRegular
    case legacyOneTime
}
```

## Testing Considerations

- Test notification limit (iOS 64 notification cap)
- Test time zone changes while notifications pending
- Test backup notification cancellation on quiz completion
- Test model persistence across app restarts
- Test reconciliation when iOS notifications and model diverge
- Test badge updates with various due secret states
