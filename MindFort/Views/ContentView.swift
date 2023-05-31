//
//  ContentView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI
import CryptoKit


struct ContentView: View {
    @StateObject private var secretsModel = SecretsViewModel(dataLoader: PlistDataLoader())
    @StateObject private var notificationsModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromPlist())
    @AppStorage("showControlPanel") var showControlPanel: Bool = false

    var body: some View {
        SecretListView(showControlPanel: showControlPanel)
            .environmentObject(secretsModel)
            .environmentObject(notificationsModel)
    }
}
