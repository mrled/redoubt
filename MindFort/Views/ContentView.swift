//
//  ContentView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI
import CryptoKit


struct ContentView: View {
    @AppStorage(MFAStorage.K.demoMode) private var demoMode: Bool = MFAStorage.D.demoMode
    @StateObject private var secretsModel: SecretsViewModel
    @StateObject private var notificationsModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromPlist())
    @StateObject private var notificationActionHandler = NotificationActionHandler.shared
    @State private var notificationsAllowed: Bool = false
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        // We can't reference the class demoMode variable here because, we're in the initializer. bleh
        let initDemoMode = MFUDStorage().demoMode
        if initDemoMode {
            _secretsModel = StateObject(wrappedValue: SecretsViewModel(dataLoader: SecretsVmDataLoaderFromPlist(secretsPlist: MFFStorage().secretsDemoPlist)))
        } else {
            _secretsModel = StateObject(wrappedValue: SecretsViewModel(dataLoader: SecretsVmDataLoaderFromPlist(secretsPlist: MFFStorage().secretsUserPlist)))
        }
    }

    var body: some View {
        SecretListView(openAction: $notificationActionHandler.openAction, notificationsAllowed: $notificationsAllowed)
            .environmentObject(secretsModel)
            .environmentObject(notificationsModel)
            .onAppear(perform: {
                // The action key is set by the notification delegate.
                // We want to unset it as soon as we launch,
                // so that it only applies when the user is launching the app by tapping on the notification.
                UserDefaults.standard.removeObject(forKey: MFAStorage.K.notificationAction)
            })
            .onChange(of: scenePhase) { newScenePhase in
                /// This code runs whenever the scene changes phases.
                /// That includes when the app becomes active, inactive, and backgrounsed. (Maybe more?)
                NotificationManager.shared.requestPermission { granted in
                    notificationsAllowed = granted
                }
            }
    }
}
