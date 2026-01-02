import Foundation
import UserNotifications


class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    let userDefaults = UserDefaults.standard

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
        
        let demoMode = userDefaults.object(forKey: MFAStorage.K.demoMode) as? Bool ?? MFAStorage.D.demoMode
        if demoMode {
            // Don't respond to notifications at all when the app is in demo mode
            print("userNotificationCenter: In demo mode")
        } else if let action = userInfo[MFAStorage.K.notificationAction] as? String {
            print("userNotificationCenter: Set action to \(action)")
            NotificationActionHandler.shared.handleNotificationAction(action)
        } else {
            print("userNotificationCenter: No action to set")
            NotificationActionHandler.shared.handleNotificationAction(MFAStorage.D.notificationAction)
        }
        
        completionHandler()
    }
}
