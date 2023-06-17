//
//  Storage.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-03.
//

import Foundation


/// MindFort AppStorage keys and defaults
/// Also used for UserDefaults and UNNotificationResponse.notification.request.content.userInfo
struct MFAStorage {
    /// AppStorage keys
    struct K {
        static let enableEasterEggs = "enableEasterEggs"
        static let showDeveloperOptions = "showDeveloperOptions"
        static let scheduleEnabled = "scheduleEnabled"
        static let scheduleType = "scheduleType"
        static let showOnboarding = "showOnboarding"
        static let onboardingHasShownOnce = "onboardingHasShownOnce"
        static let visualizationMode = "visualizationMode"
        static let notificationAction = "notificationAction"
        static let demoMode = "demoMode"
    }
    /// AppStorage default values
    struct D {
        static let enableEasterEggs = false
        static let showDeveloperOptions = false
        static let scheduleEnabled = true
        static let scheduleType = ScheduleType.daily
        static let showOnboarding = true
        static let onboardingHasShownOnce = false
        static let visualizationMode = VisualizationMode.Sha512
        static let notificationAction = "home"
        static let demoMode = false
    }
}


/// MindFort file storage keys and defaults
struct MFFStorage {
    let documents: URL
    
    init() {
        if let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            documents = d
        } else {
            fatalError("Unable to access documents directory.")
        }
    }
    
    var secretsUserPlist: URL { documents.appendingPathComponent("SecretsUser.plist") }
    var secretsDemoPlist: URL { documents.appendingPathComponent("SecretsDemo.plist") }
    var regularIntervalEntriesPlist: URL { documents.appendingPathComponent("RegularIntervalNotifications.plist") }
    var oneTimeEntriesPlist: URL { documents.appendingPathComponent("OneTimeNotifications.plist") }
}


/// MindFort storage for UserDefaults (see also UserDefaultsWrappers file)
extension UserDefaultsWrapperKey {
    static let demoMode: UserDefaultsWrapperKey = "demoMode"
}
struct MFUDStorage {
    @UserDefault(key: .demoMode, defaultValue: false)
    var demoMode: Bool
}
