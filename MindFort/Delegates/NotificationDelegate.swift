//
//  NotificationDelegate.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-01.
//

import Foundation
import UserNotifications


class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
        -> Void
    ) {
        // note: shouldn't use .alert here, it's deprecated
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping ()
        -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let action = userInfo[MFAStorage.K.notificationAction] as? String {
            print("userNotificationCenter: Set action to \(action)")
            NotificationActionHandler.shared.handleNotificationAction(action)
        } else {
            print("userNotificationCenter: No action to set")
            NotificationActionHandler.shared.handleNotificationAction(MFAStorage.D.notificationAction)
        }
        
        completionHandler()
    }
}
