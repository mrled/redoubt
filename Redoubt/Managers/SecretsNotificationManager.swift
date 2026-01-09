import Foundation
import Combine

/**
 * Manages iOS notification scheduling for quiz reminders.
 *
 * Automatically re-registers notifications when settings change using the
 * schedule-based notification system.
 */
class SecretsNotificationManager: ObservableObject {
    weak var secretsViewModel: SecretsViewModel?

    init() {

    }

    func setSecretsViewModel(_ viewModel: SecretsViewModel) {
        self.secretsViewModel = viewModel
    }
    
    /// Remove all quiz notifications from the Notification Center, and register schedule-based notifications.
    /// Uses the view model as the source of truth.
    func reregisterAllNotifications() {
        guard secretsViewModel != nil else { return }

        // Check authorization status without prompting
        // Only proceed if already authorized, don't request if notDetermined
        NotificationManager.shared.getAuthorizationStatus { status in
            if status == .authorized {
                appLogger.debug("reregisterAllNotifications: already authorized, removing old quiz notifications...")
                // Cancel only quiz.* notifications (leave dev.* notifications alone)
                NotificationManager.shared.removeNotifications(prefix: "quiz.") {
                    appLogger.debug("reregisterAllNotifications: removal complete, scheduling new notifications...")
                    // Schedule notifications based on the schedule system after removal completes
                    self.scheduleBasedOnActiveSchedule()
                }
            } else {
                appLogger.debug("reregisterAllNotifications: not authorized (status: \(status.rawValue)), skipping notification registration")
            }
        }
    }

    /// Schedule notifications based on the active review schedule using slot-based batch scheduling.
    ///
    /// Phase 4 Implementation:
    /// - Schedules up to 15 notifications at once (iOS allows 64 total per app)
    /// - For each upcoming slot, checks if any secret is due at or before that slot (but after the previous slot)
    /// - Schedules a notification at that slot time if secrets are due
    /// - Notifications repeat daily so users get reminded even if they miss the initial notification
    /// - No buffer enforcement during scheduling (buffer is only enforced in UI when setting slots)
    ///
    /// **Notification identifier format**: `"quiz.YYYY-MM-DD-HH-MM-SS"`
    func scheduleBasedOnActiveSchedule() {
        guard let viewModel = secretsViewModel else { return }

        // Only proceed if there's an active schedule configured
        guard let scheduleId = viewModel.activeScheduleId,
              let schedule = viewModel.availableSchedules.first(where: { $0.id == scheduleId }) else {
            appLogger.debug("No active schedule configured, skipping schedule-based notifications")
            NotificationManager.shared.setBadgeCount(0)
            return
        }

        // Get notification slots (use custom or schedule defaults)
        let slots: [DateComponents]
        if let customSlots = viewModel.notificationSlots {
            slots = customSlots
        } else {
            // Get default slots from the schedule
            switch schedule {
            case .expanding(let expandingSchedule):
                slots = expandingSchedule.defaultSlots
            }
        }

        guard !slots.isEmpty else {
            appLogger.debug("No notification slots configured, skipping schedule-based notifications")
            NotificationManager.shared.setBadgeCount(0)
            return
        }

        // Calculate due dates for all secrets
        let secretDueDates: [Date] = viewModel.secrets.compactMap { secret in
            schedule.nextReviewDate(
                lastQuizzed: secret.lastQuizzed,
                consecutiveSuccesses: secret.consecutiveSuccesses
            )
        }

        appLogger.debug("scheduleBasedOnActiveSchedule: found \(viewModel.secrets.count) secrets with \(secretDueDates.count) due dates")
        if !secretDueDates.isEmpty {
            let earliestDue = secretDueDates.min()!
            let latestDue = secretDueDates.max()!
            appLogger.debug("scheduleBasedOnActiveSchedule: due date range: \(earliestDue) to \(latestDue)")
        }

        guard !secretDueDates.isEmpty else {
            appLogger.debug("scheduleBasedOnActiveSchedule: No secrets to schedule notifications for")
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let maxNotifications = 15
        var scheduledCount = 0

        // Generate upcoming slot times chronologically (check up to 30 days worth)
        var upcomingSlots: [(date: Date, components: DateComponents)] = []
        for dayOffset in 0..<30 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            for slot in slots {
                var components = calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = slot.hour
                components.minute = slot.minute
                components.second = 0

                if let slotDate = calendar.date(from: components), slotDate > now {
                    upcomingSlots.append((date: slotDate, components: components))
                }
            }
        }

        // Sort slots chronologically
        upcomingSlots.sort { $0.date < $1.date }

        appLogger.debug("scheduleBasedOnActiveSchedule: generated \(upcomingSlots.count) upcoming slots")

        // For each slot, check if any secret is due at or before that slot (but after the previous slot)
        var previousSlotDate: Date? = nil

        for slot in upcomingSlots {
            guard scheduledCount < maxNotifications else { break }

            // Check if any secret is due in the window (previousSlot, currentSlot]
            let hasSecretDue = secretDueDates.contains { dueDate in
                if let previousDate = previousSlotDate {
                    // Secret is due after previous slot and at or before current slot
                    return dueDate > previousDate && dueDate <= slot.date
                } else {
                    // First slot: check if secret is due at or before this slot
                    return dueDate <= slot.date
                }
            }

            if hasSecretDue {
                addQuizNotification(components: slot.components, prefix: "quiz.", repeats: true)
                scheduledCount += 1
                appLogger.debug("Scheduled quiz notification #\(scheduledCount) at \(slot.date)")
            }

            previousSlotDate = slot.date
        }

        if scheduledCount > 0 {
            appLogger.debug("Scheduled \(scheduledCount) quiz notification(s) using slot-based batch scheduling")
        } else {
            appLogger.debug("No notifications scheduled (no secrets due in upcoming slots)")
        }

        // Update badge based on current due status
        let badgeCount = viewModel.secretsDue.isEmpty ? 0 : 1
        NotificationManager.shared.setBadgeCount(badgeCount)
    }
}
