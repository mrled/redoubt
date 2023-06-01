//
//  NotificationList.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-30.
//

import Foundation
import UserNotifications


struct NotificationItem: Identifiable {
    let id: String
    let title: String
    let body: String
    let trigger: UNCalendarNotificationTrigger?
    let triggerDate: DateComponents
}


class NotificationList: ObservableObject {
    @Published var notifications = [NotificationItem]()
    
    func refreshNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            DispatchQueue.main.async {
                self.notifications = requests.map { request in
                    let trigger = request.trigger as? UNCalendarNotificationTrigger
                    return NotificationItem(
                        id: request.identifier,
                        title: request.content.title,
                        body: request.content.body,
                        trigger: trigger,
                        triggerDate: trigger?.dateComponents ?? DateComponents()
                    )
                }
            }
        }
    }
}
