//
//  MindFortApp.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI
import os.log


/// MindFort AppStorage keys and defaults
struct MFStorage {
    struct K {
        static let enableEasterEggs = "enableEasterEggs"
        static let scheduleEnabled = "scheduleEnabled"
        static let scheduleType = "scheduleType"
        static let showControlPanel = "showControlPanel"
    }
    struct D {
        static let enableEasterEggs = false
        static let scheduleEnabled = true
        static let scheduleType = ScheduleType.daily
        static let showControlPanel = false
    }
}


class AppDelegate: UIResponder, UIApplicationDelegate {
    let notificationDelegate = NotificationDelegate()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Required to let notifications open different views than the regular app view, etc
        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        return true
    }
}


@main
struct MindFortApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


let appLogger = Logger()
