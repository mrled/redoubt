//
//  MindFortApp.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI


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

    @StateObject private var secretsVm: SecretsViewModel
    
    init() {
        // We can't reference the class demoMode variable here because, we're in the initializer. bleh
        var storage = MFUDStorage()

        // Auto-enable demo mode in simulator
        #if targetEnvironment(simulator)
        if !storage.demoMode {
            storage.demoMode = true
        }
        #endif

        let initDemoMode = storage.demoMode
        if initDemoMode {
            _secretsVm = StateObject(wrappedValue: SecretsViewModel(dataLoader: SecretsVmDataLoaderFromPlist(collectionPlist: MFFStorage().secretsDemoPlist)))
        } else {
            _secretsVm = StateObject(wrappedValue: SecretsViewModel(dataLoader: SecretsVmDataLoaderFromPlist(collectionPlist: MFFStorage().secretsUserPlist)))
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(secretsVm)
        }
    }
}
