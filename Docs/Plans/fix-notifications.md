# Current Notification Implementation

This document describes how notifications currently work in Redoubt as of January 2026.

## Architecture Overview

The notification system is built on **spaced repetition scheduling** with iOS UserNotifications framework:

- **Three-layer architecture**: Low-level iOS APIs (`NotificationManager`), mid-level orchestration (`SecretsNotificationManager`), and high-level scheduling logic
- **Legacy system**: Regular interval and one-time notifications (deprecated, to be removed in Phase 0)
- **New system**: Schedule-based notifications with customizable time slots

## Core Components

### NotificationManager
**File**: `Redoubt/Managers/NotificationManager.swift`

Singleton wrapper around iOS `UNUserNotificationCenter`. Key methods: `registerNotification()`, `removeNotifications()`, `listPendingNotifications()`, `getAuthorizationStatus()`.

### SecretsNotificationManager
**File**: `Redoubt/Managers/SecretsNotificationManager.swift`

Coordinates notification scheduling. Core method `reregisterAllNotifications()`:
1. Check authorization status
2. If authorized: remove all existing notifications, re-add legacy notifications, call `scheduleBasedOnActiveSchedule()`
3. If not authorized: skip registration

Subscriptions trigger reregistration on `viewModel.$regularIntervalNotifications` and `viewModel.$oneTimeNotifications` changes.

## Notification Identifiers

- Legacy: `"RegularIntervals-YYYY-MM-DD-HH-MM-SS"` (repeating)
- Legacy: `"OneTime-YYYY-MM-DD-HH-MM-SS"` (single)
- New System: `"ScheduleBased-YYYY-MM-DD-HH-MM-SS"` (single from schedule)

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

## Trigger Points for Re-registration

1. **App becomes active** - reregisters if authorized
2. **Settings change** - toggle, schedule change, time slot modification
3. **Data changes** - secret added/deleted/quizzed
4. **Developer actions** - manual refresh from DevNotifications screen

---

# Planned Improvements

## Current Limitations

1. **Just-in-time scheduling**: Only schedules the next immediate notification, not a batch of upcoming slot notifications
2. **Inconsistent naming**: Notification identifiers lack clear categorization
3. **No badge support**: Users can't see at-a-glance when quizzes are due

## Scope Decisions

The following are explicitly **out of scope** for this work:

- **Backup notifications**: If device is off or in focus mode, notifications may be missed. See backlog for future work.
- **Repeating notifications**: iOS repeating triggers don't fit spaced repetition schedules where intervals change.
- **Time zone & DST handling**: When changing time zones or at DST boundaries, notifications may be wrong until the app is next launched. Acceptable for MVP.

## Proposed Architecture

### 1. Notification Categorization

**Goal**: Clear, consistent notification naming

**Changes**:
- Prefix all notification identifiers by type:
  - `dev.*` - Developer test notifications (from DevNotifications screen)
  - `quiz.*` - Quiz reminder notifications
- Enables selective cancellation and filtering by type

### 2. Slot-Based Batch Scheduling

**Goal**: Schedule notifications at configured time slots instead of just-in-time

**Changes**:
- Notifications only fire at configured time slots (e.g., 9am, 6pm)
- A slot gets a notification if ANY secret is due before or at that slot, but after the previous slot
- Generate up to 15 quiz notifications at once (iOS allows 64 total per app)
- Remaining slots available for dev notifications and future features
- Regenerate all notifications fresh on each app launch/foreground (no persistent tracking needed)
- No buffer enforcement in notification scheduling (buffer is only enforced in UI when setting slots)

### 3. Unified Re-issuing Strategy

**Goal**: Consistent notification refresh logic

**Trigger Points**:
- **App launch/foreground**: Always re-schedule (handles time changes, missed notifications)
- **Data changes**: Schedule modified, secret added/deleted/quizzed
- **Notifications disabled**: Must cancel all `quiz.*` notifications

**Process** (in `reregisterAllNotifications()`):
1. Cancel all `quiz.*` notifications in iOS
2. If notifications enabled:
   a. Generate notification times for upcoming slots where secrets are due
   b. Issue all notifications to iOS (up to 15)
   c. Update badge (1 if secrets due, 0 otherwise)
3. If notifications disabled:
   - Ensure all `quiz.*` notifications are cancelled
   - Clear badge (set to 0)

**Error Handling**:
- Swallow `registerNotification()` errors silently
- See #31 for future work on better user communication of notification failures

### 4. Badge Support

**Goal**: Visual indicator when quizzes are due

**Changes**:
- Set badge on app icon when any quiz is due
- Use badge count of `1` when due, `0` when not due
- Badge is updated only at specific times (no background sync):
  - App launch/foreground
  - When notifications are scheduled (in `reregisterAllNotifications()`)
  - When user completes a quiz
- If notifications disabled: badge = 0

**Implementation**:
- Use `UNUserNotificationCenter.current().setBadgeCount()`

## Implementation Phases

### Phase 0: Remove Legacy System

**Goal**: Clean up deprecated notification code before implementing new architecture

**Tasks**:
1. **Remove legacy storage fields** from `SecretCollection`:
   - Delete `regularIntervalNotifications: [DateComponents]`
   - Delete `oneTimeNotifications: [DateComponents]`
   - Update Codable implementation if needed
   - **No migration**: Simply drop any existing legacy data on load

2. **Remove legacy notification registration** from `SecretsNotificationManager`:
   - Delete code that re-adds regular interval notifications
   - Delete code that re-adds one-time notifications
   - Remove subscription handlers for `viewModel.$regularIntervalNotifications`
   - Remove subscription handlers for `viewModel.$oneTimeNotifications`

3. **Clean up legacy identifiers**:
   - Remove generation of `"RegularIntervals-*"` identifiers
   - Remove generation of `"OneTime-*"` identifiers
   - Document only `"ScheduleBased-*"` identifiers remain (will be replaced in Phase 1)

4. **Update UI**:
   - Remove any UI controls related to legacy notifications
   - Ensure settings only show schedule-based notification options

5. **Testing**:
   - Verify app builds and runs without legacy code
   - Verify existing schedule-based notifications still work
   - Test fresh install scenario

**Benefits**:
- Cleaner codebase for implementing new features
- No confusion between old and new systems
- Simpler testing surface

### Phase 1: Slot-Based Scheduling, Prefixes & Badge
- Update notification naming to use `dev.*`/`quiz.*` prefixes
- Implement slot-based batch scheduling:
  - For each configured slot, check if any secret is due before/at that slot (but after the previous slot)
  - Schedule notification at that slot time if so
  - Generate up to 15 notifications
- Update `reregisterAllNotifications()` to:
  - Cancel all `quiz.*` notifications before re-issuing
  - Generate notifications for upcoming slots where secrets are due
  - Update badge based on due secrets (or clear if notifications disabled)
- Ensure re-scheduling on every app launch/foreground

## Testing Considerations

- Test slot-based scheduling (notifications fire at slot times, not due times)
- Test that a slot gets a notification only when secrets are due before/at it but after the previous slot
- Test notification limit (ensure ≤15 quiz notifications scheduled)
- Test re-scheduling on app foreground
- Test cancellation when notifications are disabled
- Test badge updates with various due secret states
- Test badge clears when notifications are disabled
