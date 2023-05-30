//
//  ContentView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI
import CryptoKit

struct DestinationView {
    let name: String
    let emoji: String
    let destination: (SecretListViewModel) -> AnyView
}


/// You want all this shit to be inside of ContentView, but you can't because viewModel is a property of ContentView,
/// but it isn't available at initialization time or some shit like that.
/// Instead you have to define it out here, and do the weird 'destination: (WhateverViewModel) -> AnyView' thing,
/// to hack around this. idk man.
let destinationViews: [DestinationView] = [
    DestinationView(name: "All passwords", emoji: "🛡️") { viewModel in
        AnyView(SecretListView().environmentObject(viewModel))
    },
    DestinationView(name: "Test now", emoji: "💯") { viewModel in
        AnyView(SecretTrialRunView())
    },
    DestinationView(name: "Settings", emoji: "⚙️") { viewModel in
        AnyView(SettingsView().environmentObject(viewModel))
    },
]


struct ContentView: View {
    @StateObject private var viewModel = SecretListViewModel(dataLoader: PlistDataLoader())
    
    var body: some View {
        NavigationView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(destinationViews, id: \.name) { item in
                    NavigationLink(destination: item.destination(viewModel)) {
                        VStack {
                            Text(item.emoji).font(.largeTitle)
                            Text(item.name)
                        }
                        .padding()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        return ContentView()
    }
}
