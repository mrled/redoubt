//
//  ContentView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI
import CryptoKit


struct ContentView: View {
    @StateObject private var viewModel = MindFortViewModel(dataLoader: PlistDataLoader())
    @AppStorage("showControlPanel") var showControlPanel: Bool = false

    var body: some View {
        SecretListView(showControlPanel: showControlPanel)
            .environmentObject(viewModel)
    }
}
