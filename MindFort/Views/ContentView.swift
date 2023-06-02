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
    @AppStorage("showControlPanel") var showControlPanel: Bool = false

    var body: some View {
        SecretListView(openAction: $openAction, showControlPanel: showControlPanel)
            .environmentObject(secretsModel)
            .environmentObject(notificationsModel)
            .onAppear(perform: {
                // The action key is set by the notification delegate.
                // We want to unset it as soon as we launch,
                // so that it only applies when the user is launching the app by tapping on the notification.
                UserDefaults.standard.removeObject(forKey: "action")
            })
    }
}
