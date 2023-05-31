//
//  NotificationManager.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-30.
//

import Foundation
import UserNotifications


class NotificationManager {
    static let shared = NotificationManager()

    private init() {} // Prevents others from creating their own instances.

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true)
                } else {
                    print("Request failed with error: \(error?.localizedDescription ?? "N/A")")
                    completion(false)
                }
            }
        }
    }

    /// Register a notification to be presented by any trigger
    func registerNotification(title: String, body: String, identifier: String, trigger: UNNotificationTrigger) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to register notification with error: \(error.localizedDescription)")
            } else {
                print("Successfully registered notification??")
            }
        }
    }
    
    /// Remove notifications
    /// pending: Remove notifications that have been registered, but not delivered to the notification center yet (future notifications)
    /// delivered: Remove notifications that have been delivered to the notification center already (past notifications)
    func removeNotifications(pending: Bool = true, delivered: Bool = true) {
        let notificationCenter = UNUserNotificationCenter.current()
        if pending {
            notificationCenter.removeAllPendingNotificationRequests()
        }
        if delivered {
            notificationCenter.removeAllDeliveredNotifications()

        }
    }
    
    /// List notifications that have been registered but not delivered, including repeating notifications
    func listPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            for request in requests {
                print("Pending Notification: \(request.identifier)")
            }
        }
    }
}
