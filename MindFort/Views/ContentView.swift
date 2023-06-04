//
//  ContentView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI
import CryptoKit


enum OpenAction: String {
    case home
    case startQuiz
}


struct ContentView: View {
    @StateObject private var secretsModel = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromPlist())
    @StateObject private var notificationsModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromPlist())
    @State private var openAction: OpenAction? = OpenAction(rawValue: UserDefaults.standard.string(forKey: "action") ?? "home") ?? .home
    @State private var notificationsAllowed: Bool = false
    @AppStorage(MFAStorage.K.showControlPanel) var showControlPanel: Bool = MFAStorage.D.showControlPanel
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        SecretListView(openAction: $openAction, notificationsAllowed: $notificationsAllowed, showControlPanel: showControlPanel)
            .environmentObject(secretsModel)
            .environmentObject(notificationsModel)
            .onAppear(perform: {
                // The action key is set by the notification delegate.
                // We want to unset it as soon as we launch,
                // so that it only applies when the user is launching the app by tapping on the notification.
                UserDefaults.standard.removeObject(forKey: "action")
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
