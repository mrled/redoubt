//
//  NotificationHelpers.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-10-08.
//

import Foundation
import UserNotifications


func notificationIdentifierFromDateComponents(_ components: DateComponents, prefix: String = "") -> String {
    return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)-\(components.hour ?? 0)-\(components.minute ?? 0)-\(components.second ?? 0)"
}


func addQuizNotification(components: DateComponents, prefix: String, repeats: Bool) {
    print("Going to add a quiz notification...")
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
    let identifier = notificationIdentifierFromDateComponents(components, prefix: prefix)
    
    let content = UNMutableNotificationContent()
    content.title = "Type the magic words"
    content.body = "Time to perform a passphrase ritual 🙏"
    content.userInfo = [MFAStorage.K.notificationAction: "startQuiz"]
    
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { (error) in
        if let error {
            appLogger.error("Error adding notification request with id \(identifier): \(error)")
        } else {
            appLogger.debug("Successfully registered quiz notification with id \(identifier)")
        }
    }
}
