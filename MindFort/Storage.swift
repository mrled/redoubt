//
//  Storage.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-03.
//

import Foundation


/// MindFort AppStorage keys and defaults
struct MFAStorage {
    /// AppStorage keys
    struct K {
        static let enableEasterEggs = "enableEasterEggs"
        static let scheduleEnabled = "scheduleEnabled"
        static let scheduleType = "scheduleType"
        static let showControlPanel = "showControlPanel"
        static let showOnboarding = "showOnboarding"
    }
    /// AppStorage default values
    struct D {
        static let enableEasterEggs = false
        static let scheduleEnabled = true
        static let scheduleType = ScheduleType.daily
        static let showControlPanel = false
        static let showOnboarding = true
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
    
    var secretsPlist: URL { documents.appendingPathComponent("Secrets.plist") }
    var regularIntervalEntriesPlist: URL { documents.appendingPathComponent("RegularIntervalNotifications.plist") }
    var oneTimeEntriesPlist: URL { documents.appendingPathComponent("OneTimeNotifications.plist") }
}
