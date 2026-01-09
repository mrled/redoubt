import Foundation
import UserNotifications


class NotificationManager {
    static let shared = NotificationManager()

    private init() {} // Prevents others from creating their own instances.

    /// Check current notification authorization status without requesting permission
    /// Returns the current authorization status via completion handler
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    /// Checks if we can request notification permission directly, or if user must go to Settings
    /// Returns true if we can show the system permission prompt (status is .notDetermined)
    /// Returns false if user must go to Settings (status is .denied or other)
    func canRequestPermissionDirectly(completion: @escaping (Bool) -> Void) {
        getAuthorizationStatus { status in
            completion(status == .notDetermined)
        }
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true)
                } else {
                    appLogger.error("Request failed with error: \(error?.localizedDescription ?? "N/A")")
                    completion(false)
                }
            }
        }
    }

    /// Update the app badge count based on quiz due status
    /// Pass 1 to show a badge when quizzes are due, 0 to clear the badge
    func setBadgeCount(_ count: Int, completion: @escaping () -> Void = {}) {
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                appLogger.error("Failed to set badge count: \(error.localizedDescription)")
            } else {
                appLogger.debug("Badge count updated to \(count)")
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    /// Register a notification to be presented by any trigger
    /// Arguments:
    /// title:              Title to display to user
    /// body:           Notification body to display to user
    /// identifier:     A unique identifier for storing the notification, see notificationIdentifierFromDateComponents()
    /// trigger:        A trigger for when the notification should run
    /// completion: A function that will run on the main thread if the notification is added successfully
    func registerNotification(title: String, body: String, identifier: String, trigger: UNNotificationTrigger, completion: @escaping () -> Void) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                appLogger.error("Failed to register notification with error: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    /// Remove notifications
    /// pending: Remove notifications that have been registered, but not delivered to the notification center yet (future notifications)
    /// delivered: Remove notifications that have been delivered to the notification center already (past notifications)
    /// prefix: Optional prefix to filter notifications (e.g., "quiz.", "dev."). If nil, removes all notifications.
    /// completion: Called on main thread after removal completes
    func removeNotifications(pending: Bool = true, delivered: Bool = true, prefix: String? = nil, completion: (() -> Void)? = nil) {
        let notificationCenter = UNUserNotificationCenter.current()

        if let prefix = prefix {
            // Remove only notifications matching the prefix
            let group = DispatchGroup()

            if pending {
                group.enter()
                notificationCenter.getPendingNotificationRequests { requests in
                    let identifiersToRemove = requests
                        .filter { $0.identifier.hasPrefix(prefix) }
                        .map { $0.identifier }
                    notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                    group.leave()
                }
            }
            if delivered {
                group.enter()
                notificationCenter.getDeliveredNotifications { notifications in
                    let identifiersToRemove = notifications
                        .filter { $0.request.identifier.hasPrefix(prefix) }
                        .map { $0.request.identifier }
                    notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion?()
            }
        } else {
            // Remove all notifications (synchronous operations)
            if pending {
                notificationCenter.removeAllPendingNotificationRequests()
            }
            if delivered {
                notificationCenter.removeAllDeliveredNotifications()
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    /// List notifications that have been registered but not delivered, including repeating notifications
    func listPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            for request in requests {
                appLogger.info("Pending Notification: \(request.identifier)")
            }
        }
    }
}
