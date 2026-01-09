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
    
    /// Remove all notifications from the Notification Center for the app, and register schedule-based notifications.
    /// Uses the view model as the source of truth.
    func reregisterAllNotifications() {
        guard let viewModel = secretsViewModel else { return }

        // Check authorization status without prompting
        // Only proceed if already authorized, don't request if notDetermined
        NotificationManager.shared.getAuthorizationStatus { status in
            if status == .authorized {
                appLogger.debug("reregisterAllNotifications: already authorized, registering...")
                NotificationManager.shared.removeNotifications()

                // Schedule notifications based on the schedule system
                self.scheduleBasedOnActiveSchedule()
            } else {
                appLogger.debug("reregisterAllNotifications: not authorized (status: \(status.rawValue)), skipping notification registration")
            }
        }
    }

    /// Schedule notifications based on the active review schedule.
    /// Evaluates due secrets and schedules notifications at the next appropriate time slot.
    /// This method implements the new slot-based notification system with buffer enforcement.
    ///
    /// **Notification identifier format**: `"quiz.YYYY-MM-DD-HH-MM-SS"`
    func scheduleBasedOnActiveSchedule() {
        guard let viewModel = secretsViewModel else { return }

        // Only proceed if there's an active schedule configured
        guard let scheduleId = viewModel.activeScheduleId,
              let schedule = viewModel.availableSchedules.first(where: { $0.id == scheduleId }) else {
            appLogger.debug("No active schedule configured, skipping schedule-based notifications")
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

        // Get buffer from the schedule
        let buffer: TimeInterval
        switch schedule {
        case .expanding(let expandingSchedule):
            buffer = expandingSchedule.minimumSlotBuffer
        }

        // Find the earliest due date across all secrets
        // This works for both currently-due and future secrets since nextNotificationTime
        // will find the next valid slot whether the due date is in the past or future
        let nextDueDates: [Date] = viewModel.secrets.compactMap { secret in
            schedule.nextReviewDate(
                lastQuizzed: secret.lastQuizzed,
                consecutiveSuccesses: secret.consecutiveSuccesses
            )
        }

        guard let earliestDue = nextDueDates.min() else {
            appLogger.debug("No secrets to schedule notifications for")
            return
        }

        let now = Date()
        if let nextTime = nextNotificationTime(
            dueDate: earliestDue,
            slots: slots,
            buffer: buffer,
            now: now
        ) {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextTime)
            addQuizNotification(components: components, prefix: "quiz.", repeats: false)

            let dueCount = viewModel.secretsDue.count
            if dueCount > 0 {
                appLogger.debug("Scheduled schedule-based notification for \(dueCount) due secret(s) at \(nextTime)")
            } else {
                appLogger.debug("Scheduled schedule-based notification for next due date at \(nextTime)")
            }
        } else {
            appLogger.warning("Could not calculate next notification time")
        }
    }
}
