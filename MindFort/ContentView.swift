//
//  ContentView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI
import CryptoKit


struct ContentView: View {
    @StateObject private var viewModel = SecretListViewModel(dataLoader: PlistDataLoader())
    var body: some View {
        SecretListView()
            .environmentObject(viewModel)
    }
}
