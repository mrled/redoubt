import Foundation


/// Redoubt AppStorage keys and defaults
/// Also used for UserDefaults and UNNotificationResponse.notification.request.content.userInfo
struct MFAStorage {
    /// AppStorage keys
    struct K {
        static let enableEasterEggs = "enableEasterEggs"
        static let showDeveloperOptions = "showDeveloperOptions"
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
        static let showOnboarding = true
        static let onboardingHasShownOnce = false
        static let visualizationMode = VisualizationMode.Sha512
        static let notificationAction = "home"
        static let demoMode = false
    }
}


/// Redoubt file storage keys and defaults
struct MFFStorage {
    let appSupport: URL

    init() {
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access application support directory.")
        }

        // Create the directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating application support directory: \(error)")
        }

        // Exclude the entire app support directory from backups
        var appSupportDirMutable = appSupportDir
        do {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try appSupportDirMutable.setResourceValues(resourceValues)
        } catch {
            print("Error excluding directory from backup: \(error)")
        }

        appSupport = appSupportDir
    }

    var secretsUserPlist: URL { appSupport.appendingPathComponent("SecretsUser.plist") }
    var secretsDemoPlist: URL { appSupport.appendingPathComponent("SecretsDemo.plist") }
    var regularIntervalEntriesPlist: URL { appSupport.appendingPathComponent("RegularIntervalNotifications.plist") }
    var oneTimeEntriesPlist: URL { appSupport.appendingPathComponent("OneTimeNotifications.plist") }
}


/// Redoubt storage for UserDefaults (see also UserDefaultsWrappers file)
extension UserDefaultsWrapperKey {
    static let demoMode: UserDefaultsWrapperKey = "demoMode"
}
struct MFUDStorage {
    @UserDefault(key: .demoMode, defaultValue: false)
    var demoMode: Bool
}
