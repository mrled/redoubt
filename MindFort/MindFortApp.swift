//
//  MindFortApp.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI
import os.log


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
