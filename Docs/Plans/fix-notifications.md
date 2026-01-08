# Current Notification Implementation

This document describes how notifications currently work in Redoubt as of January 2026.

**Status**: Phase 0 complete (legacy system removed). Ready for Phase 1 implementation.

## Architecture Overview

The notification system is built on **spaced repetition scheduling** with iOS UserNotifications framework:

- **Three-layer architecture**: Low-level iOS APIs (`NotificationManager`), mid-level orchestration (`SecretsNotificationManager`), and high-level scheduling logic
- **Schedule-based system**: Notifications scheduled based on spaced repetition review schedules with customizable time slots

## Core Components

### NotificationManager
**File**: `Redoubt/Managers/NotificationManager.swift`

Singleton wrapper around iOS `UNUserNotificationCenter`. Key methods: `registerNotification()`, `removeNotifications()`, `listPendingNotifications()`, `getAuthorizationStatus()`.

### SecretsNotificationManager
**File**: `Redoubt/Managers/SecretsNotificationManager.swift`

Coordinates notification scheduling. Core method `reregisterAllNotifications()`:
1. Check authorization status
2. If authorized: remove all existing notifications, call `scheduleBasedOnActiveSchedule()`
3. If not authorized: skip registration

**After Phase 0**: Legacy notification subscriptions removed. Only schedule-based notifications are registered.

## Notification Identifiers

**Legacy (Removed in Phase 0):**
- ~~`"RegularIntervals-YYYY-MM-DD-HH-MM-SS"` (repeating)~~
- ~~`"OneTime-YYYY-MM-DD-HH-MM-SS"` (single)~~

**Current (After Phase 0):**
- `"ScheduleBased-YYYY-MM-DD-HH-MM-SS"` (single from schedule)

**Phase 1 (New prefixed system):**
- `"quiz.YYYY-MM-DD-HH-MM-SS"` (quiz reminder notifications)
- `"dev.test-YYYY-MM-DD-HH-MM-SS"` (developer test notifications)

## Data Storage

**File**: `Redoubt/Models/SecretCollection.swift`

**After Phase 0:**
```swift
struct SecretCollection: Codable {
    let secrets: [Secret]

    // Schedule-based notification system
    let availableSchedules: [ReviewSchedule]      // [Default, OnceDaily]
    let activeScheduleId: UUID?                   // nil = notifications disabled
    let notificationSlots: [DateComponents]?      // nil = use schedule defaults
}
```

**Note**: Legacy `regularIntervalNotifications` and `oneTimeNotifications` fields removed. Existing data with these fields will have them silently dropped on load.

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

### Phase 0: Remove Legacy System ✓

**Status**: Complete

**Goal**: Clean up deprecated notification code before implementing new architecture

**Completed Tasks**:
1. **Removed legacy storage fields** from `SecretCollection`:
   - Deleted `regularIntervalNotifications: [DateComponents]`
   - Deleted `oneTimeNotifications: [DateComponents]`
   - **No migration**: Existing legacy data is silently dropped on load

2. **Removed legacy notification registration** from `SecretsNotificationManager`:
   - Deleted code that re-added regular interval notifications
   - Deleted code that re-added one-time notifications
   - Removed subscription handlers for `viewModel.$regularIntervalNotifications`
   - Removed subscription handlers for `viewModel.$oneTimeNotifications`

3. **Cleaned up legacy identifiers**:
   - Removed generation of `"RegularIntervals-*"` identifiers
   - Removed generation of `"OneTime-*"` identifiers
   - Only `"ScheduleBased-*"` identifiers remain (will be replaced in Phase 1)

**Benefits**:
- Cleaner codebase for implementing new features
- No confusion between old and new systems
- Simpler testing surface

---

### Phase 1: Notification Prefix System

**Goal**: Implement consistent, categorized notification naming

**Scope:**
- Update notification identifiers to use prefixes:
  - `quiz.YYYY-MM-DD-HH-MM-SS` (replace `ScheduleBased-*`)
  - `dev.test-YYYY-MM-DD-HH-MM-SS` (for developer tests)
- Add prefix-based filtering to `NotificationManager.removeNotifications()`

**Files changed:** ~2-3 (NotificationManager, SecretsNotificationManager)
**Risk:** Low (mostly naming changes)

**Testing:**
- Verify all new notifications use prefixed identifiers
- Test filtering notifications by prefix

---

### Phase 2: Developer Tools UI

**Goal**: Enhance DevNotifications screen with prefix-based controls

**Scope:**
- **Test Notification Controls**:
  - "Notify me in 5 seconds" - registers `dev.*` notification for immediate testing
  - "Notify me when minute changes" - registers `dev.*` notification at next minute boundary
  - These call `NotificationManager.shared.registerNotification()` directly (no ViewModel/storage)
  - Dev notifications are ephemeral - not persisted to disk
- **Selective Deletion**:
  - "Delete All Dev Notifications" - removes only `dev.*` notifications
  - "Delete All Quiz Notifications" - removes only `quiz.*` notifications (for testing)
- **Display Improvements**:
  - Group registered notifications by type (`dev.*` vs `quiz.*`)
  - Show count of each notification type
  - Keep existing "Refresh Notifications" and "Re-register All Notifications" buttons

**Files changed:** ~1-2 (DevNotifications view)
**Risk:** Very low (UI only, uses Phase 1's filtering)

**Testing:**
- Test dev notification registration (5 seconds, minute change)
- Verify dev notifications use `dev.*` prefix
- Test selective deletion (dev-only, quiz-only)
- Verify dev notifications are not persisted to storage
- Test notification list grouping by type
- Verify notification counts are displayed correctly

---

### Phase 3: Badge Support

**Goal**: Visual indicator when quizzes are due

**Scope:**
- Implement badge count logic (1 when any quiz due, 0 otherwise)
- Update badge at key moments:
  - App launch/foreground
  - When notifications are scheduled
  - After quiz completion
- Clear badge when notifications disabled
- Use `UNUserNotificationCenter.current().setBadgeCount()`

**Files changed:** ~2-3 (SecretsNotificationManager, possibly ContentView)
**Risk:** Low (additive feature)

**Testing:**
- Test badge updates with various due secret states
- Test badge clears when notifications are disabled
- Verify badge updates on app launch, quiz completion, and notification scheduling

---

### Phase 4: Slot-Based Batch Scheduling

**Goal**: Schedule notifications at configured time slots instead of just-in-time

**Scope:**
- Implement slot-based batch scheduling algorithm:
  - For each configured slot, check if any secret is due before/at that slot (but after the previous slot)
  - Schedule notification at that slot time if so
  - Generate up to 15 notifications at once
- Update `reregisterAllNotifications()` to:
  - Cancel all `quiz.*` notifications before re-issuing
  - Generate notifications for upcoming slots where secrets are due
  - Update badge based on due secrets (or clear if notifications disabled)
- Ensure re-scheduling on every app launch/foreground

**Files changed:** ~1-2 (SecretsNotificationManager)
**Risk:** Medium (complex scheduling logic)

**Testing:**
- Test slot-based scheduling (notifications fire at slot times, not due times)
- Test that a slot gets a notification only when secrets are due before/at it but after the previous slot
- Test notification limit (ensure ≤15 quiz notifications scheduled)
- Test re-scheduling on app foreground
- Test cancellation when notifications are disabled
- Verify all quiz notifications use `quiz.*` prefix

## General Testing Notes

**Cross-Phase Verification:**
- After each phase, verify existing functionality still works
- Test fresh install scenario
- Test upgrade scenario (app with Phase N deployed, upgrading to Phase N+1)
- Verify no notifications are lost during phase transitions

**End-to-End Testing (After Phase 4):**
- Full notification lifecycle: schedule → fire → interact → reschedule
- Time zone changes and DST transitions (known limitation, but verify graceful handling)
- Notification permissions: authorized → denied → re-authorized flow
- Multiple secrets with varying schedules and due dates
