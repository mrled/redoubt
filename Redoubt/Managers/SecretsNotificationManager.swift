import Foundation
import Combine

/**
 * Manages iOS notification scheduling for quiz reminders.
 * 
 * Automatically re-registers notifications when settings change and handles
 * both regular interval and one-time notification schedules.
 */
class SecretsNotificationManager: ObservableObject {
    weak var secretsViewModel: SecretsViewModel?
    
    /// It's easier to keep track of cancellables for regularIntervalsNotifications and oneTimeNotifications in separate arrays
    private var regularIntervalsNotificationsCancellables = Set<AnyCancellable>()
    private var oneTimeNotificationsCancellables = Set<AnyCancellable>()
    
    init() {
        
    }
    
    func setSecretsViewModel(_ viewModel: SecretsViewModel) {
        self.secretsViewModel = viewModel
        setupNotificationSubscriptions()
    }
    
    private func setupNotificationSubscriptions() {
        guard let viewModel = secretsViewModel else { return }
        
        // These subscritions handle making the change in the Notification Center when we change entries
        // We store these in the cancellables property, so they are valid for the lifetime of the SecretsNotificationManager.
        // ([weak self] prevents a memory leak with automatic reference counting.)
        // These are passed by value so we can just use the simpler @Published and don't need to deal with them in setupPublishers()
        viewModel.$regularIntervalNotifications
            .sink { [weak self] _ in
                appLogger.debug("SecretsNotificationManager $regularIntervalEntries .sink: noticed change, reregistering...")
                self?.reregisterAllNotifications()
            }
            .store(in: &regularIntervalsNotificationsCancellables)
        
        viewModel.$oneTimeNotifications
            .sink { [weak self] _ in
                appLogger.debug("SecretsNotificationManager $oneTimeEntries .sink: noticed change, reregistering...")
                self?.reregisterAllNotifications()
            }
            .store(in: &oneTimeNotificationsCancellables)
    }
    
    // MARK: - One Time Notifications
    
    func addOneTimeNotification(_ dateComponents: DateComponents, completion: @escaping () -> Void) {
        guard let viewModel = secretsViewModel else { return }
        viewModel.oneTimeNotifications.append(dateComponents)
        viewModel.dataManager.saveItems()
        reregisterAllNotifications()
        completion()
    }

    func deleteOneTimeNotification(_ dateComponents: DateComponents) {
        guard let viewModel = secretsViewModel else { return }
        if let index = viewModel.oneTimeNotifications.firstIndex(of: dateComponents) {
            viewModel.oneTimeNotifications.remove(at: index)
            viewModel.dataManager.saveItems()
            reregisterAllNotifications()
        }
    }
    
    // MARK: - Regular Interval Notifications
    
    func addRegularIntervalNotification(_ dateComponents: DateComponents, completion: @escaping () -> Void) {
        guard let viewModel = secretsViewModel else { return }
        viewModel.regularIntervalNotifications.append(dateComponents)
        viewModel.dataManager.saveItems()
        reregisterAllNotifications()
        completion()
    }

    func deleteRegularIntervalNotification(_ dateComponents: DateComponents) {
        guard let viewModel = secretsViewModel else { return }
        if let index = viewModel.regularIntervalNotifications.firstIndex(of: dateComponents) {
            viewModel.regularIntervalNotifications.remove(at: index)
            viewModel.dataManager.saveItems()
            reregisterAllNotifications()
        }
    }
    
    /// Remove all notifications from the Notification Center for the app, and register all notifications in this view model.
    /// Uses the view model as the source of truth.
    func reregisterAllNotifications() {
        guard let viewModel = secretsViewModel else { return }
        
        // Don't do anything if the user hasn't granted us notification permissions
        NotificationManager.shared.requestPermission { granted in
            if granted {
                appLogger.debug("reregisterAllNotifications: granted permission to notify, registering...")
                NotificationManager.shared.removeNotifications()
                
                for schedule in viewModel.regularIntervalNotifications {
                    addQuizNotification(components: schedule, prefix: "RegularIntervals-", repeats: true)
                }
                
                for components in viewModel.oneTimeNotifications {
                    addQuizNotification(components: components, prefix: "OneTime-", repeats: false)
                }
                
                // Schedule notifications based on the new schedule system
                self.scheduleBasedOnActiveSchedule()
            } else {
                appLogger.debug("reregisterAllNotifications: not granted permission to notify, nothing we can do")
            }
        }
    }

    // MARK: - Schedule-Based Notifications

    /// Schedule notifications based on the active review schedule.
    /// Evaluates due secrets and schedules notifications at the next appropriate time slot.
    /// This method implements the new slot-based notification system with buffer enforcement.
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
            addQuizNotification(components: components, prefix: "ScheduleBased-", repeats: false)

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
