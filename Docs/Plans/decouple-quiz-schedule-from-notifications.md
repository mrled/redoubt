# Notification Retry System Plan

## Problem

If a notification fires but the user misses it (phone off, focus mode), nothing happens. We need to:
1. Track when secrets are due for review (independent of notifications)
2. Retry notifications at reasonable time slots until the user completes their review

## Architecture

```
Secrets become due (lastQuizzed + duration) → tracked independently
        ↓
Any secrets due? → schedule notification for next time slot
        ↓
User completes quiz → nothing due → stop notifications
User misses it      → still due   → retry at next slot
```

Notifications are generic ("time to practice"), not per-secret.

## Changes Required

### 1. `Secret.swift`
- Add `nextReviewDue: Date?` computed property
- Add `isDueForReview: Bool` computed property

### 2. `SecretsViewModel.swift`
- Add `hasSecretsDueForReview: Bool`
- Add notification time preferences (`morningHour`, `eveningHour`)

### 3. `SecretCollection.swift`
- Persist notification time preferences

### 4. `SecretsNotificationManager.swift`
- Check if any secrets are due
- If due, ensure notification scheduled for next available slot
- After quiz completion, re-evaluate and cancel if nothing due

### 5. App lifecycle (`RedoubtApp.swift` or ViewModel)
- On launch/resume: check due status and schedule accordingly
